<?php

namespace App\Http\Controllers;

use App\Models\JournalEntry;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class JournalController extends Controller
{
    /**
     * Admin feed: Get all learning journal entries & Preparatory daily wellbeing logs.
     */
    public function index(Request $request)
    {
        $query = JournalEntry::with(['student.school', 'author:id,name,role']);

        if ($request->filled('student_id')) {
            $query->where('student_id', $request->student_id);
        }

        if ($request->filled('type') && $request->type !== 'all') {
            $query->where('type', $request->type);
        }
        if ($request->user()?->role === 'teacher') {
            $teacher = $request->user()->teacherProfile;
            $classNames = $teacher?->assignedClasses()->pluck('class_name') ?? collect();
            $query->whereHas('student', fn ($studentQuery) => $studentQuery->taughtBy($teacher));
        } elseif ($request->user()?->role === 'guardian') {
            $query->whereIn('student_id', $request->user()->students()->select('students.id'));
        } elseif ($request->user()?->role === 'admin') {
            $schoolId = $request->user()->school_id;
            $query->whereHas('student', fn ($studentQuery) => $studentQuery->where('school_id', $schoolId ?? 0));
        } elseif ($request->user()?->role === 'website_admin') {
            // Platform owners can review entries across schools.
        }

        $entries = $query->orderBy('created_at', 'desc')->limit(50)->get()->map(function ($entry) {
            $mediaUrl = $entry->media_url;
            if ($mediaUrl && !Str::startsWith($mediaUrl, ['http://', 'https://'])) {
                $mediaUrl = url($mediaUrl);
            }

            return [
                'id' => $entry->id,
                'student_id' => $entry->student_id,
                'student_name' => $entry->student ? $entry->student->name : 'Learner',
                'grade' => $entry->student ? $entry->student->grade : '',
                'class_name' => $entry->student ? $entry->student->class_name : '',
                'school_name' => $entry->student && $entry->student->school ? $entry->student->school->name : 'Primary School',
                'type' => $entry->type,
                'caption' => $entry->caption,
                'media_url' => $mediaUrl,
                'wellbeing_data' => $entry->wellbeing_data,
                'author_name' => $entry->author ? $entry->author->name : 'School staff',
                'created_at' => $entry->created_at->diffForHumans(),
                'created_at_date' => $entry->created_at->format('d M Y, h:i A'),
            ];
        });

        return response()->json([
            'status' => 'success',
            'entries' => $entries,
            'total' => $entries->count(),
        ]);
    }

    /**
     * Get learning journal entries & Preparatory daily wellbeing logs for single student.
     */
    public function getEntries(Request $request, $student_id)
    {
        $student = Student::findOrFail($student_id);
        $user = $request->user();
        if ($user?->role === 'guardian' && !$user->students()->where('students.id', $student_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'This student is not linked to your account.'], 403);
        }
        if ($user?->role === 'teacher' && (!$user->teacherProfile || (int) $user->teacherProfile->school_id !== (int) $student->school_id || !$user->teacherProfile->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists())) {
            return response()->json(['status' => 'error', 'message' => 'You may only view students in your assigned classes.'], 403);
        }
        $entries = JournalEntry::where('student_id', $student_id)
            ->with('author:id,name,role')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => [
                'student' => [
                    'id' => $student->id,
                    'name' => $student->name,
                    'grade' => $student->grade,
                    'class_name' => $student->class_name,
                ],
                'entries' => $entries
            ]
        ]);
    }

    /**
     * Post a new multimedia work sample or Preparatory daily log.
     */
    public function storeEntry(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|exists:students,id',
            'type' => 'required|in:photo,video,drawing,voice,text,link,wellbeing',
            'caption' => 'nullable|string',
            'media_url' => 'nullable|url:https',
            'subject_name' => 'nullable|string',
            'wellbeing_data' => 'nullable|array',
            'wellbeing_data.meals' => 'nullable|string',
            'wellbeing_data.nap' => 'nullable|string',
            'wellbeing_data.hygiene' => 'nullable|string',
            'wellbeing_data.mood' => 'nullable|string',
            'image' => 'nullable|file|image|max:8192',
            'file' => 'nullable|file|mimes:jpg,jpeg,png,gif,mp4,webm,mp3,wav,m4a,ogg|max:10240',
        ]);

        $student = Student::findOrFail($validated['student_id']);
        $user = $request->user();
        if ($user?->role === 'teacher' && (!$user->teacherProfile || (int) $user->teacherProfile->school_id !== (int) $student->school_id || !$user->teacherProfile->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists())) {
            return response()->json(['status' => 'error', 'message' => 'You may only update students in your assigned classes.'], 403);
        }
        if ($user?->role === 'admin' && (!$user->school_id || (int) $user->school_id !== (int) $student->school_id)) {
            return response()->json(['status' => 'error', 'message' => 'This student is outside your school.'], 403);
        }
        if (!in_array($user?->role, ['teacher', 'admin', 'website_admin'], true)) {
            return response()->json(['status' => 'error', 'message' => 'You may not edit journal entries.'], 403);
        }
        if ($user?->role === 'teacher' && $request->filled('subject_name')) {
            $class = $user->teacherProfile->assignedClasses()->where('grade',$student->grade)->where('class_name',$student->class_name)->first();
            abort_unless($class && $user->teacherProfile->teachesSubject($class,$request->subject_name),403,'Choose an assigned subject.');
        }
        $mediaUrl = $validated['media_url'] ?? null;

        if ($request->hasFile('image') || $request->hasFile('file')) {
            $file = $request->file('image') ?? $request->file('file');
            $filename = 'journal_' . time() . '_' . Str::random(6) . '.' . $file->getClientOriginalExtension();
            $file->storeAs('journal', $filename, 'public');
            $mediaUrl = Storage::disk('public')->url('journal/' . $filename);
        }

        $userId = $request->user() ? $request->user()->id : 1;

        $entry = JournalEntry::create([
            'student_id' => $validated['student_id'],
            'author_id' => $userId,
            'type' => $validated['type'],
            'caption' => $validated['caption'] ?? null,
            'media_url' => $mediaUrl,
            'subject_name' => $validated['subject_name'] ?? null,
            'wellbeing_data' => $validated['wellbeing_data'] ?? null,
            'fee_gated' => false,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Journal entry posted successfully.',
            'data' => $entry->load(['author:id,name,role', 'student'])
        ], 201);
    }

    /**
     * Delete journal entry.
     */
    public function destroy($id)
    {
        $entry = JournalEntry::findOrFail($id);
        $user = request()->user();
        if ($user?->role === 'admin' && !Student::where('id', $entry->student_id)->where('school_id', $user->school_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'This entry is outside your school.'], 403);
        }
        if ($user?->role === 'teacher') {
            $student = Student::find($entry->student_id);
            if (!$student || (int) $student->school_id !== (int) $user->teacherProfile?->school_id || !$user->teacherProfile?->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists()) {
                return response()->json(['status' => 'error', 'message' => 'This entry is outside your assigned classes.'], 403);
            }
            if ((int) $entry->author_id !== (int) $user->id) {
                return response()->json(['status' => 'error', 'message' => 'You may only delete journal entries you created.'], 403);
            }
            $entry->delete();
            return response()->json(['status' => 'success', 'message' => 'Journal entry deleted successfully.']);
        }
        if (!in_array($user?->role, ['admin', 'website_admin'], true)) {
            return response()->json(['status' => 'error', 'message' => 'Only administrators may delete journal entries.'], 403);
        }
        $entry->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Journal entry deleted successfully.'
        ]);
    }
}

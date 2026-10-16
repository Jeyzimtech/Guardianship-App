<?php

namespace App\Http\Controllers;

use App\Models\Assignment;
use App\Models\Student;
use App\Models\SchoolClass;
use Illuminate\Http\Request;

class AssignmentController extends Controller
{
    public function teacherIndex(Request $request)
    {
        $teacher = $request->user()->teacherProfile;
        abort_unless($teacher, 403, 'Teacher profile not found.');
        return response()->json([
            'status' => 'success',
            'classes' => $teacher->assignedClasses()->where('school_classes.school_id',$teacher->school_id)->get(),
            'data' => Assignment::where('created_by', $request->user()->id)->orderByDesc('id')->get(),
        ]);
    }

    /**
     * Get upcoming and overdue assignments for a student
     */
    public function getStudentAssignments(Request $request, $student_id)
    {
        $student = Student::findOrFail($student_id);
        $user = $request->user();
        if ($user?->role === 'guardian' && !$user->students()->where('students.id', $student_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'This student is not linked to your account.'], 403);
        }
        if ($user?->role === 'teacher' && (!$user->teacherProfile || (int) $user->teacherProfile->school_id !== (int) $student->school_id || !$user->teacherProfile->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists())) {
            return response()->json(['status' => 'error', 'message' => 'You may only view students in your assigned classes.'], 403);
        }

        if ($user?->role === 'teacher') {
            $assignedIds = $user->teacherProfile->assignedClasses()->pluck('school_classes.id');
        } else {
            $assignedIds = collect();
        }

        $assignments = Assignment::where(function ($query) use ($student, $user, $assignedIds) {
            $query->whereHas('schoolClass', function ($q) use ($student) {
                $q->where('school_id', $student->school_id)
                  ->where('grade', $student->grade)
                  ->where('class_name', $student->class_name);
            })->when($user?->role === 'teacher', fn ($q) => $q->whereHas('schoolClass', fn ($class) => $class->whereIn('school_classes.id', $assignedIds)))->orWhere(function ($q) use ($student, $user) {
                $q->whereNull('school_class_id')->whereHas('createdBy', function ($author) use ($student) {
                    $author->where('school_id', $student->school_id)->orWhereHas('teacherProfile', fn ($teacher) => $teacher->where('school_id', $student->school_id));
                })->where(function ($legacy) use ($student) {
                    $legacy->where('grade_name', $student->grade)->orWhereNull('grade_name');
                })->when($user?->role === 'teacher', fn ($legacy) => $legacy->where('created_by', $user->id));
            });
        })
        ->orderBy('due_date', 'asc')
        ->get();

        $today = now()->toDateString();
        $upcoming = $assignments->filter(fn($a) => $a->due_date >= $today)->values();
        $overdue = $assignments->filter(fn($a) => $a->due_date < $today)->values();

        return response()->json([
            'status' => 'success',
            'data' => [
                'upcoming' => $upcoming,
                'overdue' => $overdue,
                'all' => $assignments
            ]
        ]);
    }

    /**
     * Create class/subject assignment
     */
    public function storeAssignment(Request $request)
    {
        $validated = $request->validate([
            'grade_name' => 'nullable|string',
            'school_class_id' => 'nullable|exists:school_classes,id',
            'subject_name' => 'nullable|string',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'due_date' => 'required|date',
        ]);

        if ($request->user()->role === 'teacher') {
            $teacher = $request->user()->teacherProfile;
            abort_unless($teacher && !empty($validated['school_class_id']), 422, 'Choose an assigned class.');
            $class = SchoolClass::whereHas('teachers', fn($q) => $q->where('teachers.id', $teacher->id))
                ->find($validated['school_class_id']);
            abort_unless($class, 403, 'You can only assign work to your classes.');
            abort_unless($teacher->teachesSubject($class, $validated['subject_name'] ?? null), 403, 'Choose a subject assigned to you for this class.');
            $validated['grade_name'] = $class->grade;
        }
        if (in_array($request->user()->role, ['admin', 'website_admin'], true) && !empty($validated['school_class_id'])) {
            $class = SchoolClass::findOrFail($validated['school_class_id']);
            if ($request->user()->role === 'admin' && (int) $class->school_id !== (int) $request->user()->school_id) {
                abort(403, 'You can only assign work at your school.');
            }
            $validated['grade_name'] = $class->grade;
        }

        if ($request->user()->role === 'admin') {
            abort_unless(!empty($validated['school_class_id']), 422, 'Choose a class at your school.');
        }
        $assignment = Assignment::create([
            'grade_name' => $validated['grade_name'] ?? null,
            'school_class_id' => $validated['school_class_id'] ?? null,
            'subject_name' => $validated['subject_name'] ?? null,
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'due_date' => $validated['due_date'],
            'created_by' => $request->user()->id,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Assignment created successfully.',
            'data' => $assignment
        ], 201);
    }
}

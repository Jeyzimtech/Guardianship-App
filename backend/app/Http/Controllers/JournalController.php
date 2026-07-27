<?php

namespace App\Http\Controllers;

use App\Models\JournalEntry;
use App\Models\Student;
use Illuminate\Http\Request;

class JournalController extends Controller
{
    /**
     * Get learning journal entries & Preparatory daily wellbeing logs.
     * Note: Journal entries are NEVER fee-gated.
     */
    public function getEntries($student_id)
    {
        $student = Student::findOrFail($student_id);

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
     * Post a new multimedia work sample or Preparatory daily log (Teachers/Caregivers/Admin)
     */
    public function storeEntry(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|exists:students,id',
            'type' => 'required|in:photo,video,drawing,voice,text,link,wellbeing',
            'caption' => 'nullable|string',
            'media_url' => 'nullable|string',
            'subject_name' => 'nullable|string',
            'wellbeing_data' => 'nullable|array',
            'wellbeing_data.meals' => 'nullable|string',
            'wellbeing_data.nap' => 'nullable|string',
            'wellbeing_data.hygiene' => 'nullable|string',
            'wellbeing_data.mood' => 'nullable|string',
        ]);

        $entry = JournalEntry::create([
            'student_id' => $validated['student_id'],
            'author_id' => $request->user()->id,
            'type' => $validated['type'],
            'caption' => $validated['caption'] ?? null,
            'media_url' => $validated['media_url'] ?? null,
            'subject_name' => $validated['subject_name'] ?? null,
            'wellbeing_data' => $validated['wellbeing_data'] ?? null,
            'fee_gated' => false,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Journal entry posted successfully.',
            'data' => $entry->load('author:id,name,role')
        ], 201);
    }
}

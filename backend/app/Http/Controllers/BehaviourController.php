<?php

namespace App\Http\Controllers;

use App\Models\BehaviourIncident;
use App\Models\Student;
use Illuminate\Http\Request;

class BehaviourController extends Controller
{
    /**
     * Get behaviour and merits log snapshot for a student
     */
    public function getStudentBehaviour(Request $request, $student_id)
    {
        $student = Student::findOrFail($student_id);
        $user = $request->user();
        if ($user?->role === 'guardian' && !$user->students()->where('students.id', $student_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'This student is not linked to your account.'], 403);
        }
        if ($user?->role === 'admin' && (!$user->school_id || (int) $user->school_id !== (int) $student->school_id)) {
            return response()->json(['status' => 'error', 'message' => 'This student is outside your school.'], 403);
        }
        if ($user?->role === 'teacher' && (!$user->teacherProfile || (int) $user->teacherProfile->school_id !== (int) $student->school_id || !$user->teacherProfile->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists())) {
            return response()->json(['status' => 'error', 'message' => 'You may only view students in your assigned classes.'], 403);
        }

        $incidents = BehaviourIncident::where('student_id', $student_id)
            ->with('recordedBy:id,name,role')
            ->orderBy('incident_date', 'desc')
            ->get();

        $positiveCount = $incidents->where('polarity', 'positive')->count();
        $negativeCount = $incidents->where('polarity', 'negative')->count();

        return response()->json([
            'status' => 'success',
            'data' => [
                'summary' => [
                    'positive_count' => $positiveCount,
                    'negative_count' => $negativeCount,
                    'net_merits' => $positiveCount - $negativeCount,
                ],
                'incidents' => $incidents->map(function ($incident) {
                    $incident->setAttribute('recorded_by', $incident->recordedBy);
                    return $incident;
                })
            ]
        ]);
    }

    /**
     * Log a new behaviour incident or merit award
     */
    public function storeIncident(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|exists:students,id',
            'polarity' => 'required|in:positive,negative',
            'category' => 'required|string|max:255',
            'note' => 'nullable|string',
            'incident_date' => 'required|date',
        ]);

        $student = Student::findOrFail($validated['student_id']);
        $user = $request->user();
        if ($user?->role === 'teacher' && (!$user->teacherProfile || (int) $user->teacherProfile->school_id !== (int) $student->school_id || !$user->teacherProfile->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists())) {
            return response()->json(['status' => 'error', 'message' => 'You may only update students in your assigned classes.'], 403);
        }
        if ($user?->role === 'admin' && (!$user->school_id || (int) $user->school_id !== (int) $student->school_id)) {
            return response()->json(['status' => 'error', 'message' => 'This student is outside your school.'], 403);
        }

        // Once the school admin has configured categories, incidents must use one of them.
        $configured = \App\Models\BehaviourCategory::where('school_id', $student->school_id)->where('polarity', $validated['polarity']);
        if ((clone $configured)->exists() && !(clone $configured)->where('name', $validated['category'])->exists()) {
            return response()->json(['status' => 'error', 'message' => 'Choose one of the behaviour categories set by your school.'], 422);
        }

        $incident = BehaviourIncident::create([
            'student_id' => $validated['student_id'],
            'polarity' => $validated['polarity'],
            'category' => $validated['category'],
            'note' => $validated['note'] ?? null,
            'recorded_by' => $request->user()->id,
            'incident_date' => $validated['incident_date'],
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Behaviour incident logged successfully.',
            'data' => $incident->load('recordedBy:id,name,role')
        ], 201);
    }
}

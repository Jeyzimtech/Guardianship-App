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
    public function getStudentBehaviour($student_id)
    {
        $student = Student::findOrFail($student_id);

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
                'incidents' => $incidents
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

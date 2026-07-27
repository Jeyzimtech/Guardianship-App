<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Models\Student;
use App\Models\Subscription;
use Illuminate\Http\Request;

class WebsiteAdminController extends Controller
{
    /**
     * Onboard new school on platform (Website Admin only)
     */
    public function onboardSchool(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|in:prep,primary,secondary',
            'primary_admin_name' => 'nullable|string|max:255',
            'primary_admin_email' => 'nullable|email|max:255',
            'primary_admin_phone' => 'nullable|string|max:50',
            'branding_color' => 'nullable|string|max:20',
        ]);

        $school = School::create([
            'name' => $validated['name'],
            'type' => $validated['type'],
            'primary_admin_name' => $validated['primary_admin_name'] ?? null,
            'primary_admin_email' => $validated['primary_admin_email'] ?? null,
            'primary_admin_phone' => $validated['primary_admin_phone'] ?? null,
            'branding_color' => $validated['branding_color'] ?? '#3B5998',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'School onboarded successfully.',
            'data' => $school
        ], 201);
    }

    /**
     * Cross-school student roster directory (Website Admin view-all)
     */
    public function listDirectory(Request $request)
    {
        $schools = School::with(['students' => function ($query) {
            $query->with('activeSubscription');
        }])->get();

        return response()->json([
            'status' => 'success',
            'data' => $schools
        ]);
    }

    /**
     * Toggle a child's subscription on or off with start/end duration
     */
    public function toggleSubscription(Request $request)
    {
        $validated = $request->validate([
            'student_id' => 'required|exists:students,id',
            'status' => 'required|in:active,inactive',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        $subscription = Subscription::create([
            'student_id' => $validated['student_id'],
            'status' => $validated['status'],
            'start_date' => $validated['start_date'] ?? now()->toDateString(),
            'end_date' => $validated['end_date'] ?? null,
            'set_by_user_id' => $request->user()->id,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => "Child subscription set to {$validated['status']}.",
            'data' => $subscription
        ]);
    }

    /**
     * View subscription log per child
     */
    public function getSubscriptionHistory($student_id)
    {
        $student = Student::findOrFail($student_id);
        $history = Subscription::where('student_id', $student_id)
            ->with('setByUser:id,name,email')
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'data' => [
                'student' => $student,
                'history' => $history
            ]
        ]);
    }
}

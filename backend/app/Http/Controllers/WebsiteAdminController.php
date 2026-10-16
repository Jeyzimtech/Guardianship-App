<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Models\Student;
use App\Models\Subscription;
use App\Models\User;
use Illuminate\Support\Str;
use Illuminate\Http\Request;

class WebsiteAdminController extends Controller
{
    /**
     * Onboard new school on platform (Website Admin only)
     */
    public function onboardSchool(Request $request)
    {
        abort_unless($request->user()?->role === 'website_admin', 403);
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

        $admin = null;
        $delivery = null;
        if (!empty($validated['primary_admin_email'])) {
            $admin = User::firstOrNew(['email' => strtolower($validated['primary_admin_email'])]);
            if (!$admin->exists) {
                $admin->fill([
                    'name' => $validated['primary_admin_name'] ?: $school->name . ' Admin',
                    'phone_number' => $validated['primary_admin_phone'] ?: '+school-' . Str::lower(Str::random(12)),
                    'role' => 'admin',
                    'school_id' => $school->id,
                    'account_uid' => 'uid_admin_' . Str::random(20),
                    'password' => \Illuminate\Support\Facades\Hash::make(Str::random(48)),
                ])->save();
            }
            if ($admin->wasRecentlyCreated) {
                $delivery = EmailSettingsController::sendPasswordSetupLink($admin);
            }
        }

        return response()->json([
            'status' => 'success',
            'message' => 'School onboarded successfully.',
            'data' => $school,
            'admin_invited' => isset($delivery) && $delivery['success'],
            'admin_invitation_message' => isset($delivery) ? $delivery['message'] : null,
        ], 201);
    }

    /**
     * Cross-school student roster directory (Website Admin view-all)
     */
    public function listDirectory(Request $request)
    {
        abort_unless($request->user()?->role === 'website_admin', 403);
        $schools = School::with(['students' => function ($query) {
            $query->with(['activeSubscription', 'guardians']);
        }])->get();

        $directory = [];
        foreach ($schools as $school) {
            foreach ($school->students as $student) {
                $guardian = $student->guardians->first();
                $sub = $student->activeSubscription;
                $today = now()->toDateString();
                // No subscription row means the parent still has access (matches CheckChildSubscription).
                $subscriptionStatus = $sub?->status ?? 'active';
                if ($sub && $sub->start_date && $sub->start_date->toDateString() > $today) {
                    $subscriptionStatus = $sub->status === 'inactive' ? 'active' : 'inactive';
                }
                if ($sub && $sub->end_date && $sub->end_date->toDateString() < $today) {
                    $subscriptionStatus = $sub->status === 'inactive' ? 'active' : 'inactive';
                }
                $directory[] = [
                    'student_id' => $student->id,
                    'school_id' => $school->id,
                    'student_name' => $student->name,
                    'grade' => $student->grade,
                    'class_name' => $student->class_name,
                    'school_name' => $school->name,
                    'guardian_name' => $guardian ? $guardian->name : 'N/A',
                    'guardian_phone' => $guardian ? ($guardian->phone_number ?? 'N/A') : 'N/A',
                    'subscription_status' => $subscriptionStatus,
                    'subscription_start' => $sub?->start_date?->toDateString(),
                    'subscription_end' => $sub?->end_date?->toDateString(),
                ];
            }
        }

        return response()->json([
            'status' => 'success',
            'directory' => $directory,
            'data' => $schools
        ]);
    }

    /**
     * Toggle a child's subscription on or off with start/end duration
     */
    public function toggleSubscription(Request $request)
    {
        abort_unless($request->user()?->role === 'website_admin', 403);
        $validated = $request->validate([
            'student_id' => 'required|exists:students,id',
            'status' => 'required|in:active,inactive',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date|after_or_equal:start_date',
        ]);

        $student = Student::findOrFail($validated['student_id']);
        Subscription::where('student_id', $student->id)->update(['status' => 'inactive']);
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
    public function getSubscriptionHistory(Request $request, $student_id)
    {
        abort_unless($request->user()?->role === 'website_admin', 403);
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

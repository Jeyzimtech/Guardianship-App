<?php

namespace App\Http\Controllers;

use App\Models\School;
use App\Models\User;
use Illuminate\Http\Request;

class SchoolController extends Controller
{
    /**
     * Display a listing of schools with counts.
     */
    public function index(Request $request)
    {
        $query = School::withCount(['students', 'teachers', 'schoolClasses']);
        if ($request->user()?->role === 'teacher') {
            $teacherId = $request->user()->teacherProfile?->id;
            $query->whereHas('schoolClasses.teachers', fn ($teachers) => $teachers->where('teachers.id', $teacherId ?? 0));
        }
        if ($request->user()?->role === 'admin') {
            $query->whereKey($request->user()->school_id ?? 0);
        }
        $schools = $query->get();

        return response()->json([
            'status' => 'success',
            'schools' => $schools
        ]);
    }

    /**
     * Store a newly created school.
     */
    public function store(Request $request)
    {
        if ($request->user()?->role === 'admin') {
            return response()->json(['status' => 'error', 'message' => 'Only a platform owner can create a school.'], 403);
        }
        $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|in:prep,primary,secondary',
            'primary_admin_name' => 'nullable|string|max:255',
            'primary_admin_email' => 'nullable|email|max:255',
            'primary_admin_phone' => 'nullable|string|max:50',
            'branding_color' => 'nullable|string|max:20',
        ]);

        $school = School::create([
            'name' => $request->name,
            'type' => $request->type,
            'primary_admin_name' => $request->primary_admin_name,
            'primary_admin_email' => $request->primary_admin_email,
            'primary_admin_phone' => $request->primary_admin_phone,
            'branding_color' => $request->branding_color,
        ]);

        if ($request->filled('primary_admin_email')) {
            $admin = User::firstOrNew(['email' => strtolower($request->primary_admin_email)]);
            if (!$admin->exists) {
                $admin->fill([
                    'name' => $request->primary_admin_name ?: $school->name . ' Admin',
                    'phone_number' => $request->primary_admin_phone ?: '+school-' . \Illuminate\Support\Str::lower(\Illuminate\Support\Str::random(12)),
                    'role' => 'admin',
                    'school_id' => $school->id,
                    'account_uid' => 'uid_admin_' . \Illuminate\Support\Str::random(20),
                    'password' => \Illuminate\Support\Facades\Hash::make(\Illuminate\Support\Str::random(48)),
                ])->save();
                $invitation = EmailSettingsController::sendPasswordSetupLink($admin);
            }
        }

        return response()->json([
            'status' => 'success',
            'message' => 'School created successfully.' . (isset($invitation) ? ($invitation['success'] ? ' Admin invitation sent.' : ' Admin invitation email failed.') : ''),
            'school' => $school,
            'admin_invited' => isset($invitation) && $invitation['success'],
        ], 201);
    }

    /**
     * Display the specified school details.
     */
    public function show($id)
    {
        $school = School::with([
            'students',
            'teachers.user',
            'schoolClasses.academicYear'
        ])->withCount(['students', 'teachers', 'schoolClasses'])->findOrFail($id);
        if (request()->user()?->role === 'teacher' && !$school->schoolClasses()->whereHas('teachers', fn ($teachers) => $teachers->where('teachers.id', request()->user()->teacherProfile?->id ?? 0))->exists()) {
            return response()->json(['status' => 'error', 'message' => 'You may only view schools where you teach.'], 403);
        }
        if (request()->user()?->role === 'admin' && (int) $school->id !== (int) request()->user()->school_id) {
            return response()->json(['status' => 'error', 'message' => 'You may only view your own school.'], 403);
        }

        return response()->json([
            'status' => 'success',
            'school' => $school
        ]);
    }

    /**
     * Update the specified school.
     */
    public function update(Request $request, $id)
    {
        $school = School::findOrFail($id);
        if ($request->user()?->role === 'teacher') {
            return response()->json(['status' => 'error', 'message' => 'Only administrators may edit schools.'], 403);
        }
        if ($request->user()?->role === 'admin' && (int) $request->user()->school_id !== (int) $school->id) {
            return response()->json(['status' => 'error', 'message' => 'You may only manage your own school.'], 403);
        }

        if ($request->user()?->role === 'admin') {
            $request->validate([
                'name' => 'sometimes|required|string|max:255',
                'type' => 'sometimes|required|in:prep,primary,secondary',
                'primary_admin_name' => 'sometimes|nullable|string|max:255',
                'primary_admin_email' => 'sometimes|nullable|email|max:255',
                'primary_admin_phone' => 'sometimes|nullable|string|max:50',
                'branding_color' => 'sometimes|nullable|string|max:20',
            ]);
            $school->update($request->only(['name', 'type', 'primary_admin_name', 'primary_admin_email', 'primary_admin_phone', 'branding_color']));
            return response()->json(['status' => 'success', 'message' => 'School updated successfully.', 'school' => $school]);
        }

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'type' => 'sometimes|required|in:prep,primary,secondary',
        ]);

        $school->update($request->only(['name', 'type']));

        return response()->json([
            'status' => 'success',
            'message' => 'School updated successfully.',
            'school' => $school
        ]);
    }

    /**
     * Remove the specified school.
     */
    public function destroy(Request $request, $id)
    {
        if ($request->user()?->role === 'teacher') {
            return response()->json(['status' => 'error', 'message' => 'Only platform owners may delete schools.'], 403);
        }
        $school = School::findOrFail($id);
        if ($request->user()?->role === 'admin') {
            return response()->json(['status' => 'error', 'message' => 'Only a platform owner can remove a school.'], 403);
        }
        $school->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'School deleted successfully.'
        ]);
    }
}

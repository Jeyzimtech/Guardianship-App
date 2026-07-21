<?php

namespace App\Http\Controllers;

use App\Models\Teacher;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class UserController extends Controller
{
    /**
     * Display a listing of users, optionally filtered by role or search.
     */
    public function index(Request $request)
    {
        $query = User::with(['teacherProfile.school', 'students']);

        if ($request->has('role') && !empty($request->role)) {
            $query->where('role', $request->role);
        }

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->where(function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone_number', 'like', "%{$search}%");
            });
        }

        $users = $query->orderBy('name', 'asc')->get();

        return response()->json([
            'status' => 'success',
            'users' => $users
        ]);
    }

    /**
     * Store a newly created user (Admin, Teacher, or Guardian).
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'nullable|email|unique:users,email',
            'phone_number' => 'required|string|unique:users,phone_number',
            'role' => 'required|in:admin,teacher,guardian',
            'password' => 'nullable|string|min:6',
            'school_id' => 'nullable|exists:schools,id',
            'subject_specialties' => 'nullable|array',
            'student_ids' => 'nullable|array',
            'student_ids.*' => 'exists:students,id',
        ]);

        $password = $request->password ? Hash::make($request->password) : Hash::make(Str::random(16));
        $firebaseUid = 'uid_' . $request->role . '_' . time();

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'phone_number' => $request->phone_number,
            'role' => $request->role,
            'firebase_uid' => $firebaseUid,
            'password' => $password,
        ]);

        if ($request->role === 'teacher') {
            $schoolId = $request->school_id ?? 1;
            Teacher::create([
                'user_id' => $user->id,
                'school_id' => $schoolId,
                'subject_specialties' => $request->subject_specialties ?? [],
            ]);
        }

        if ($request->role === 'guardian' && !empty($request->student_ids)) {
            $user->students()->attach($request->student_ids);
        }

        $user->load(['teacherProfile.school', 'students']);

        return response()->json([
            'status' => 'success',
            'message' => 'User created successfully.',
            'user' => $user
        ], 201);
    }

    /**
     * Display the specified user details.
     */
    public function show(Request $request, $id)
    {
        $currentUser = $request->user();

        // Users can see their own profile, admins can see any profile
        if ($currentUser->role !== 'admin' && $currentUser->id != $id) {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized to view this user profile.'
            ], 403);
        }

        $user = User::with(['teacherProfile.school', 'students'])->findOrFail($id);

        return response()->json([
            'status' => 'success',
            'user' => $user
        ]);
    }

    /**
     * Update the specified user details.
     */
    public function update(Request $request, $id)
    {
        $user = User::findOrFail($id);

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => 'nullable|email|unique:users,email,' . $id,
            'phone_number' => 'sometimes|required|string|unique:users,phone_number,' . $id,
            'role' => 'sometimes|required|in:admin,teacher,guardian',
            'password' => 'nullable|string|min:6',
            'school_id' => 'nullable|exists:schools,id',
            'subject_specialties' => 'nullable|array',
            'student_ids' => 'nullable|array',
            'student_ids.*' => 'exists:students,id',
        ]);

        if ($request->has('name')) $user->name = $request->name;
        if ($request->has('email')) $user->email = $request->email;
        if ($request->has('phone_number')) $user->phone_number = $request->phone_number;
        if ($request->has('role')) $user->role = $request->role;
        if ($request->has('password') && !empty($request->password)) {
            $user->password = Hash::make($request->password);
        }

        $user->save();

        if ($user->role === 'teacher' && ($request->has('school_id') || $request->has('subject_specialties'))) {
            $schoolId = $request->school_id ?? ($user->teacherProfile?->school_id ?? 1);
            Teacher::updateOrCreate(
                ['user_id' => $user->id],
                [
                    'school_id' => $schoolId,
                    'subject_specialties' => $request->subject_specialties ?? ($user->teacherProfile?->subject_specialties ?? []),
                ]
            );
        }

        if ($user->role === 'guardian' && $request->has('student_ids')) {
            $user->students()->sync($request->student_ids);
        }

        $user->load(['teacherProfile.school', 'students']);

        return response()->json([
            'status' => 'success',
            'message' => 'User updated successfully.',
            'user' => $user
        ]);
    }

    /**
     * Remove the specified user.
     */
    public function destroy(Request $request, $id)
    {
        $user = User::findOrFail($id);
        $user->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'User deleted successfully.'
        ]);
    }
}

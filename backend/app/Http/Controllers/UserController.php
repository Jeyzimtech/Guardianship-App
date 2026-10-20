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
        $currentUser = $request->user();
        if ($currentUser?->role === 'admin') {
            $schoolId = $currentUser->school_id ?? 0;
            $query->where(function ($q) use ($schoolId) {
                $q->where('school_id', $schoolId)
                    ->orWhereHas('teacherProfile', fn ($teacher) => $teacher->where('school_id', $schoolId))
                    ->orWhereHas('students', fn ($student) => $student->where('school_id', $schoolId));
            });
        }

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
        $actor = $request->user();
        abort_unless(in_array($actor->role, ['admin', 'teacher'], true), 403);
        abort_unless(($actor->role === 'admin' && $request->role === 'teacher')
            || ($actor->role === 'teacher' && $request->role === 'guardian'), 403,
            'School admins invite teachers; teachers invite parents and guardians.');
        $request->merge(['email' => $request->filled('email') ? strtolower(trim($request->email)) : null]);
        if ($request->role === 'guardian' && $request->filled('phone_number')) $request->merge(['phone_number' => \App\Services\SmsPop::phone((string) $request->phone_number)]);
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required_if:role,teacher|nullable|email|max:255|unique:users,email',
            'phone_number' => 'required_if:role,teacher|nullable|string|max:50|unique:users,phone_number',
            'role' => 'required|in:teacher,guardian',
            'school_id' => 'nullable|exists:schools,id',
            'subject_specialties' => 'nullable|array',
            'student_ids' => 'required_if:role,guardian|array|min:1',
            'student_ids.*' => 'required|integer|distinct|exists:students,id',
        ]);
        if ($actor->role === 'admin') {
            abort_unless($actor->school_id, 403, 'Your account has no school assignment.');
            abort_if($request->filled('school_id') && (int) $request->school_id !== (int) $actor->school_id, 403, 'Select your own school.');
            $schoolId = $actor->school_id;
        } else {
            $teacher = $actor->teacherProfile;
            abort_unless($teacher, 403, 'Your teacher profile has no school assignment.');
            $schoolId = $teacher->school_id;
            foreach (\App\Models\Student::whereIn('id', $data['student_ids'])->get() as $student) {
                abort_unless($teacher->teachesStudent($student), 403, 'You may only invite guardians for students in your assigned classes.');
            }
        }
        if ($data['role'] === 'guardian' && !empty($data['phone_number']) && User::whereIn('phone_number', \App\Services\SmsPop::aliases($data['phone_number']))->exists()) {
            throw \Illuminate\Validation\ValidationException::withMessages(['phone_number' => 'This phone number already has an account.']);
        }
        $user = \Illuminate\Support\Facades\DB::transaction(function () use ($data, $schoolId) {
            $user = User::create([
                'name' => trim($data['name']), 'email' => $data['email'],
                'phone_number' => $data['phone_number'] ?? null, 'role' => $data['role'],
                'school_id' => $data['role'] === 'teacher' ? $schoolId : null,
                'account_uid' => (string) Str::uuid(), 'password' => Str::random(64),
            ]);
            if ($data['role'] === 'teacher') {
                Teacher::create(['user_id' => $user->id, 'school_id' => $schoolId,
                    'subject_specialties' => $data['subject_specialties'] ?? []]);
            } else {
                $user->students()->attach($data['student_ids']);
            }
            return $user;
        });
        $delivery = $user->email ? EmailSettingsController::sendPasswordSetupLink($user) : ['success' => false];
        return response()->json([
            'status' => 'success',
            'message' => !$user->email && !$user->phone_number ? 'Parent account created. Add an email or phone number before the parent can sign in.' : (!$user->email ? 'Parent account created. Sign in with this phone number and an SMS verification code.' : ($delivery['success'] ? 'Account created. A password setup link has been emailed.'
                : 'Account created, but the setup email could not be sent. Please retry the invitation.')),
            'user' => $user->load(['teacherProfile.school', 'students']),
            'email_sent' => $delivery['success'],
        ], 201);
    }

    /**
     * Display the specified user details.
     */
    public function show(Request $request, $id)
    {
        $currentUser = $request->user();

        // Users can see their own profile, admins can see any profile
        if (!in_array($currentUser->role, ['admin', 'website_admin'], true) && $currentUser->id != $id) {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized to view this user profile.'
            ], 403);
        }

        $user = User::with(['teacherProfile.school', 'students'])->findOrFail($id);
        if ($currentUser->role === 'admin' && $user->school_id !== $currentUser->school_id && $user->teacherProfile?->school_id !== $currentUser->school_id) {
            if (!$user->students()->where('students.school_id', $currentUser->school_id)->exists()) {
                return response()->json(['status' => 'error', 'message' => 'You may only view accounts in your school.'], 403);
            }
        }

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
        if ($request->user()?->role === 'admin' && $request->user()->school_id !== $user->school_id && $user->teacherProfile?->school_id !== $request->user()->school_id) {
            if (!$user->students()->where('students.school_id', $request->user()->school_id)->exists()) {
                return response()->json(['status' => 'error', 'message' => 'You may only manage accounts in your school.'], 403);
            }
        }

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => 'nullable|email|unique:users,email,' . $id,
            'phone_number' => ($user->role === 'guardian' ? 'sometimes|nullable|string|unique:users,phone_number,' : 'sometimes|required|string|unique:users,phone_number,') . $id,
            'role' => 'sometimes|required|in:admin,teacher,guardian',
            'password' => 'nullable|string|min:6',
            'school_id' => 'nullable|exists:schools,id',
            'subject_specialties' => 'nullable|array',
            'student_ids' => 'nullable|array',
            'student_ids.*' => 'exists:students,id',
        ]);

        if ($request->user()?->role === 'admin' && $request->has('role') && $request->role !== $user->role) {
            return response()->json(['status' => 'error', 'message' => 'School administrators cannot change account roles.'], 403);
        }
        if ($request->has('student_ids') && \App\Models\Student::whereIn('id', $request->student_ids)->pluck('school_id')->unique()->count() > 1) {
            return response()->json(['status' => 'error', 'message' => 'Select guardian students at one school.'], 422);
        }
        if ($request->user()?->role === 'admin' && $request->has('student_ids') && \App\Models\Student::whereIn('id', $request->student_ids)->where('school_id', '!=', $request->user()->school_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'Selected students must belong to your school.'], 403);
        }

        if ($request->has('name')) $user->name = $request->name;
        if ($request->has('email')) $user->email = $request->email;
        if ($request->has('phone_number')) $user->phone_number = $request->phone_number;
        if ($request->has('role')) $user->role = $request->role;
        if ($request->has('school_id') && $request->user()?->role === 'website_admin') $user->school_id = $request->school_id;
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

        $invitation = null;
        if ($user->role === 'teacher' && $user->email && $request->input('send_invite', true)) {
            $invitation = EmailSettingsController::sendPasswordSetupLink($user);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'User updated successfully.' . ($invitation ? ($invitation['success'] ? ' Password setup link sent.' : ' Password setup email failed.') : ''),
            'user' => $user
        ]);
    }

    /**
     * Remove the specified user.
     */
    public function destroy(Request $request, $id)
    {
        $user = User::findOrFail($id);
        if ($request->user()?->role === 'admin' && $user->school_id !== $request->user()->school_id && $user->teacherProfile?->school_id !== $request->user()->school_id) {
            if (!$user->students()->where('students.school_id', $request->user()->school_id)->exists()) {
                return response()->json(['status' => 'error', 'message' => 'You may only manage accounts in your school.'], 403);
            }
        }
        if ($request->user()?->role === 'admin' && $user->role === 'admin') {
            return response()->json(['status' => 'error', 'message' => 'School administrators cannot delete administrator accounts.'], 403);
        }
        $user->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'User deleted successfully.'
        ]);
    }
}

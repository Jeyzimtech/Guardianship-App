<?php

namespace App\Http\Controllers;

use App\Models\Teacher;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class TeacherController extends Controller
{
    /**
     * Display a listing of teachers with user details and class assignments.
     */
    public function index(Request $request)
    {
        $query = Teacher::with(['user', 'school', 'assignedClasses.school']);
        if ($request->user()?->role === 'admin') {
            $query->where('school_id', $request->user()->school_id ?? 0);
        }

        if ($request->has('school_id') && !empty($request->school_id)) {
            if ($request->user()?->role === 'admin' && (int) $request->school_id !== (int) $request->user()->school_id) {
                return response()->json(['status' => 'error', 'message' => 'You may only view teachers at your school.'], 403);
            }
            $query->where('school_id', $request->school_id);
        }

        if ($request->has('search') && !empty($request->search)) {
            $search = $request->search;
            $query->whereHas('user', function ($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%")
                  ->orWhere('phone_number', 'like', "%{$search}%");
            });
        }

        $teachers = $query->get();

        return response()->json([
            'status' => 'success',
            'teachers' => $teachers
        ]);
    }

    /**
     * Store a newly created teacher profile and assign classes.
     */
    public function store(Request $request)
    {
        if ($request->user()?->role === 'admin') {
            if (!$request->user()->school_id) {
                return response()->json(['status' => 'error', 'message' => 'Administrator account has no school assignment.'], 403);
            }
            $request->merge(['school_id' => $request->user()->school_id]);
        }
        if ($request->user()?->role === 'website_admin' && !$request->has('user_id')) {
            return response()->json(['status' => 'error', 'message' => 'Create a school user account before assigning a teacher profile.'], 422);
        }
        $request->validate([
            'subject_specialties' => 'nullable|array',
            'class_assignments' => 'nullable|array',
            'class_assignments.*.school_class_id' => 'required_with:class_assignments|exists:school_classes,id',
            'class_assignments.*.subject_name' => 'nullable|string',
        ]);
        if ($request->filled('class_name')) {
            abort_unless(\App\Models\SchoolClass::where('school_id', $request->school_id)->where('class_name', $request->class_name)->exists(), 422, 'Select a class at your school.');
        }
        if (!empty($request->class_assignments)) {
            abort_if(\App\Models\SchoolClass::whereIn('id', collect($request->class_assignments)->pluck('school_class_id'))->where('school_id', '!=', $request->school_id)->exists(), 422, 'Assigned classes must belong to your school.');
        }
        if (!$request->has('user_id') && $request->filled('name')) {
            if ($request->user()?->role === 'admin') {
                $request->merge(['school_id' => $request->user()->school_id]);
            }
            $request->validate([
                'name' => 'required|string|max:255',
                'email' => 'required|email|unique:users,email',
                'phone' => 'required|string|unique:users,phone_number',
                'school_id' => 'required|exists:schools,id',
            ]);
            $user = User::create([
                'school_id' => $request->school_id,
                'name' => $request->name,
                'email' => $request->email,
                'phone_number' => $request->phone,
                'role' => 'teacher',
                'password' => \Illuminate\Support\Facades\Hash::make(\Illuminate\Support\Str::random(48)),
                'account_uid' => (string) \Illuminate\Support\Str::uuid(),
            ]);
            $request->merge(['user_id' => $user->id]);
        }

        $request->validate([
            'user_id' => 'required|exists:users,id',
            'school_id' => 'required|exists:schools,id',
            'subject_specialties' => 'nullable|array',
            'class_assignments' => 'nullable|array',
            'class_assignments.*.school_class_id' => 'required_with:class_assignments|exists:school_classes,id',
            'class_assignments.*.subject_name' => 'nullable|string',
        ]);

        if (!empty($request->class_assignments) && \App\Models\SchoolClass::whereIn('id', collect($request->class_assignments)->pluck('school_class_id'))->where('school_id', '!=', $request->school_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'Assigned classes must belong to the selected school.'], 422);
        }

        // Ensure user is marked as teacher
        $user = User::findOrFail($request->user_id);
        if ($request->user()?->role === 'admin' && $user->role !== 'teacher') {
            return response()->json(['status' => 'error', 'message' => 'You may only manage teachers at your school.'], 403);
        }
        if ($user->role !== 'teacher') {
            return response()->json(['status' => 'error', 'message' => 'Select a teacher account.'], 422);
        }
        if ($request->user()?->role === 'admin' && $user->teacherProfile && (int) $user->teacherProfile->school_id !== (int) $request->user()->school_id) {
            return response()->json(['status' => 'error', 'message' => 'You may only manage teachers at your school.'], 403);
        }
        $teacher = Teacher::updateOrCreate(
            ['user_id' => $request->user_id],
            [
                'school_id' => $request->school_id,
                'subject_specialties' => $request->subject_specialties ?? [],
            ]
        );

        if ($request->has('class_assignments')) {
            $teacher->assignedClasses()->detach();
            foreach ($request->class_assignments as $assignment) {
                $teacher->assignedClasses()->attach($assignment['school_class_id'], [
                    'subject_name' => $assignment['subject_name'] ?? 'General',
                ]);
            }
        }

        if (!$request->has('class_assignments') && $request->filled('class_name')) {
            $class = \App\Models\SchoolClass::where('school_id', $teacher->school_id)->where('class_name', $request->class_name)->first();
            if (!$class) {
                return response()->json(['status' => 'error', 'message' => 'Select a class belonging to this school.'], 422);
            }
            $teacher->assignedClasses()->syncWithoutDetaching([$class->id => [
                'subject_name' => $request->input('subject_specialties.0', 'General'),
            ]]);
        }

        $teacher->load(['user', 'school', 'assignedClasses.school']);

        $invitation = null;
        if ($teacher->user?->email) {
            $invitation = EmailSettingsController::sendPasswordSetupLink($teacher->user);
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Teacher profile created successfully.' . ($invitation ? ($invitation['success'] ? ' Setup link sent.' : ' Setup email could not be delivered.') : ''),
            'teacher' => $teacher,
            'email_sent' => $invitation['success'] ?? false,
        ], 201);
    }

    /**
     * Display the specified teacher profile.
     */
    public function show($id)
    {
        $teacher = Teacher::with(['user', 'school', 'assignedClasses.school', 'assignedClasses.academicYear'])->findOrFail($id);
        if (request()->user()?->role === 'teacher' && $teacher->id !== request()->user()->teacherProfile?->id) {
            return response()->json(['status' => 'error', 'message' => 'You may only view your teacher profile.'], 403);
        }
        if (request()->user()?->role === 'admin' && (int) $teacher->school_id !== (int) request()->user()->school_id) {
            return response()->json(['status' => 'error', 'message' => 'You may only view teachers at your school.'], 403);
        }

        return response()->json([
            'status' => 'success',
            'teacher' => $teacher,
            'email_sent' => $invitation['success'] ?? false,
        ]);
    }

    /**
     * Update teacher profile, subject specialties, and class assignments.
     */
    public function update(Request $request, $id)
    {
        $teacher = Teacher::findOrFail($id);
        if ($request->user()?->role === 'teacher') {
            return response()->json(['status' => 'error', 'message' => 'Teachers may not edit teacher profiles.'], 403);
        }
        if ($request->user()?->role === 'admin' && $teacher->school_id !== $request->user()->school_id) {
            return response()->json(['status' => 'error', 'message' => 'You may only manage teachers at your school.'], 403);
        }
        if ($request->filled('school_id') && $request->user()?->role !== 'website_admin' && (int) $request->school_id !== (int) $teacher->school_id) {
            return response()->json(['status' => 'error', 'message' => 'Only platform owners may move teachers between schools.'], 403);
        }

        $request->validate([
            'school_id' => 'sometimes|required|exists:schools,id',
            'subject_specialties' => 'nullable|array',
            'class_assignments' => 'nullable|array',
            'class_assignments.*.school_class_id' => 'required_with:class_assignments|exists:school_classes,id',
            'class_assignments.*.subject_name' => 'nullable|string',
        ]);

        if ($request->user()?->role === 'admin' && $request->filled('school_id') && (int) $request->school_id !== (int) $teacher->school_id) {
            return response()->json(['status' => 'error', 'message' => 'You may not move a teacher to another school.'], 403);
        }
        if ($request->has('class_assignments')) {
            $ids = collect($request->class_assignments)->pluck('school_class_id');
            $targetSchoolId = $request->input('school_id', $teacher->school_id);
            if (\App\Models\SchoolClass::whereIn('id', $ids)->where('school_id', '!=', $targetSchoolId)->exists()) {
                return response()->json(['status' => 'error', 'message' => 'Assigned classes must belong to the teacher school.'], 422);
            }
        }
        if ($request->has('name') || $request->has('email') || $request->has('phone_number')) {
            $request->validate([
                'name' => 'sometimes|required|string|max:255',
                'email' => 'sometimes|nullable|email|unique:users,email,' . $teacher->user_id,
                'phone_number' => 'sometimes|required|string|max:50|unique:users,phone_number,' . $teacher->user_id,
            ]);
        }

        if ($request->has('school_id')) $teacher->school_id = $request->school_id;
        if ($request->has('subject_specialties')) $teacher->subject_specialties = $request->subject_specialties;
        $teacher->save();

        if ($request->has('name') || $request->has('email') || $request->has('phone_number')) {
            $user = $teacher->user;
            if ($user) {
                if ($request->filled('name')) $user->name = $request->name;
                if ($request->filled('email')) $user->email = $request->email;
                if ($request->filled('phone_number')) $user->phone_number = $request->phone_number;
                $user->save();
            }
        }

        if ($request->has('class_assignments')) {
            $teacher->assignedClasses()->detach();
            foreach ($request->class_assignments as $assignment) {
                $teacher->assignedClasses()->attach($assignment['school_class_id'], [
                    'subject_name' => $assignment['subject_name'] ?? 'General',
                ]);
            }
        }

        $teacher->load(['user', 'school', 'assignedClasses.school']);

        return response()->json([
            'status' => 'success',
            'message' => 'Teacher profile updated successfully.',
            'teacher' => $teacher,
            'email_sent' => $invitation['success'] ?? false,
        ]);
    }

    /**
     * Remove teacher record.
     */
    public function destroy(Request $request, $id)
    {
        if ($request->user()?->role === 'teacher') {
            return response()->json(['status' => 'error', 'message' => 'Only administrators may remove teacher accounts.'], 403);
        }
        $teacher = Teacher::findOrFail($id);
        if ($request->user()?->role === 'admin' && (int) $teacher->school_id !== (int) $request->user()->school_id) {
            return response()->json(['status' => 'error', 'message' => 'You may only manage teachers at your school.'], 403);
        }
        if ($request->has('class_assignments')) {
            $classIds = collect($request->class_assignments)->pluck('school_class_id');
            if (\App\Models\SchoolClass::whereIn('id', $classIds)->where('school_id', '!=', $teacher->school_id)->exists()) {
                return response()->json(['status' => 'error', 'message' => 'Assigned classes must belong to the teacher school.'], 422);
            }
        }
        if ($request->has('class_assignments') && \App\Models\SchoolClass::whereIn('id', collect($request->class_assignments)->pluck('school_class_id'))->where('school_id', '!=', $request->filled('school_id') ? $request->school_id : $teacher->school_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'Assigned classes must belong to the teacher school.'], 422);
        }
        $teacher->delete();
        $teacher->user?->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Teacher record deleted successfully.'
        ]);
    }
}

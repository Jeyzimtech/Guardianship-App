<?php

namespace App\Http\Controllers;

use App\Models\Teacher;
use App\Models\User;
use Illuminate\Http\Request;

class TeacherController extends Controller
{
    /**
     * Display a listing of teachers with user details and class assignments.
     */
    public function index(Request $request)
    {
        $query = Teacher::with(['user', 'school', 'assignedClasses.school']);

        if ($request->has('school_id') && !empty($request->school_id)) {
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
        $request->validate([
            'user_id' => 'required|exists:users,id',
            'school_id' => 'required|exists:schools,id',
            'subject_specialties' => 'nullable|array',
            'class_assignments' => 'nullable|array',
            'class_assignments.*.school_class_id' => 'required_with:class_assignments|exists:school_classes,id',
            'class_assignments.*.subject_name' => 'nullable|string',
        ]);

        // Ensure user is marked as teacher
        $user = User::findOrFail($request->user_id);
        if ($user->role !== 'teacher') {
            $user->role = 'teacher';
            $user->save();
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

        $teacher->load(['user', 'school', 'assignedClasses.school']);

        return response()->json([
            'status' => 'success',
            'message' => 'Teacher profile created successfully.',
            'teacher' => $teacher
        ], 201);
    }

    /**
     * Display the specified teacher profile.
     */
    public function show($id)
    {
        $teacher = Teacher::with(['user', 'school', 'assignedClasses.school', 'assignedClasses.academicYear'])->findOrFail($id);

        return response()->json([
            'status' => 'success',
            'teacher' => $teacher
        ]);
    }

    /**
     * Update teacher profile, subject specialties, and class assignments.
     */
    public function update(Request $request, $id)
    {
        $teacher = Teacher::findOrFail($id);

        $request->validate([
            'school_id' => 'sometimes|required|exists:schools,id',
            'subject_specialties' => 'nullable|array',
            'class_assignments' => 'nullable|array',
            'class_assignments.*.school_class_id' => 'required_with:class_assignments|exists:school_classes,id',
            'class_assignments.*.subject_name' => 'nullable|string',
        ]);

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
            'teacher' => $teacher
        ]);
    }

    /**
     * Remove teacher record.
     */
    public function destroy($id)
    {
        $teacher = Teacher::findOrFail($id);
        $teacher->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Teacher record deleted successfully.'
        ]);
    }
}

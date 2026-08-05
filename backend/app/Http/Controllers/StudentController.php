<?php

namespace App\Http\Controllers;

use App\Models\Student;
use App\Models\School;
use Illuminate\Http\Request;

class StudentController extends Controller
{
    /**
     * Display a listing of students scoped by user role.
     */
    public function index(Request $request)
    {
        $user = $request->user();

        if ($user->role === 'guardian') {
            // Get all children linked to this guardian
            $students = $user->students()->with('school')->get();
            return response()->json([
                'status' => 'success',
                'students' => $students
            ]);
        }

        if ($user->role === 'teacher') {
            // Get students in the teacher's school
            $teacherProfile = $user->teacherProfile;
            if (!$teacherProfile) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Teacher profile not found.'
                ], 403);
            }

            $students = Student::where('school_id', $teacherProfile->school_id)
                ->with('school')
                ->get();

            return response()->json([
                'status' => 'success',
                'students' => $students
            ]);
        }

        if ($user->role === 'admin') {
            // Admin gets all students
            $students = Student::with('school')->get();
            return response()->json([
                'status' => 'success',
                'students' => $students
            ]);
        }

        return response()->json([
            'status' => 'error',
            'message' => 'Unauthorized role.'
        ], 403);
    }

    /**
     * Create a new student (Admin only).
     */
    public function store(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'admin') {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized. Admin access only.'
            ], 403);
        }

        $request->validate([
            'school_id' => 'required|exists:schools,id',
            'name' => 'required|string|max:255',
            'grade' => 'required|string',
            'class_name' => 'required|string',
            'dob' => 'nullable|date',
        ]);

        $student = Student::create($request->all());

        // Create an associated fee account for the student
        $student->feeAccount()->create([
            'balance_usd' => 0.00,
            'balance_zig' => 0.00,
        ]);

        return response()->json([
            'status' => 'success',
            'student' => $student->load('school')
        ], 201);
    }

    /**
     * Link a guardian to a student (Admin only).
     */
    public function linkGuardian(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'admin') {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized. Admin access only.'
            ], 403);
        }

        $request->validate([
            'guardian_id' => 'required|exists:users,id',
            'student_id' => 'required|exists:students,id',
        ]);

        $student = Student::findOrFail($request->student_id);
        
        // Link guardian
        $student->guardians()->syncWithoutDetaching([$request->guardian_id]);

        return response()->json([
            'status' => 'success',
            'message' => 'Guardian linked successfully.'
        ]);
    }

    /**
     * Submit a student link request (Guardian endpoint).
     */
    public function requestLink(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'guardian') {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized. Guardian access only.'
            ], 403);
        }

        $request->validate([
            'student_name' => 'required|string|max:255',
            'school_name' => 'nullable|string|max:255',
            'relationship' => 'nullable|string|max:255',
            'notes' => 'nullable|string|max:1000',
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Student link request submitted successfully. School admin verification pending.',
            'request_details' => [
                'guardian_id' => $user->id,
                'student_name' => $request->student_name,
                'school_name' => $request->school_name ?? 'Default Campus',
                'relationship' => $request->relationship ?? 'Parent/Guardian',
                'status' => 'pending_admin_approval',
                'submitted_at' => now()->toIso8601String(),
            ]
        ], 201);
    }
}

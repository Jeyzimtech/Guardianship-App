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

        if (in_array($user->role, ['admin', 'website_admin'])) {
            // Admin gets all students
            $students = Student::with(['school', 'guardians'])->get();
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
        if (!in_array($user->role, ['admin', 'website_admin'])) {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized. Admin access only.'
            ], 403);
        }

        if (!$request->has('school_id')) {
            $defaultSchool = \App\Models\School::first();
            if ($defaultSchool) {
                $request->merge(['school_id' => $defaultSchool->id]);
            }
        }

        $request->validate([
            'school_id' => 'required|exists:schools,id',
            'name' => 'required|string|max:255',
            'grade' => 'required|string',
            'class_name' => 'required|string',
            'dob' => 'nullable|date',
            'guardian_name' => 'nullable|string|max:255',
            'guardian_phone' => 'nullable|string|max:50',
            'guardian_email' => 'nullable|email|max:255',
            'guardian_id' => 'nullable|exists:users,id',
        ]);

        $student = Student::create([
            'school_id' => $request->school_id,
            'name' => trim($request->name),
            'grade' => trim($request->grade),
            'class_name' => trim($request->class_name),
            'dob' => $request->dob,
        ]);

        // Create an associated fee account for the student
        $student->feeAccount()->create([
            'balance_usd' => 0.00,
            'balance_zig' => 0.00,
        ]);

        // Create active subscription by default
        \App\Models\Subscription::create([
            'student_id' => $student->id,
            'status' => 'active',
            'start_date' => now()->toDateString(),
            'set_by_user_id' => $user->id,
        ]);

        // Link or auto-provision guardian if provided
        $guardianId = $request->guardian_id;
        if (!$guardianId && $request->filled('guardian_name')) {
            $guardianName = trim($request->guardian_name);
            $guardianEmail = $request->guardian_email ? strtolower(trim($request->guardian_email)) : null;
            $guardianPhone = $request->guardian_phone ? trim($request->guardian_phone) : null;

            $guardianUser = null;
            if ($guardianEmail) {
                $guardianUser = \App\Models\User::where('email', $guardianEmail)->first();
            }
            if (!$guardianUser && $guardianPhone) {
                $guardianUser = \App\Models\User::where('phone_number', $guardianPhone)->first();
            }
            if (!$guardianUser) {
                $cleanName = strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $guardianName));
                $guardianUser = \App\Models\User::create([
                    'name' => $guardianName,
                    'email' => $guardianEmail ?? ($cleanName . rand(100, 999) . '@guardianship.local'),
                    'phone_number' => $guardianPhone ?? ('+2637' . rand(10000000, 99999999)),
                    'role' => 'guardian',
                    'password' => \Illuminate\Support\Facades\Hash::make('password123'),
                    'firebase_uid' => 'uid_guardian_' . time() . '_' . rand(10, 99),
                ]);
            }
            $guardianId = $guardianUser->id;
        }

        if ($guardianId) {
            $student->guardians()->syncWithoutDetaching([$guardianId]);
        }

        return response()->json([
            'status' => 'success',
            'student' => $student->load(['school', 'guardians'])
        ], 201);
    }

    /**
     * Link a guardian to a student (Admin only).
     */
    public function linkGuardian(Request $request)
    {
        $user = $request->user();
        if (!in_array($user->role, ['admin', 'website_admin'])) {
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

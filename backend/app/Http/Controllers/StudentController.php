<?php

namespace App\Http\Controllers;

use App\Models\Student;
use App\Models\School;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

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

            $classNames = $teacherProfile->assignedClasses()->pluck('class_name');
            $students = Student::taughtBy($teacherProfile)
                ->with('school')
                ->get();

            return response()->json([
                'status' => 'success',
                'students' => $students
            ]);
        }

        if (in_array($user->role, ['admin', 'website_admin'])) {
            // Admin gets all students
            $students = Student::with(['school', 'guardians'])
                ->when($user->role === 'admin', fn ($q) => $q->where('school_id', $user->school_id ?? 0))
                ->get();
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

    /** Enroll a student: school admins into any class at their school, teachers into their assigned classes. */
    public function store(Request $request)
    {
        $user = $request->user();
        abort_unless(in_array($user->role, ['teacher'], true), 403, 'Teachers enroll students in their assigned classes.');

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'class_id' => 'required|integer|exists:school_classes,id',
            'dob' => 'nullable|date',
            'guardian_name' => 'nullable|string|max:255',
            'guardian_phone' => 'required_with:guardian_name|nullable|string|max:50',
            'guardian_email' => 'nullable|email|max:255',
            'guardian_id' => 'nullable|exists:users,id',
        ]);

        if ($user->role === 'admin') {
            abort_unless($user->school_id, 403, 'Administrator account has no school assignment.');
            $class = \App\Models\SchoolClass::where('school_id', $user->school_id)->find($validated['class_id']);
            abort_unless($class, 403, 'You may only enroll students in classes at your school.');
        } else {
            $teacher = $user->teacherProfile;
            abort_unless($teacher, 403, 'Teacher profile not found.');
            $class = $teacher->assignedClasses()->whereKey($validated['class_id'])->first();
            abort_unless($class, 403, 'You may only enroll students in your assigned classes.');
        }

        if (!empty($validated['guardian_phone'])) $validated['guardian_phone'] = \App\Services\SmsPop::phone($validated['guardian_phone']);

        $guardian = null;
        if (!empty($validated['guardian_id'])) {
            $guardian = \App\Models\User::whereKey($validated['guardian_id'])->where('role', 'guardian')->first();
            abort_unless($guardian, 422, 'Select a parent or guardian account.');
        } elseif (!empty($validated['guardian_name'])) {
            $email = !empty($validated['guardian_email']) ? strtolower(trim($validated['guardian_email'])) : null;
            $phone = !empty($validated['guardian_phone']) ? trim($validated['guardian_phone']) : null;
            $guardian = $email ? \App\Models\User::where('email', $email)->first() : null;
            if (!$guardian && $phone) $guardian = \App\Models\User::whereIn('phone_number', \App\Services\SmsPop::aliases($phone))->first();
            if ($guardian) {
                abort_unless($guardian->role === 'guardian', 422, 'The matching account is not a guardian.');
                abort_unless(\App\Services\SmsPop::phone($guardian->phone_number) === $phone, 422, 'This email belongs to a different phone number. Check the parent details.');
            }
        }

        $student = DB::transaction(function () use ($validated, $class, $guardian, $user) {
            $student = Student::create([
                'school_id' => $class->school_id,
                'name' => trim($validated['name']),
                'grade' => $class->grade,
                'class_name' => $class->class_name,
                'dob' => $validated['dob'] ?? null,
            ]);
            $student->feeAccount()->create(['balance_usd' => 0.00, 'balance_zig' => 0.00]);
            \App\Models\Subscription::create([
                'student_id' => $student->id,
                'status' => 'active',
                'start_date' => now()->toDateString(),
                'set_by_user_id' => $user->id,
            ]);
            if (!$guardian && !empty($validated['guardian_name'])) {
                $guardianName = trim($validated['guardian_name']);
                $guardianEmail = !empty($validated['guardian_email']) ? strtolower(trim($validated['guardian_email'])) : null;
                $guardianPhone = !empty($validated['guardian_phone']) ? trim($validated['guardian_phone']) : null;
                $cleanName = strtolower(preg_replace('/[^a-zA-Z0-9]/', '', $guardianName));
                $guardian = \App\Models\User::create([
                    'name' => $guardianName,
                    'email' => $guardianEmail,
                    'phone_number' => $guardianPhone,
                    'role' => 'guardian',
                    'password' => \Illuminate\Support\Facades\Hash::make(\Illuminate\Support\Str::random(64)),
                    'account_uid' => 'uid_guardian_' . time() . '_' . rand(10, 99),
                ]);
                if ($guardianEmail) EmailSettingsController::sendPasswordSetupLink($guardian);
            }
            if ($guardian) $student->guardians()->syncWithoutDetaching([$guardian->id]);
            return $student;
        });

        return response()->json([
            'status' => 'success',
            'student' => $student->load(['school', 'guardians'])
        ], 201);
    }

    public function update(Request $request, int $id)
    {
        $user = $request->user();
        abort_unless($user?->role === 'admin' && $user->school_id, 403);
        $student = Student::where('school_id', $user->school_id)->findOrFail($id);
        $data = $request->validate([
            'name' => 'required|string|max:255',
            'class_id' => 'required|integer|exists:school_classes,id',
            'dob' => 'nullable|date',
        ]);
        $class = \App\Models\SchoolClass::where('school_id', $user->school_id)->findOrFail($data['class_id']);
        $student->update([
            'name' => trim($data['name']),
            'grade' => $class->grade,
            'class_name' => $class->class_name,
            'dob' => $data['dob'] ?? null,
        ]);

        return response()->json(['status' => 'success', 'message' => 'Student record updated.', 'student' => $student->fresh(['school', 'guardians'])]);
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
        if ($user->role === 'admin' && (!$user->school_id || (int) $student->school_id !== (int) $user->school_id)) {
            return response()->json(['status' => 'error', 'message' => 'You may only link guardians to students at your school.'], 403);
        }
        
        // Link guardian
        $guardian = \App\Models\User::findOrFail($request->guardian_id);
        if ($guardian->role !== 'guardian') {
            return response()->json(['status' => 'error', 'message' => 'Select a parent or guardian account.'], 422);
        }
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

        $requestId = DB::table('student_link_requests')->insertGetId([
            'guardian_id' => $user->id,
            'student_name' => $request->student_name,
            'school_name' => $request->school_name,
            'relationship' => $request->relationship ?? 'Parent/Guardian',
            'notes' => $request->notes,
            'status' => 'pending',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Student link request submitted successfully. School admin verification pending.',
            'request_id' => $requestId,
        ], 201);
    }

    public function linkRequests(Request $request)
    {
        $user = $request->user();
        abort_unless($user->role === 'admin', 403);

        $query = DB::table('student_link_requests')
            ->join('users as guardians', 'guardians.id', '=', 'student_link_requests.guardian_id')
            ->select('student_link_requests.*', 'guardians.name as guardian_name', 'guardians.email as guardian_email')
            ->where('student_link_requests.status', 'pending')
            ->orderBy('student_link_requests.created_at');

        if ($user->role === 'admin') {
            abort_unless($user->school_id, 403, 'Administrator account has no school assignment.');
            $query->whereExists(function ($sub) use ($user) {
                $sub->selectRaw('1')->from('students')
                    ->join('schools', 'schools.id', '=', 'students.school_id')
                    ->whereRaw('LOWER(students.name) = LOWER(student_link_requests.student_name)')
                    ->where('students.school_id', $user->school_id)
                    ->where(function ($school) {
                        $school->whereNull('student_link_requests.school_name')
                            ->orWhereRaw('LOWER(schools.name) = LOWER(student_link_requests.school_name)');
                    });
            });
        }

        return response()->json(['status' => 'success', 'requests' => $query->get()]);
    }

    public function reviewLinkRequest(Request $request, int $id)
    {
        $user = $request->user();
        abort_unless($user->role === 'admin', 403);
        $data = $request->validate([
            'decision' => 'required|in:approve,reject',
            'student_id' => 'required_if:decision,approve|nullable|integer|exists:students,id',
        ]);

        return DB::transaction(function () use ($user, $id, $data) {
            $linkRequest = DB::table('student_link_requests')->where('id', $id)->lockForUpdate()->first();
            abort_unless($linkRequest && $linkRequest->status === 'pending', 404, 'Pending link request not found.');

            if ($data['decision'] === 'approve') {
                $student = Student::findOrFail($data['student_id']);
                if ($user->role === 'admin' && (int) $student->school_id !== (int) $user->school_id) {
                    abort(403, 'You may only approve links to students at your school.');
                }
                if (mb_strtolower(trim($student->name)) !== mb_strtolower(trim($linkRequest->student_name))) {
                    abort(422, 'Selected student name does not match the request.');
                }
                if ($linkRequest->school_name && mb_strtolower(trim($student->school?->name ?? '')) !== mb_strtolower(trim($linkRequest->school_name))) {
                    abort(422, 'Selected student does not belong to the requested school.');
                }
                $guardian = \App\Models\User::whereKey($linkRequest->guardian_id)->where('role', 'guardian')->firstOrFail();
                $student->guardians()->syncWithoutDetaching([$guardian->id]);
            }

            DB::table('student_link_requests')->where('id', $id)->update([
                'status' => $data['decision'] === 'approve' ? 'approved' : 'rejected',
                'reviewed_by' => $user->id,
                'updated_at' => now(),
            ]);

            return response()->json(['status' => 'success', 'message' => 'Link request ' . ($data['decision'] === 'approve' ? 'approved and guardian linked.' : 'rejected.')]);
        });
    }
}

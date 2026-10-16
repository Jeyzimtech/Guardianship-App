<?php

namespace App\Http\Controllers;

use App\Models\Announcement;
use App\Models\AttendanceRecord;
use App\Models\FeeAccount;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Subscription;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    /**
     * Get aggregate statistics for the Web Admin Dashboard.
     */
    public function getAdminStats(Request $request)
    {
        $user = $request->user();
        $schoolId = $user?->role === 'admin' ? $user->school_id : null;
        if ($user?->role === 'admin' && !$schoolId) {
            return response()->json(['status' => 'error', 'message' => 'Administrator account has no school assignment.'], 403);
        }
        $totalStudents = Student::when($schoolId, fn ($q) => $q->where('school_id', $schoolId))->count();
        $activeTeachers = Teacher::when($schoolId, fn ($q) => $q->where('school_id', $schoolId))->count();
        $totalClasses = SchoolClass::when($schoolId, fn ($q) => $q->where('school_id', $schoolId))->count();
        $totalSchools = $user?->role === 'admin' ? 1 : School::count();
        $totalGuardians = User::where('role', 'guardian')->when($schoolId, fn ($q) => $q->whereHas('students', fn ($s) => $s->where('school_id', $schoolId)))->count();

        // Attendance rate calculation
        $attendanceQuery = AttendanceRecord::when($schoolId, fn ($q) => $q->whereHas('student', fn ($s) => $s->where('school_id', $schoolId)));
        $totalAttendance = (clone $attendanceQuery)->count();
        $presentAttendance = (clone $attendanceQuery)->where('status', 'present')->count();
        $attendanceRate = $totalAttendance > 0 ? round(($presentAttendance / $totalAttendance) * 100) : 0;

        // Stream distribution based on actual students
        $prepCount = Student::when($schoolId, fn ($q) => $q->where('school_id', $schoolId))
            ->where(fn ($q) => $q->whereHas('school', fn ($school) => $school->where('type', 'prep'))
                ->orWhere('grade', 'like', '%ECD%'))->count();

        $primaryCount = Student::when($schoolId, fn ($q) => $q->where('school_id', $schoolId))
            ->where(fn ($q) => $q->whereHas('school', fn ($school) => $school->where('type', 'primary'))
                ->orWhere('grade', 'like', '%Grade%'))->count();

        $secondaryCount = Student::when($schoolId, fn ($q) => $q->where('school_id', $schoolId))
            ->where(fn ($q) => $q->whereHas('school', fn ($school) => $school->where('type', 'secondary'))
                ->orWhere('grade', 'like', '%Form%'))->count();

        // Fallbacks if students not assigned streams yet
        if ($prepCount === 0 && $primaryCount === 0 && $secondaryCount === 0 && $totalStudents > 0) {
            $primaryCount = $totalStudents;
        }

        $activeSubs = Subscription::where('status', 'active')->when($schoolId, fn ($q) => $q->whereHas('student', fn ($s) => $s->where('school_id', $schoolId)))->count();
        $suspendedSubs = Subscription::where('status', 'inactive')->when($schoolId, fn ($q) => $q->whereHas('student', fn ($s) => $s->where('school_id', $schoolId)))->count();

        return response()->json([
            'status' => 'success',
            'stats' => [
                'total_students' => $totalStudents,
                'attendance_rate' => $attendanceRate,
                'active_teachers' => $activeTeachers,
                'total_classes' => $totalClasses,
                'total_schools' => $totalSchools,
                'total_guardians' => $totalGuardians,
                'active_subscriptions' => $activeSubs,
                'suspended_subscriptions' => $suspendedSubs,
                'stream_distribution' => [
                    'prep' => $prepCount,
                    'primary' => $primaryCount,
                    'secondary' => $secondaryCount,
                ],
            ],
        ]);
    }

    /**
     * Get dashboard summary for a specific student.
     */
    public function getStudentDashboard(Request $request, $studentId)
    {
        $user = $request->user();
        $student = Student::findOrFail($studentId);

        // Access scoping
        if ($user->role === 'guardian') {
            $isLinked = $user->students()->where('students.id', $studentId)->exists();
            if (!$isLinked) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Unauthorized. This student is not linked to your account.'
                ], 403);
            }
        }
        if ($user->role === 'teacher' && (!$user->teacherProfile || (int) $user->teacherProfile->school_id !== (int) $student->school_id || !$user->teacherProfile->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists())) {
            return response()->json(['status' => 'error', 'message' => 'You may only view students in your assigned classes.'], 403);
        }
        // 1. Attendance Snapshot
        $attendanceRecords = AttendanceRecord::where('student_id', $studentId);
        $totalDays = (clone $attendanceRecords)->count();
        $presentDays = (clone $attendanceRecords)->where('status', 'present')->count();
        $attendancePercentage = $totalDays > 0 ? round(($presentDays / $totalDays) * 100) : 0;
        $behaviourCounts = \App\Models\BehaviourIncident::where('student_id', $studentId)
            ->selectRaw("SUM(CASE WHEN polarity = 'positive' THEN 1 ELSE 0 END) as positive_count, SUM(CASE WHEN polarity = 'negative' THEN 1 ELSE 0 END) as negative_count")
            ->first();

        // 2. Fee Balances
        $feeAccount = FeeAccount::where('student_id', $studentId)->first();
        $balanceUsd = $feeAccount ? $feeAccount->balance_usd : 0.00;
        $balanceZig = $feeAccount ? $feeAccount->balance_zig : 0.00;

        // 3. Unread Announcements/Alerts
        $recentAnnouncements = Announcement::where('school_id', $student->school_id)
            ->whereIn('audience_role', ['guardian', 'all'])
            ->orderBy('created_at', 'desc')
            ->limit(3)
            ->get();

        // 4. Z-Score Trajectory
        $zScoreTrend = []; // No assessment series is configured.

        // 5. Velocity Engine Status
        $velocityEngineStatus = $attendancePercentage >= 90 ? 'OPTIMAL' : 'RECOVERY_REQUIRED';

        return response()->json([
            'status' => 'success',
            'student' => [
                'id' => $student->id,
                'name' => $student->name,
                'grade' => $student->grade,
                'class_name' => $student->class_name,
                'school_name' => $student->school ? $student->school->name : 'N/A',
                'school_type' => $student->school ? $student->school->type : 'primary',
            ],
            'attendance_snapshot' => [
                'total_days' => $totalDays,
                'present_days' => $presentDays,
                'percentage' => $attendancePercentage,
            ],
            'behaviour_snapshot' => [
                'positive_count' => (int) ($behaviourCounts->positive_count ?? 0),
                'negative_count' => (int) ($behaviourCounts->negative_count ?? 0),
            ],
            // Teachers have no fee access.
            'fee_snapshot' => $user->role === 'teacher' ? null : [
                'balance_usd' => $balanceUsd,
                'balance_zig' => $balanceZig,
                'currency_status' => 'Dual Currency Enabled (USD / ZiG)'
            ],
            'z_score_trend' => $zScoreTrend,
            'velocity_engine_status' => $velocityEngineStatus,
            'recent_announcements' => $recentAnnouncements
        ]);
    }
}

<?php

namespace App\Http\Controllers;

use App\Models\Announcement;
use App\Models\AttendanceRecord;
use App\Models\FeeAccount;
use App\Models\Student;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
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

        // 1. Attendance Snapshot
        $totalDays = AttendanceRecord::where('student_id', $studentId)->count();
        $presentDays = AttendanceRecord::where('student_id', $studentId)->where('status', 'present')->count();
        $attendancePercentage = $totalDays > 0 ? round(($presentDays / $totalDays) * 100) : 100;

        // 2. Fee Balances
        $feeAccount = FeeAccount::where('student_id', $studentId)->first();
        $balanceUsd = $feeAccount ? $feeAccount->balance_usd : 0.00;
        $balanceZig = $feeAccount ? $feeAccount->balance_zig : 0.00;

        // 3. Unread Announcements/Alerts (get recent 3 announcements for this student's school)
        $recentAnnouncements = Announcement::where('school_id', $student->school_id)
            ->whereIn('audience_role', ['guardian', 'all'])
            ->orderBy('created_at', 'desc')
            ->limit(3)
            ->get();

        // 4. Z-Score Trajectory (Mock Z-Scores for MVP academic performance visualization)
        // A normal distribution score representing academic performance relative to the grade level.
        $zScoreTrend = [
            ['term' => 'Term 1 2025', 'z_score' => 0.85],
            ['term' => 'Term 2 2025', 'z_score' => 1.12],
            ['term' => 'Term 3 2025', 'z_score' => 0.98],
            ['term' => 'Term 1 2026', 'z_score' => 1.25],
        ];

        // 5. Required Velocity Engine Status (Mock Business Status for student's learning momentum)
        $velocityEngineStatus = $attendancePercentage >= 90 ? 'OPTIMAL' : 'RECOVERY_REQUIRED';

        return response()->json([
            'status' => 'success',
            'student' => [
                'id' => $student->id,
                'name' => $student->name,
                'grade' => $student->grade,
                'class_name' => $student->class_name,
                'school_name' => $student->school->name,
                'school_type' => $student->school->type,
            ],
            'attendance_snapshot' => [
                'total_days' => $totalDays,
                'present_days' => $presentDays,
                'percentage' => $attendancePercentage,
            ],
            'fee_snapshot' => [
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

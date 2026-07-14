<?php

namespace App\Http\Controllers;

use App\Models\AttendanceRecord;
use App\Models\Student;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    /**
     * Get attendance history for a specific student.
     * Parents can only view their own child's attendance.
     */
    public function getStudentAttendance(Request $request, $studentId)
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

        $attendance = AttendanceRecord::where('student_id', $studentId)
            ->orderBy('date', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'attendance' => $attendance
        ]);
    }

    /**
     * Submit/Mark daily or subject-level attendance roster (Teacher or Admin only).
     */
    public function markAttendance(Request $request)
    {
        $user = $request->user();
        if (!in_array($user->role, ['teacher', 'admin'])) {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized. Only teachers and admins can mark attendance.'
            ], 403);
        }

        $request->validate([
            'date' => 'required|date',
            'subject_name' => 'nullable|string', // Nullable for Primary/Prep, string for Secondary
            'records' => 'required|array',
            'records.*.student_id' => 'required|exists:students,id',
            'records.*.status' => 'required|in:present,absent',
        ]);

        $markedRecords = [];

        foreach ($request->records as $record) {
            // Create or update attendance record for that date
            $attendance = AttendanceRecord::updateOrCreate(
                [
                    'student_id' => $record['student_id'],
                    'date' => $request->date,
                    'subject_name' => $request->subject_name,
                ],
                [
                    'status' => $record['status'],
                    'marked_by' => $user->id,
                ]
            );

            $markedRecords[] = $attendance;
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Attendance marked successfully.',
            'records' => $markedRecords
        ]);
    }
}

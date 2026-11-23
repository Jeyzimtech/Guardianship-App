<?php

namespace App\Http\Controllers;

use App\Models\AttendanceRecord;
use App\Models\Student;
use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function export(Request $request)
    {
        $request->validate(['date' => 'required|date_format:Y-m-d']);
        $response = $this->getRoster($request);
        if ($response->getStatusCode() !== 200) return $response;
        $data = $response->getData(true);
        $rows = collect($data['roster'])->where('marked', true);
        abort_if($rows->isEmpty(), 422, 'No saved register exists for this date.');
        return response()->streamDownload(function () use ($rows, $data) {
            $file = fopen('php://output', 'w');
            fwrite($file, "\xEF\xBB\xBF");
            fputcsv($file, ['Date', 'Student ID', 'Name', 'Grade', 'Class', 'Status', 'Remarks']);
            foreach ($rows as $row) {
                $values = [$data['date'], $row['roll_no'], $row['name'], $row['grade'], $row['class_name'], $row['status'], $row['remarks']];
                fputcsv($file, array_map(fn ($v) => preg_match('/^[\s]*[=+@-]/u', (string) $v) ? "'".$v : $v, $values));
            }
            fclose($file);
        }, 'attendance-'.$data['date'].'.csv', ['Content-Type' => 'text/csv; charset=UTF-8', 'Cache-Control' => 'private, no-store']);
    }

    /**
     * Get attendance roster for a given date and class.
     * Admin and Teachers can retrieve roster to mark daily attendance.
     */
    public function getRoster(Request $request)
    {
        $date = $request->query('date', now()->toDateString());
        $className = $request->query('class_name');

        $query = Student::with(['school', 'guardians:users.id,users.name,users.email,users.phone_number']);
        if ($request->user()?->role === 'admin' && !$request->user()->school_id) {
            return response()->json(['status' => 'error', 'message' => 'Administrator account has no school assignment.'], 403);
        }
        if ($request->user()?->role === 'admin') {
            $query->where('school_id', $request->user()->school_id);
        }
        if ($className && $className !== 'all') {
            $query->where('class_name', $className);
        }
        $user = $request->user();
        if ($user?->role === 'teacher') {
            $teacher = $user->teacherProfile;
            if (!$teacher?->school_id) {
                return response()->json(['status' => 'error', 'message' => 'Teacher school assignment is required.'], 403);
            }
            $classNames = $teacher->assignedClasses()->pluck('class_name');
            if ($classNames->isEmpty()) {
                return response()->json(['status' => 'error', 'message' => 'No classes are assigned to this teacher.'], 403);
            }
            $query->taughtBy($teacher);
        } elseif ($user?->role === 'guardian') {
            return response()->json(['status' => 'error', 'message' => 'Only school staff can access the attendance roster.'], 403);
        }
        $students = $query->orderBy('name')->get();

        $studentIds = $students->pluck('id');
        $existingRecords = AttendanceRecord::where('date', $date)
            ->whereIn('student_id', $studentIds)
            ->get()
            ->keyBy('student_id');

        $merits = \App\Models\BehaviourIncident::whereIn('student_id', $studentIds)->where('polarity', 'positive')
            ->selectRaw('student_id, count(*) as total')->groupBy('student_id')->pluck('total', 'student_id');

        $roster = $students->map(function ($s, $idx) use ($existingRecords, $merits) {
            $rec = $existingRecords->get($s->id);
            $guardians = $s->guardians->map(fn ($g) => $g->only(['id', 'name', 'email', 'phone_number']))->values();
            return [
                'student_id' => $s->id,
                'photo_url' => $s->photo_url,
                'roll_no' => 'STU-' . str_pad($s->id, 3, '0', STR_PAD_LEFT),
                'name' => $s->name,
                'guardians' => $guardians,
                'grade' => $s->grade,
                'class_name' => $s->class_name,
                'grade' => $s->grade,
                'school_name' => $s->school ? $s->school->name : 'N/A',
                'status' => $rec ? $rec->status : 'present',
                'marked' => (bool) $rec,
                'merits' => (int) ($merits[$s->id] ?? 0),
                'remarks' => $rec && $rec->subject_name ? $rec->subject_name : '',
            ];
        });

        return response()->json([
            'status' => 'success',
            'date' => $date,
            'roster' => $roster,
            'total' => $roster->count(),
        ]);
    }

    /**
     * Get attendance history for a specific student.
     */
    public function getStudentAttendance(Request $request, $studentId)
    {
        $user = $request->user();

        $student = Student::findOrFail($studentId);

        if ($user?->role === 'teacher') {
            $teacher = $user->teacherProfile;
            $assigned = $teacher && (int) $teacher->school_id === (int) $student->school_id
                && $teacher->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists();
            if (!$assigned) {
                return response()->json(['status' => 'error', 'message' => 'You may only view attendance for students in your assigned classes.'], 403);
            }
        }
        if ($user?->role === 'admin' && (!$user->school_id || (int) $user->school_id !== (int) $student->school_id)) {
            return response()->json(['status' => 'error', 'message' => 'This student is outside your school.'], 403);
        }

        // Access scoping
        if ($user && $user->role === 'guardian') {
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
     * Submit/Mark daily attendance roster (Teacher or Admin).
     */
    public function markAttendance(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'date' => 'required|date',
            'subject_name' => 'nullable|string',
            'records' => 'required|array',
            'records.*.student_id' => 'required|exists:students,id',
            'records.*.status' => 'required|in:present,absent,late',
        ]);

        if ($user?->role === 'teacher') {
            $teacher = $user->teacherProfile;
            $studentIds = collect($request->input('records', []))->pluck('student_id');
            $classNames = $teacher?->assignedClasses()->pluck('class_name') ?? collect();
            if (!$teacher?->school_id || !$studentIds->every(fn ($id) => Student::whereKey($id)->taughtBy($teacher)->exists())) {
                return response()->json(['status' => 'error', 'message' => 'You can only mark attendance for students in your assigned classes.'], 403);
            }
        }
        if ($user?->role === 'admin') {
            $schoolId = $user->school_id;
            $studentIds = collect($request->input('records', []))->pluck('student_id');
            if (!$schoolId || Student::whereIn('id', $studentIds)->where('school_id', '!=', $schoolId)->exists()) {
                return response()->json(['status' => 'error', 'message' => 'You can only mark attendance for students at your school.'], 403);
            }
        }

        $markedRecords = [];
        $userId = $user ? $user->id : 1;

        foreach ($request->records as $record) {
            $status = $record['status'];
            $attendance = AttendanceRecord::updateOrCreate(
                [
                    'student_id' => $record['student_id'],
                    'date' => $request->date,
                ],
                [
                    'status' => $status,
                    'subject_name' => $record['remarks'] ?? $request->subject_name,
                    'marked_by' => $userId,
                ]
            );

            $markedRecords[] = $attendance;
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Attendance register saved successfully.',
            'records' => $markedRecords
        ]);
    }
}

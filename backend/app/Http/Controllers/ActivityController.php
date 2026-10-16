<?php

namespace App\Http\Controllers;

use App\Models\Activity;
use App\Models\ActivityAttendance;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/**
 * Extra-curricular activity rosters. Admins manage every activity at their
 * school; teachers manage participation only for students in their classes;
 * guardians read their own child's participation.
 */
class ActivityController extends Controller
{
    public function index(Request $request)
    {
        $schoolId = $this->staffSchoolId($request);
        $allowedIds = $this->teacherStudentIds($request);

        $activities = Activity::where('school_id', $schoolId)
            ->with('attendances')
            ->orderByDesc('activity_date')
            ->get()
            ->map(function (Activity $activity) use ($allowedIds) {
                $roster = collect($activity->roster ?? [])->map(fn ($id) => (int) $id);
                $attendances = $activity->attendances;
                if ($allowedIds !== null) {
                    $roster = $roster->intersect($allowedIds);
                    $attendances = $attendances->whereIn('student_id', $allowedIds->all());
                }
                return [
                    'id' => $activity->id,
                    'title' => $activity->title,
                    'description' => $activity->description,
                    'activity_date' => $activity->activity_date,
                    'roster_count' => $roster->count(),
                    'participated_count' => $attendances->whereIn('status', ['present', 'late'])->count(),
                ];
            });

        return response()->json(['status' => 'success', 'activities' => $activities]);
    }

    public function store(Request $request)
    {
        $schoolId = $this->staffSchoolId($request);
        $data = $request->validate([
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'activity_date' => 'required|date',
            'student_ids' => 'nullable|array',
            'student_ids.*' => 'integer|exists:students,id',
        ]);

        $studentIds = collect($data['student_ids'] ?? [])->map(fn ($id) => (int) $id)->unique();
        $this->assertStudentsManageable($request, $schoolId, $studentIds);

        $activity = Activity::create([
            'school_id' => $schoolId,
            'title' => $data['title'],
            'description' => $data['description'] ?? null,
            'activity_date' => $data['activity_date'],
            'roster' => $studentIds->values()->all(),
            'created_by' => $request->user()->id,
        ]);

        return response()->json(['status' => 'success', 'message' => 'Activity created.', 'activity' => $activity], 201);
    }

    public function roster(Request $request, int $id)
    {
        $schoolId = $this->staffSchoolId($request);
        $activity = Activity::where('school_id', $schoolId)->findOrFail($id);
        $allowedIds = $this->teacherStudentIds($request);

        // Teachers see their own class lists so they can add learners to the roster.
        $candidates = Student::where('school_id', $schoolId)
            ->when($allowedIds !== null, fn ($q) => $q->whereIn('id', $allowedIds))
            ->orderBy('class_name')->orderBy('name')
            ->get(['id', 'name', 'class_name', 'grade']);
        $rosterIds = collect($activity->roster ?? [])->map(fn ($v) => (int) $v);
        $statuses = ActivityAttendance::where('activity_id', $activity->id)->pluck('status', 'student_id');

        return response()->json([
            'status' => 'success',
            'activity' => $activity->only(['id', 'title', 'description', 'activity_date']),
            'roster' => $candidates->map(fn ($student) => [
                'student_id' => $student->id,
                'name' => $student->name,
                'class_name' => $student->class_name,
                'grade' => $student->grade,
                'on_roster' => $rosterIds->contains($student->id),
                'status' => $statuses[$student->id] ?? null,
            ])->values(),
        ]);
    }

    public function markRoster(Request $request, int $id)
    {
        $schoolId = $this->staffSchoolId($request);
        $activity = Activity::where('school_id', $schoolId)->findOrFail($id);
        $data = $request->validate([
            'records' => 'required|array',
            'records.*.student_id' => 'required|integer|exists:students,id',
            'records.*.status' => 'nullable|in:present,absent,late',
        ]);

        $records = collect($data['records']);
        $this->assertStudentsManageable($request, $schoolId, $records->pluck('student_id')->map(fn ($v) => (int) $v));

        DB::transaction(function () use ($activity, $records, $request) {
            $roster = collect($activity->roster ?? [])->map(fn ($v) => (int) $v);
            foreach ($records as $record) {
                $studentId = (int) $record['student_id'];
                if (empty($record['status'])) {
                    // Removing a learner from the roster clears their participation.
                    $roster = $roster->reject(fn ($v) => $v === $studentId);
                    ActivityAttendance::where('activity_id', $activity->id)->where('student_id', $studentId)->delete();
                    continue;
                }
                $roster->push($studentId);
                ActivityAttendance::updateOrCreate(
                    ['activity_id' => $activity->id, 'student_id' => $studentId],
                    ['status' => $record['status'], 'marked_by' => $request->user()->id]
                );
            }
            $activity->update(['roster' => $roster->unique()->values()->all()]);
        });

        return response()->json(['status' => 'success', 'message' => 'Activity roster saved.']);
    }

    public function destroy(Request $request, int $id)
    {
        $schoolId = $this->staffSchoolId($request);
        Activity::where('school_id', $schoolId)->findOrFail($id)->delete();

        return response()->json(['status' => 'success', 'message' => 'Activity deleted.']);
    }

    /** Guardian / staff view of one learner's activity participation. */
    public function studentParticipation(Request $request, int $student_id)
    {
        $student = Student::findOrFail($student_id);
        // Filtered in PHP so the query works on every database driver.
        $activities = Activity::where('school_id', $student->school_id)
            ->orderByDesc('activity_date')
            ->get()
            ->filter(fn ($activity) => collect($activity->roster ?? [])->map(fn ($v) => (int) $v)->contains($student->id));
        $statuses = ActivityAttendance::where('student_id', $student->id)
            ->whereIn('activity_id', $activities->pluck('id'))
            ->pluck('status', 'activity_id');

        return response()->json([
            'status' => 'success',
            'activities' => $activities->map(fn ($activity) => [
                'id' => $activity->id,
                'title' => $activity->title,
                'description' => $activity->description,
                'activity_date' => $activity->activity_date,
                'status' => $statuses[$activity->id] ?? 'enrolled',
            ])->values(),
        ]);
    }

    private function staffSchoolId(Request $request): int
    {
        $user = $request->user();
        $schoolId = $user->role === 'teacher' ? $user->teacherProfile?->school_id : $user->school_id;
        abort_unless($schoolId, 403, 'Your account has no school assignment.');
        return (int) $schoolId;
    }

    /** Null for admins (whole school); otherwise the ids of the teacher's students. */
    private function teacherStudentIds(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'teacher') {
            return null;
        }
        $teacher = $user->teacherProfile;
        return Student::taughtBy($teacher)
            ->pluck('id')
            ->map(fn ($id) => (int) $id);
    }

    private function assertStudentsManageable(Request $request, int $schoolId, $studentIds): void
    {
        if ($studentIds->isEmpty()) {
            return;
        }
        abort_if(Student::whereIn('id', $studentIds)->where('school_id', '!=', $schoolId)->exists(), 403, 'Students must belong to your school.');
        $allowed = $this->teacherStudentIds($request);
        abort_if($allowed !== null && $studentIds->diff($allowed)->isNotEmpty(), 403, 'You may only manage students in your assigned classes.');
    }
}

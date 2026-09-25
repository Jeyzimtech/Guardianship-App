<?php

namespace App\Http\Controllers;

use App\Models\Assignment;
use App\Models\Student;
use App\Models\SchoolClass;
use Illuminate\Http\Request;

class AssignmentController extends Controller
{
    public function teacherIndex(Request $request)
    {
        $teacher = $request->user()->teacherProfile;
        abort_unless($teacher, 403, 'Teacher profile not found.');
        return response()->json([
            'status' => 'success',
            'classes' => SchoolClass::whereHas('teachers', fn($q) => $q->where('teachers.id', $teacher->id))->get(),
            'data' => Assignment::where('created_by', $request->user()->id)->orderByDesc('id')->get(),
        ]);
    }

    /**
     * Get upcoming and overdue assignments for a student
     */
    public function getStudentAssignments($student_id)
    {
        $student = Student::findOrFail($student_id);

        $assignments = Assignment::where(function ($query) use ($student) {
            $query->whereHas('schoolClass', function ($q) use ($student) {
                $q->where('school_id', $student->school_id)
                  ->where('grade', $student->grade)
                  ->where('class_name', $student->class_name);
            })->orWhere(function ($q) use ($student) {
                $q->whereNull('school_class_id')->where(function ($legacy) use ($student) {
                    $legacy->where('grade_name', $student->grade)->orWhereNull('grade_name');
                });
            });
        })
        ->orderBy('due_date', 'asc')
        ->get();

        $today = now()->toDateString();
        $upcoming = $assignments->filter(fn($a) => $a->due_date >= $today)->values();
        $overdue = $assignments->filter(fn($a) => $a->due_date < $today)->values();

        return response()->json([
            'status' => 'success',
            'data' => [
                'upcoming' => $upcoming,
                'overdue' => $overdue,
                'all' => $assignments
            ]
        ]);
    }

    /**
     * Create class/subject assignment
     */
    public function storeAssignment(Request $request)
    {
        $validated = $request->validate([
            'grade_name' => 'nullable|string',
            'school_class_id' => 'nullable|exists:school_classes,id',
            'subject_name' => 'nullable|string',
            'title' => 'required|string|max:255',
            'description' => 'nullable|string',
            'due_date' => 'required|date',
        ]);

        if ($request->user()->role === 'teacher') {
            $teacher = $request->user()->teacherProfile;
            abort_unless($teacher && !empty($validated['school_class_id']), 422, 'Choose an assigned class.');
            $class = SchoolClass::whereHas('teachers', fn($q) => $q->where('teachers.id', $teacher->id))
                ->find($validated['school_class_id']);
            abort_unless($class, 403, 'You can only assign work to your classes.');
            $validated['grade_name'] = $class->grade;
        }

        $assignment = Assignment::create([
            'grade_name' => $validated['grade_name'] ?? null,
            'school_class_id' => $validated['school_class_id'] ?? null,
            'subject_name' => $validated['subject_name'] ?? null,
            'title' => $validated['title'],
            'description' => $validated['description'] ?? null,
            'due_date' => $validated['due_date'],
            'created_by' => $request->user()->id,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Assignment created successfully.',
            'data' => $assignment
        ], 201);
    }
}

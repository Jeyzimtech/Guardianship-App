<?php

namespace App\Http\Controllers;

use App\Models\SchoolClass;
use Illuminate\Http\Request;

class SchoolClassController extends Controller
{
    /**
     * Display a listing of school classes/grades.
     */
    public function index(Request $request)
    {
        $query = SchoolClass::with(['school', 'academicYear']);
        if ($request->user()?->role === 'teacher') {
            $teacherId = $request->user()->teacherProfile?->id;
            $query->whereHas('teachers', fn ($teachers) => $teachers->where('teachers.id', $teacherId ?? 0));
        }
        if ($request->user()?->role === 'admin') {
            $query->where('school_id', $request->user()->school_id ?? 0);
        }

        if ($request->has('school_id') && !empty($request->school_id)) {
            if ($request->user()?->role === 'admin' && (int) $request->school_id !== (int) $request->user()->school_id) {
                return response()->json(['status' => 'error', 'message' => 'You may only view classes at your school.'], 403);
            }
            $query->where('school_id', $request->school_id);
        }

        if ($request->has('academic_year_id') && !empty($request->academic_year_id)) {
            $query->where('academic_year_id', $request->academic_year_id);
        }

        if ($request->has('grade') && !empty($request->grade)) {
            $query->where('grade', 'like', "%{$request->grade}%");
        }

        $classes = $query->orderBy('grade', 'asc')->orderBy('class_name', 'asc')->get();

        return response()->json([
            'status' => 'success',
            'classes' => $classes,
            'school_classes' => $classes,
        ]);
    }

    /**
     * Store a newly created grade/class stream.
     */
    public function store(Request $request)
    {
        if ($request->user()?->role === 'teacher') {
            abort(403, 'Only administrators may create classes.');
        }
        if ($request->user()?->role === 'admin') {
            $request->merge(['school_id' => $request->user()->school_id]);
        }
        if ($request->user()?->role === 'admin' && (int) $request->input('school_id') !== (int) $request->user()->school_id) {
            return response()->json(['status' => 'error', 'message' => 'You may only manage classes at your school.'], 403);
        }
        if ($request->filled('academic_year_id') && !\App\Models\AcademicYear::whereKey($request->academic_year_id)->where('school_id', $request->input('school_id'))->exists()) {
            return response()->json(['status' => 'error', 'message' => 'Select an academic year at the selected school.'], 422);
        }
        $request->validate([
            'school_id' => 'required|exists:schools,id',
            'academic_year_id' => 'nullable|exists:academic_years,id',
            'grade' => 'required|string|max:100',
            'class_name' => 'required|string|max:100',
            'capacity' => 'nullable|integer|min:1',
        ]);

        if ($request->filled('academic_year_id') && !\App\Models\AcademicYear::whereKey($request->academic_year_id)->where('school_id', $request->school_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'Select an academic year at the selected school.'], 422);
        }

        $class = SchoolClass::create([
            'school_id' => $request->school_id,
            'academic_year_id' => $request->academic_year_id,
            'grade' => $request->grade,
            'class_name' => $request->class_name,
            'capacity' => $request->capacity ?? 30,
        ]);

        $class->load(['school', 'academicYear']);

        return response()->json([
            'status' => 'success',
            'message' => 'Grade class created successfully.',
            'class' => $class
        ], 201);
    }

    /**
     * Update the specified grade/class stream.
     */
    public function update(Request $request, $id)
    {
        if ($request->user()?->role === 'teacher') {
            abort(403, 'Only administrators may edit classes.');
        }
        $class = SchoolClass::findOrFail($id);
        if ($request->user()?->role === 'admin' && (int) $class->school_id !== (int) $request->user()->school_id) {
            return response()->json(['status' => 'error', 'message' => 'You may only manage classes at your school.'], 403);
        }
        $request->validate([
            'school_id' => 'sometimes|required|exists:schools,id',
            'academic_year_id' => 'nullable|exists:academic_years,id',
            'grade' => 'sometimes|required|string|max:100',
            'class_name' => 'sometimes|required|string|max:100',
            'capacity' => 'nullable|integer|min:1',
        ]);

        if ($request->user()?->role === 'admin' && $request->filled('school_id') && (int) $request->school_id !== (int) $request->user()->school_id) {
            return response()->json(['status' => 'error', 'message' => 'You may only manage classes at your school.'], 403);
        }

        if ($request->filled('academic_year_id')
            && !\App\Models\AcademicYear::whereKey($request->academic_year_id)->where('school_id', $class->school_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'Select an academic year at the class school.'], 422);
        }
        $class->update($request->only(['academic_year_id', 'grade', 'class_name', 'capacity']));
        $class->load(['school', 'academicYear']);

        return response()->json([
            'status' => 'success',
            'message' => 'Grade class updated successfully.',
            'class' => $class
        ]);
    }

    /**
     * Remove the specified grade/class stream.
     */
    public function destroy(Request $request, $id)
    {
        if ($request->user()?->role === 'teacher') {
            abort(403, 'Only administrators may delete classes.');
        }
        $class = SchoolClass::findOrFail($id);
        if (request()->user()?->role === 'admin' && (!$class->school_id || (int) $class->school_id !== (int) request()->user()->school_id)) {
            return response()->json(['status' => 'error', 'message' => 'You may only manage classes at your school.'], 403);
        }
        $class->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Grade class deleted successfully.'
        ]);
    }
}

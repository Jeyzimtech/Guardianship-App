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

        if ($request->has('school_id') && !empty($request->school_id)) {
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
            'classes' => $classes
        ]);
    }

    /**
     * Store a newly created grade/class stream.
     */
    public function store(Request $request)
    {
        $request->validate([
            'school_id' => 'required|exists:schools,id',
            'academic_year_id' => 'nullable|exists:academic_years,id',
            'grade' => 'required|string|max:100',
            'class_name' => 'required|string|max:100',
            'capacity' => 'nullable|integer|min:1',
        ]);

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
        $class = SchoolClass::findOrFail($id);

        $request->validate([
            'school_id' => 'sometimes|required|exists:schools,id',
            'academic_year_id' => 'nullable|exists:academic_years,id',
            'grade' => 'sometimes|required|string|max:100',
            'class_name' => 'sometimes|required|string|max:100',
            'capacity' => 'nullable|integer|min:1',
        ]);

        $class->update($request->only(['school_id', 'academic_year_id', 'grade', 'class_name', 'capacity']));
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
    public function destroy($id)
    {
        $class = SchoolClass::findOrFail($id);
        $class->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Grade class deleted successfully.'
        ]);
    }
}

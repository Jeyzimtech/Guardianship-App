<?php

namespace App\Http\Controllers;

use App\Models\School;
use Illuminate\Http\Request;

class SchoolController extends Controller
{
    /**
     * Display a listing of schools with counts.
     */
    public function index()
    {
        $schools = School::withCount(['students', 'teachers', 'schoolClasses'])->get();

        return response()->json([
            'status' => 'success',
            'schools' => $schools
        ]);
    }

    /**
     * Store a newly created school.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'type' => 'required|in:prep,primary,secondary',
        ]);

        $school = School::create([
            'name' => $request->name,
            'type' => $request->type,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'School created successfully.',
            'school' => $school
        ], 201);
    }

    /**
     * Display the specified school details.
     */
    public function show($id)
    {
        $school = School::with([
            'students',
            'teachers.user',
            'schoolClasses.academicYear'
        ])->withCount(['students', 'teachers', 'schoolClasses'])->findOrFail($id);

        return response()->json([
            'status' => 'success',
            'school' => $school
        ]);
    }

    /**
     * Update the specified school.
     */
    public function update(Request $request, $id)
    {
        $school = School::findOrFail($id);

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'type' => 'sometimes|required|in:prep,primary,secondary',
        ]);

        $school->update($request->only(['name', 'type']));

        return response()->json([
            'status' => 'success',
            'message' => 'School updated successfully.',
            'school' => $school
        ]);
    }

    /**
     * Remove the specified school.
     */
    public function destroy($id)
    {
        $school = School::findOrFail($id);
        $school->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'School deleted successfully.'
        ]);
    }
}

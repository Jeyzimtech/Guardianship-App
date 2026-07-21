<?php

namespace App\Http\Controllers;

use App\Models\AcademicYear;
use Illuminate\Http\Request;

class AcademicYearController extends Controller
{
    /**
     * Display a listing of academic years.
     */
    public function index()
    {
        $academicYears = AcademicYear::withCount('schoolClasses')
            ->orderBy('is_current', 'desc')
            ->orderBy('id', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'academic_years' => $academicYears
        ]);
    }

    /**
     * Store a newly created academic year.
     */
    public function store(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:academic_years,code',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'is_current' => 'nullable|boolean',
        ]);

        if ($request->is_current) {
            AcademicYear::query()->update(['is_current' => false]);
        }

        $academicYear = AcademicYear::create([
            'name' => $request->name,
            'code' => $request->code,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'is_current' => $request->is_current ?? false,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Academic year created successfully.',
            'academic_year' => $academicYear
        ], 201);
    }

    /**
     * Update the specified academic year.
     */
    public function update(Request $request, $id)
    {
        $academicYear = AcademicYear::findOrFail($id);

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'code' => 'sometimes|required|string|max:50|unique:academic_years,code,' . $id,
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'is_current' => 'nullable|boolean',
        ]);

        if ($request->has('is_current') && $request->is_current) {
            AcademicYear::where('id', '!=', $id)->update(['is_current' => false]);
        }

        $academicYear->update($request->only(['name', 'code', 'start_date', 'end_date', 'is_current']));

        return response()->json([
            'status' => 'success',
            'message' => 'Academic year updated successfully.',
            'academic_year' => $academicYear
        ]);
    }

    /**
     * Set active academic year.
     */
    public function setCurrent($id)
    {
        AcademicYear::query()->update(['is_current' => false]);
        
        $academicYear = AcademicYear::findOrFail($id);
        $academicYear->is_current = true;
        $academicYear->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Active academic year set to ' . $academicYear->name,
            'academic_year' => $academicYear
        ]);
    }

    /**
     * Remove the specified academic year.
     */
    public function destroy($id)
    {
        $academicYear = AcademicYear::findOrFail($id);
        $academicYear->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Academic year deleted successfully.'
        ]);
    }
}

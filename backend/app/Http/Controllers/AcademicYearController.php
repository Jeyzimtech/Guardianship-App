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
        $query = AcademicYear::withCount('schoolClasses');
        if (request()->user()?->role === 'admin') {
            $query->where('school_id', request()->user()->school_id ?? 0);
        } elseif (request()->user()?->role === 'teacher') {
            $teacherId = request()->user()->teacherProfile?->id;
            $query->whereHas('schoolClasses.teachers', fn ($teachers) => $teachers->where('teachers.id', $teacherId ?? 0));
        }
        $academicYears = $query
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
        abort_if($request->user()?->role === 'teacher', 403, 'Only administrators may manage academic years.');
        if ($request->user()?->role === 'admin' && !$request->user()->school_id) {
            abort(403, 'Administrator account has no school assignment.');
        }
        $request->validate([
            'name' => 'required|string|max:255',
            'code' => 'required|string|max:50|unique:academic_years,code',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'is_current' => 'nullable|boolean',
        ]);

        if ($request->user()?->role === 'admin' && $request->is_current) {
            AcademicYear::where('school_id', $request->user()->school_id)->update(['is_current' => false]);
        }

        if ($request->is_current) {
            AcademicYear::where('school_id', $request->user()?->role === 'admin' ? $request->user()->school_id : null)->update(['is_current' => false]);
        }

        $schoolId = $request->user()?->role === 'admin' ? $request->user()->school_id : null;
        $academicYear = AcademicYear::create([
            'name' => $request->name,
            'code' => $request->code,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'is_current' => $request->is_current ?? false,
            'school_id' => $schoolId,
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
        abort_if($request->user()?->role === 'teacher', 403, 'Only administrators may manage academic years.');
        $academicYear = AcademicYear::findOrFail($id);
        if ($request->user()?->role === 'admin' && (int) $academicYear->school_id !== (int) $request->user()->school_id) {
            abort(403, 'You may only manage academic years at your school.');
        }

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'code' => 'sometimes|required|string|max:50|unique:academic_years,code,' . $id,
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'is_current' => 'nullable|boolean',
        ]);

        if ($request->has('is_current') && $request->is_current) {
            AcademicYear::where('id', '!=', $id)->where('school_id', $academicYear->school_id)->update(['is_current' => false]);
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
    public function setCurrent(Request $request, $id)
    {
        abort_if($request->user()?->role === 'teacher', 403, 'Only administrators may manage academic years.');
        $academicYear = AcademicYear::findOrFail($id);
        if ($request->user()?->role === 'admin') {
            if ((int) $academicYear->school_id !== (int) $request->user()->school_id) {
                abort(403, 'You may only manage academic years at your school.');
            }
            AcademicYear::where('school_id', $request->user()->school_id)->update(['is_current' => false]);
        } else {
            AcademicYear::query()->update(['is_current' => false]);
        }
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
    public function destroy(Request $request, $id)
    {
        abort_if($request->user()?->role === 'teacher', 403, 'Only administrators may manage academic years.');
        $academicYear = AcademicYear::findOrFail($id);
        if ($request->user()?->role === 'admin' && (int) $academicYear->school_id !== (int) $request->user()->school_id) {
            abort(403, 'You may only manage academic years at your school.');
        }
        $academicYear->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Academic year deleted successfully.'
        ]);
    }
}

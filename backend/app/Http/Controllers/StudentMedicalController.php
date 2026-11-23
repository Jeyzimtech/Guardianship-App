<?php

namespace App\Http\Controllers;

use App\Models\Student;
use App\Models\StudentMedicalProfile;
use Illuminate\Http\Request;

class StudentMedicalController extends Controller
{
    private function student(Request $request, int $id): Student
    {
        $user = $request->user();
        if ($user->role === 'guardian') return $user->students()->whereKey($id)->firstOrFail();
        abort_unless($user->role === 'teacher' && $user->teacherProfile, 403);
        return Student::taughtBy($user->teacherProfile)->whereKey($id)->firstOrFail();
    }

    public function show(Request $request, int $id)
    {
        $student = $this->student($request, $id);
        return response()->json(['data' => StudentMedicalProfile::where('student_id', $student->id)->first(), 'student_name' => $student->name])
            ->header('Cache-Control', 'private, no-store');
    }

    public function update(Request $request, int $id)
    {
        abort_unless($request->user()->role === 'guardian', 403);
        $student = $this->student($request, $id);
        $data = $request->validate([
            'allergies' => 'present|nullable|string|max:2000',
            'conditions' => 'present|nullable|string|max:2000',
            'medications' => 'present|nullable|string|max:2000',
            'care_instructions' => 'present|nullable|string|max:2000',
        ]);
        $profile = StudentMedicalProfile::updateOrCreate(['student_id' => $student->id], $data + ['updated_by' => $request->user()->id]);
        return response()->json(['message' => 'Medical details saved.', 'data' => $profile])->header('Cache-Control', 'private, no-store');
    }
}

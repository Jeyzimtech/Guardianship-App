<?php

namespace App\Http\Controllers;

use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;

class StudentPhotoController extends Controller
{
    private function student(Request $request, int $id): Student
    {
        $user = $request->user();
        if ($user->role === 'guardian') return $user->students()->whereKey($id)->firstOrFail();
        abort_unless($user->role === 'teacher' && $user->teacherProfile, 403);
        return Student::taughtBy($user->teacherProfile)->whereKey($id)->firstOrFail();
    }

    public function details(Request $request, int $id)
    {
        $student = $this->student($request, $id);
        return response()->json(['photo_url' => $student->photo_url])->header('Cache-Control', 'private, no-store');
    }

    public function show(Request $request, int $id)
    {
        $student = $this->student($request, $id);
        abort_unless($student->photo_path && Storage::disk('local')->exists($student->photo_path), 404);
        return response()->file(Storage::disk('local')->path($student->photo_path), [
            'Cache-Control' => 'private, no-store', 'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    public function store(Request $request, int $id)
    {
        $student = $this->student($request, $id);
        $request->validate(['photo' => 'required|file|image|mimes:jpg,jpeg,png|mimetypes:image/jpeg,image/png|max:4096|dimensions:max_width=6000,max_height=6000']);
        $path = $request->file('photo')->store('student-photos', 'local');
        abort_unless($path, 503, 'Could not save this photo. Please try again.');
        try {
            $oldPath = DB::transaction(function () use ($student, $path) {
                $locked = Student::whereKey($student->id)->lockForUpdate()->firstOrFail();
                $old = $locked->photo_path;
                $locked->forceFill(['photo_path' => $path])->save();
                return $old;
            });
        } catch (\Throwable $e) {
            Storage::disk('local')->delete($path);
            throw $e;
        }
        if ($oldPath) Storage::disk('local')->delete($oldPath);
        return response()->json(['message' => 'Student photo saved.', 'photo_url' => $student->fresh()->photo_url])->header('Cache-Control', 'private, no-store');
    }

    public function destroy(Request $request, int $id)
    {
        $student = $this->student($request, $id);
        $oldPath = DB::transaction(function () use ($student) {
            $locked = Student::whereKey($student->id)->lockForUpdate()->firstOrFail();
            $path = $locked->photo_path;
            $locked->forceFill(['photo_path' => null])->save();
            return $path;
        });
        if ($oldPath) Storage::disk('local')->delete($oldPath);
        return response()->json(['message' => 'Student photo removed.', 'photo_url' => null]);
    }
}

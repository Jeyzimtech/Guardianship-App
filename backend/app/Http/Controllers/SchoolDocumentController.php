<?php

namespace App\Http\Controllers;

use App\Http\Middleware\CheckChildSubscription;
use App\Models\{SchoolClass, SchoolDocument, Student, User};
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class SchoolDocumentController extends Controller
{
    private function authorise(Request $request, SchoolDocument $document): void
    {
        $user = $request->user();
        if ($user->role === 'admin') {
            abort_unless((int) $user->school_id === (int) $document->school_id, 403);
        } elseif ($user->role === 'teacher') {
            $teacher = $user->teacherProfile;
            abort_unless($teacher && (int) $teacher->school_id === (int) $document->school_id, 403);
            abort_if($document->school_class_id && !$teacher->assignedClasses()->where('school_classes.id', $document->school_class_id)->exists(), 403);
        } elseif ($user->role === 'guardian') {
            $student = Student::findOrFail($request->integer('student_id'));
            abort_unless($user->students()->where('students.id', $student->id)->exists() && (int) $student->school_id === (int) $document->school_id, 403);
            if ($document->school_class_id) {
                $class = $document->schoolClass;
                abort_unless($class && $class->grade === $student->grade && $class->class_name === $student->class_name, 403);
            }
        } else {
            abort(403);
        }
    }

    public function index(Request $request)
    {
        $user = $request->user();
        $query = SchoolDocument::with('schoolClass')->whereNull('assignment_id')->latest();
        if ($user->role === 'guardian') {
            $request->validate(['student_id' => 'required|integer|exists:students,id']);
            $student = Student::findOrFail($request->integer('student_id'));
            abort_unless($user->students()->where('students.id', $student->id)->exists(), 403);
            $classIds = SchoolClass::where('school_id', $student->school_id)->where('grade', $student->grade)->where('class_name', $student->class_name)->pluck('id');
            $query->where('school_id', $student->school_id)->where(fn ($q) => $q->whereNull('school_class_id')->orWhereIn('school_class_id', $classIds));
        } elseif ($user->role === 'teacher') {
            $teacher = $user->teacherProfile;
            abort_unless($teacher, 403);
            $query->where('school_id', $teacher->school_id)->where(fn ($q) => $q->whereNull('school_class_id')->orWhereIn('school_class_id', $teacher->assignedClasses()->pluck('school_classes.id')));
        } else {
            abort_unless($user->role === 'admin' && $user->school_id, 403);
            $query->where('school_id', $user->school_id);
        }
        return response()->json(['status' => 'success', 'documents' => $query->get()->map(fn ($d) => $d->forViewer($user, $request->integer('student_id') ?: null))])->header('Cache-Control', 'private, no-store');
    }

    public function store(Request $request)
    {
        abort_unless($request->user()->role === 'admin' && $request->user()->school_id, 403);
        $data = $request->validate([
            'title' => 'required|string|max:255', 'description' => 'nullable|string|max:5000',
            'school_class_id' => 'nullable|integer|exists:school_classes,id',
            'file' => array_merge(['required'], SchoolDocument::fileRules()),
        ]);
        $schoolId = $request->user()->school_id;
        if (!empty($data['school_class_id'])) {
            abort_unless(SchoolClass::whereKey($data['school_class_id'])->where('school_id', $schoolId)->exists(), 403);
        }
        $document = SchoolDocument::upload($request->file('file'), [
            'title' => $data['title'], 'description' => $data['description'] ?? null,
            'school_id' => $schoolId, 'school_class_id' => $data['school_class_id'] ?? null,
            'uploaded_by' => $request->user()->id,
        ]);
        return response()->json(['status' => 'success', 'document' => $document->forViewer($request->user())], 201);
    }

    public function download(Request $request, int $document_id)
    {
        $document = SchoolDocument::findOrFail($document_id);
        $this->authorise($request, $document);
        abort_unless(Storage::disk('local')->exists($document->file_path), 404, 'Document file is unavailable.');
        return Storage::disk('local')->download($document->file_path, $document->file_name, [
            'Content-Type' => $document->mime_type,
            'X-Content-Type-Options' => 'nosniff', 'Cache-Control' => 'private, no-store',
        ]);
    }

    public function downloadLink(Request $request, int $document_id)
    {
        $document = SchoolDocument::findOrFail($document_id);
        $this->authorise($request, $document);
        abort_unless(Storage::disk('local')->exists($document->file_path), 404, 'Document file is unavailable.');
        return response()->json(['status' => 'success', 'download_url' => $document->forViewer($request->user(), $request->integer('student_id') ?: null)['download_url']])->header('Cache-Control', 'private, no-store');
    }

    public function signedDownload(Request $request, int $document_id)
    {
        $viewer = User::findOrFail($request->query('viewer'));
        $request->setUserResolver(fn () => $viewer);
        return app(CheckChildSubscription::class)->handle($request, fn () => $this->download($request, $document_id));
    }

    public function destroy(Request $request, int $document_id)
    {
        $document = SchoolDocument::findOrFail($document_id);
        abort_unless($request->user()->role === 'admin', 403);
        $this->authorise($request, $document);
        abort_if($document->assignment_id, 403, 'Homework attachments are managed with their assignment.');
        $path = $document->file_path;
        $document->delete();
        Storage::disk('local')->delete($path);
        return response()->json(['status' => 'success']);
    }
}

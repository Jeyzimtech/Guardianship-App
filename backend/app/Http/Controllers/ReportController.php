<?php

namespace App\Http\Controllers;

use App\Models\ReportDocument;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class ReportController extends Controller
{
    /**
     * Admin index: List all report documents and circulars across students.
     */
    public function index(Request $request)
    {
        $query = ReportDocument::with(['student.school', 'uploader:id,name']);
        $user = $request->user();
        if ($user?->role === 'teacher') {
            $teacher = $user->teacherProfile;
            $classNames = $teacher?->assignedClasses()->pluck('class_name') ?? collect();
            $query->whereHas('student', fn ($studentQuery) => $studentQuery->taughtBy($teacher));
        } elseif ($user?->role === 'guardian') {
            $query->whereIn('student_id', $user->students()->select('students.id'));
        } elseif ($user?->role === 'admin') {
            $schoolId = $user->school_id;
            $query->whereHas('student', fn ($studentQuery) => $studentQuery->where('school_id', $schoolId ?? 0));
        }
        $reports = $query
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($r) use ($user) {
                return [
                    'id' => $r->id,
                    'student_id' => $r->student_id,
                    'student_name' => $r->student ? $r->student->name : 'General School Document',
                    'class_name' => $r->student ? $r->student->class_name : 'All Classes',
                    'grade' => $r->student ? $r->student->grade : 'All Grades',
                    'title' => $r->title,
                    'type' => $r->type,
                    'file_path' => $this->protectedUrl($r, $user),
                    'file_url' => $this->protectedUrl($r, $user),
                    'uploaded_by' => $r->uploader ? $r->uploader->name : 'Administrator',
                    'created_at' => $r->created_at->format('d M Y'),
                ];
            });

        return response()->json([
            'status' => 'success',
            'reports' => $reports,
            'total' => $reports->count(),
        ]);
    }

    /**
     * Get list of reports/merits/certificates for a student.
     */
    public function getStudentReports(Request $request, $studentId)
    {
        $user = $request->user();
        $student = Student::findOrFail($studentId);

        // Access scoping
        if ($user?->role === 'teacher' && (!$user->teacherProfile || (int) $user->teacherProfile->school_id !== (int) $student->school_id || !$user->teacherProfile->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists())) {
            return response()->json(['status' => 'error', 'message' => 'You may only view reports for students in your assigned classes.'], 403);
        }
        if ($user?->role === 'admin' && (int) $user->school_id !== (int) $student->school_id) {
            return response()->json(['status' => 'error', 'message' => 'This student is outside your school.'], 403);
        }
        if ($user && $user->role === 'guardian') {
            $isLinked = $user->students()->where('students.id', $studentId)->exists();
            if (!$isLinked) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Unauthorized. This student is not linked to your account.'
                ], 403);
            }
        }

        $reports = ReportDocument::where('student_id', $studentId)
            ->orderBy('created_at', 'desc')
            ->get();

        $processedReports = $reports->map(function ($report) use ($user) {
            return [
                'id' => $report->id,
                'student_id' => $report->student_id,
                'title' => $report->title,
                'type' => $report->type,
                'fee_gated' => false,
                'is_locked' => false,
                'file_path' => $this->protectedUrl($report, $user),
                'file_url' => $this->protectedUrl($report, $user),
                'created_at' => $report->created_at,
            ];
        });

        return response()->json([
            'status' => 'success',
            'reports' => $processedReports
        ]);
    }

    /**
     * Download a report.
     */
    public function downloadReport(Request $request, $reportId)
    {
        $report = ReportDocument::findOrFail($reportId);
        $user = $request->user();
        if ($user?->role === 'guardian' && !$user->students()->where('students.id', $report->student_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'This report is not linked to your account.'], 403);
        }
        if ($user?->role === 'admin' && !Student::where('id', $report->student_id)->where('school_id', $user->school_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'This report is outside your school.'], 403);
        }
        if ($user?->role === 'teacher') {
            $student = Student::find($report->student_id);
            if (!$student || !$user->teacherProfile || (int) $user->teacherProfile->school_id !== (int) $student->school_id || !$user->teacherProfile->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists()) {
                return response()->json(['status' => 'error', 'message' => 'You may only access reports for students in your assigned classes.'], 403);
            }
        }
        return response()->json([
            'status' => 'success',
            'message' => 'Report download authorized.',
            'report_title' => $report->title,
            'download_url' => $this->protectedUrl($report, $user),
        ]);
    }

    private function protectedUrl(ReportDocument $report, $user): string
    {
        return \Illuminate\Support\Facades\URL::temporarySignedRoute('reports.file', now()->addMinutes(5), ['report_id'=>$report->id,'viewer'=>$user->id]);
    }

    public function downloadFile(Request $request, int $report_id)
    {
        $viewer=\App\Models\User::findOrFail($request->query('viewer'));
        $request->setUserResolver(fn()=>$viewer);
        return app(\App\Http\Middleware\CheckChildSubscription::class)->handle($request, function() use($request,$report_id) {
            $report=ReportDocument::findOrFail($report_id);
            // Recheck role/link/subscription when the signed link is opened.
            $this->downloadReport($request,$report_id);
            if (str_starts_with($report->file_path,'private:')) {
                $path=substr($report->file_path,8);
                abort_unless(str_starts_with($path,'reports/') && !str_contains($path,'..') && Storage::disk('local')->exists($path),404,'Report file unavailable.');
                return Storage::disk('local')->download($path);
            }
            if (Str::startsWith($report->file_path,['https://'])) return redirect()->away($report->file_path);
            abort(404,'Report file unavailable. Ask your school to upload the report again.');
        });
    }

    /**
     * Upload a new report card/merit document.
     */
    public function uploadReport(Request $request)
    {
        $user = $request->user();

        $request->validate([
            'student_id' => 'required|exists:students,id',
            'title' => 'required|string|max:255',
            'type' => 'required|in:report,merit,certificate',
            'file_path' => 'nullable|url|starts_with:https://|required_without:file',
            'file' => 'nullable|file|mimes:pdf,png,jpg,jpeg|max:10240|required_without:file_path',
        ]);
        $student = Student::findOrFail($request->input('student_id'));
        if ($user?->role === 'teacher' && (!$user->teacherProfile || (int) $user->teacherProfile->school_id !== (int) $student->school_id || !$user->teacherProfile->assignedClasses()->where('class_name', $student->class_name)->where('grade', $student->grade)->exists())) {
            return response()->json(['status' => 'error', 'message' => 'You may only upload reports for students in your assigned classes.'], 403);
        }
        if ($user?->role === 'admin' && (int) $user->school_id !== (int) $student->school_id) {
            return response()->json(['status' => 'error', 'message' => 'This student is outside your school.'], 403);
        }
        if (!in_array($user?->role, ['teacher', 'admin', 'website_admin'], true)) {
            return response()->json(['status' => 'error', 'message' => 'You may not upload reports.'], 403);
        }

        $filePath = $request->file_path;

        if ($request->hasFile('file')) {
            $file = $request->file('file');
            $filename = 'report_' . time() . '_' . Str::random(6) . '.' . $file->getClientOriginalExtension();
            $path = $file->storeAs('reports', $filename, 'local');
            $filePath = 'private:' . $path;
        }



        $userId = $user ? $user->id : 1;

        $report = ReportDocument::create([
            'student_id' => $request->student_id,
            'title' => $request->title,
            'type' => $request->type,
            'fee_gated' => false,
            'file_path' => $filePath,
            'uploaded_by' => $userId,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Report uploaded successfully.',
            'report' => $report
        ], 201);
    }

    /**
     * Delete report document.
     */
    public function destroy($id)
    {
        $report = ReportDocument::findOrFail($id);
        if (request()->user()?->role === 'admin' && !Student::whereKey($report->student_id)->where('school_id', request()->user()->school_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'This report is outside your school.'], 403);
        }
        if (request()->user()?->role === 'admin' && !Student::whereKey($report->student_id)->where('school_id', request()->user()->school_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'This report is outside your school.'], 403);
        }
        $report->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Report deleted successfully.'
        ]);
    }
}

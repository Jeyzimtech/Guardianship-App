<?php

namespace App\Http\Controllers;

use App\Models\FeeAccount;
use App\Models\ReportDocument;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ReportController extends Controller
{
    /**
     * Get list of reports/merits/certificates for a student.
     * Enforces the fee-gating rule by masking file paths if fees are outstanding.
     */
    public function getStudentReports(Request $request, $studentId)
    {
        $user = $request->user();
        $student = Student::findOrFail($studentId);

        // Access scoping
        if ($user->role === 'guardian') {
            $isLinked = $user->students()->where('students.id', $studentId)->exists();
            if (!$isLinked) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Unauthorized. This student is not linked to your account.'
                ], 403);
            }
        }

        // Check if student has outstanding fee balances
        $feeAccount = FeeAccount::where('student_id', $studentId)->first();
        $hasOutstandingFees = false;
        if ($feeAccount) {
            $hasOutstandingFees = ($feeAccount->balance_usd > 0 || $feeAccount->balance_zig > 0);
        }

        $reports = ReportDocument::where('student_id', $studentId)
            ->orderBy('created_at', 'desc')
            ->get();

        // Map reports to mask file paths if gated
        $processedReports = $reports->map(function ($report) use ($hasOutstandingFees) {
            $isGated = $report->fee_gated && $hasOutstandingFees;
            
            return [
                'id' => $report->id,
                'student_id' => $report->student_id,
                'title' => $report->title,
                'type' => $report->type,
                'fee_gated' => $report->fee_gated,
                'is_locked' => $isGated,
                // Mask the file path if locked
                'file_path' => $isGated ? 'LOCKED_DUE_TO_FEES' : $report->file_path,
                'created_at' => $report->created_at,
            ];
        });

        return response()->json([
            'status' => 'success',
            'has_outstanding_fees' => $hasOutstandingFees,
            'reports' => $processedReports
        ]);
    }

    /**
     * Download a report.
     * Enforces the fee-gating business rule explicitly.
     */
    public function downloadReport(Request $request, $reportId)
    {
        $user = $request->user();
        $report = ReportDocument::findOrFail($reportId);
        $studentId = $report->student_id;

        // Access scoping
        if ($user->role === 'guardian') {
            $isLinked = $user->students()->where('students.id', $studentId)->exists();
            if (!$isLinked) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Unauthorized. This student is not linked to your account.'
                ], 403);
            }
        }

        // Enforce fee-gating rule
        if ($report->fee_gated) {
            $feeAccount = FeeAccount::where('student_id', $studentId)->first();
            if ($feeAccount && ($feeAccount->balance_usd > 0 || $feeAccount->balance_zig > 0)) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Outstanding fees: Access to report card is locked until balance is cleared.'
                ], 403);
            }
        }

        // Mock download: If file doesn't exist, we send back a JSON response or mock data.
        // In production, we would use: return Storage::download($report->file_path);
        return response()->json([
            'status' => 'success',
            'message' => 'Report download authorized.',
            'report_title' => $report->title,
            'file_content_mock' => 'PDF MOCK CONTENT FOR REPORT ' . $report->id,
            'download_url' => url('/api/reports/download/' . $report->id)
        ]);
    }

    /**
     * Upload a new report card/merit document (Teacher or Admin only).
     */
    public function uploadReport(Request $request)
    {
        $user = $request->user();
        if (!in_array($user->role, ['teacher', 'admin'])) {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized. Only teachers and admins can upload reports.'
            ], 403);
        }

        $request->validate([
            'student_id' => 'required|exists:students,id',
            'title' => 'required|string|max:255',
            'type' => 'required|in:report,merit,certificate',
            'fee_gated' => 'required|boolean',
            'file_path' => 'required|string', // Send a path or simulated path
        ]);

        $report = ReportDocument::create([
            'student_id' => $request->student_id,
            'title' => $request->title,
            'type' => $request->type,
            'fee_gated' => $request->fee_gated,
            'file_path' => $request->file_path,
            'uploaded_by' => $user->id,
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Report uploaded successfully.',
            'report' => $report
        ], 201);
    }
}

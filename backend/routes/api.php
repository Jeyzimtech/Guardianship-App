<?php

use App\Http\Controllers\AnnouncementController;
use App\Http\Controllers\AttendanceController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\FeeController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\StudentController;
use Illuminate\Support\Facades\Route;

// Public auth endpoints
Route::post('/auth/firebase-login', [AuthController::class, 'firebaseLogin']);

// Authenticated routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth profile & logout
    Route::get('/auth/profile', [AuthController::class, 'profile']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Dashboard
    Route::get('/dashboard/{student_id}', [DashboardController::class, 'getStudentDashboard']);

    // Students
    Route::get('/students', [StudentController::class, 'index']);
    Route::post('/students', [StudentController::class, 'store']);
    Route::post('/students/link-guardian', [StudentController::class, 'linkGuardian']);

    // Attendance
    Route::get('/attendance/{student_id}', [AttendanceController::class, 'getStudentAttendance']);
    Route::post('/attendance/mark', [AttendanceController::class, 'markAttendance']);

    // Fees & Transactions
    Route::get('/fees/{student_id}', [FeeController::class, 'getFeeDetails']);
    Route::post('/fees/pay', [FeeController::class, 'processPayment']);
    Route::post('/fees/update-balance', [FeeController::class, 'updateBalance']);

    // Reports & Gated Downloads
    Route::get('/reports/{student_id}', [ReportController::class, 'getStudentReports']);
    Route::get('/reports/download/{report_id}', [ReportController::class, 'downloadReport']);
    Route::post('/reports/upload', [ReportController::class, 'uploadReport']);

    // Announcements
    Route::get('/announcements', [AnnouncementController::class, 'index']);
    Route::post('/announcements', [AnnouncementController::class, 'store']);
});

<?php

use App\Http\Controllers\AcademicYearController;
use App\Http\Controllers\AnnouncementController;
use App\Http\Controllers\AttendanceController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\FeeController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SchoolClassController;
use App\Http\Controllers\SchoolController;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\UserController;
use Illuminate\Support\Facades\Route;

// Public auth endpoints
Route::post('/auth/firebase-login', [AuthController::class, 'firebaseLogin']);

// Authenticated routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth profile & logout
    Route::get('/auth/profile', [AuthController::class, 'profile']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // User Management Module (Admin Restricted)
    Route::middleware('role:admin')->group(function () {
        Route::get('/users', [UserController::class, 'index']);
        Route::post('/users', [UserController::class, 'store']);
        Route::put('/users/{id}', [UserController::class, 'update']);
        Route::delete('/users/{id}', [UserController::class, 'destroy']);
    });
    Route::get('/users/{id}', [UserController::class, 'show']);

    // School Management Module
    Route::get('/schools', [SchoolController::class, 'index']);
    Route::get('/schools/{id}', [SchoolController::class, 'show']);
    Route::get('/academic-years', [AcademicYearController::class, 'index']);
    Route::get('/school-classes', [SchoolClassController::class, 'index']);

    Route::middleware('role:admin')->group(function () {
        // Schools
        Route::post('/schools', [SchoolController::class, 'store']);
        Route::put('/schools/{id}', [SchoolController::class, 'update']);
        Route::delete('/schools/{id}', [SchoolController::class, 'destroy']);

        // Academic Years
        Route::post('/academic-years', [AcademicYearController::class, 'store']);
        Route::put('/academic-years/{id}', [AcademicYearController::class, 'update']);
        Route::post('/academic-years/{id}/set-current', [AcademicYearController::class, 'setCurrent']);
        Route::delete('/academic-years/{id}', [AcademicYearController::class, 'destroy']);

        // Grades & Classes
        Route::post('/school-classes', [SchoolClassController::class, 'store']);
        Route::put('/school-classes/{id}', [SchoolClassController::class, 'update']);
        Route::delete('/school-classes/{id}', [SchoolClassController::class, 'destroy']);
    });

    // Dashboard
    Route::get('/dashboard/{student_id}', [DashboardController::class, 'getStudentDashboard']);

    // Students
    Route::get('/students', [StudentController::class, 'index']);
    Route::middleware('role:admin')->group(function () {
        Route::post('/students', [StudentController::class, 'store']);
        Route::post('/students/link-guardian', [StudentController::class, 'linkGuardian']);
    });

    // Attendance
    Route::get('/attendance/{student_id}', [AttendanceController::class, 'getStudentAttendance']);
    Route::post('/attendance/mark', [AttendanceController::class, 'markAttendance'])->middleware('role:admin,teacher');

    // Fees & Transactions
    Route::get('/fees/{student_id}', [FeeController::class, 'getFeeDetails']);
    Route::post('/fees/pay', [FeeController::class, 'processPayment']);
    Route::post('/fees/update-balance', [FeeController::class, 'updateBalance'])->middleware('role:admin');

    // Reports & Gated Downloads
    Route::get('/reports/{student_id}', [ReportController::class, 'getStudentReports']);
    Route::get('/reports/download/{report_id}', [ReportController::class, 'downloadReport']);
    Route::post('/reports/upload', [ReportController::class, 'uploadReport'])->middleware('role:admin,teacher');

    // Announcements
    Route::get('/announcements', [AnnouncementController::class, 'index']);
    Route::post('/announcements', [AnnouncementController::class, 'store'])->middleware('role:admin,teacher');
});

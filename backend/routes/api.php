<?php

use App\Http\Controllers\AcademicYearController;
use App\Http\Controllers\AnnouncementController;
use App\Http\Controllers\AssignmentController;
use App\Http\Controllers\AttendanceController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\BehaviourController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\FeeController;
use App\Http\Controllers\GuardianProfileController;
use App\Http\Controllers\JournalController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SchoolClassController;
use App\Http\Controllers\SchoolController;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\TeacherController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\WebsiteAdminController;
use App\Http\Middleware\CheckChildSubscription;
use Illuminate\Support\Facades\Route;

// Public auth endpoints
Route::post('/auth/firebase-login', [AuthController::class, 'firebaseLogin']);

// Authenticated routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth profile & logout
    Route::get('/auth/profile', [AuthController::class, 'profile']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Guardian Self-Service Profile (paperless details update)
    Route::get('/guardian/profile', [GuardianProfileController::class, 'getProfile']);
    Route::put('/guardian/profile', [GuardianProfileController::class, 'updateProfile']);

    // Website Admin / Platform Owner Console (Restricted to platform owners)
    Route::middleware('role:website_admin,admin')->prefix('platform')->group(function () {
        Route::post('/schools', [WebsiteAdminController::class, 'onboardSchool']);
        Route::get('/directory', [WebsiteAdminController::class, 'listDirectory']);
        Route::post('/subscriptions/toggle', [WebsiteAdminController::class, 'toggleSubscription']);
        Route::get('/subscriptions/history/{student_id}', [WebsiteAdminController::class, 'getSubscriptionHistory']);
    });

    // User Management Module (Admin Restricted)
    Route::middleware('role:admin,website_admin')->group(function () {
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

    Route::middleware('role:admin,website_admin')->group(function () {
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

    // Teacher Management Module
    Route::get('/teachers', [TeacherController::class, 'index']);
    Route::get('/teachers/{id}', [TeacherController::class, 'show']);
    Route::middleware('role:admin,website_admin')->group(function () {
        Route::post('/teachers', [TeacherController::class, 'store']);
        Route::put('/teachers/{id}', [TeacherController::class, 'update']);
        Route::delete('/teachers/{id}', [TeacherController::class, 'destroy']);
    });

    // Students List & Linking
    Route::get('/students', [StudentController::class, 'index']);
    Route::post('/students/request-link', [StudentController::class, 'requestLink']);
    Route::middleware('role:admin,website_admin')->group(function () {
        Route::post('/students', [StudentController::class, 'store']);
        Route::post('/students/link-guardian', [StudentController::class, 'linkGuardian']);
    });

    // Student-Scoped Routes guarded by CheckChildSubscription
    Route::middleware(CheckChildSubscription::class)->group(function () {
        // Dashboard
        Route::get('/dashboard/{student_id}', [DashboardController::class, 'getStudentDashboard']);

        // Attendance
        Route::get('/attendance/{student_id}', [AttendanceController::class, 'getStudentAttendance']);

        // Learning Journal (Ungated Work Samples & Preparatory Wellbeing Logs)
        Route::get('/journal/{student_id}', [JournalController::class, 'getEntries']);

        // Behaviour & Merits Snapshot
        Route::get('/behaviour/{student_id}', [BehaviourController::class, 'getStudentBehaviour']);

        // Assignments & Homework
        Route::get('/assignments/{student_id}', [AssignmentController::class, 'getStudentAssignments']);

        // Fees & Transactions
        Route::get('/fees/{student_id}', [FeeController::class, 'getFeeDetails']);

        // Reports & Gated Downloads
        Route::get('/reports/{student_id}', [ReportController::class, 'getStudentReports']);
        Route::get('/reports/download/{report_id}', [ReportController::class, 'downloadReport']);
    });

    // Authoring Endpoints (Teachers & Admin)
    Route::post('/attendance/mark', [AttendanceController::class, 'markAttendance'])->middleware('role:admin,teacher,website_admin');
    Route::post('/fees/pay', [FeeController::class, 'processPayment']);
    Route::post('/fees/update-balance', [FeeController::class, 'updateBalance'])->middleware('role:admin,website_admin');
    Route::post('/reports/upload', [ReportController::class, 'uploadReport'])->middleware('role:admin,teacher,website_admin');
    Route::post('/journal', [JournalController::class, 'storeEntry'])->middleware('role:admin,teacher,website_admin');
    Route::post('/behaviour', [BehaviourController::class, 'storeIncident'])->middleware('role:admin,teacher,website_admin');
    Route::post('/assignments', [AssignmentController::class, 'storeAssignment'])->middleware('role:admin,teacher,website_admin');

    // Announcements
    Route::get('/announcements', [AnnouncementController::class, 'index']);
    Route::post('/announcements', [AnnouncementController::class, 'store'])->middleware('role:admin,teacher,website_admin');
});

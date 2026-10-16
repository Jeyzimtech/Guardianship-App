<?php

use App\Http\Controllers\AcademicYearController;
use App\Http\Controllers\ActivityController;
use App\Http\Controllers\BehaviourCategoryController;
use App\Http\Controllers\AnnouncementController;
use App\Http\Controllers\AssignmentController;
use App\Http\Controllers\AttendanceController;
use App\Http\Controllers\AuthController;
use App\Http\Controllers\BehaviourController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\EmailSettingsController;
use App\Http\Controllers\FeeController;
use App\Http\Controllers\GuardianProfileController;
use App\Http\Controllers\JournalController;
use App\Http\Controllers\ReportController;
use App\Http\Controllers\SchoolClassController;
use App\Http\Controllers\SchoolController;
use App\Http\Controllers\StudentController;
use App\Http\Controllers\TeacherController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\UniformController;
use App\Http\Controllers\RoadrunnerController;
use App\Http\Controllers\WebsiteAdminController;
use App\Http\Middleware\CheckChildSubscription;
use Illuminate\Support\Facades\Route;

// Public health check endpoint
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'message' => 'Guardianship API is running',
        'timestamp' => now()->toIso8601String(),
    ]);
});

// Public uniform catalog
Route::get('/uniforms', [UniformController::class, 'index']);
Route::post('/delivery/quote', [RoadrunnerController::class, 'quote'])->middleware('throttle:20,1');

// Public auth endpoints
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/change-password', [AuthController::class, 'changePassword'])->middleware('auth:sanctum');
Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/auth/reset-password', [AuthController::class, 'resetPassword']);

// Authenticated routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth profile & logout
    Route::get('/auth/profile', [AuthController::class, 'profile']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Guardian Self-Service Profile (paperless details update)
    Route::get('/guardian/profile', [GuardianProfileController::class, 'getProfile']);
    Route::put('/guardian/profile', [GuardianProfileController::class, 'updateProfile']);

    // Website Admin / Platform Owner Console (Restricted to platform owners)
    Route::middleware('role:website_admin')->prefix('platform')->group(function () {
        Route::post('/schools', [WebsiteAdminController::class, 'onboardSchool']);
        Route::get('/directory', [WebsiteAdminController::class, 'listDirectory']);
        Route::post('/subscriptions/toggle', [WebsiteAdminController::class, 'toggleSubscription']);
        Route::get('/subscriptions/history/{student_id}', [WebsiteAdminController::class, 'getSubscriptionHistory']);
    });

    Route::post('/users', [UserController::class, 'store'])->middleware('role:admin,teacher');
    Route::post('/users/{id}/send-link', [EmailSettingsController::class, 'sendUserAccessLink'])->middleware('role:admin,teacher');

    // User Management Module (Admin Restricted)
    Route::middleware('role:admin')->group(function () {
        Route::get('/users', [UserController::class, 'index']);
        Route::put('/users/{id}', [UserController::class, 'update']);
        Route::delete('/users/{id}', [UserController::class, 'destroy']);

        // Mail & Delivery Gateway Configuration
        Route::get('/settings/mail', [EmailSettingsController::class, 'getSettings']);
        Route::post('/settings/mail', [EmailSettingsController::class, 'saveSettings']);
        Route::post('/settings/mail/test', [EmailSettingsController::class, 'sendTestEmail']);
    });
    Route::get('/users/{id}', [UserController::class, 'show'])->middleware('role:admin');

    Route::get('/uniform-payments/pending', [UniformController::class, 'pendingOrderPayments'])->middleware('role:admin');
    Route::post('/uniform-orders/{id}/payment-reference', [UniformController::class, 'submitPaymentReference'])->middleware('role:guardian');
    Route::post('/uniform-orders/{id}/verify-payment', [UniformController::class, 'verifyOrderPayment'])->middleware('role:admin');

    // Uniform orders are stored and scoped to the selected student.
    Route::get('/uniform-orders/{student_id}', [UniformController::class, 'orders'])->middleware('role:guardian,admin');
    Route::post('/uniform-orders', [UniformController::class, 'placeOrder'])->middleware('role:guardian,admin');

    // School Management Module
    Route::get('/schools', [SchoolController::class, 'index'])->middleware('role:admin,website_admin');
    Route::get('/schools/{id}', [SchoolController::class, 'show'])->middleware('role:admin');
    Route::get('/academic-years', [AcademicYearController::class, 'index'])->middleware('role:admin');
    Route::get('/school-classes', [SchoolClassController::class, 'index'])->middleware('role:admin,teacher');

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

    // Teacher Management Module
    Route::get('/teachers', [TeacherController::class, 'index'])->middleware('role:admin');
    Route::get('/teachers/{id}', [TeacherController::class, 'show'])->middleware('role:admin');
    Route::middleware('role:admin')->group(function () {
        Route::post('/teachers', [TeacherController::class, 'store']);
        Route::put('/teachers/{id}', [TeacherController::class, 'update']);
        Route::delete('/teachers/{id}', [TeacherController::class, 'destroy']);
    });

    // Students List & Linking
    Route::get('/students', [StudentController::class, 'index'])->middleware('role:guardian,teacher,admin');
    Route::post('/students/request-link', [StudentController::class, 'requestLink'])->middleware('role:guardian');
    Route::middleware('role:admin')->group(function () {
        Route::get('/students/link-requests', [StudentController::class, 'linkRequests']);
        Route::post('/students/link-requests/{id}/review', [StudentController::class, 'reviewLinkRequest']);
        Route::post('/students/link-guardian', [StudentController::class, 'linkGuardian']);
        Route::put('/students/{id}', [StudentController::class, 'update']);
    });
    Route::post('/students', [StudentController::class, 'store'])->middleware('role:admin,teacher');

    // Attendance Roster (Teacher & Admin)
    Route::get('/attendance/roster', [AttendanceController::class, 'getRoster'])->middleware('role:admin,teacher');
    Route::get('/fees/payments/pending', [FeeController::class, 'pendingPayments'])->middleware('role:admin');
    Route::post('/fees/payments/{id}/verify', [FeeController::class, 'verifyPayment'])->middleware('role:admin');
    Route::get('/fees/accounts', [FeeController::class, 'accounts'])->middleware('role:admin');

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

        // Activity participation (read-only for guardians)
        Route::get('/activities/student/{student_id}', [ActivityController::class, 'studentParticipation']);
    });

    // Activity Rosters (Admin manages all; teachers manage their own students)
    Route::middleware('role:admin,teacher')->group(function () {
        Route::get('/activities', [ActivityController::class, 'index']);
        Route::post('/activities', [ActivityController::class, 'store']);
        Route::get('/activities/{id}/roster', [ActivityController::class, 'roster'])->whereNumber('id');
        Route::post('/activities/{id}/roster', [ActivityController::class, 'markRoster'])->whereNumber('id');
        Route::get('/behaviour-categories', [BehaviourCategoryController::class, 'index']);
    });
    Route::delete('/activities/{id}', [ActivityController::class, 'destroy'])->middleware('role:admin');

    // Behaviour Categories (School Admin configuration)
    Route::middleware('role:admin')->group(function () {
        Route::post('/behaviour-categories', [BehaviourCategoryController::class, 'store']);
        Route::delete('/behaviour-categories/{id}', [BehaviourCategoryController::class, 'destroy']);
    });

    Route::get('/teacher/assignments', [AssignmentController::class, 'teacherIndex'])->middleware('role:teacher');

    // Authoring Endpoints (Teachers & Admin)
    Route::post('/attendance/mark', [AttendanceController::class, 'markAttendance'])->middleware('role:admin,teacher');
    Route::post('/fees/pay', [FeeController::class, 'processPayment'])->middleware('role:guardian,admin');
    Route::post('/fees/update-balance', [FeeController::class, 'updateBalance'])->middleware('role:admin');
    Route::post('/reports/upload', [ReportController::class, 'uploadReport'])->middleware('role:admin,teacher');
    Route::post('/journal', [JournalController::class, 'storeEntry'])->middleware('role:admin,teacher');
    Route::post('/behaviour', [BehaviourController::class, 'storeIncident'])->middleware('role:admin,teacher');
    Route::post('/assignments', [AssignmentController::class, 'storeAssignment'])->middleware('role:admin,teacher');

    // Admin Dashboard Live Stats
    Route::get('/admin/dashboard-stats', [DashboardController::class, 'getAdminStats'])->middleware('role:admin');

    // Reports Management
    Route::get('/reports', [ReportController::class, 'index'])->middleware('role:admin,teacher');
    Route::delete('/reports/{id}', [ReportController::class, 'destroy'])->middleware('role:admin');

    // Learning Journal Admin Feed
    Route::get('/journal', [JournalController::class, 'index'])->middleware('role:admin,teacher');
    Route::delete('/journal/{id}', [JournalController::class, 'destroy'])->middleware('role:admin');

    // Uniforms Catalog Management (Admin Authoring)
    Route::post('/uniforms', [UniformController::class, 'store'])->middleware('role:admin');
    Route::post('/uniforms/{id}', [UniformController::class, 'update'])->middleware('role:admin');
    Route::put('/uniforms/{id}', [UniformController::class, 'update'])->middleware('role:admin');
    Route::delete('/uniforms/{id}', [UniformController::class, 'destroy'])->middleware('role:admin');

    // Announcements
    Route::get('/announcements', [AnnouncementController::class, 'index'])->middleware('role:guardian,admin,teacher');
    Route::post('/announcements', [AnnouncementController::class, 'store'])->middleware('role:admin,teacher');
});

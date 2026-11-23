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
use App\Http\Controllers\WebsiteAdminController;
use App\Http\Middleware\CheckChildSubscription;
use Illuminate\Support\Facades\Route;

// Public health check endpoint
Route::post('/payments/pesepay/result', [\App\Http\Controllers\UniformPaymentController::class, 'callback'])->middleware('throttle:120,1');
Route::get('/health', function () {
    return response()->json([
        'status' => 'ok',
        'message' => 'Guardianship API is running',
        'timestamp' => now()->toIso8601String(),
    ]);
});

// Public uniform catalog
Route::get('/uniforms', [UniformController::class, 'index']);

Route::post('/auth/phone/request', [\App\Http\Controllers\PhoneAuthController::class, 'requestCode'])->middleware('throttle:5,1');
Route::post('/auth/phone/verify', [\App\Http\Controllers\PhoneAuthController::class, 'verify'])->middleware('throttle:15,1');

// Public auth endpoints
Route::post('/auth/login', [AuthController::class, 'login']);
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/change-password', [AuthController::class, 'changePassword'])->middleware('auth:sanctum');
Route::post('/auth/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/auth/reset-password', [AuthController::class, 'resetPassword']);

// Authenticated routes
Route::middleware(['auth:sanctum', \App\Http\Middleware\GuardianSubscription::class])->group(function () {
    Route::get('/subscription', fn (\Illuminate\Http\Request $request) => response()->json(\App\Services\GuardianAccess::status($request->user())))->middleware('role:guardian');
    Route::post('/sos', [\App\Http\Controllers\SosController::class, 'store'])->middleware(['role:teacher', 'throttle:2,1']);
    Route::get('/sos', [\App\Http\Controllers\SosController::class, 'index'])->middleware('role:guardian');
    Route::get('/sos/history', [\App\Http\Controllers\SosController::class, 'history'])->middleware('role:guardian');
    Route::post('/sos/{id}/acknowledge', [\App\Http\Controllers\SosController::class, 'acknowledge'])->middleware('role:guardian');
    // Auth profile & logout
    Route::get('/auth/profile', [AuthController::class, 'profile']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);
    Route::post('/auth/delete-account', [AuthController::class, 'deleteAccount'])->middleware('throttle:5,1');
    Route::post('/support/reports', [\App\Http\Controllers\SupportReportController::class, 'store'])->middleware('throttle:5,1');

    // Guardian Self-Service Profile (paperless details update)
    Route::get('/guardian/profile', [GuardianProfileController::class, 'getProfile']);
    Route::put('/guardian/profile', [GuardianProfileController::class, 'updateProfile']);

    // Website Admin / Platform Owner Console (Restricted to platform owners)
    Route::middleware('role:website_admin')->prefix('platform')->group(function () {
        Route::post('/schools', [WebsiteAdminController::class, 'onboardSchool']);
        Route::delete('/schools/{id}', [WebsiteAdminController::class, 'destroySchool']);
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
    Route::post('/uniform-orders/{id}/checkout', [\App\Http\Controllers\UniformPaymentController::class, 'checkout'])->middleware(['role:guardian,admin','throttle:10,1']);
    Route::get('/uniform-orders/{id}/payment-status', [\App\Http\Controllers\UniformPaymentController::class, 'status'])->middleware(['role:guardian,admin','throttle:20,1']);
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


    Route::middleware('role:guardian,teacher')->group(function () {
        Route::get('/students/{id}/photo-details', [\App\Http\Controllers\StudentPhotoController::class, 'details']);
        Route::get('/students/{id}/photo', [\App\Http\Controllers\StudentPhotoController::class, 'show']);
        Route::post('/students/{id}/photo', [\App\Http\Controllers\StudentPhotoController::class, 'store'])->middleware('throttle:10,1');
        Route::delete('/students/{id}/photo', [\App\Http\Controllers\StudentPhotoController::class, 'destroy']);
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
    Route::get('/parents/import/template', [\App\Http\Controllers\ParentImportController::class, 'template'])->middleware('role:teacher');
    Route::post('/parents/import', [\App\Http\Controllers\ParentImportController::class, 'import'])->middleware(['role:teacher', 'throttle:10,1']);

    // Attendance Roster (Teacher & Admin)
    Route::get('/attendance/export', [AttendanceController::class, 'export'])->middleware('role:admin,teacher');
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
    Route::get('/documents', [\App\Http\Controllers\SchoolDocumentController::class, 'index'])->middleware(['role:admin,teacher,guardian', CheckChildSubscription::class]);
    Route::post('/documents', [\App\Http\Controllers\SchoolDocumentController::class, 'store'])->middleware('role:admin');
    Route::get('/documents/{document_id}/download', [\App\Http\Controllers\SchoolDocumentController::class, 'downloadLink'])->middleware(['role:admin,teacher,guardian', CheckChildSubscription::class]);
    Route::delete('/documents/{document_id}', [\App\Http\Controllers\SchoolDocumentController::class, 'destroy'])->middleware('role:admin');

    // Authoring Endpoints (Teachers & Admin)
    Route::post('/attendance/mark', [AttendanceController::class, 'markAttendance'])->middleware('role:admin,teacher');
    Route::get('/fees/payments/{id}/proof', [FeeController::class, 'proof'])->middleware('role:guardian,admin');
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

    Route::get('/moderation/reports', [\App\Http\Controllers\SupportReportController::class, 'index'])->middleware('role:website_admin');
    Route::put('/moderation/reports/{id}', [\App\Http\Controllers\SupportReportController::class, 'review'])->middleware('role:website_admin');
    Route::post('/messages/block/{userId}', [\App\Http\Controllers\MessageController::class, 'block'])->middleware('role:guardian,teacher')->whereNumber('userId');
    Route::delete('/messages/block/{userId}', [\App\Http\Controllers\MessageController::class, 'block'])->middleware('role:guardian,teacher')->whereNumber('userId');

    // Direct teacher-guardian messages
    Route::middleware('role:teacher,guardian')->group(function () {
        Route::delete('/mobile-notifications', [\App\Http\Controllers\MobileNotificationController::class, 'destroy']);
        Route::get('/mobile-notifications/counts', [\App\Http\Controllers\MobileNotificationController::class, 'counts']);
        Route::post('/mobile-notifications/read', [\App\Http\Controllers\MobileNotificationController::class, 'read']);
        Route::post('/mobile-notifications/device', [\App\Http\Controllers\MobileNotificationController::class, 'register']);
        Route::delete('/mobile-notifications/device', [\App\Http\Controllers\MobileNotificationController::class, 'unregister']);
    });
    Route::middleware('role:teacher,guardian')->group(function () {
        Route::delete('/messages/with/{userId}', [\App\Http\Controllers\MessageController::class, 'destroy'])->whereNumber('userId');
        Route::get('/messages/contacts', [\App\Http\Controllers\MessageController::class, 'contacts']);
        Route::get('/messages/with/{userId}', [\App\Http\Controllers\MessageController::class, 'thread'])->whereNumber('userId');
        Route::post('/messages', [\App\Http\Controllers\MessageController::class, 'store'])->middleware('throttle:30,1');
    });

    // Announcements
    Route::get('/announcements', [AnnouncementController::class, 'index'])->middleware('role:guardian,admin,teacher');
    Route::post('/announcements', [AnnouncementController::class, 'store'])->middleware('role:admin,teacher');
});

<?php
\Illuminate\Support\Facades\Route::get('/payments/pesepay/return', fn () => response('<!doctype html><html><meta name="viewport" content="width=device-width,initial-scale=1"><title>Uniform payment</title><body style="font:18px system-ui;background:#f7f8fa;padding:32px;max-width:560px;margin:auto"><h1>Return to your uniform order</h1><p>Your checkout has ended. Return to the app and tap Check payment status to see the verified result.</p><p>Closing checkout does not confirm payment.</p></body></html>'));

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('admin');
});

Route::get('/admin', function () {
    return view('admin');
});

Route::get('/login', function () {
    return redirect('/');
})->name('login');

// Mobile App Password Creation & Reset Web Pages
Route::get('/set-password', function (Request $request) {
    return view('auth.reset-password', [
        'token' => $request->query('token', ''),
        'email' => $request->query('email', ''),
        'isNewUser' => true,
    ]);
});

Route::get('/reset-password', function (Request $request) {
    return view('auth.reset-password', [
        'token' => $request->query('token', ''),
        'email' => $request->query('email', ''),
        'isNewUser' => false,
    ]);
});

Route::get('/report-files/{report_id}', [\App\Http\Controllers\ReportController::class, 'downloadFile'])->middleware('signed')->name('reports.file');

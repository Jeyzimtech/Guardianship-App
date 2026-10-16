<?php

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

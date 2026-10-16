<?php

use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('platform:create-owner {email} {--name=Platform Owner}', function () {
    $email = strtolower(trim($this->argument('email')));
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        $this->error('Enter a valid email address.');
        return 1;
    }
    if (\App\Models\User::where('email', $email)->exists()) {
        $this->error('That email already belongs to an account. No changes made.');
        return 1;
    }
    $password = $this->secret('Choose a password (at least 12 characters)');
    if (!is_string($password) || strlen($password) < 12) {
        $this->error('The password must contain at least 12 characters.');
        return 1;
    }
    \App\Models\User::create([
        'name' => $this->option('name'), 'email' => $email,
        'phone_number' => '+owner-' . \Illuminate\Support\Str::random(16),
        'account_uid' => 'owner_' . \Illuminate\Support\Str::uuid(),
        'role' => 'website_admin', 'password' => $password,
    ]);
    $this->info('Platform owner created. Sign in at /admin with your email and password.');
    return 0;
})->purpose('Create a platform owner without changing existing accounts');

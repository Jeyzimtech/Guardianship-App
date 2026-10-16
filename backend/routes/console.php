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

Artisan::command('uniforms:seed-payment-test {school}', function () {
    $school=\App\Models\School::findOrFail($this->argument('school'));
    if (!config('services.pesepay.sandbox')) { $this->error('Test catalog requires PesePay sandbox mode.'); return 1; }
    foreach ([['TEST-PESEPAY-SHIRT','Test uniform - school shirt','Shirts',1.00],['TEST-PESEPAY-JERSEY','Test uniform - school jersey','Jerseys',2.00]] as [$code,$name,$category,$price]) {
        \App\Models\UniformItem::firstOrCreate(['school_id'=>$school->id,'item_code'=>$code],[
            'name'=>$name,'category'=>$category,'price_usd'=>$price,'price_zig'=>0,
            'sizes'=>['S','M','L'],'stock_count'=>20,'in_stock'=>true,
            'description'=>'PesePay sandbox test item. Not a real fulfillment order.',
        ]);
    }
    $this->info('Two payment-test uniforms are available for '.$school->name.'. Existing items unchanged.');
})->purpose('Add two explicit, repeatable sandbox uniform fixtures for a school');

Artisan::command('payments:reconcile-uniforms', function () {
    \App\Models\UniformPayment::whereNotNull('reference')
        ->whereIn('status',['INITIATED','PROCESSING','PENDING','PARTIALLY_PAID'])
        ->where('sandbox',(bool)config('services.pesepay.sandbox'))->orderBy('id')
        ->chunkById(100,function($payments) {
            foreach($payments as $payment) {
                try { app(\App\Services\Pesepay::class)->reconcile($payment); }
                catch(\Throwable $e) { $this->warn('Could not verify payment '.$payment->id.'; will retry.'); }
            }
        });
})->purpose('Reconcile uniform payments if a PesePay callback was missed');

// Production runs reconciliation through the dedicated systemd payment timer.

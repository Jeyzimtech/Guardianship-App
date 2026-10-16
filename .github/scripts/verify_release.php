<?php
// Run from the deployed backend directory. Creates no sample school/student data.
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

$base = rtrim(config('app.url'), '/').'/api';
$failures = [];
function checkResponse($label, $response, $expected = [200]) {
    global $failures;
    $ok = in_array($response->status(), $expected, true);
    echo ($ok ? 'PASS ' : 'FAIL ').$label.' HTTP '.$response->status().PHP_EOL;
    if (!$ok) {
        $failures[] = $label;
        echo substr($response->body(), 0, 300).PHP_EOL;
    }
}

// Delete only unchanged products from the former demonstration seeder.
$samples = [
    ['UNI-BLZ-101','Official Embroidered School Blazer',45,85],
    ['UNI-SHT-102','Long-Sleeve Cotton Shirt (Pack of 2)',22,120],
    ['UNI-TRS-103','School Trousers / Pleated Skirt',25,60],
    ['UNI-TRK-104','Full Athletics Tracksuit Set',38,45],
    ['UNI-POL-105','House Color Sports Polo Shirt',14,90],
    ['UNI-TIE-106','Official Striped School Tie',8,150],
    ['UNI-SHS-107','Genuine Leather School Shoes',32,40],
    ['UNI-FLC-108','Winter Fleece Pullover & Beanie',28,55],
];
$removed = DB::transaction(function () use ($samples) {
    $count = 0;
    foreach ($samples as [$code,$name,$price,$stock]) {
        $count += DB::table('uniform_items')->whereNull('school_id')->where('item_code',$code)
            ->where('name',$name)->where('price_usd',$price)->where('stock_count',$stock)
            ->where('image_url','like','https://images.unsplash.com/%')->delete();
    }
    return $count;
});
echo 'Confirmed sample catalog products removed: '.$removed.PHP_EOL;

$owner = User::where('role','website_admin')->first();
if (!$owner) {
    $password = Str::password(24);
    $owner = User::create(['name'=>'Platform Owner', 'email'=>'owner@educonnect.local',
        'phone_number'=>'+owner-'.Str::random(16), 'account_uid'=>'owner_'.Str::uuid(),
        'role'=>'website_admin', 'password'=>$password]);
    $login = Http::acceptJson()->timeout(20)->post($base.'/auth/login', ['email'=>$owner->email,'password'=>$password]);
    checkResponse('Production owner password login', $login);
    $id = explode('|', $login->json('token') ?? '')[0];
    if ($id) $owner->tokens()->whereKey($id)->delete();
    echo 'OWNER_EMAIL='.$owner->email.PHP_EOL.'OWNER_PASSWORD='.$password.PHP_EOL;
}

checkResponse('Public health', Http::acceptJson()->timeout(20)->get($base.'/health'));
checkResponse('Unauthenticated student directory blocked', Http::acceptJson()->timeout(20)->get($base.'/students'), [401]);
checkResponse('Removed external authentication endpoint', Http::acceptJson()->timeout(20)->post($base.'/auth/firebase-login', []), [404]);
if (!\Illuminate\Support\Facades\Schema::hasColumn('users','account_uid') || \Illuminate\Support\Facades\Schema::hasColumn('users','firebase_uid')) $failures[] = 'account identifier migration';
try {
    \App\Http\Controllers\EmailSettingsController::configureMailTransport();
    $transport = app('mail.manager')->mailer('smtp')->getSymfonyTransport();
    $transport->start();
    $transport->stop();
    echo 'PASS configured SMTP authentication'.PHP_EOL;
} catch (\Throwable $exception) {
    echo 'FAIL configured SMTP authentication'.PHP_EOL;
    $failures[] = 'SMTP authentication';
}


foreach (['website_admin','admin','teacher','guardian'] as $role) {
    $user = User::where('role',$role)->first();
    if (!$user) { echo 'No existing '.$role.' account to verify'.PHP_EOL; continue; }
    $token = $user->createToken('deployment-verification');
    $client = Http::acceptJson()->withToken($token->plainTextToken)->timeout(20);
    try {
        $paths = match ($role) {
            'website_admin' => ['/platform/directory','/schools'],
            'admin' => ['/students','/teachers','/school-classes','/academic-years','/admin/dashboard-stats','/activities','/behaviour-categories','/fees/accounts'],
            'teacher' => ['/students','/activities','/behaviour-categories','/teacher/assignments'],
            'guardian' => ['/students','/announcements'],
        };
        foreach ($paths as $path) checkResponse($role.' '.$path, $client->get($base.$path));
        if ($role === 'admin') {
            checkResponse('Admin teacher invitation accepts validation', $client->post($base.'/users',['role'=>'teacher']), [422]);
            checkResponse('Admin cannot create guardians through staff invitation', $client->post($base.'/users',['role'=>'guardian']), [403]);
        }
        if ($role === 'teacher') {
            checkResponse('Teacher guardian invitation accepts validation', $client->post($base.'/users',['role'=>'guardian']), [422]);
            checkResponse('Teacher cannot create staff', $client->post($base.'/users',['role'=>'teacher']), [403]);
            $classes = $user->teacherProfile?->assignedClasses()->count() ?? 0;
            echo 'TEACHER_ASSIGNED_CLASSES='.$classes.PHP_EOL;
            checkResponse('Teacher attendance respects configured class scope', $client->get($base.'/attendance/roster'), $classes ? [200] : [403]);
        }
        if ($role !== 'website_admin') checkResponse($role.' platform denied', $client->get($base.'/platform/directory'), [403]);
        if ($role === 'guardian') {
            $child = $user->students()->first();
            if ($child) {
                checkResponse('Guardian school catalog bearer authentication', $client->get($base.'/uniforms', ['school_id'=>$child->school_id]));
                foreach (['attendance','behaviour','journal','activities/student','reports','assignments'] as $path) {
                    $response = $client->get($base.'/'.$path.'/'.$child->id);
                    $expected = $response->json('code') === 'subscription_suspended' ? [403] : [200];
                    checkResponse('Guardian '.$path, $response, $expected);
                }
            }
        }
    } finally {
        $token->accessToken->delete();
    }
}
$integrity = DB::select('PRAGMA integrity_check');
$foreignKeys = DB::select('PRAGMA foreign_key_check');
echo 'DATABASE_INTEGRITY='.json_encode($integrity).PHP_EOL;
echo 'FOREIGN_KEY_VIOLATIONS='.count($foreignKeys).PHP_EOL;
echo 'SCOPED_ADMINS='.User::where('role','admin')->whereNotNull('school_id')->count().PHP_EOL;
echo 'COUNTS='.json_encode(['users'=>User::count(), 'students'=>DB::table('students')->count(), 'schools'=>DB::table('schools')->count(), 'uniforms'=>DB::table('uniform_items')->count()]).PHP_EOL;
if (count($foreignKeys)) $failures[] = 'foreign keys';
echo 'VERIFICATION_FAILURES='.json_encode($failures).PHP_EOL;
exit(count($failures) ? 1 : 0);

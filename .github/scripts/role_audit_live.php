<?php
// Read-only role audit. Temporary verification tokens are removed immediately.
require 'vendor/autoload.php';
$app=require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\DB;
use App\Models\User;

$manifest=json_decode(file_get_contents('/tmp/guardianship-role-audit-hashes.json'),true);
foreach ($manifest as $path=>$expected) {
    $actual=hash('sha256',str_replace("\r\n","\n",file_get_contents($path)));
    echo ($actual===$expected?'MATCH ':'DIFFERENT ').$path.PHP_EOL;
}
$base=rtrim(config('app.url'),'/').'/api';
echo 'HEALTH='.Http::timeout(20)->get($base.'/health')->status().PHP_EOL;
foreach (['website_admin','admin','teacher','guardian'] as $role) {
    $user=User::where('role',$role)->first();
    if (!$user) continue;
    $token=$user->createToken('read-only-role-audit');
    try {
        $client=Http::acceptJson()->withToken($token->plainTextToken)->timeout(20);
        $paths=match($role) {
            'website_admin'=>['/platform/directory','/schools'],
            'admin'=>['/students','/activities','/behaviour-categories','/fees/accounts'],
            'teacher'=>['/attendance/roster','/activities','/teacher/assignments'],
            'guardian'=>['/students','/announcements'],
        };
        foreach ($paths as $path) echo $role.' '.$path.' '.$client->get($base.$path)->status().PHP_EOL;
        if ($role!=='website_admin') echo $role.' /platform/directory '.$client->get($base.'/platform/directory')->status().PHP_EOL;
    } finally { $token->accessToken->delete(); }
}
echo 'ASSIGNED_TEACHER_CLASSES='.DB::table('teacher_school_class')->count().PHP_EOL;
echo 'DATABASE_INTEGRITY='.json_encode(DB::select('PRAGMA integrity_check')).PHP_EOL;
echo 'FOREIGN_KEY_VIOLATIONS='.count(DB::select('PRAGMA foreign_key_check')).PHP_EOL;

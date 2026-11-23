<?php
// Transactional live smoke checks: only synthetic fixtures; rollback in all cases.
chdir('/var/www/guardianship/backend');
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use App\Models\{School, SchoolClass, Student, Teacher, User, Subscription, FeeAccount};
use Illuminate\Support\Facades\{DB, Auth};
$kernel = $app->make(Illuminate\Contracts\Http\Kernel::class);
$checks = 0;
function check($condition, string $label): void { global $checks; if (!$condition) throw new RuntimeException($label); $checks++; echo "PASS $label\n"; }
function api(string $method, string $path, array $data, ?User $user, int $expected): array {
    global $kernel;
    Auth::forgetGuards();
    $headers = ['HTTP_ACCEPT'=>'application/json','CONTENT_TYPE'=>'application/json','HTTPS'=>'on'];
    if ($user) $headers['HTTP_AUTHORIZATION']='Bearer '.$user->createToken('feature-smoke')->plainTextToken;
    $request = Illuminate\Http\Request::create('https://admin.chewetechnologies.co.zw/api'.$path,$method,[],[],[],$headers,json_encode($data));
    $response = $kernel->handle($request);
    check($response->getStatusCode()===$expected,$method.' '.$path.' status '.$expected);
    return json_decode($response->getContent(),true) ?? [];
}
$marker = 'smoke-'.bin2hex(random_bytes(8));
$before = DB::table('schools')->count();
DB::beginTransaction();
try {
    $password=bin2hex(random_bytes(16));
    $account=function(string $role, ?int $school=null) use($marker,$password) {
        $uid=$marker.'-'.$role.'-'.bin2hex(random_bytes(3));
        return User::create(['name'=>'Release check '.$role,'email'=>$uid.'@example.test','phone_number'=>'+test-'.$uid,'account_uid'=>$uid,'role'=>$role,'school_id'=>$school,'password'=>$password]);
    };
    $school=School::create(['name'=>$marker.' School One','type'=>'primary']);
    $other=School::create(['name'=>$marker.' School Two','type'=>'primary']);
    $class=SchoolClass::create(['school_id'=>$school->id,'grade'=>'1','class_name'=>'Smoke']);
    $classTwo=SchoolClass::create(['school_id'=>$other->id,'grade'=>'1','class_name'=>'Smoke']);
    $teacher=$account('teacher'); $profile=Teacher::create(['user_id'=>$teacher->id,'school_id'=>$school->id]); $profile->assignedClasses()->attach($class->id);
    $teacherTwo=$account('teacher'); Teacher::create(['user_id'=>$teacherTwo->id,'school_id'=>$other->id])->assignedClasses()->attach($classTwo->id);
    $parent=$account('guardian'); $admin=$account('admin',$school->id); $owner=$account('website_admin');
    $child=Student::create(['school_id'=>$school->id,'name'=>'Release child one','grade'=>'1','class_name'=>'Smoke']);
    $second=Student::create(['school_id'=>$other->id,'name'=>'Release child two','grade'=>'1','class_name'=>'Smoke']);
    $parent->students()->attach($child->id);
    Subscription::create(['student_id'=>$child->id,'status'=>'inactive','start_date'=>today()]);
    api('POST','/auth/login',['email'=>$parent->email,'password'=>$password],null,200);
    $status=api('GET','/subscription',[],$parent,200);
    check($status['access_allowed']===false && $status['contact_number']==='079 054 3013','Subscription contact and suspended state');
    api('GET','/announcements',[],$parent,403);
    api('GET','/messages/contacts',[],$parent,403);
    api('GET','/dashboard/'.$child->id,[],$teacher,200);
    api('POST','/journal',['student_id'=>$child->id,'type'=>'text','caption'=>'Release verification'], $teacher,201);
    api('POST','/journal',['student_id'=>$child->id,'type'=>'drawing','caption'=>'Retired'], $teacher,422);
    api('GET','/admin/dashboard-stats',[],$admin,200);
    api('POST','/users',['role'=>'guardian','name'=>'Release parent','email'=>$parent->email,'student_ids'=>[$second->id]],$teacherTwo,200);
    check($parent->students()->count()===2,'Parent is linked at both schools');
    api('POST','/platform/subscriptions/toggle',['student_id'=>$child->id,'status'=>'active','start_date'=>today()->toDateString()],$owner,200);
    $id=api('POST','/activities',['title'=>'Release sports register','activity_date'=>today()->toDateString(),'student_ids'=>[$child->id]],$teacher,201)['activity']['id'];
    api('POST','/activities/'.$id.'/roster',['records'=>[['student_id'=>$child->id,'status'=>'present']]],$teacher,200);
    $participation=api('GET','/activities/student/'.$child->id,[],$parent,200);
    check($participation['activities'][0]['status']==='present','Parent reads activity participation');
    FeeAccount::create(['student_id'=>$child->id,'balance_usd'=>100,'balance_zig'=>0]);
    $payment=api('POST','/fees/pay',['student_id'=>$child->id,'amount'=>10,'currency'=>'USD','payment_method'=>'Card','reference'=>$marker],$parent,202);
    check($payment['transaction']['status']==='pending','Payment still requires school verification');
    api('DELETE','/platform/schools/'.$other->id,['confirm_name'=>$other->name],$admin,403);
    api('DELETE','/platform/schools/'.$other->id,['confirm_name'=>'wrong'], $owner,422);
    api('DELETE','/platform/schools/'.$other->id,['confirm_name'=>$other->name],$owner,200);
    check(User::whereKey($parent->id)->exists() && $parent->students()->count()===1,'Removing synthetic school preserves shared parent');
} finally {
    while (DB::transactionLevel()>0) DB::rollBack();
}
check(DB::table('schools')->count()===$before,'All synthetic changes rolled back');
echo json_encode(['status'=>'passed','checks'=>$checks])."\n";

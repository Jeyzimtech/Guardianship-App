<?php
require 'vendor/autoload.php';
$app=require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use App\Models\{School,SchoolClass,Student,Teacher,User};
use Illuminate\Support\Facades\{DB,Auth,Mail,Queue};
use Illuminate\Support\Str;

function check($ok,$label){if(!$ok)throw new RuntimeException('FAIL '.$label);echo 'PASS '.$label.PHP_EOL;}
function callApi($user,$method,$path,$data=[]){
    global $app;
    Auth::forgetGuards();
    $token=$user->createToken('transactional-release-verification')->plainTextToken;
    $request=Illuminate\Http\Request::create('/api'.$path,$method,[],[],[],['HTTP_ACCEPT'=>'application/json','CONTENT_TYPE'=>'application/json','HTTP_AUTHORIZATION'=>'Bearer '.$token],json_encode($data));
    $response=$app->make(Illuminate\Contracts\Http\Kernel::class)->handle($request);
    return [$response->getStatusCode(),json_decode($response->getContent(),true)];
}
Mail::fake();Queue::fake();
check(app()->environment('production')&&!config('app.debug'),'Production configuration');
check(DB::selectOne('pragma integrity_check')->integrity_check==='ok','Database integrity');
$before=DB::table('users')->count();
DB::beginTransaction();
try{
 $tag=(string)Str::uuid();
 $school=School::create(['name'=>'Transactional verification '.$tag,'type'=>'primary']);
 $class=SchoolClass::create(['school_id'=>$school->id,'grade'=>'1','class_name'=>'Verify']);
 $teacher=User::create(['name'=>'Verification teacher','role'=>'teacher','account_uid'=>'verify_t_'.$tag]);
 Teacher::create(['user_id'=>$teacher->id,'school_id'=>$school->id])->assignedClasses()->attach($class->id);
 $parent=User::create(['name'=>'Verification parent','role'=>'guardian','account_uid'=>'verify_p_'.$tag]);
 $student=Student::create(['name'=>'Verification learner','school_id'=>$school->id,'grade'=>'1','class_name'=>'Verify']);
 $parent->students()->attach($student->id);
 $admin=User::create(['name'=>'Verification moderator','role'=>'website_admin','account_uid'=>'verify_a_'.$tag]);
 [$status,$body]=callApi($parent,'GET','/messages/contacts');check($status===200&&count($body['contacts'])===1,'Scoped guardian contacts');
 [$status]=callApi($teacher,'POST','/messages',['recipient_ids'=>[$parent->id],'body'=>'Temporary isolated verification']);check($status===201,'Direct message creation');
 [$status,$body]=callApi($parent,'GET','/messages/with/'.$teacher->id);check($status===200&&count($body['messages'])===1,'Message delivery and visibility');
 [$status]=callApi($parent,'POST','/messages/block/'.$teacher->id);check($status===200,'Block contact');
 [$status]=callApi($teacher,'POST','/messages',['recipient_ids'=>[$parent->id],'body'=>'Must not send']);check($status===403,'Blocked sender cannot bypass block');
 [$status]=callApi($parent,'DELETE','/messages/block/'.$teacher->id);check($status===200,'Unblock contact');
 [$status,$body]=callApi($parent,'POST','/support/reports',['category'=>'safety','message'=>'Temporary test of the reporting and moderation workflow.']);check($status===201,'Safety report persistence');$report=$body['id'];
 [$status]=callApi($parent,'GET','/moderation/reports');check($status===403,'Reports restricted from ordinary users');
 [$status]=callApi($admin,'PUT','/moderation/reports/'.$report,['review_status'=>'resolved','review_notes'=>'Isolated verification; no real content involved.']);check($status===200,'Moderator review');
 [$status]=callApi($parent,'POST','/auth/delete-account');check($status===200,'Guardian account deletion');
 check(!DB::table('users')->where('id',$parent->id)->exists(),'Guardian identity deleted');
 check(!DB::table('direct_messages')->where('recipient_id',$parent->id)->exists(),'Associated messages deleted');
 check(DB::table('students')->where('id',$student->id)->exists(),'School learner records preserved');
}finally{DB::rollBack();Auth::forgetGuards();}
check(DB::table('users')->count()===$before,'All temporary verification records rolled back');
echo 'No real messages, email or SMS sent.'.PHP_EOL;

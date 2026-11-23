<?php
namespace Tests\Feature;
use App\Models\{School, SchoolClass, Student, Teacher, User, Subscription, FeeAccount, FeeTransaction, JournalEntry, Activity};
use App\Services\MessageRetention;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\{DB, Storage, Queue};
use Tests\TestCase;

class RequestedFeaturesTest extends TestCase
{
    use RefreshDatabase;
    private function family(): array {
        $school = School::create(['name'=>'School One','type'=>'primary']);
        $class = SchoolClass::create(['school_id'=>$school->id,'grade'=>'1','class_name'=>'Blue']);
        $teacher = User::factory()->create(['role'=>'teacher']);
        Teacher::create(['user_id'=>$teacher->id,'school_id'=>$school->id])->assignedClasses()->attach($class->id);
        $child = Student::create(['school_id'=>$school->id,'name'=>'Child One','grade'=>'1','class_name'=>'Blue']);
        $parent = User::factory()->create(['role'=>'guardian','password'=>'password123']);
        $parent->students()->attach($child->id);
        $admin = User::factory()->create(['role'=>'admin','school_id'=>$school->id]);
        return [$school,$class,$teacher,$child,$parent,$admin];
    }
    public function test_suspended_parent_can_login_and_check_activation_but_cannot_bypass_the_gate(): void {
        [,, $teacher,$child,$parent] = $this->family();
        Subscription::create(['student_id'=>$child->id,'status'=>'inactive','start_date'=>today()]);
        $this->postJson('/api/auth/login',['email'=>$parent->email,'password'=>'password123'])->assertOk()->assertJsonPath('user.role','guardian');
        $this->actingAs($parent)->getJson('/api/subscription')->assertOk()->assertJsonPath('access_allowed',false)->assertJsonPath('contact_number','079 054 3013');
        foreach (['/api/students','/api/announcements','/api/guardian/profile','/api/messages/contacts','/api/documents?student_id='.$child->id,'/api/dashboard/'.$child->id] as $url)
            $this->getJson($url)->assertForbidden()->assertJsonPath('code','subscription_suspended');
        $this->postJson('/api/messages',['recipient_ids'=>[$teacher->id],'body'=>'Bypass'])->assertForbidden();
        $this->postJson('/api/auth/logout')->assertOk();
    }
    public function test_activation_and_date_windows_are_respected(): void {
        [,,,$child,$parent] = $this->family();
        $sub=Subscription::create(['student_id'=>$child->id,'status'=>'active','start_date'=>today(),'end_date'=>today()]);
        $this->actingAs($parent)->getJson('/api/subscription')->assertJsonPath('access_allowed',true);
        $sub->update(['end_date'=>today()->subDay()]);
        $this->getJson('/api/subscription')->assertJsonPath('access_allowed',false);
        $this->getJson('/api/announcements')->assertForbidden();
    }
    public function test_teachers_and_school_admins_work_while_parents_are_suspended(): void {
        [,, $teacher,$child,$parent,$admin] = $this->family();
        Subscription::create(['student_id'=>$child->id,'status'=>'inactive','start_date'=>today()]);
        $this->actingAs($teacher)->postJson('/api/journal',['student_id'=>$child->id,'type'=>'text','caption'=>'Learning continues'])->assertCreated();
        $this->postJson('/api/messages',['recipient_ids'=>[$parent->id],'body'=>'Class update'])->assertCreated();
        $this->getJson('/api/activities')->assertOk();
        $this->getJson('/api/subscription')->assertForbidden();
        $this->actingAs($admin)->getJson('/api/admin/dashboard-stats')->assertOk();
        $this->getJson('/api/subscription')->assertForbidden();
    }
    public function test_existing_parent_can_be_linked_at_a_second_school_without_losing_credentials_or_children(): void {
        [,,,$first,$parent] = $this->family();
        [,, $secondTeacher,$second] = $this->family();
        $hash=$parent->password;
        $this->actingAs($secondTeacher)->postJson('/api/users',['name'=>'Different spelling','role'=>'guardian','email'=>$parent->email,'student_ids'=>[$second->id]])
            ->assertOk()->assertJsonPath('user.id',$parent->id);
        $this->assertEqualsCanonicalizing([$first->id,$second->id],$parent->students()->pluck('students.id')->all());
        $this->assertSame($hash,$parent->fresh()->password);
        $this->assertSame(1,User::where('email',$parent->email)->count());
    }
    public function test_school_admin_cannot_unlink_a_parents_other_school_children(): void {
        [,,,$one,$parent,$admin] = $this->family();
        [,,,$two] = $this->family();
        $parent->students()->attach($two->id);
        $this->actingAs($admin)->putJson('/api/users/'.$parent->id,['student_ids'=>[]])->assertOk();
        $this->assertSame([$two->id],$parent->students()->pluck('students.id')->all());
    }
    public function test_drawings_are_no_longer_accepted(): void {
        [,, $teacher,$child] = $this->family();
        $this->actingAs($teacher)->postJson('/api/journal',['student_id'=>$child->id,'type'=>'drawing','caption'=>'Retired'])->assertUnprocessable();
        $this->postJson('/api/journal',['student_id'=>$child->id,'type'=>'photo','media_url'=>'https://example.com/photo.jpg'])->assertCreated();
    }
    public function test_messages_expire_at_seven_days_and_are_physically_removed(): void {
        [,, $teacher,,$parent] = $this->family();
        $this->travelTo(now()->startOfSecond());
        $row=['sender_id'=>$teacher->id,'recipient_id'=>$parent->id,'body'=>'Message','updated_at'=>now()];
        $old=DB::table('direct_messages')->insertGetId($row+['created_at'=>now()->subDays(7)]);
        $fresh=DB::table('direct_messages')->insertGetId($row+['created_at'=>now()->subDays(7)->addSecond()]);
        DB::table('mobile_reads')->insert(['user_id'=>$parent->id,'category'=>'messages','item_id'=>$old]);
        $this->actingAs($parent)->getJson('/api/messages/with/'.$teacher->id)->assertOk()->assertJsonCount(1,'messages')->assertJsonPath('messages.0.id',$fresh);
        $this->assertDatabaseMissing('direct_messages',['id'=>$old]);
        $this->assertDatabaseMissing('mobile_reads',['item_id'=>$old,'category'=>'messages']);
        $this->artisan('messages:prune')->assertSuccessful();
    }
    public function test_only_owner_can_remove_school_and_confirmation_is_required(): void {
        [$school,,,,$parent,$admin] = $this->family();
        $owner=User::factory()->create(['role'=>'website_admin']);
        $url='/api/platform/schools/'.$school->id;
        foreach ([$admin,$parent] as $actor) $this->actingAs($actor)->deleteJson($url,['confirm_name'=>$school->name])->assertForbidden();
        $this->actingAs($owner)->deleteJson($url,['confirm_name'=>'wrong'])->assertUnprocessable();
        $this->assertDatabaseHas('schools',['id'=>$school->id]);
    }
    public function test_school_wipe_preserves_other_school_and_shared_parent(): void {
        Queue::fake();
        [$school,, $teacher,$child,$parent,$admin] = $this->family();
        [$other,,, $otherChild] = $this->family();
        $parent->students()->attach($otherChild->id);
        JournalEntry::create(['student_id'=>$child->id,'author_id'=>$teacher->id,'type'=>'text','caption'=>'Wipe']);
        DB::table('sos_alerts')->insert(['teacher_id'=>$teacher->id,'request_id'=>(string) \Illuminate\Support\Str::uuid(),'message'=>'Old alert','created_at'=>now(),'updated_at'=>now()]);
        $owner=User::factory()->create(['role'=>'website_admin']);
        $this->actingAs($owner)->deleteJson('/api/platform/schools/'.$school->id,['confirm_name'=>$school->name])->assertOk();
        foreach (['schools'=>$school->id,'students'=>$child->id,'users'=>$teacher->id] as $table=>$id) $this->assertDatabaseMissing($table,['id'=>$id]);
        $this->assertDatabaseHas('schools',['id'=>$other->id]);
        $this->assertDatabaseHas('users',['id'=>$parent->id]);
        $this->assertSame([$otherChild->id],$parent->students()->pluck('students.id')->all());
        $this->assertDatabaseCount('journal_entries',0);
    }
    public function test_file_cleanup_removes_only_the_supplied_school_files(): void {
        Storage::fake('local');
        Storage::disk('local')->put('student-photos/one.png','one');
        Storage::disk('local')->put('student-photos/two.png','two');
        (new \App\Jobs\PurgeSchoolFiles([['local','student-photos/one.png']]))->handle();
        Storage::disk('local')->assertMissing('student-photos/one.png');
        Storage::disk('local')->assertExists('student-photos/two.png');
    }
    public function test_payment_proof_is_private_and_does_not_credit_or_activate_subscription(): void {
        Storage::fake('local');
        [,,, $child,$parent,$admin] = $this->family();
        FeeAccount::create(['student_id'=>$child->id,'balance_usd'=>100,'balance_zig'=>0]);
        $proof=UploadedFile::fake()->createWithContent('receipt.pdf','%PDF-1.4 receipt');
        $id=$this->actingAs($parent)->post('/api/fees/pay',['student_id'=>$child->id,'amount'=>10,'currency'=>'USD','payment_method'=>'Card','reference'=>'REF-PROOF','proof'=>$proof],['Accept'=>'application/json'])
            ->assertStatus(202)->assertJsonPath('transaction.has_proof',true)->json('transaction.id');
        $this->assertSame('pending',FeeTransaction::find($id)->status);
        $this->assertSame(100.0,(float)$child->feeAccount->balance_usd);
        $this->assertDatabaseCount('subscriptions',0);
        $this->actingAs($admin)->get('/api/fees/payments/'.$id.'/proof')->assertOk();
        [, , , , ,$otherAdmin]=$this->family();
        $this->actingAs($otherAdmin)->getJson('/api/fees/payments/'.$id.'/proof')->assertForbidden();
    }
    public function test_activity_register_reaches_parent_and_is_school_scoped(): void {
        [,, $teacher,$child,$parent] = $this->family();
        $id=$this->actingAs($teacher)->postJson('/api/activities',['title'=>'Sports extra lesson','activity_date'=>today()->toDateString(),'student_ids'=>[$child->id]])->assertCreated()->json('activity.id');
        $this->postJson('/api/activities/'.$id.'/roster',['records'=>[['student_id'=>$child->id,'status'=>'present']]])->assertOk();
        $this->actingAs($parent)->getJson('/api/activities/student/'.$child->id)->assertOk()->assertJsonPath('activities.0.status','present');
        $this->postJson('/api/activities',['title'=>'Parent edit','activity_date'=>today()->toDateString()])->assertForbidden();
        [,, $otherTeacher]=$this->family();
        $this->actingAs($otherTeacher)->getJson('/api/activities/'.$id.'/roster')->assertNotFound();
    }
    public function test_suspension_at_one_school_does_not_expose_that_schools_notices_or_contacts(): void {
        [$one,, $teacherOne,$childOne,$parent] = $this->family();
        [$two,, $teacherTwo,$childTwo] = $this->family();
        $parent->students()->attach($childTwo->id);
        Subscription::create(['student_id'=>$childOne->id,'status'=>'inactive','start_date'=>today()]);
        \App\Models\Announcement::create(['school_id'=>$one->id,'title'=>'Locked','content'=>'Private','audience_role'=>'guardian']);
        \App\Models\Announcement::create(['school_id'=>$two->id,'title'=>'Visible','content'=>'Available','audience_role'=>'guardian']);
        $this->actingAs($parent)->getJson('/api/announcements')->assertOk()->assertJsonCount(1,'announcements')->assertJsonPath('announcements.0.title','Visible');
        $this->getJson('/api/messages/contacts')->assertOk()->assertJsonCount(1,'contacts')->assertJsonPath('contacts.0.id',$teacherTwo->id);
        $this->getJson('/api/dashboard/'.$childOne->id)->assertForbidden();
        $this->getJson('/api/dashboard/'.$childTwo->id)->assertOk();
    }
    public function test_removing_shared_parent_from_one_school_keeps_the_other_link(): void {
        [,,,$child,$parent,$admin] = $this->family();
        [,,,$other] = $this->family();
        $parent->students()->attach($other->id);
        $this->actingAs($admin)->deleteJson('/api/users/'.$parent->id)->assertOk();
        $this->assertDatabaseHas('users',['id'=>$parent->id]);
        $this->assertSame([$other->id],$parent->students()->pluck('students.id')->all());
    }

    public function test_school_admin_cannot_read_other_school_links_or_reset_a_shared_parents_password(): void {
        [,,,$child,$parent,$admin] = $this->family();
        [,,,$other] = $this->family(); $parent->students()->attach($other->id);
        $this->actingAs($admin)->getJson('/api/users/'.$parent->id)->assertOk()->assertJsonCount(1,'user.students')->assertJsonPath('user.students.0.id',$child->id);
        $this->putJson('/api/users/'.$parent->id,['password'=>'replacepassword'])->assertUnprocessable();
    }

}

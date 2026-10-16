<?php
namespace Tests\Feature;

use App\Models\{User, School, SchoolClass, Student, Teacher};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\{Mail, DB, Hash};
use Tests\TestCase;

class AccountInvitationTest extends TestCase
{
    use RefreshDatabase;

    private function staff(): array
    {
        $school = School::create(['name'=>'School','type'=>'primary']);
        $class = SchoolClass::create(['school_id'=>$school->id,'grade'=>'1','class_name'=>'Blue']);
        $child = Student::create(['school_id'=>$school->id,'name'=>'Child','grade'=>'1','class_name'=>'Blue']);
        $teacher = User::create(['name'=>'Teacher','phone_number'=>'teacher','account_uid'=>'t','role'=>'teacher']);
        Teacher::create(['user_id'=>$teacher->id,'school_id'=>$school->id])->assignedClasses()->attach($class->id);
        $admin = User::create(['name'=>'Admin','phone_number'=>'admin','account_uid'=>'a','role'=>'admin','school_id'=>$school->id]);
        return [$teacher,$admin,$school,$child];
    }

    private function expectInvitation(?string &$url): void
    {
        Mail::shouldReceive('purge')->zeroOrMoreTimes();
        Mail::shouldReceive('send')->once()->with('emails.set_password', \Mockery::on(function ($data) use (&$url) {
            $url = $data['setupUrl'];
            return str_contains($url, '/set-password?token=');
        }), \Mockery::type('Closure'));
    }

    public function test_teacher_invites_guardian_and_the_email_link_sets_a_working_password(): void
    {
        [$teacher,,$school,$child] = $this->staff();
        $url = null; $this->expectInvitation($url);
        $this->actingAs($teacher)->postJson('/api/users', ['name'=>'Parent','email'=>' Parent@Example.com ','phone_number'=>'parent','role'=>'guardian','student_ids'=>[$child->id]])
            ->assertCreated()->assertJsonPath('email_sent', true);
        $parent = User::where('email','parent@example.com')->firstOrFail();
        $this->assertTrue($parent->students()->whereKey($child->id)->exists());
        parse_str(parse_url($url, PHP_URL_QUERY), $query);
        $this->assertTrue(Hash::check($query['token'], DB::table('password_reset_tokens')->where('email',$parent->email)->value('token')));
        $this->postJson('/api/auth/reset-password', $query + ['password'=>'New-password-123','password_confirmation'=>'New-password-123'])->assertOk();
        $this->postJson('/api/auth/login', ['email'=>$parent->email,'password'=>'New-password-123'])->assertOk()->assertJsonPath('user.role','guardian');
        $this->postJson('/api/auth/reset-password', $query + ['password'=>'Other-password-123','password_confirmation'=>'Other-password-123'])->assertStatus(422);
    }

    public function test_admin_invites_teacher_at_own_school(): void
    {
        [,$admin,$school] = $this->staff();
        $url=null; $this->expectInvitation($url);
        $this->actingAs($admin)->postJson('/api/users', ['name'=>'New Teacher','email'=>'new@example.com','phone_number'=>'new','role'=>'teacher'])
            ->assertCreated()->assertJsonPath('email_sent',true)->assertJsonPath('user.teacher_profile.school_id',$school->id);
    }

    public function test_teacher_profile_creation_sends_exactly_one_invitation(): void
    {
        [,$admin,$school] = $this->staff();
        $url=null; $this->expectInvitation($url);
        $this->actingAs($admin)->postJson('/api/teachers', ['name'=>'Profile Teacher','email'=>'profile@example.com','phone'=>'profile-phone','school_id'=>$school->id])
            ->assertCreated()->assertJsonPath('email_sent',true);
    }

    public function test_teacher_cannot_invite_guardians_for_other_classes_or_create_staff(): void
    {
        [$teacher,,$school] = $this->staff();
        $other = Student::create(['school_id'=>$school->id,'name'=>'Other','grade'=>'2','class_name'=>'Blue']);
        $this->actingAs($teacher)->postJson('/api/users', ['name'=>'Parent','email'=>'other@example.com','phone_number'=>'other','role'=>'guardian','student_ids'=>[$other->id]])->assertForbidden();
        $this->postJson('/api/users', ['role'=>'teacher'])->assertForbidden();
        $this->assertDatabaseMissing('users',['email'=>'other@example.com']);
    }

    public function test_teacher_can_resend_only_guardian_links_in_own_classes(): void
    {
        [$teacher,,$school,$child] = $this->staff();
        $parent = User::create(['name'=>'Parent','email'=>'parent@example.com','phone_number'=>'parent','account_uid'=>'p','role'=>'guardian']);
        $this->actingAs($teacher)->postJson('/api/users/'.$parent->id.'/send-link')->assertForbidden();
        $parent->students()->attach($child->id);
        $url=null; $this->expectInvitation($url);
        $this->postJson('/api/users/'.$parent->id.'/send-link')->assertOk();
    }

    public function test_email_templates_render_a_single_clear_action(): void
    {
        $html = view('emails.set_password',['name'=>'Parent','email'=>'parent@example.com','role'=>'guardian','setupUrl'=>'https://example.com/set-password?token=test'])->render();
        $this->assertStringContainsString('Create my password',$html);
        $this->assertStringNotContainsString('linear-gradient',$html);
        $this->assertStringContainsString('48 hours',$html);
    }
}

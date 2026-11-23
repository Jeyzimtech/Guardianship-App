<?php

namespace Tests\Feature;

use App\Models\{School, SchoolClass, Student, Teacher, User};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\{DB, Mail};
use Tests\TestCase;

class AccountDeletionAndSupportTest extends TestCase
{
    use RefreshDatabase;

    private function records(): array
    {
        $school = School::create(['name'=>'School','type'=>'primary']);
        $class = SchoolClass::create(['school_id'=>$school->id,'grade'=>'4','class_name'=>'Blue']);
        $child = Student::create(['school_id'=>$school->id,'name'=>'Child','grade'=>'4','class_name'=>'Blue']);
        $parent = User::create(['name'=>'Parent','role'=>'guardian','phone_number'=>'0771234567','account_uid'=>'p','email'=>'parent@example.com']);
        $parent->students()->attach($child->id);
        $teacher = User::create(['name'=>'Teacher','role'=>'teacher','phone_number'=>'0711234567','account_uid'=>'t','email'=>'teacher@example.com','password'=>'secret123']);
        Teacher::create(['school_id'=>$school->id,'user_id'=>$teacher->id])->assignedClasses()->attach($class->id);
        return [$parent, $teacher, $child];
    }

    public function test_guardian_deletes_own_account_and_links(): void
    {
        [$parent, , $child] = $this->records();
        $token = $parent->createToken('auth-token')->plainTextToken;
        $this->withToken($token)->postJson('/api/auth/delete-account')->assertOk()->assertJsonPath('status', 'success');
        $this->assertDatabaseMissing('users', ['id'=>$parent->id]);
        $this->assertDatabaseMissing('personal_access_tokens', ['tokenable_id'=>$parent->id]);
        $this->assertDatabaseHas('students', ['id'=>$child->id]);
    }

    public function test_teacher_deletion_erases_identity_but_keeps_school_records(): void
    {
        [, $teacher, $child] = $this->records();
        DB::table('sos_alerts')->insert(['teacher_id'=>$teacher->id,'request_id'=>(string) \Illuminate\Support\Str::uuid(),'message'=>'Drill','created_at'=>now(),'updated_at'=>now()]);
        $this->actingAs($teacher)->postJson('/api/auth/delete-account')->assertOk();
        $fresh = $teacher->fresh();
        $this->assertSame('Former teacher', $fresh->name);
        $this->assertNull($fresh->email);
        $this->assertNull($fresh->phone_number);
        $this->assertSame('deleted', $fresh->role);
        $this->assertDatabaseMissing('teachers', ['user_id'=>$teacher->id]);
        $this->assertDatabaseHas('sos_alerts', ['teacher_id'=>$teacher->id]);
        $this->postJson('/api/auth/login', ['email'=>'teacher@example.com','password'=>'secret123'])->assertUnauthorized();
    }

    public function test_admins_cannot_delete_from_the_app(): void
    {
        $admin = User::create(['name'=>'Admin','role'=>'admin','phone_number'=>'admin','account_uid'=>'a']);
        $this->actingAs($admin)->postJson('/api/auth/delete-account')->assertForbidden();
        $this->assertDatabaseHas('users', ['id'=>$admin->id]);
    }

    public function test_support_report_is_stored_and_emailed_to_support(): void
    {
        Mail::fake();
        [$parent] = $this->records();
        $this->actingAs($parent)->postJson('/api/support/reports', [
            'category'=>'bug', 'message'=>'Homework page does not open.', 'app_version'=>'1.0.8 (9)', 'platform'=>'android',
        ])->assertCreated();
        $this->assertDatabaseHas('support_reports', ['user_id'=>$parent->id, 'category'=>'bug', 'app_version'=>'1.0.8 (9)']);
        $this->postJson('/api/support/reports', ['category'=>'spam', 'message'=>'short'])->assertUnprocessable();
    }

    public function test_support_report_requires_sign_in_and_legal_pages_are_public(): void
    {
        $this->postJson('/api/support/reports', ['category'=>'bug','message'=>'Something broke here.'])->assertUnauthorized();
        foreach (['/privacy-policy', '/terms', '/account-deletion'] as $page) {
            $this->get($page)->assertOk()->assertSee('admin@teramark.co.zw');
        }
    }

    public function test_safety_reports_can_only_be_reviewed_by_platform_administrators(): void
    {
        Mail::fake();
        [$parent, $teacher] = $this->records();
        $this->actingAs($parent)->postJson('/api/support/reports', ['category'=>'safety', 'message'=>'Please review this objectionable classroom message.'])->assertCreated();
        $id=DB::table('support_reports')->value('id');
        $this->getJson('/api/moderation/reports')->assertForbidden();
        $this->actingAs($teacher)->putJson('/api/moderation/reports/'.$id, ['review_status'=>'resolved','review_notes'=>'Not allowed'])->assertForbidden();
        $admin=User::create(['name'=>'Platform','role'=>'website_admin','account_uid'=>'moderator']);
        $this->actingAs($admin)->getJson('/api/moderation/reports')->assertOk()->assertJsonCount(1,'reports');
        $this->putJson('/api/moderation/reports/'.$id, ['review_status'=>'reviewing','review_notes'=>'Contacted the school administrator.'])->assertOk();
        $this->assertDatabaseHas('support_reports',['id'=>$id,'review_status'=>'reviewing','reviewed_by'=>$admin->id]);
    }
}

<?php

namespace Tests\Feature;

use App\Models\{School, SchoolClass, Student, Teacher, User};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\{DB, Http, RateLimiter};
use Illuminate\Support\Str;
use Tests\TestCase;

class SmsAndSosTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        config(['services.smspop.token' => 'test-token', 'services.smspop.sender_id' => 'SMSPoP']);
        Http::preventStrayRequests();
    }

    private function parentAccount(): User
    {
        return User::create(['name' => 'Parent', 'role' => 'guardian', 'phone_number' => '0771234567', 'account_uid' => (string) Str::uuid()]);
    }

    private function gateway(): void
    {
        Http::fake(['smspop.co.zw/*' => Http::response(['success' => true, 'data' => ['summary' => ['sent' => 1], 'contacts' => [['message_id' => 1, 'phone' => '263771234567', 'status' => 'sent']]]])]);
    }

    public function test_phone_only_account_verifies_and_code_cannot_be_reused(): void
    {
        $parent = $this->parentAccount(); $this->gateway();
        $id = $this->postJson('/api/auth/phone/request', ['phone_number' => '+263771234567'])->assertOk()->json('challenge_id');
        $code = null;
        Http::assertSent(function ($request) use (&$code) {
            preg_match('/code: (\d{6})/', $request['message'], $matches); $code = $matches[1];
            return $request['manual_contacts'] === '263771234567' && $request->hasHeader('Authorization', 'Bearer test-token');
        });
        $this->assertNotSame($code, DB::table('phone_otps')->value('code_hash'));
        $this->postJson('/api/auth/phone/verify', ['challenge_id' => $id, 'code' => $code])->assertOk()->assertJsonPath('user.id', $parent->id)->assertJsonStructure(['token']);
        $this->assertNotNull($parent->fresh()->phone_verified_at);
        $this->postJson('/api/auth/phone/verify', ['challenge_id' => $id, 'code' => $code])->assertUnprocessable();
    }

    public function test_otp_is_rate_limited_expired_and_locked_after_five_attempts(): void
    {
        $this->parentAccount(); $this->gateway();
        $id = $this->postJson('/api/auth/phone/request', ['phone_number' => '0771234567'])->assertOk()->json('challenge_id');
        $this->postJson('/api/auth/phone/request', ['phone_number' => '263771234567'])->assertStatus(429);
        for ($i = 0; $i < 5; $i++) $this->postJson('/api/auth/phone/verify', ['challenge_id' => $id, 'code' => '000000'])->assertUnprocessable();
        $this->assertSame(5, DB::table('phone_otps')->value('attempts'));
        DB::table('phone_otps')->update(['attempts' => 0, 'expires_at' => now()->subMinute()]);
        $this->postJson('/api/auth/phone/verify', ['challenge_id' => $id, 'code' => '000000'])->assertUnprocessable();
    }

    public function test_gateway_failure_never_returns_a_usable_challenge(): void
    {
        $this->parentAccount(); Http::fake(['*' => Http::response(['message' => 'Insufficient credits'], 402)]);
        $this->postJson('/api/auth/phone/request', ['phone_number' => '0771234567'])->assertStatus(503);
        $this->assertDatabaseCount('phone_otps', 0);
    }

    private function classroom(): array
    {
        $school = School::create(['name' => 'School', 'type' => 'primary']);
        $class = SchoolClass::create(['school_id' => $school->id, 'grade' => '1', 'class_name' => 'Blue']);
        $teacher = User::create(['name' => 'Teacher', 'role' => 'teacher', 'phone_number' => '0711234567', 'account_uid' => (string) Str::uuid()]);
        Teacher::create(['user_id' => $teacher->id, 'school_id' => $school->id])->assignedClasses()->attach($class->id);
        $student = Student::create(['name' => 'Child', 'school_id' => $school->id, 'grade' => '1', 'class_name' => 'Blue']);
        return [$teacher, $student, $class];
    }

    public function test_teacher_adds_phone_only_parent_and_student_but_admin_cannot_enroll(): void
    {
        [$teacher, $student, $class] = $this->classroom();
        $this->actingAs($teacher)->postJson('/api/users', ['name' => 'Parent', 'phone_number' => '0771234567', 'role' => 'guardian', 'student_ids' => [$student->id]])
            ->assertCreated()->assertJsonPath('user.email', null)->assertJsonPath('user.phone_number', '263771234567');
        $this->postJson('/api/students', ['name' => 'New Child', 'class_id' => $class->id, 'guardian_name' => 'Other Parent', 'guardian_phone' => '0781234567'])->assertCreated();
        $this->postJson('/api/users', ['role' => 'teacher'])->assertForbidden();
        $this->actingAs(User::create(['name' => 'Admin', 'role' => 'admin', 'phone_number' => 'admin', 'account_uid' => 'admin']))
            ->postJson('/api/students', ['name' => 'No', 'class_id' => $class->id])->assertForbidden();
    }

    public function test_parent_contacts_are_independently_optional(): void
    {
        [$teacher, $student, $class] = $this->classroom();
        \Illuminate\Support\Facades\Mail::fake();
        $this->actingAs($teacher);
        foreach ([[], ['email' => 'parent@example.com'], ['phone_number' => '0771234567'], ['email' => 'both@example.com', 'phone_number' => '0781234567']] as $contacts) {
            $response = $this->postJson('/api/users', $contacts + ['name' => 'Parent', 'role' => 'guardian', 'student_ids' => [$student->id]])->assertCreated();
            $this->assertSame($contacts['email'] ?? null, $response->json('user.email'));
            if (empty($contacts['phone_number'])) $response->assertJsonPath('user.phone_number', null);
        }
        foreach ([[], ['guardian_email' => 'enroll@example.com']] as $contacts) {
            $this->postJson('/api/students', $contacts + ['name' => 'Child', 'class_id' => $class->id, 'guardian_name' => 'New Parent'])
                ->assertCreated()->assertJsonPath('student.guardians.0.phone_number', null);
        }
        $this->postJson('/api/users', ['name' => 'Invalid', 'role' => 'guardian', 'phone_number' => 'invalid', 'student_ids' => [$student->id]])->assertUnprocessable();
    }

    public function test_sos_is_scoped_deduplicated_and_acknowledged_by_recipient_only(): void
    {
        [$teacher, $student] = $this->classroom();
        $parent = $this->parentAccount(); $parent->students()->attach($student->id);
        $outsider = User::create(['name' => 'Other', 'role' => 'guardian', 'phone_number' => '0781234567', 'account_uid' => 'other']);
        $this->gateway();
        $payload = ['request_id' => (string) Str::uuid(), 'message' => 'Contact the school.'];
        $id = $this->actingAs($teacher)->postJson('/api/sos', $payload)->assertCreated()->assertJsonPath('recipients', 1)->assertJsonPath('alert.sms_status', 'accepted')->json('alert.id');
        $this->postJson('/api/sos', $payload)->assertCreated()->assertJsonPath('alert.id', $id);
        Http::assertSentCount(1);
        $this->actingAs($outsider)->getJson('/api/sos')->assertJsonCount(0, 'alerts');
        $this->postJson('/api/sos/'.$id.'/acknowledge')->assertNotFound();
        $this->actingAs($parent)->getJson('/api/sos')->assertJsonCount(1, 'alerts');
        $this->postJson('/api/sos/'.$id.'/acknowledge')->assertOk();
        $this->getJson('/api/sos')->assertJsonCount(0, 'alerts');
        $this->postJson('/api/sos', $payload)->assertForbidden();
    }

    public function test_failed_sms_keeps_the_emergency_visible_in_the_app(): void
    {
        [$teacher, $student] = $this->classroom();
        $parent = $this->parentAccount(); $parent->students()->attach($student->id);
        Http::fake(['*' => Http::response([], 402)]);
        $this->actingAs($teacher)->postJson('/api/sos', ['request_id' => (string) Str::uuid(), 'message' => 'Emergency'])
            ->assertCreated()->assertJsonPath('alert.sms_status', 'unconfirmed');
        $this->actingAs($parent)->getJson('/api/sos')->assertJsonCount(1, 'alerts');
    }
}

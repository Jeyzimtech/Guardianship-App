<?php
namespace Tests\Feature;

use App\Models\{User, School, Student};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PlatformOwnerAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_owner_command_creates_a_working_login_without_overwriting_accounts(): void
    {
        $this->artisan('platform:create-owner', ['email' => 'owner@example.com'])
            ->expectsQuestion('Choose a password (at least 12 characters)', 'Private-owner-123!')
            ->assertExitCode(0);
        $login = $this->postJson('/api/auth/login', ['email' => 'owner@example.com', 'password' => 'Private-owner-123!'])
            ->assertOk()->assertJsonPath('user.role', 'website_admin');
        $this->withToken($login->json('token'))->getJson('/api/platform/directory')->assertOk();
        $this->artisan('platform:create-owner', ['email' => 'owner@example.com'])->assertExitCode(1);
        $this->assertDatabaseCount('users', 1);
    }

    public function test_owner_manages_subscription_and_school_admin_cannot_enter_platform(): void
    {
        $school = School::create(['name' => 'School', 'type' => 'primary']);
        $student = Student::create(['name' => 'Child', 'school_id' => $school->id, 'grade' => '4', 'class_name' => 'Gold']);
        $owner = User::factory()->create(['role' => 'website_admin', 'phone_number' => 'owner-phone', 'account_uid' => 'owner-test']);
        $this->actingAs($owner)->postJson('/api/platform/subscriptions/toggle', [
            'student_id' => $student->id, 'status' => 'inactive',
            'start_date' => now()->toDateString(), 'end_date' => now()->addDays(3)->toDateString(),
        ])->assertOk();
        $this->getJson('/api/platform/directory')->assertJsonPath('directory.0.subscription_status', 'inactive');
        $this->getJson('/api/platform/subscriptions/history/'.$student->id)->assertOk()->assertJsonCount(1, 'data.history');
        $admin = User::factory()->create(['role' => 'admin', 'phone_number' => 'admin-phone', 'account_uid' => 'admin-test', 'school_id' => $school->id]);
        $this->actingAs($admin)->getJson('/api/platform/directory')->assertForbidden();
        $this->postJson('/api/platform/subscriptions/toggle', ['student_id' => $student->id, 'status' => 'active'])->assertForbidden();
    }
}

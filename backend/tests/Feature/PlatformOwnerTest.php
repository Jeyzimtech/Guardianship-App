<?php
namespace Tests\Feature;
use App\Models\{School, User, Student};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** Website Admin (Platform Owner): onboard schools, view students per school, toggle subscriptions. */
class PlatformOwnerTest extends TestCase {
    use RefreshDatabase;

    public function test_owner_onboards_views_and_toggles_subscription_for_a_period(): void {
        $owner = User::create(['name' => 'Owner', 'phone_number' => '10', 'role' => 'website_admin', 'firebase_uid' => 'w']);
        $this->actingAs($owner);

        $schoolId = $this->postJson('/api/platform/schools', ['name' => 'Second School', 'type' => 'primary'])->assertCreated()->json('data.id');
        $child = Student::create(['name' => 'Child', 'school_id' => $schoolId, 'grade' => '1', 'class_name' => 'Red']);
        $parent = User::create(['name' => 'Parent', 'phone_number' => '11', 'role' => 'guardian', 'firebase_uid' => 'p']);
        $parent->students()->attach($child->id);

        $this->getJson('/api/schools')->assertOk()->assertJsonPath('schools.0.students_count', 1);
        $this->getJson('/api/platform/directory')->assertOk()
            ->assertJsonPath('directory.0.school_id', $schoolId)
            ->assertJsonPath('directory.0.subscription_status', 'active');

        // Suspend for a set period starting today.
        $this->postJson('/api/platform/subscriptions/toggle', [
            'student_id' => $child->id, 'status' => 'inactive',
            'start_date' => now()->toDateString(), 'end_date' => now()->addDays(7)->toDateString(),
        ])->assertOk();
        $this->getJson('/api/platform/directory')->assertJsonPath('directory.0.subscription_status', 'inactive');
        $this->actingAs($parent)->getJson("/api/attendance/{$child->id}")->assertForbidden()->assertJsonPath('code', 'subscription_suspended');

        // Switch back on.
        $this->actingAs($owner)->postJson('/api/platform/subscriptions/toggle', ['student_id' => $child->id, 'status' => 'active'])->assertOk();
        $this->actingAs($parent)->getJson("/api/attendance/{$child->id}")->assertOk();
        $this->actingAs($owner)->getJson("/api/platform/subscriptions/history/{$child->id}")->assertOk()->assertJsonCount(2, 'data.history');
    }

    public function test_owner_is_blocked_from_school_internal_work(): void {
        $school = School::create(['name' => 'Hillside', 'type' => 'primary']);
        $child = Student::create(['name' => 'Child', 'school_id' => $school->id, 'grade' => '1', 'class_name' => 'Red']);
        $this->actingAs(User::create(['name' => 'Owner', 'phone_number' => '12', 'role' => 'website_admin', 'firebase_uid' => 'w2']));

        $this->postJson('/api/attendance/mark', ['date' => now()->toDateString(), 'records' => [['student_id' => $child->id, 'status' => 'present']]])->assertForbidden();
        $this->postJson('/api/behaviour', ['student_id' => $child->id, 'polarity' => 'positive', 'category' => 'x', 'incident_date' => now()->toDateString()])->assertForbidden();
        $this->postJson('/api/announcements', ['title' => 't', 'content' => 'c', 'audience_role' => 'all', 'school_id' => $school->id])->assertForbidden();
        $this->putJson("/api/students/{$child->id}", ['name' => 'X', 'class_id' => 1])->assertForbidden();
    }

    public function test_school_admin_cannot_use_platform_console(): void {
        $school = School::create(['name' => 'Hillside', 'type' => 'primary']);
        $this->actingAs(User::create(['name' => 'Admin', 'phone_number' => '13', 'role' => 'admin', 'firebase_uid' => 'a', 'school_id' => $school->id]));
        $this->getJson('/api/platform/directory')->assertForbidden();
        $this->postJson('/api/platform/schools', ['name' => 'X', 'type' => 'primary'])->assertForbidden();
    }
}

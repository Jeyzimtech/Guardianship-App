<?php
namespace Tests\Feature;
use App\Models\{School, SchoolClass, Teacher, User, Student, BehaviourCategory};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

/** Checks the platform owner / school admin / teacher / parent / student role matrix. */
class RoleMatrixTest extends TestCase {
    use RefreshDatabase;

    private School $school;
    private SchoolClass $gold;
    private Student $goldChild;
    private Student $blueChild;
    private User $teacher;
    private User $admin;
    private User $parent;

    protected function setUp(): void {
        parent::setUp();
        $this->school = School::create(['name' => 'Hillside', 'type' => 'primary']);
        $this->gold = SchoolClass::create(['school_id' => $this->school->id, 'grade' => '4', 'class_name' => 'Gold']);
        SchoolClass::create(['school_id' => $this->school->id, 'grade' => '4', 'class_name' => 'Blue']);
        $this->goldChild = Student::create(['name' => 'Gold Child', 'school_id' => $this->school->id, 'grade' => '4', 'class_name' => 'Gold']);
        $this->blueChild = Student::create(['name' => 'Blue Child', 'school_id' => $this->school->id, 'grade' => '4', 'class_name' => 'Blue']);
        $this->teacher = User::create(['name' => 'Teacher', 'phone_number' => '1', 'role' => 'teacher', 'account_uid' => 't']);
        Teacher::create(['school_id' => $this->school->id, 'user_id' => $this->teacher->id])->assignedClasses()->attach($this->gold->id);
        $this->admin = User::create(['name' => 'Admin', 'phone_number' => '2', 'role' => 'admin', 'account_uid' => 'a', 'school_id' => $this->school->id]);
        $this->parent = User::create(['name' => 'Parent', 'phone_number' => '3', 'role' => 'guardian', 'account_uid' => 'p']);
        $this->parent->students()->attach($this->goldChild->id);
    }

    public function test_teacher_is_scoped_to_own_classes(): void {
        $this->actingAs($this->teacher);
        $this->getJson("/api/journal/{$this->goldChild->id}")->assertOk();
        $this->getJson("/api/journal/{$this->blueChild->id}")->assertForbidden();
        $this->getJson("/api/fees/{$this->goldChild->id}")->assertForbidden();
    }

    public function test_parent_reads_only_linked_child_and_cannot_author(): void {
        $this->actingAs($this->parent);
        $this->getJson("/api/behaviour/{$this->goldChild->id}")->assertOk();
        $this->getJson("/api/behaviour/{$this->blueChild->id}")->assertForbidden();
        $this->postJson('/api/behaviour', ['student_id' => $this->goldChild->id, 'polarity' => 'positive', 'category' => 'x', 'incident_date' => '2026-10-16'])->assertForbidden();
        $this->putJson("/api/students/{$this->goldChild->id}", ['name' => 'Renamed', 'class_id' => $this->gold->id])->assertForbidden();
    }

    public function test_admin_configures_categories_and_teacher_enrolls_students(): void {
        $this->actingAs($this->admin);
        $this->postJson('/api/students', ['name' => 'New Child', 'class_id' => $this->gold->id])->assertForbidden();
        $this->actingAs($this->teacher)->postJson('/api/students', ['name' => 'New Child', 'class_id' => $this->gold->id])->assertCreated();
        $this->actingAs($this->admin);
        $this->postJson('/api/behaviour-categories', ['name' => 'Kindness', 'polarity' => 'positive'])->assertCreated();

        $this->actingAs($this->teacher);
        $incident = ['student_id' => $this->goldChild->id, 'polarity' => 'positive', 'incident_date' => '2026-10-16'];
        $this->postJson('/api/behaviour', $incident + ['category' => 'Random'])->assertStatus(422);
        $this->postJson('/api/behaviour', $incident + ['category' => 'Kindness'])->assertCreated();
        $this->postJson('/api/behaviour-categories', ['name' => 'Nope', 'polarity' => 'positive'])->assertForbidden();
    }

    public function test_activity_rosters_flow_from_teacher_to_parent(): void {
        $this->actingAs($this->teacher);
        $id = $this->postJson('/api/activities', ['title' => 'Athletics', 'activity_date' => '2026-10-16'])->assertCreated()->json('activity.id');
        $this->postJson("/api/activities/{$id}/roster", ['records' => [['student_id' => $this->blueChild->id, 'status' => 'present']]])->assertForbidden();
        $this->postJson("/api/activities/{$id}/roster", ['records' => [['student_id' => $this->goldChild->id, 'status' => 'present']]])->assertOk();

        $this->actingAs($this->parent);
        $this->getJson("/api/activities/student/{$this->goldChild->id}")->assertOk()->assertJsonPath('activities.0.status', 'present');
        $this->getJson('/api/activities')->assertForbidden();
    }

    public function test_teacher_notices_reach_only_their_class_parents(): void {
        $otherParent = User::create(['name' => 'Other', 'phone_number' => '4', 'role' => 'guardian', 'account_uid' => 'o']);
        $otherParent->students()->attach($this->blueChild->id);

        $this->actingAs($this->teacher)->postJson('/api/announcements', ['title' => 'Trip', 'content' => 'Bring hats', 'audience_role' => 'guardian'])->assertCreated();
        $this->actingAs($this->teacher)->postJson('/api/announcements', ['title' => 'X', 'content' => 'Y', 'audience_role' => 'guardian', 'class_name' => 'Blue'])->assertForbidden();

        $this->actingAs($this->parent)->getJson('/api/announcements')->assertJsonCount(1, 'announcements');
        $this->actingAs($otherParent)->getJson('/api/announcements')->assertJsonCount(0, 'announcements');
    }

    public function test_platform_owner_cannot_edit_academic_records(): void {
        $owner = User::create(['name' => 'Owner', 'phone_number' => '5', 'role' => 'website_admin', 'account_uid' => 'w']);
        $this->actingAs($owner);
        $this->getJson('/api/platform/directory')->assertOk();
        $this->postJson('/api/attendance/mark', ['date' => '2026-10-16', 'records' => [['student_id' => $this->goldChild->id, 'status' => 'present']]])->assertForbidden();
        $this->postJson('/api/journal', ['student_id' => $this->goldChild->id, 'type' => 'text'])->assertForbidden();
        $this->postJson('/api/announcements', ['title' => 'x', 'content' => 'y', 'audience_role' => 'all', 'school_id' => $this->school->id])->assertForbidden();
    }

    public function test_student_accounts_are_not_in_mvp(): void {
        User::create(['name' => 'Pupil', 'phone_number' => '6', 'role' => 'student', 'account_uid' => 's', 'password' => 'secret123']);
        $this->postJson('/api/auth/login', ['username' => 'Pupil', 'password' => 'secret123'])->assertForbidden();
    }
}

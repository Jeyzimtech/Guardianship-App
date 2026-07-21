<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\Student;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UserManagementTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $teacher;
    protected $guardian;
    protected $school;
    protected $student;

    protected function setUp(): void
    {
        parent::setUp();

        $this->school = School::create([
            'name' => 'Hillside Primary School',
            'type' => 'primary',
        ]);

        $this->admin = User::create([
            'name' => 'Admin Tinotenda',
            'email' => 'admin@hillside.ac.zw',
            'phone_number' => '+263771111111',
            'role' => 'admin',
            'firebase_uid' => 'uid_admin_123',
        ]);

        $this->teacher = User::create([
            'name' => 'Teacher Grace',
            'email' => 'grace@hillside.ac.zw',
            'phone_number' => '+263772222222',
            'role' => 'teacher',
            'firebase_uid' => 'uid_teacher_123',
        ]);

        $this->guardian = User::create([
            'name' => 'Guardian John',
            'email' => 'john@chewe.tech',
            'phone_number' => '+263773333333',
            'role' => 'guardian',
            'firebase_uid' => 'uid_guardian_123',
        ]);

        $this->student = Student::create([
            'school_id' => $this->school->id,
            'name' => 'Alice Chewe',
            'grade' => 'Grade 1',
            'class_name' => 'Green',
        ]);
    }

    /**
     * Test admin can list all users.
     */
    public function test_admin_can_list_users()
    {
        $this->actingAs($this->admin);

        $response = $this->getJson('/api/users');

        $response->assertStatus(200)
            ->assertJsonStructure(['status', 'users'])
            ->assertJsonCount(3, 'users');
    }

    /**
     * Test filtering users by role.
     */
    public function test_admin_can_filter_users_by_role()
    {
        $this->actingAs($this->admin);

        $response = $this->getJson('/api/users?role=teacher');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'users')
            ->assertJsonPath('users.0.name', 'Teacher Grace');
    }

    /**
     * Test admin can create a new Teacher account.
     */
    public function test_admin_can_create_teacher_account()
    {
        $this->actingAs($this->admin);

        $response = $this->postJson('/api/users', [
            'name' => 'New Teacher Bob',
            'email' => 'bob@hillside.ac.zw',
            'phone_number' => '+263775555555',
            'role' => 'teacher',
            'school_id' => $this->school->id,
            'subject_specialties' => ['Science', 'English'],
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('user.name', 'New Teacher Bob')
            ->assertJsonPath('user.role', 'teacher');

        $this->assertDatabaseHas('users', ['phone_number' => '+263775555555', 'role' => 'teacher']);
        $this->assertDatabaseHas('teachers', ['school_id' => $this->school->id]);
    }

    /**
     * Test admin can create a new Guardian account linked to a student.
     */
    public function test_admin_can_create_guardian_account_with_student_link()
    {
        $this->actingAs($this->admin);

        $response = $this->postJson('/api/users', [
            'name' => 'New Guardian Mary',
            'phone_number' => '+263776666666',
            'role' => 'guardian',
            'student_ids' => [$this->student->id],
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('user.name', 'New Guardian Mary')
            ->assertJsonPath('user.role', 'guardian');

        $this->assertDatabaseHas('users', ['phone_number' => '+263776666666', 'role' => 'guardian']);
        $this->assertDatabaseHas('guardian_student', ['student_id' => $this->student->id]);
    }

    /**
     * Test admin can update user profile.
     */
    public function test_admin_can_update_user()
    {
        $this->actingAs($this->admin);

        $response = $this->putJson('/api/users/' . $this->teacher->id, [
            'name' => 'Teacher Grace Modified',
            'phone_number' => '+263772222222',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('user.name', 'Teacher Grace Modified');

        $this->assertDatabaseHas('users', ['id' => $this->teacher->id, 'name' => 'Teacher Grace Modified']);
    }

    /**
     * Test admin can delete user.
     */
    public function test_admin_can_delete_user()
    {
        $this->actingAs($this->admin);

        $response = $this->deleteJson('/api/users/' . $this->teacher->id);

        $response->assertStatus(200);
        $this->assertDatabaseMissing('users', ['id' => $this->teacher->id]);
    }

    /**
     * Test non-admin cannot access user management endpoints.
     */
    public function test_non_admin_cannot_access_user_management()
    {
        $this->actingAs($this->guardian);

        $responseList = $this->getJson('/api/users');
        $responseList->assertStatus(403);

        $responseCreate = $this->postJson('/api/users', [
            'name' => 'Unauthorized Admin',
            'phone_number' => '+263779999999',
            'role' => 'admin',
        ]);
        $responseCreate->assertStatus(403);
    }
}

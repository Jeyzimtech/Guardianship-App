<?php

namespace Tests\Feature;

use App\Models\School;
use App\Models\SchoolClass;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TeacherManagementTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $guardian;
    protected $teacherUser;
    protected $school;
    protected $schoolClass;

    protected function setUp(): void
    {
        parent::setUp();

        $this->school = School::create([
            'name' => 'Hillside Primary School',
            'type' => 'primary',
        ]);

        $this->schoolClass = SchoolClass::create([
            'school_id' => $this->school->id,
            'grade' => 'Grade 4',
            'class_name' => 'Gold',
            'capacity' => 30,
        ]);

        $this->admin = User::create([
            'name' => 'Admin Tinotenda',
            'email' => 'admin@hillside.ac.zw',
            'phone_number' => '+263771111111',
            'role' => 'admin',
            'firebase_uid' => 'uid_admin_123',
        ]);

        $this->teacherUser = User::create([
            'name' => 'Teacher Grace',
            'email' => 'grace@hillside.ac.zw',
            'phone_number' => '+263772222222',
            'role' => 'teacher',
            'firebase_uid' => 'uid_teacher_123',
        ]);

        $this->guardian = User::create([
            'name' => 'Guardian John',
            'phone_number' => '+263773333333',
            'role' => 'guardian',
            'firebase_uid' => 'uid_guardian_123',
        ]);
    }

    /**
     * Test admin can create a teacher profile with subject specialties and class assignments.
     */
    public function test_admin_can_create_teacher_profile_and_class_assignments()
    {
        $this->actingAs($this->admin);

        $response = $this->postJson('/api/teachers', [
            'user_id' => $this->teacherUser->id,
            'school_id' => $this->school->id,
            'subject_specialties' => ['Mathematics', 'Science'],
            'class_assignments' => [
                [
                    'school_class_id' => $this->schoolClass->id,
                    'subject_name' => 'Mathematics',
                ]
            ],
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('teacher.school_id', $this->school->id)
            ->assertJsonPath('teacher.subject_specialties.0', 'Mathematics');

        $this->assertDatabaseHas('teachers', ['user_id' => $this->teacherUser->id, 'school_id' => $this->school->id]);
        $this->assertDatabaseHas('teacher_school_class', [
            'school_class_id' => $this->schoolClass->id,
            'subject_name' => 'Mathematics',
        ]);
    }

    /**
     * Test admin can list teachers.
     */
    public function test_admin_can_list_teachers()
    {
        $this->actingAs($this->admin);

        Teacher::create([
            'user_id' => $this->teacherUser->id,
            'school_id' => $this->school->id,
            'subject_specialties' => ['Shona', 'English'],
        ]);

        $response = $this->getJson('/api/teachers');

        $response->assertStatus(200)
            ->assertJsonCount(1, 'teachers')
            ->assertJsonPath('teachers.0.user.name', 'Teacher Grace');
    }

    /**
     * Test admin can update teacher specialties and class assignments.
     */
    public function test_admin_can_update_teacher_profile()
    {
        $this->actingAs($this->admin);

        $teacher = Teacher::create([
            'user_id' => $this->teacherUser->id,
            'school_id' => $this->school->id,
            'subject_specialties' => ['Maths'],
        ]);

        $response = $this->putJson('/api/teachers/' . $teacher->id, [
            'subject_specialties' => ['Physics', 'Chemistry'],
            'class_assignments' => [
                [
                    'school_class_id' => $this->schoolClass->id,
                    'subject_name' => 'Physics',
                ]
            ]
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('teacher.subject_specialties.0', 'Physics');

        $this->assertDatabaseHas('teacher_school_class', [
            'teacher_id' => $teacher->id,
            'subject_name' => 'Physics',
        ]);
    }

    /**
     * Test non-admin receives 403 when modifying teacher profiles.
     */
    public function test_non_admin_cannot_modify_teachers()
    {
        $this->actingAs($this->guardian);

        $response = $this->postJson('/api/teachers', [
            'user_id' => $this->teacherUser->id,
            'school_id' => $this->school->id,
        ]);

        $response->assertStatus(403);
    }
}

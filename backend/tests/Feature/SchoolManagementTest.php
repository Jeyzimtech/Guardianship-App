<?php

namespace Tests\Feature;

use App\Models\AcademicYear;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class SchoolManagementTest extends TestCase
{
    use RefreshDatabase;

    protected $admin;
    protected $guardian;
    protected $school;

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

        $this->guardian = User::create([
            'name' => 'Guardian John',
            'phone_number' => '+263773333333',
            'role' => 'guardian',
            'firebase_uid' => 'uid_guardian_123',
        ]);
    }

    /**
     * Test admin can create and list schools.
     */
    public function test_admin_can_create_and_list_schools()
    {
        $this->actingAs($this->admin);

        $createResponse = $this->postJson('/api/schools', [
            'name' => 'Hillside High School',
            'type' => 'secondary',
        ]);

        $createResponse->assertStatus(201)
            ->assertJsonPath('school.name', 'Hillside High School');

        $listResponse = $this->getJson('/api/schools');
        $listResponse->assertStatus(200)
            ->assertJsonCount(2, 'schools');
    }

    /**
     * Test admin can create academic years and set active term.
     */
    public function test_admin_can_manage_academic_years()
    {
        $this->actingAs($this->admin);

        $ay1 = AcademicYear::create([
            'name' => 'Term 1 2025',
            'code' => 'AY-2025-T1',
            'is_current' => true,
        ]);

        $ay2Response = $this->postJson('/api/academic-years', [
            'name' => 'Term 1 2026',
            'code' => 'AY-2026-T1',
            'is_current' => true,
        ]);

        $ay2Response->assertStatus(201)
            ->assertJsonPath('academic_year.is_current', true);

        // Verify previous active year was toggled to false
        $this->assertDatabaseHas('academic_years', [
            'id' => $ay1->id,
            'is_current' => false,
        ]);
    }

    /**
     * Test admin can create grade class streams.
     */
    public function test_admin_can_manage_school_classes()
    {
        $this->actingAs($this->admin);

        $ay = AcademicYear::create([
            'name' => 'Term 1 2026',
            'code' => 'AY-2026-T1',
            'is_current' => true,
        ]);

        $response = $this->postJson('/api/school-classes', [
            'school_id' => $this->school->id,
            'academic_year_id' => $ay->id,
            'grade' => 'Grade 4',
            'class_name' => 'Gold',
            'capacity' => 35,
        ]);

        $response->assertStatus(201)
            ->assertJsonPath('class.grade', 'Grade 4')
            ->assertJsonPath('class.class_name', 'Gold');

        $this->assertDatabaseHas('school_classes', [
            'school_id' => $this->school->id,
            'grade' => 'Grade 4',
            'class_name' => 'Gold',
        ]);
    }

    /**
     * Test non-admin receives 403 when attempting management mutations.
     */
    public function test_non_admin_cannot_create_schools_or_classes()
    {
        $this->actingAs($this->guardian);

        $schoolResponse = $this->postJson('/api/schools', [
            'name' => 'Unauthorized School',
            'type' => 'primary',
        ]);
        $schoolResponse->assertStatus(403);

        $classResponse = $this->postJson('/api/school-classes', [
            'school_id' => $this->school->id,
            'grade' => 'Form 1',
            'class_name' => 'Blue',
        ]);
        $classResponse->assertStatus(403);
    }
}

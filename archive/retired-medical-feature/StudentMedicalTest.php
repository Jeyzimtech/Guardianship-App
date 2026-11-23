<?php

namespace Tests\Feature;

use App\Models\{School, SchoolClass, Student, Teacher, User};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class StudentMedicalTest extends TestCase
{
    use RefreshDatabase;

    private function records(): array
    {
        $school = School::create(['name'=>'School','type'=>'primary']);
        $class = SchoolClass::create(['school_id'=>$school->id,'grade'=>'4','class_name'=>'Blue']);
        $child = Student::create(['school_id'=>$school->id,'name'=>'Child','grade'=>'4','class_name'=>'Blue']);
        $parent = User::create(['name'=>'Parent','role'=>'guardian','phone_number'=>'0771234567','account_uid'=>'p']);
        $parent->students()->attach($child->id);
        $teacher = User::create(['name'=>'Teacher','role'=>'teacher','phone_number'=>'0711234567','account_uid'=>'t']);
        Teacher::create(['school_id'=>$school->id,'user_id'=>$teacher->id])->assignedClasses()->attach($class->id);
        return [$parent, $teacher, $child, $school];
    }

    private function details(): array
    {
        return ['allergies'=>'Peanut allergy','conditions'=>null,'medications'=>null,'care_instructions'=>'Contact parent if there is a concern.'];
    }

    public function test_parent_saves_reads_and_clears_medical_details_with_encrypted_storage(): void
    {
        [$parent, , $child] = $this->records();
        $url = '/api/students/'.$child->id.'/medical';
        $this->actingAs($parent)->getJson($url)->assertOk()->assertJsonPath('data',null);
        $this->putJson($url, $this->details())->assertOk()->assertJsonPath('data.allergies','Peanut allergy');
        $this->assertNotSame('Peanut allergy', DB::table('student_medical_profiles')->value('allergies'));
        $this->getJson($url)->assertOk()->assertJsonPath('data.allergies','Peanut allergy')->assertHeader('Cache-Control','no-store, private');
        $this->putJson($url, array_fill_keys(array_keys($this->details()), null))->assertOk()->assertJsonPath('data.allergies',null);
        $this->assertDatabaseCount('student_medical_profiles',1);
    }

    public function test_unlinked_parents_and_other_class_teachers_cannot_read_or_edit(): void
    {
        [$parent, $teacher, $child, $school] = $this->records();
        $other = Student::create(['school_id'=>$school->id,'name'=>'Other','grade'=>'5','class_name'=>'Red']);
        $url = '/api/students/'.$other->id.'/medical';
        $this->actingAs($parent)->getJson($url)->assertNotFound();
        $this->putJson($url, $this->details())->assertNotFound();
        $this->actingAs($teacher)->getJson($url)->assertNotFound();
        $this->putJson('/api/students/'.$child->id.'/medical', $this->details())->assertForbidden();
    }

    public function test_assigned_teacher_reads_parent_details_and_general_directory_does_not_leak_them(): void
    {
        [$parent, $teacher, $child] = $this->records();
        $url = '/api/students/'.$child->id.'/medical';
        $this->actingAs($parent)->putJson($url,$this->details())->assertOk();
        $this->actingAs($teacher)->getJson($url)->assertOk()->assertJsonPath('data.allergies','Peanut allergy');
        $this->getJson('/api/students')->assertOk()->assertDontSee('Peanut allergy');
        $this->actingAs(User::create(['name'=>'Admin','role'=>'admin','phone_number'=>'admin','account_uid'=>'admin']))->getJson($url)->assertForbidden();
    }

    public function test_medical_fields_validate_length_and_do_not_change_student_identity(): void
    {
        [$parent, , $child] = $this->records();
        $this->actingAs($parent)->putJson('/api/students/'.$child->id.'/medical', ['allergies'=>str_repeat('x',2001)] + $this->details())->assertUnprocessable();
        $this->putJson('/api/students/'.$child->id.'/medical', ['name'=>'Changed'] + $this->details())->assertOk();
        $this->assertSame('Child', $child->fresh()->name);
    }
}

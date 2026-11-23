<?php

namespace Tests\Feature;

use App\Models\{School, SchoolClass, Student, Teacher, User};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Str;
use Tests\TestCase;

class ParentImportTest extends TestCase
{
    use RefreshDatabase;

    private function setupSchool(): array
    {
        $school = School::create(['name' => 'School', 'type' => 'primary']);
        $blue = SchoolClass::create(['school_id' => $school->id, 'grade' => 'Grade 1', 'class_name' => 'Blue']);
        $red = SchoolClass::create(['school_id' => $school->id, 'grade' => 'Grade 2', 'class_name' => 'Red']);
        $teacher = User::create(['name' => 'Teacher', 'role' => 'teacher', 'phone_number' => '0711234567', 'account_uid' => (string) Str::uuid()]);
        Teacher::create(['user_id' => $teacher->id, 'school_id' => $school->id])->assignedClasses()->attach($blue->id);
        $existing = Student::create(['name' => 'Tatenda Moyo', 'school_id' => $school->id, 'grade' => 'Grade 1', 'class_name' => 'Blue']);
        $admin = User::create(['name' => 'Admin', 'role' => 'admin', 'phone_number' => '0719999999', 'account_uid' => (string) Str::uuid(), 'school_id' => $school->id]);
        return [$teacher, $existing, $blue, $red, $admin];
    }

    private function csv(string $content): UploadedFile
    {
        return UploadedFile::fake()->createWithContent('parents.csv', $content);
    }

    public function test_teacher_imports_phone_only_and_email_parents(): void
    {
        [$teacher, $existing] = $this->setupSchool();
        $file = $this->csv("\xEF\xBB\xBFStudent Name,Parent Name,Parent Phone,Parent Email,Class\n"
            ."tatenda moyo,Tariro Moyo,0771234567,,Grade 1 Blue\n"
            ."Anesu Dube,Rudo Dube,782345678,rudo@example.com,Blue\n"
            ."Wrong Class,Some Parent,0773333333,,Red\n"
            ."No Phone,Bad Email,0774444444,not-an-email,\n");
        $this->actingAs($teacher)->post('/api/parents/import', ['file' => $file], ['Accept' => 'application/json'])->assertOk()
            ->assertJsonPath('linked', 2)->assertJsonPath('created_parents', 2)->assertJsonPath('enrolled_students', 1)
            ->assertJsonPath('skipped', 2)->assertJsonPath('errors.0.row', 4);

        $tariro = User::where('name', 'Tariro Moyo')->first();
        $this->assertSame('263771234567', $tariro->phone_number);
        $this->assertNull($tariro->email);
        $this->assertTrue($existing->guardians()->whereKey($tariro->id)->exists());
        $anesu = Student::where('name', 'Anesu Dube')->first();
        $this->assertSame('Blue', $anesu->class_name);
        $this->assertSame('263782345678', $anesu->guardians()->first()->phone_number);
        $this->assertDatabaseMissing('students', ['name' => 'Wrong Class']);

        // Re-importing links the same parent instead of creating duplicates.
        $this->post('/api/parents/import', ['file' => $this->csv("student_name,parent_name,parent_phone\nTatenda Moyo,Tariro Moyo,+263771234567\n")], ['Accept' => 'application/json'])
            ->assertOk()->assertJsonPath('created_parents', 0)->assertJsonPath('linked', 1);
        $this->assertSame(1, User::where('name', 'Tariro Moyo')->count());
    }

    public function test_import_requires_template_columns_and_teacher_role(): void
    {
        [$teacher, , , , $admin] = $this->setupSchool();
        $this->actingAs($teacher)->post('/api/parents/import', ['file' => $this->csv("name,phone\nA,0771234567\n")], ['Accept' => 'application/json'])->assertStatus(422);
        $this->actingAs($admin)->post('/api/parents/import', ['file' => $this->csv("student_name,parent_name\nA,B\n")], ['Accept' => 'application/json'])->assertForbidden();
        $this->actingAs($teacher)->get('/api/parents/import/template')->assertOk()->assertSee('student_name,parent_name,parent_phone,parent_email,class');
    }

    public function test_admin_sees_class_information_and_rename_moves_students(): void
    {
        [, $existing, $blue, $red, $admin] = $this->setupSchool();
        $this->actingAs($admin)->getJson('/api/school-classes')->assertOk()
            ->assertJsonPath('school_classes.0.student_count', 1)->assertJsonPath('school_classes.0.roster.0.name', 'Tatenda Moyo')
            ->assertJsonPath('school_classes.0.teacher_list.0.name', 'Teacher');
        $this->putJson("/api/school-classes/{$blue->id}", ['class_name' => 'Blue Stars'])->assertOk();
        $this->assertSame('Blue Stars', $existing->fresh()->class_name);
        $this->deleteJson("/api/school-classes/{$blue->id}")->assertStatus(422);
        $this->deleteJson("/api/school-classes/{$red->id}")->assertOk();
    }
}

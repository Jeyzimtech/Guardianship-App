<?php

namespace Tests\Feature;

use App\Models\{School, SchoolClass, Student, Teacher, User};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class StudentPhotoTest extends TestCase
{
    use RefreshDatabase;

    private function records(): array
    {
        Storage::fake('local');
        $school = School::create(['name'=>'School','type'=>'primary']);
        $class = SchoolClass::create(['school_id'=>$school->id,'grade'=>'4','class_name'=>'Blue']);
        $student = Student::create(['school_id'=>$school->id,'name'=>'Child','grade'=>'4','class_name'=>'Blue']);
        $parent = User::create(['name'=>'Parent','role'=>'guardian','phone_number'=>'0771234567','account_uid'=>'p']);
        $parent->students()->attach($student->id);
        $teacher = User::create(['name'=>'Teacher','role'=>'teacher','phone_number'=>'0711234567','account_uid'=>'t']);
        Teacher::create(['school_id'=>$school->id,'user_id'=>$teacher->id])->assignedClasses()->attach($class->id);
        return [$parent,$teacher,$student,$school];
    }

    private function png(): string
    {
        return base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZx8AAAAASUVORK5CYII=');
    }

    public function test_parent_upload_is_shared_with_teacher_and_private_photo_is_replaced_and_removed(): void
    {
        [$parent,$teacher,$student] = $this->records();
        $url = '/api/students/'.$student->id.'/photo';
        $first = $this->actingAs($parent)->postJson($url,['photo'=>UploadedFile::fake()->createWithContent('portrait.png',$this->png())])->assertOk()->json('photo_url');
        $path = $student->fresh()->photo_path;
        Storage::disk('local')->assertExists($path);
        $this->getJson('/api/students')->assertJsonPath('students.0.photo_url',$first)->assertJsonMissingPath('students.0.photo_path');
        $this->actingAs($teacher)->getJson('/api/attendance/roster')->assertOk()->assertJsonPath('roster.0.photo_url',$first);
        $this->getJson('/api/students')->assertOk()->assertJsonPath('students.0.photo_url', $first);
        $activity = $this->postJson('/api/activities', ['title' => 'Sports', 'activity_date' => now()->toDateString()])->assertCreated()->json('activity.id');
        $this->getJson('/api/activities/'.$activity.'/roster')->assertOk()->assertJsonPath('roster.0.photo_url', $first)->assertJsonMissingPath('roster.0.photo_path');
        $this->get($first,['Accept'=>'image/png'])->assertOk()->assertHeader('Content-Type','image/png');
        $second = $this->postJson($url,['photo'=>UploadedFile::fake()->createWithContent('new.png',$this->png())])->assertOk()->json('photo_url');
        $this->assertNotSame($first,$second);
        Storage::disk('local')->assertMissing($path);
        $this->actingAs($parent)->getJson('/api/students/'.$student->id.'/photo-details')->assertJsonPath('photo_url',$second);
        $newPath = $student->fresh()->photo_path;
        $this->deleteJson($url)->assertOk()->assertJsonPath('photo_url',null);
        Storage::disk('local')->assertMissing($newPath);
        $this->get($url)->assertNotFound();
    }

    public function test_other_parents_and_teachers_cannot_access_or_change_an_unassigned_students_photo(): void
    {
        [$parent,$teacher,,$school] = $this->records();
        $other = Student::create(['school_id'=>$school->id,'name'=>'Other','grade'=>'5','class_name'=>'Red']);
        $url = '/api/students/'.$other->id.'/photo';
        foreach ([$parent,$teacher] as $user) {
            $this->actingAs($user)->getJson($url)->assertNotFound();
            $this->postJson($url,['photo'=>UploadedFile::fake()->createWithContent('x.png',$this->png())])->assertNotFound();
            $this->deleteJson($url)->assertNotFound();
        }
    }

    public function test_photo_upload_rejects_oversized_non_image_and_gif_files(): void
    {
        [$parent,,$student] = $this->records();
        $url = '/api/students/'.$student->id.'/photo';
        $this->actingAs($parent)->postJson($url,['photo'=>UploadedFile::fake()->createWithContent('large.png',$this->png().str_repeat('a',4*1024*1024))])->assertUnprocessable();
        $this->postJson($url,['photo'=>UploadedFile::fake()->createWithContent('spoof.png','Not an image')])->assertUnprocessable();
        $gif = base64_decode('R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7');
        $this->postJson($url,['photo'=>UploadedFile::fake()->createWithContent('x.gif',$gif)])->assertUnprocessable();
        $this->assertNull($student->fresh()->photo_path);
        $this->assertSame([],Storage::disk('local')->allFiles('student-photos'));
    }

    public function test_missing_photo_is_reported_and_student_fields_cannot_be_overwritten(): void
    {
        [$parent,,$student] = $this->records();
        $this->actingAs($parent)->getJson('/api/students/'.$student->id.'/photo-details')->assertOk()->assertJsonPath('photo_url',null);
        $this->postJson('/api/students/'.$student->id.'/photo',['photo'=>UploadedFile::fake()->createWithContent('x.png',$this->png()),'name'=>'Changed','student_id'=>999])->assertOk();
        $this->assertSame('Child',$student->fresh()->name);
    }
}

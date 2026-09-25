<?php
namespace Tests\Feature;
use App\Models\{School, SchoolClass, Teacher, User, Student};
use App\Http\Controllers\AssignmentController;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AssignmentAuthoringTest extends TestCase {
    use RefreshDatabase;
    public function test_teacher_can_create_and_reload_only_assigned_class_work(): void {
        $school = School::create(['name'=>'Test school', 'type'=>'primary']);
        $class = SchoolClass::create(['school_id'=>$school->id,'grade'=>'4','class_name'=>'Gold']);
        $other = SchoolClass::create(['school_id'=>$school->id,'grade'=>'4','class_name'=>'Blue']);
        $user = User::create(['name'=>'Teacher','phone_number'=>'12345','role'=>'teacher','firebase_uid'=>'teacher-test']);
        $teacher = Teacher::create(['school_id'=>$school->id,'user_id'=>$user->id]);
        $teacher->assignedClasses()->attach($class->id);
        $this->actingAs($user);
        $payload = ['title'=>'Fractions','description'=>'Complete exercises','subject_name'=>'Math','due_date'=>'2027-01-01','school_class_id'=>$class->id];
        $this->postJson('/api/assignments',$payload)->assertCreated()->assertJsonPath('data.created_by',$user->id);
        $this->getJson('/api/teacher/assignments')->assertOk()->assertJsonCount(1,'data')->assertJsonCount(1,'classes');
        $payload['school_class_id'] = $other->id;
        $this->postJson('/api/assignments',$payload)->assertForbidden();
        $student = Student::create(['name'=>'Child','school_id'=>$school->id,'grade'=>'4','class_name'=>'Gold']);
        $result = app(AssignmentController::class)->getStudentAssignments($student->id)->getData(true);
        $this->assertCount(1,$result['data']['all']);
        $student->update(['class_name'=>'Blue']);
        $result = app(AssignmentController::class)->getStudentAssignments($student->id)->getData(true);
        $this->assertCount(0,$result['data']['all']);
    }
    public function test_parent_cannot_create_assignment(): void {
        $user = User::create(['name'=>'Parent','phone_number'=>'67890','role'=>'guardian','firebase_uid'=>'parent-test']);
        $this->actingAs($user)->postJson('/api/assignments',['title'=>'Task','due_date'=>'2027-01-01'])->assertForbidden();
    }
}

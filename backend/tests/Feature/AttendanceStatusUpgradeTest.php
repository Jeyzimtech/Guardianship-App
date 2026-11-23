<?php

namespace Tests\Feature;

use App\Models\{AttendanceRecord, School, SchoolClass, Student, Teacher, User};
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\{DB, Schema};
use Tests\TestCase;

class AttendanceStatusUpgradeTest extends TestCase
{
    use RefreshDatabase;

    public function test_legacy_register_upgrades_without_losing_records_and_saves_late(): void
    {
        $school = School::create(['name' => 'School', 'type' => 'primary']);
        $class = SchoolClass::create(['school_id' => $school->id, 'grade' => '1', 'class_name' => 'Blue']);
        $teacher = User::factory()->create(['role' => 'teacher']);
        Teacher::create(['user_id' => $teacher->id, 'school_id' => $school->id])->assignedClasses()->attach($class->id);
        $student = Student::create(['name' => 'Learner', 'school_id' => $school->id, 'grade' => '1', 'class_name' => 'Blue']);
        $record = AttendanceRecord::create(['student_id' => $student->id, 'date' => '2026-10-21', 'status' => 'present', 'marked_by' => $teacher->id]);
        Schema::table('attendance_records', fn (Blueprint $table) => $table->enum('status', ['present', 'absent'])->change());

        $migration = require database_path('migrations/2026_10_21_000003_align_attendance_statuses.php');
        $migration->up();
        $this->assertDatabaseHas('attendance_records', ['id' => $record->id, 'status' => 'present', 'student_id' => $student->id]);
        $this->actingAs($teacher)->postJson('/api/attendance/mark', [
            'date' => '2026-10-21', 'records' => [['student_id' => $student->id, 'status' => 'late']],
        ])->assertOk();
        $this->getJson('/api/attendance/roster?date=2026-10-21')->assertOk()->assertJsonPath('roster.0.status', 'late')->assertJsonPath('roster.0.marked', true);
        $this->assertDatabaseCount('attendance_records', 1);
        $this->assertDatabaseHas('attendance_records', ['id' => $record->id, 'status' => 'late', 'marked_by' => $teacher->id]);
        $this->getJson('/api/dashboard/'.$student->id)->assertOk()
            ->assertJsonPath('attendance_snapshot.percentage', 100)
            ->assertJsonPath('attendance_snapshot.present_days', 1);
        $this->assertCount(0, DB::select('pragma foreign_key_check'));
    }
}

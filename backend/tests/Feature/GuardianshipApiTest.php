<?php

namespace Tests\Feature;

use App\Models\Announcement;
use App\Models\AttendanceRecord;
use App\Models\FeeAccount;
use App\Models\ReportDocument;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GuardianshipApiTest extends TestCase
{
    use RefreshDatabase;

    protected $school;
    protected $guardian;
    protected $teacher;
    protected $admin;
    protected $student1;
    protected $student2;

    protected function setUp(): void
    {
        parent::setUp();

        // Create initial seed data for each test
        $this->school = School::create([
            'name' => 'Hillside Primary School',
            'type' => 'primary',
        ]);

        $this->guardian = User::create([
            'name' => 'Guardian John',
            'phone_number' => '+263773333333',
            'role' => 'guardian',
            'firebase_uid' => 'uid_guardian_123',
        ]);

        $this->teacher = User::create([
            'name' => 'Teacher Grace',
            'phone_number' => '+263772222222',
            'role' => 'teacher',
            'firebase_uid' => 'uid_teacher_123',
        ]);

        $this->admin = User::create([
            'name' => 'Admin Tinotenda',
            'phone_number' => '+263771111111',
            'role' => 'admin',
            'firebase_uid' => 'uid_admin_123',
        ]);

        Teacher::create([
            'user_id' => $this->teacher->id,
            'school_id' => $this->school->id,
            'subject_specialties' => ['Maths'],
        ]);

        $this->student1 = Student::create([
            'school_id' => $this->school->id,
            'name' => 'Alice Chewe',
            'grade' => 'Grade 1',
            'class_name' => 'Green',
        ]);

        $this->student2 = Student::create([
            'school_id' => $this->school->id,
            'name' => 'Bob Chewe',
            'grade' => 'Grade 4',
            'class_name' => 'Blue',
        ]);

        // Link guardian to both students
        $this->guardian->students()->attach([$this->student1->id, $this->student2->id]);

        // Create Fee Account for student 1 with outstanding balance
        FeeAccount::create([
            'student_id' => $this->student1->id,
            'balance_usd' => 100.00,
            'balance_zig' => 0.00,
        ]);

        // Create Fee Account for student 2 with zero balance
        FeeAccount::create([
            'student_id' => $this->student2->id,
            'balance_usd' => 0.00,
            'balance_zig' => 0.00,
        ]);

        // Create Gated report documents for both
        ReportDocument::create([
            'student_id' => $this->student1->id,
            'title' => 'Alice Term 1 Report',
            'file_path' => 'reports/alice.pdf',
            'type' => 'report',
            'fee_gated' => true,
            'uploaded_by' => $this->teacher->id,
        ]);

        ReportDocument::create([
            'student_id' => $this->student2->id,
            'title' => 'Bob Term 1 Report',
            'file_path' => 'reports/bob.pdf',
            'type' => 'report',
            'fee_gated' => true,
            'uploaded_by' => $this->teacher->id,
        ]);
    }

    /**
     * Test Firebase auth login flow.
     */
    public function test_firebase_login_creates_token_for_existing_user()
    {
        $response = $this->postJson('/api/auth/firebase-login', [
            'id_token' => 'mock-firebase-token-+263773333333-uid_guardian_123',
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure(['status', 'token', 'user'])
            ->assertJsonPath('user.phone_number', '+263773333333')
            ->assertJsonPath('user.role', 'guardian');
    }

    /**
     * Test Firebase auth login flow registers a new user if not exists.
     */
    public function test_firebase_login_registers_new_user()
    {
        $response = $this->postJson('/api/auth/firebase-login', [
            'id_token' => 'mock-firebase-token-+263774444444-uid_new_123',
            'name' => 'New Parent',
            'role' => 'guardian',
        ]);

        $response->assertStatus(200)
            ->assertJsonPath('user.phone_number', '+263774444444')
            ->assertJsonPath('user.role', 'guardian');

        $this->assertDatabaseHas('users', ['phone_number' => '+263774444444']);
    }

    /**
     * Test scoped student access.
     */
    public function test_guardian_can_retrieve_only_linked_students()
    {
        $this->actingAs($this->guardian);

        $response = $this->getJson('/api/students');

        $response->assertStatus(200)
            ->assertJsonCount(2, 'students')
            ->assertJsonPath('students.0.name', 'Alice Chewe')
            ->assertJsonPath('students.1.name', 'Bob Chewe');
    }

    /**
     * Reports remain accessible regardless of legacy account balances.
     */
    public function test_reports_allow_downloads_with_outstanding_balances()
    {
        $this->actingAs($this->guardian);

        // Legacy outstanding balances do not hide reports.
        $responseList = $this->getJson('/api/reports/' . $this->student1->id);
        $responseList->assertStatus(200)
            ->assertJsonPath('reports.0.file_path', 'reports/alice.pdf')
            ->assertJsonPath('reports.0.is_locked', false);

        // The linked guardian can download the report.
        $aliceReport = ReportDocument::where('student_id', $this->student1->id)->first();
        $responseDownload = $this->getJson('/api/reports/download/' . $aliceReport->id);
        $responseDownload->assertStatus(200)
            ->assertJsonPath('status', 'success');

        // 3. Get reports list for Bob (no fees) - verify file path is readable
        $responseListBob = $this->getJson('/api/reports/' . $this->student2->id);
        $responseListBob->assertStatus(200)
            ->assertJsonPath('reports.0.file_path', 'reports/bob.pdf')
            ->assertJsonPath('reports.0.is_locked', false);

        // 4. Try to download Bob's report - expect 200 Success
        $bobReport = ReportDocument::where('student_id', $this->student2->id)->first();
        $responseDownloadBob = $this->getJson('/api/reports/download/' . $bobReport->id);
        $responseDownloadBob->assertStatus(200)
            ->assertJsonPath('status', 'success');
    }

    public function test_unlinked_guardian_cannot_access_reports()
    {
        $this->guardian->students()->detach($this->student1->id);
        $this->actingAs($this->guardian);
        $report = ReportDocument::where('student_id', $this->student1->id)->first();
        $this->getJson('/api/reports/' . $this->student1->id)->assertForbidden();
        $this->getJson('/api/reports/download/' . $report->id)->assertForbidden();
    }

    /**
     * Test role-based access control for attendance marking.
     */
    public function test_guardian_cannot_mark_attendance_but_teacher_can()
    {
        // 1. Test Guardian marking attendance - fails with 403
        $this->actingAs($this->guardian);
        $responseGuardian = $this->postJson('/api/attendance/mark', [
            'date' => '2026-07-14',
            'records' => [
                ['student_id' => $this->student1->id, 'status' => 'present']
            ]
        ]);
        $responseGuardian->assertStatus(403);

        // 2. Test Teacher marking attendance - succeeds with 200
        $this->actingAs($this->teacher);
        $responseTeacher = $this->postJson('/api/attendance/mark', [
            'date' => '2026-07-14',
            'records' => [
                ['student_id' => $this->student1->id, 'status' => 'present']
            ]
        ]);
        $responseTeacher->assertStatus(200);

        $this->assertDatabaseHas('attendance_records', [
            'student_id' => $this->student1->id,
            'date' => '2026-07-14',
            'status' => 'present'
        ]);
    }
}

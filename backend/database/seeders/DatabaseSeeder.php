<?php

namespace Database\Seeders;

use App\Models\Announcement;
use App\Models\AttendanceRecord;
use App\Models\FeeAccount;
use App\Models\FeeTransaction;
use App\Models\ReportDocument;
use App\Models\School;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Create Schools
        $prepSchool = School::create([
            'name' => 'Hillside Preparatory School',
            'type' => 'prep',
        ]);

        $primarySchool = School::create([
            'name' => 'Hillside Primary School',
            'type' => 'primary',
        ]);

        $secondarySchool = School::create([
            'name' => 'Hillside Secondary School',
            'type' => 'secondary',
        ]);

        // 2. Create Users (Admin, Teacher, Guardian)
        $admin = User::create([
            'name' => 'Admin Tinotenda',
            'email' => 'admin@hillside.ac.zw',
            'phone_number' => '+263771111111',
            'firebase_uid' => 'mock_uid_admin_123',
            'role' => 'admin',
            'password' => Hash::make('password'),
        ]);

        $teacher = User::create([
            'name' => 'Teacher Grace',
            'email' => 'grace@hillside.ac.zw',
            'phone_number' => '+263772222222',
            'firebase_uid' => 'mock_uid_teacher_123',
            'role' => 'teacher',
            'password' => Hash::make('password'),
        ]);

        $guardian = User::create([
            'name' => 'Guardian John Chewe',
            'email' => 'john.chewe@gmail.com',
            'phone_number' => '+263773333333',
            'firebase_uid' => 'mock_uid_guardian_123',
            'role' => 'guardian',
            'password' => Hash::make('password'),
        ]);

        // 3. Create Teacher Profile
        Teacher::create([
            'user_id' => $teacher->id,
            'school_id' => $primarySchool->id,
            'subject_specialties' => ['Mathematics', 'English', 'Shona'],
        ]);

        // 4. Create Students
        $student1 = Student::create([
            'school_id' => $prepSchool->id,
            'name' => 'Alice Chewe',
            'grade' => 'ECD B',
            'class_name' => 'Butterflies',
            'dob' => '2021-05-14',
        ]);

        $student2 = Student::create([
            'school_id' => $primarySchool->id,
            'name' => 'Bob Chewe',
            'grade' => 'Grade 4',
            'class_name' => 'Gold',
            'dob' => '2017-08-22',
        ]);

        // 5. Link Guardian to Students
        $guardian->students()->attach([$student1->id, $student2->id]);

        // 6. Create Fee Accounts
        $feeAccount1 = FeeAccount::create([
            'student_id' => $student1->id,
            'balance_usd' => 150.00,
            'balance_zig' => 1200.00,
        ]);

        $feeAccount2 = FeeAccount::create([
            'student_id' => $student2->id,
            'balance_usd' => 0.00, // No outstanding fees for Bob!
            'balance_zig' => 0.00,
        ]);

        // 7. Create Fee Transactions
        FeeTransaction::create([
            'fee_account_id' => $feeAccount1->id,
            'amount' => 100.00,
            'currency' => 'USD',
            'payment_method' => 'Card',
            'status' => 'completed',
            'created_at' => now()->subDays(10),
        ]);

        FeeTransaction::create([
            'fee_account_id' => $feeAccount2->id,
            'amount' => 450.00,
            'currency' => 'USD',
            'payment_method' => 'EcoCash',
            'status' => 'completed',
            'created_at' => now()->subDays(5),
        ]);

        // 8. Create Attendance Records
        $dates = [
            now()->subDays(4)->format('Y-m-d'),
            now()->subDays(3)->format('Y-m-d'),
            now()->subDays(2)->format('Y-m-d'),
            now()->subDays(1)->format('Y-m-d'),
            now()->format('Y-m-d'),
        ];

        foreach ($dates as $index => $date) {
            // Alice attendance (Prep - homeroom only)
            AttendanceRecord::create([
                'student_id' => $student1->id,
                'date' => $date,
                'status' => $index == 2 ? 'absent' : 'present', // Absent on day 2
                'marked_by' => $teacher->id,
            ]);

            // Bob attendance
            AttendanceRecord::create([
                'student_id' => $student2->id,
                'date' => $date,
                'status' => 'present',
                'marked_by' => $teacher->id,
            ]);
        }

        // 9. Create Report Documents
        // Alice has outstanding fees (Locked report)
        ReportDocument::create([
            'student_id' => $student1->id,
            'title' => 'ECD B Term 1 Progress Report',
            'file_path' => 'reports/alice_term1_2026.pdf',
            'type' => 'report',
            'fee_gated' => true,
            'uploaded_by' => $teacher->id,
        ]);

        // Alice's merit is not gated (always accessible)
        ReportDocument::create([
            'student_id' => $student1->id,
            'title' => 'Outstanding Swimming Performance Certificate',
            'file_path' => 'reports/alice_swim_merit.pdf',
            'type' => 'merit',
            'fee_gated' => false,
            'uploaded_by' => $teacher->id,
        ]);

        // Bob has no outstanding fees (Unlocked report)
        ReportDocument::create([
            'student_id' => $student2->id,
            'title' => 'Grade 4 Term 1 Report Card',
            'file_path' => 'reports/bob_term1_2026.pdf',
            'type' => 'report',
            'fee_gated' => true,
            'uploaded_by' => $teacher->id,
        ]);

        // 10. Create Announcements
        Announcement::create([
            'school_id' => $prepSchool->id,
            'title' => 'Early Childhood Sports Day Postponed',
            'content' => 'Please note that ECD Sports Day has been postponed to next Friday, July 24th, due to forecast weather conditions. Kids should wear comfortable sportswear.',
            'audience_role' => 'guardian',
        ]);

        Announcement::create([
            'school_id' => $primarySchool->id,
            'title' => 'Annual General Meeting (AGM) Notice',
            'content' => 'The Annual General Meeting for Hillside Primary School will be held in the main school hall on Saturday, July 18th at 09:00 AM. We encourage all parents and guardians to attend.',
            'audience_role' => 'all',
        ]);

        Announcement::create([
            'school_id' => $primarySchool->id,
            'title' => 'Mid-Term Consultation Bookings',
            'content' => 'Mid-term academic consultation bookings will open tomorrow morning. Slots can be booked directly through the consultations dashboard.',
            'audience_role' => 'guardian',
        ]);
    }
}

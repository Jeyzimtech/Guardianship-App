<?php

namespace Database\Seeders;

use App\Models\Announcement;
use App\Models\Assignment;
use App\Models\AttendanceRecord;
use App\Models\BehaviourIncident;
use App\Models\FeeAccount;
use App\Models\FeeTransaction;
use App\Models\JournalEntry;
use App\Models\ReportDocument;
use App\Models\School;
use App\Models\Student;
use App\Models\Subscription;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

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
            'primary_admin_name' => 'Sarah Jenkins',
            'primary_admin_email' => 'sjenkins@prep.hillside.ac.zw',
            'primary_admin_phone' => '+263771000111',
            'branding_color' => '#10B981',
        ]);

        $primarySchool = School::create([
            'name' => 'Hillside Primary School',
            'type' => 'primary',
            'primary_admin_name' => 'Admin Tinotenda',
            'primary_admin_email' => 'admin@hillside.ac.zw',
            'primary_admin_phone' => '+263771111111',
            'branding_color' => '#3B5998',
        ]);

        $secondarySchool = School::create([
            'name' => 'Hillside Secondary School',
            'type' => 'secondary',
            'primary_admin_name' => 'Dr. Michael Moyo',
            'primary_admin_email' => 'mmoyo@sec.hillside.ac.zw',
            'primary_admin_phone' => '+263771999888',
            'branding_color' => '#6366F1',
        ]);

        // 2. Create Users (Website Admin, Admin, Teacher, Guardian)
        $websiteAdmin = User::create([
            'name' => 'CT Pulse Platform Owner',
            'email' => 'platform@ctpulse.co.zw',
            'phone_number' => '+263770000000',
            'firebase_uid' => 'mock_uid_webadmin_000',
            'role' => 'website_admin',
            'password' => Hash::make('password'),
        ]);

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
            'address' => '14 Samora Machel Avenue, Harare',
            'preferred_language' => 'English',
            'emergency_contact_name' => 'Mary Chewe',
            'emergency_contact_phone' => '+263774444444',
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

        // 6. Subscriptions (Platform Owner Active Subscriptions)
        Subscription::create([
            'student_id' => $student1->id,
            'status' => 'active',
            'start_date' => now()->subMonths(3)->toDateString(),
            'set_by_user_id' => $websiteAdmin->id,
        ]);

        Subscription::create([
            'student_id' => $student2->id,
            'status' => 'active',
            'start_date' => now()->subMonths(3)->toDateString(),
            'set_by_user_id' => $websiteAdmin->id,
        ]);

        // 7. Learning Journal Entries (Ungated work samples & Prep daily logs)
        JournalEntry::create([
            'student_id' => $student1->id,
            'author_id' => $teacher->id,
            'type' => 'wellbeing',
            'caption' => 'Alice had a great morning! Participating well in circle time and art.',
            'wellbeing_data' => [
                'meals' => 'Ate all of lunch (chicken & rice)',
                'nap' => 'Rested 45 mins quietly',
                'hygiene' => 'Hands washed before and after meals',
                'mood' => 'Cheerful & Energetic'
            ],
            'fee_gated' => false,
        ]);

        JournalEntry::create([
            'student_id' => $student1->id,
            'author_id' => $teacher->id,
            'type' => 'drawing',
            'media_url' => 'https://picsum.photos/400/300?random=1',
            'caption' => 'Finger painting experiment: Family Portrait!',
            'fee_gated' => false,
        ]);

        JournalEntry::create([
            'student_id' => $student2->id,
            'author_id' => $teacher->id,
            'type' => 'photo',
            'subject_name' => 'Science',
            'media_url' => 'https://picsum.photos/400/300?random=2',
            'caption' => 'Bob built a working solar circuit during Science Lab session today.',
            'fee_gated' => false,
        ]);

        // 8. Behaviour & Merits
        BehaviourIncident::create([
            'student_id' => $student2->id,
            'polarity' => 'positive',
            'category' => 'Excellence in Mathematics',
            'note' => 'Scored highest mark in mid-term mental arithmetic speed quiz.',
            'recorded_by' => $teacher->id,
            'incident_date' => now()->subDays(2)->toDateString(),
        ]);

        BehaviourIncident::create([
            'student_id' => $student2->id,
            'polarity' => 'positive',
            'category' => 'Helpfulness & Leadership',
            'note' => 'Assisted fellow class members in organizing classroom library books.',
            'recorded_by' => $teacher->id,
            'incident_date' => now()->subDays(5)->toDateString(),
        ]);

        // 9. Assignments
        Assignment::create([
            'grade_name' => 'Grade 4',
            'subject_name' => 'Mathematics',
            'title' => 'Fractions & Decimals Exercise Set 3',
            'description' => 'Complete problems 1 to 15 on page 42 of Math workbook.',
            'due_date' => now()->addDays(2)->toDateString(),
            'created_by' => $teacher->id,
        ]);

        Assignment::create([
            'grade_name' => 'Grade 4',
            'subject_name' => 'Science',
            'title' => 'Photosynthesis Observation Journal',
            'description' => 'Document daily plant growth progress in project notebook.',
            'due_date' => now()->subDays(1)->toDateString(), // Overdue!
            'created_by' => $teacher->id,
        ]);

        // 10. Create Fee Accounts
        $feeAccount1 = FeeAccount::create([
            'student_id' => $student1->id,
            'balance_usd' => 150.00,
            'balance_zig' => 1200.00,
        ]);

        $feeAccount2 = FeeAccount::create([
            'student_id' => $student2->id,
            'balance_usd' => 0.00,
            'balance_zig' => 0.00,
        ]);

        // 11. Create Fee Transactions
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

        // 12. Attendance Records
        $dates = [
            now()->subDays(4)->format('Y-m-d'),
            now()->subDays(3)->format('Y-m-d'),
            now()->subDays(2)->format('Y-m-d'),
            now()->subDays(1)->format('Y-m-d'),
            now()->format('Y-m-d'),
        ];

        foreach ($dates as $index => $date) {
            AttendanceRecord::create([
                'student_id' => $student1->id,
                'date' => $date,
                'status' => $index == 2 ? 'absent' : 'present',
                'marked_by' => $teacher->id,
            ]);

            AttendanceRecord::create([
                'student_id' => $student2->id,
                'date' => $date,
                'status' => 'present',
                'marked_by' => $teacher->id,
            ]);
        }

        // 13. Report Documents (Gated vs Merit)
        ReportDocument::create([
            'student_id' => $student1->id,
            'title' => 'ECD B Term 1 Progress Report',
            'file_path' => 'reports/alice_term1_2026.pdf',
            'type' => 'report',
            'fee_gated' => true,
            'uploaded_by' => $teacher->id,
        ]);

        ReportDocument::create([
            'student_id' => $student1->id,
            'title' => 'Outstanding Swimming Performance Certificate',
            'file_path' => 'reports/alice_swim_merit.pdf',
            'type' => 'merit',
            'fee_gated' => false,
            'uploaded_by' => $teacher->id,
        ]);

        ReportDocument::create([
            'student_id' => $student2->id,
            'title' => 'Grade 4 Term 1 Report Card',
            'file_path' => 'reports/bob_term1_2026.pdf',
            'type' => 'report',
            'fee_gated' => true,
            'uploaded_by' => $teacher->id,
        ]);

        // 14. Announcements
        Announcement::create([
            'school_id' => $prepSchool->id,
            'title' => 'Early Childhood Sports Day Postponed',
            'content' => 'Please note that ECD Sports Day has been postponed to next Friday, July 24th.',
            'audience_role' => 'guardian',
        ]);

        Announcement::create([
            'school_id' => $primarySchool->id,
            'title' => 'Annual General Meeting (AGM) Notice',
            'content' => 'The AGM for Hillside Primary School will be held in the main hall on Saturday.',
            'audience_role' => 'all',
        ]);
    }
}

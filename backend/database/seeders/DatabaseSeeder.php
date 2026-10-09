<?php

namespace Database\Seeders;

use App\Models\AcademicYear;
use App\Models\Announcement;
use App\Models\School;
use App\Models\SchoolClass;
use App\Models\Student;
use App\Models\Teacher;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // 1. Remove all dummy students, teachers, users and associated records for a clean slate
        try {
            DB::table('guardian_student')->delete();
            DB::table('attendance_records')->delete();
            DB::table('journal_entries')->delete();
            DB::table('behaviour_incidents')->delete();
            DB::table('report_documents')->delete();
            DB::table('subscriptions')->delete();
            DB::table('fee_transactions')->delete();
            DB::table('fee_accounts')->delete();
            DB::table('students')->delete();
            DB::table('teachers')->delete();
            DB::table('personal_access_tokens')->delete();
            DB::table('users')->delete();
        } catch (\Exception $e) {
            // Tables might be empty or migrations already fresh
        }

        // 2. Create / Ensure Schools (Only Hillside Primary School)
        DB::table('school_classes')->delete();
        DB::table('schools')->delete();

        $primarySchool = School::create([
            'name' => 'Hillside Primary School',
            'type' => 'primary',
            'primary_admin_name' => 'chewetinotenda',
            'primary_admin_email' => 'chewetinotenda@hillside.ac.zw',
            'primary_admin_phone' => '+263771000001',
            'branding_color' => '#3B5998',
        ]);

        // 3. Create / Ensure Academic Years & School Classes (Primary School)
        $academicYear = AcademicYear::firstOrCreate(
            ['code' => 'AY-2026'],
            [
                'name' => '2026 Academic Year',
                'start_date' => '2026-01-12',
                'end_date' => '2026-12-04',
                'is_current' => true,
            ]
        );

        SchoolClass::firstOrCreate(
            ['school_id' => $primarySchool->id, 'class_name' => 'Grade 1A'],
            [
                'academic_year_id' => $academicYear->id,
                'grade' => 'Grade 1',
                'capacity' => 30,
            ]
        );

        SchoolClass::firstOrCreate(
            ['school_id' => $primarySchool->id, 'class_name' => 'Grade 2A'],
            [
                'academic_year_id' => $academicYear->id,
                'grade' => 'Grade 2',
                'capacity' => 30,
            ]
        );

        SchoolClass::firstOrCreate(
            ['school_id' => $primarySchool->id, 'class_name' => 'Grade 3A'],
            [
                'academic_year_id' => $academicYear->id,
                'grade' => 'Grade 3',
                'capacity' => 30,
            ]
        );

        // 4. Create single administrator chewetinotenda (Clean slate for custom data)
        User::create([
            'name' => 'chewetinotenda',
            'email' => 'chewetinotenda@hillside.ac.zw',
            'phone_number' => '+263771000001',
            'firebase_uid' => 'uid_admin_chewetinotenda',
            'role' => 'admin',
            'password' => Hash::make('chewetech4321#$'),
        ]);

        // 5. General Announcements
        Announcement::firstOrCreate(
            ['title' => 'New Term Academic Notice'],
            [
                'school_id' => $primarySchool->id,
                'content' => 'Welcome to the 2026 Academic Year at Hillside Schools. Portals are active.',
                'audience_role' => 'all',
            ]
        );
    }
}

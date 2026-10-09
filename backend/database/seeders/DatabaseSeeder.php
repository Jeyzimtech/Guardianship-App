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

        // 2. Create / Ensure Schools
        $prepSchool = School::firstOrCreate(
            ['name' => 'Hillside Preparatory School'],
            [
                'type' => 'prep',
                'primary_admin_name' => 'Sarah Jenkins',
                'primary_admin_email' => 'sjenkins@prep.hillside.ac.zw',
                'primary_admin_phone' => '+263771000111',
                'branding_color' => '#10B981',
            ]
        );

        $primarySchool = School::firstOrCreate(
            ['name' => 'Hillside Primary School'],
            [
                'type' => 'primary',
                'primary_admin_name' => 'Admin Tinotenda',
                'primary_admin_email' => 'admin@hillside.ac.zw',
                'primary_admin_phone' => '+263771111111',
                'branding_color' => '#3B5998',
            ]
        );

        $secondarySchool = School::firstOrCreate(
            ['name' => 'Hillside Secondary School'],
            [
                'type' => 'secondary',
                'primary_admin_name' => 'Dr. Michael Moyo',
                'primary_admin_email' => 'mmoyo@sec.hillside.ac.zw',
                'primary_admin_phone' => '+263771999888',
                'branding_color' => '#6366F1',
            ]
        );

        // 3. Create / Ensure Academic Years & School Classes
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
            ['school_id' => $prepSchool->id, 'class_name' => 'Butterflies'],
            [
                'academic_year_id' => $academicYear->id,
                'grade' => 'ECD B',
                'capacity' => 25,
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
            ['school_id' => $primarySchool->id, 'class_name' => 'Gold'],
            [
                'academic_year_id' => $academicYear->id,
                'grade' => 'Grade 4',
                'capacity' => 32,
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

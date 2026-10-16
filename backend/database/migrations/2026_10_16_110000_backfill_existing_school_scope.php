<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // Infer scope only from existing explicit, unambiguous relationships.
        foreach (DB::table('users')->where('role', 'admin')->whereNull('school_id')->get() as $admin) {
            if (!$admin->email) continue;
            $schools = DB::table('schools')->whereRaw('LOWER(primary_admin_email) = ?', [strtolower($admin->email)])->pluck('id');
            if ($schools->count() === 1) {
                DB::table('users')->where('id', $admin->id)->update(['school_id' => $schools->first()]);
            }
        }
        foreach (DB::table('academic_years')->whereNull('school_id')->get() as $year) {
            $schools = DB::table('school_classes')->where('academic_year_id', $year->id)->distinct()->pluck('school_id');
            if ($schools->count() === 1) {
                DB::table('academic_years')->where('id', $year->id)->update(['school_id' => $schools->first()]);
            }
        }
    }

    public function down(): void
    {
        // Preserve assignments: later administrator edits cannot be distinguished.
    }
};

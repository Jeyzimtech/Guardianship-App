<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        if (!Schema::hasColumn('academic_years', 'school_id')) {
            Schema::table('academic_years', function (Blueprint $table) {
                $table->foreignId('school_id')->nullable()->after('id')->constrained()->nullOnDelete();
            });
        }
    }

    public function down(): void
    {
        if (Schema::hasColumn('academic_years', 'school_id')) {
            Schema::table('academic_years', fn (Blueprint $table) => $table->dropConstrainedForeignId('school_id'));
        }
    }
};

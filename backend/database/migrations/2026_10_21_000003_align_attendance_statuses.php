<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        // Older installations restricted this column to present/absent. Editing
        // the original migration does not update an already-created database.
        Schema::table('attendance_records', function (Blueprint $table) {
            $table->enum('status', ['present', 'absent', 'late'])->change();
        });
    }

    public function down(): void
    {
        // Retain Late support so rolling back never discards saved attendance.
    }
};

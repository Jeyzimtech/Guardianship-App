<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        // 1. Schools table
        Schema::create('schools', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->enum('type', ['prep', 'primary', 'secondary']);
            $table->timestamps();
        });

        // 2. Students table
        Schema::create('students', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained()->onDelete('cascade');
            $table->string('name');
            $table->string('grade'); // e.g. Grade 1, ECD A, Form 1
            $table->string('class_name'); // e.g. Green, Red, Room 4
            $table->date('dob')->nullable();
            $table->timestamps();
        });

        // 3. Pivot table linking Guardians (Users) and Students
        Schema::create('guardian_student', function (Blueprint $table) {
            $table->foreignId('guardian_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->primary(['guardian_id', 'student_id']);
        });

        // 4. Teachers table
        Schema::create('teachers', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->foreignId('school_id')->constrained('schools')->onDelete('cascade');
            $table->json('subject_specialties')->nullable(); // e.g. ["Maths", "Science"]
            $table->timestamps();
        });

        // 5. Attendance Records
        Schema::create('attendance_records', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->date('date');
            $table->enum('status', ['present', 'absent']);
            $table->foreignId('marked_by')->constrained('users');
            $table->string('subject_name')->nullable(); // Nullable for Prep/Primary, required for Secondary
            $table->timestamps();
        });

        // 6. Fee Accounts
        Schema::create('fee_accounts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->decimal('balance_usd', 10, 2)->default(0.00);
            $table->decimal('balance_zig', 10, 2)->default(0.00);
            $table->timestamps();
        });

        // 7. Fee Transactions
        Schema::create('fee_transactions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('fee_account_id')->constrained('fee_accounts')->onDelete('cascade');
            $table->decimal('amount', 10, 2);
            $table->enum('currency', ['USD', 'ZiG']);
            $table->enum('payment_method', ['EcoCash', 'OneMoney', 'Card']);
            $table->enum('status', ['pending', 'completed'])->default('pending');
            $table->timestamps();
        });

        // 8. Report Cards / Documents
        Schema::create('report_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->string('title');
            $table->string('file_path');
            $table->enum('type', ['report', 'merit', 'certificate'])->default('report');
            $table->boolean('fee_gated')->default(true);
            $table->foreignId('uploaded_by')->constrained('users');
            $table->timestamps();
        });

        // 9. Announcements / Notifications
        Schema::create('announcements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->onDelete('cascade');
            $table->string('title');
            $table->text('content');
            $table->enum('audience_role', ['guardian', 'teacher', 'all'])->default('all');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('announcements');
        Schema::dropIfExists('report_documents');
        Schema::dropIfExists('fee_transactions');
        Schema::dropIfExists('fee_accounts');
        Schema::dropIfExists('attendance_records');
        Schema::dropIfExists('teachers');
        Schema::dropIfExists('guardian_student');
        Schema::dropIfExists('students');
        Schema::dropIfExists('schools');
    }
};

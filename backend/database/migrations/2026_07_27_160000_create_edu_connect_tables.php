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
        // 1. Update Users table for self-service guardian profile
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'address')) {
                $table->string('address')->nullable()->after('role');
            }
            if (!Schema::hasColumn('users', 'preferred_language')) {
                $table->string('preferred_language')->default('English')->after('address');
            }
            if (!Schema::hasColumn('users', 'emergency_contact_name')) {
                $table->string('emergency_contact_name')->nullable()->after('preferred_language');
            }
            if (!Schema::hasColumn('users', 'emergency_contact_phone')) {
                $table->string('emergency_contact_phone')->nullable()->after('emergency_contact_name');
            }
        });

        // 2. Update Schools table for Platform Owner onboarding details
        Schema::table('schools', function (Blueprint $table) {
            if (!Schema::hasColumn('schools', 'primary_admin_name')) {
                $table->string('primary_admin_name')->nullable()->after('type');
            }
            if (!Schema::hasColumn('schools', 'primary_admin_email')) {
                $table->string('primary_admin_email')->nullable()->after('primary_admin_name');
            }
            if (!Schema::hasColumn('schools', 'primary_admin_phone')) {
                $table->string('primary_admin_phone')->nullable()->after('primary_admin_email');
            }
            if (!Schema::hasColumn('schools', 'branding_color')) {
                $table->string('branding_color')->nullable()->default('#3B5998')->after('primary_admin_phone');
            }
        });

        // 3. Subscriptions table (Website Admin control per child)
        Schema::create('subscriptions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->enum('status', ['active', 'inactive'])->default('active');
            $table->date('start_date')->nullable();
            $table->date('end_date')->nullable();
            $table->foreignId('set_by_user_id')->nullable()->constrained('users')->onDelete('set null');
            $table->timestamps();
        });

        // 4. Journal Entries (Multimedia Learning Journal & Preparatory Wellbeing Log)
        Schema::create('journal_entries', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->foreignId('author_id')->constrained('users')->onDelete('cascade');
            $table->enum('type', ['photo', 'video', 'drawing', 'voice', 'text', 'link', 'wellbeing'])->default('text');
            $table->string('media_url')->nullable();
            $table->text('caption')->nullable();
            $table->string('subject_name')->nullable();
            $table->json('wellbeing_data')->nullable(); // meals, nap, hygiene details for Prep
            $table->boolean('fee_gated')->default(false);
            $table->timestamps();
        });

        // 5. Behaviour & Merits Incidents
        Schema::create('behaviour_incidents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->enum('polarity', ['positive', 'negative']);
            $table->string('category');
            $table->text('note')->nullable();
            $table->foreignId('recorded_by')->constrained('users')->onDelete('cascade');
            $table->date('incident_date');
            $table->timestamps();
        });

        // 6. Assignments & Homework
        Schema::create('assignments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_class_id')->nullable()->constrained('school_classes')->onDelete('cascade');
            $table->string('grade_name')->nullable(); // fallback or direct link
            $table->string('subject_name')->nullable();
            $table->string('title');
            $table->text('description')->nullable();
            $table->date('due_date');
            $table->foreignId('created_by')->constrained('users')->onDelete('cascade');
            $table->timestamps();
        });

        // 7. Uniform Orders
        Schema::create('uniform_orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->json('items');
            $table->decimal('total_amount', 10, 2);
            $table->enum('currency', ['USD', 'ZiG'])->default('USD');
            $table->enum('payment_status', ['pending', 'paid', 'cancelled'])->default('pending');
            $table->timestamps();
        });

        // 8. Activities & Activity Attendance
        Schema::create('activities', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->constrained('schools')->onDelete('cascade');
            $table->string('title');
            $table->text('description')->nullable();
            $table->date('activity_date');
            $table->json('roster')->nullable();
            $table->timestamps();
        });

        Schema::create('activity_attendances', function (Blueprint $table) {
            $table->id();
            $table->foreignId('activity_id')->constrained('activities')->onDelete('cascade');
            $table->foreignId('student_id')->constrained('students')->onDelete('cascade');
            $table->enum('status', ['present', 'absent']);
            $table->foreignId('marked_by')->constrained('users')->onDelete('cascade');
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('activity_attendances');
        Schema::dropIfExists('activities');
        Schema::dropIfExists('uniform_orders');
        Schema::dropIfExists('assignments');
        Schema::dropIfExists('behaviour_incidents');
        Schema::dropIfExists('journal_entries');
        Schema::dropIfExists('subscriptions');

        Schema::table('schools', function (Blueprint $table) {
            $table->dropColumn(['primary_admin_name', 'primary_admin_email', 'primary_admin_phone', 'branding_color']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['address', 'preferred_language', 'emergency_contact_name', 'emergency_contact_phone']);
        });
    }
};

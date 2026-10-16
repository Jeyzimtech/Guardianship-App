<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Behaviour categories configured by school admins, and class-scoped
     * announcements so teachers only message their own students' parents.
     */
    public function up(): void
    {
        if (!Schema::hasTable('behaviour_categories')) {
            Schema::create('behaviour_categories', function (Blueprint $table) {
                $table->id();
                $table->foreignId('school_id')->constrained('schools')->onDelete('cascade');
                $table->string('name');
                $table->enum('polarity', ['positive', 'negative']);
                $table->timestamps();
                $table->unique(['school_id', 'name', 'polarity']);
            });
        }

        Schema::table('announcements', function (Blueprint $table) {
            if (!Schema::hasColumn('announcements', 'class_name')) {
                $table->string('class_name')->nullable()->after('audience_role');
            }
            if (!Schema::hasColumn('announcements', 'author_id')) {
                $table->foreignId('author_id')->nullable()->after('class_name')->constrained('users')->nullOnDelete();
            }
        });

        Schema::table('activities', function (Blueprint $table) {
            if (!Schema::hasColumn('activities', 'created_by')) {
                $table->foreignId('created_by')->nullable()->after('roster')->constrained('users')->nullOnDelete();
            }
        });
    }

    public function down(): void
    {
        Schema::table('activities', function (Blueprint $table) {
            if (Schema::hasColumn('activities', 'created_by')) {
                $table->dropConstrainedForeignId('created_by');
            }
        });
        Schema::table('announcements', function (Blueprint $table) {
            if (Schema::hasColumn('announcements', 'author_id')) {
                $table->dropConstrainedForeignId('author_id');
            }
            if (Schema::hasColumn('announcements', 'class_name')) {
                $table->dropColumn('class_name');
            }
        });
        Schema::dropIfExists('behaviour_categories');
    }
};

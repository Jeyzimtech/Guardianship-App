<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('message_blocks', function (Blueprint $t) {
            $t->id();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->foreignId('blocked_user_id')->constrained('users')->cascadeOnDelete();
            $t->timestamps();
            $t->unique(['user_id', 'blocked_user_id']);
        });
        Schema::table('support_reports', function (Blueprint $t) {
            $t->string('review_status', 30)->default('pending');
            $t->text('review_notes')->nullable();
            $t->foreignId('reviewed_by')->nullable()->constrained('users')->nullOnDelete();
            $t->timestamp('reviewed_at')->nullable();
        });
    }
    public function down(): void
    {
        Schema::table('support_reports', function (Blueprint $t) {
            $t->dropForeign(['reviewed_by']);
            $t->dropColumn(['review_status', 'review_notes', 'reviewed_by', 'reviewed_at']);
        });
        Schema::dropIfExists('message_blocks');
    }
};

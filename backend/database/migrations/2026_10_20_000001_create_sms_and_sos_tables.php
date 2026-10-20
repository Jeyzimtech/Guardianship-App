<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('users', fn (Blueprint $t) => $t->timestamp('phone_verified_at')->nullable());
        Schema::create('phone_otps', function (Blueprint $t) {
            $t->uuid('id')->primary();
            $t->foreignId('user_id')->constrained()->cascadeOnDelete();
            $t->string('phone_number');
            $t->string('code_hash');
            $t->unsignedTinyInteger('attempts')->default(0);
            $t->timestamp('expires_at');
            $t->timestamp('consumed_at')->nullable();
            $t->timestamps();
        });
        Schema::create('sos_alerts', function (Blueprint $t) {
            $t->id();
            $t->foreignId('teacher_id')->constrained('users');
            $t->uuid('request_id');
            $t->string('message', 500);
            $t->string('sms_status')->default('pending');
            $t->json('sms_result')->nullable();
            $t->timestamps();
            $t->unique(['teacher_id', 'request_id']);
        });
        Schema::create('sos_recipients', function (Blueprint $t) {
            $t->id();
            $t->foreignId('sos_alert_id')->constrained()->cascadeOnDelete();
            $t->foreignId('guardian_id')->constrained('users')->cascadeOnDelete();
            $t->timestamp('acknowledged_at')->nullable();
            $t->unique(['sos_alert_id', 'guardian_id']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('sos_recipients');
        Schema::dropIfExists('sos_alerts');
        Schema::dropIfExists('phone_otps');
        Schema::table('users', fn (Blueprint $t) => $t->dropColumn('phone_verified_at'));
    }
};

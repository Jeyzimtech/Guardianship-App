<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::table('direct_messages', function (Blueprint $table) {
            $table->timestamp('sender_deleted_at')->nullable();
            $table->timestamp('recipient_deleted_at')->nullable();
        });
    }
    public function down(): void
    {
        Schema::table('direct_messages', fn (Blueprint $table) => $table->dropColumn(['sender_deleted_at', 'recipient_deleted_at']));
    }
};

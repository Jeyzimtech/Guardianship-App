<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('direct_messages', function (Blueprint $t) {
            $t->id();
            $t->foreignId('sender_id')->constrained('users')->cascadeOnDelete();
            $t->foreignId('recipient_id')->constrained('users')->cascadeOnDelete();
            $t->text('body');
            $t->timestamp('read_at')->nullable();
            $t->timestamps();
            $t->index(['sender_id', 'recipient_id']);
            $t->index(['recipient_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('direct_messages');
    }
};

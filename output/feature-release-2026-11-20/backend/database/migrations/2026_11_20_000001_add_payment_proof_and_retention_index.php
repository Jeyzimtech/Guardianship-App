<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;
return new class extends Migration {
    public function up(): void {
        Schema::table('fee_transactions', fn (Blueprint $t) => $t->string('proof_path')->nullable());
        Schema::table('direct_messages', fn (Blueprint $t) => $t->index('created_at', 'direct_messages_expiry_index'));
    }
    public function down(): void {
        Schema::table('fee_transactions', fn (Blueprint $t) => $t->dropColumn('proof_path'));
        Schema::table('direct_messages', fn (Blueprint $t) => $t->dropIndex('direct_messages_expiry_index'));
    }
};

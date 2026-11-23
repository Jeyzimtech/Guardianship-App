<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\{DB, Schema};

return new class extends Migration {
    public function up(): void
    {
        Schema::table('direct_messages', function (Blueprint $table) {
            $table->timestamp('delivered_at')->nullable();
            $table->index(['recipient_id', 'delivered_at']);
        });
        DB::table('direct_messages')->whereNotNull('read_at')->update(['delivered_at' => DB::raw('read_at')]);
    }

    public function down(): void
    {
        Schema::table('direct_messages', function (Blueprint $table) {
            $table->dropIndex(['recipient_id', 'delivered_at']);
            $table->dropColumn('delivered_at');
        });
    }
};

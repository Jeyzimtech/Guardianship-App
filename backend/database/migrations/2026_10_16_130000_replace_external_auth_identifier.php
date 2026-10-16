<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        if (Schema::hasColumn('users', 'firebase_uid') && !Schema::hasColumn('users', 'account_uid')) {
            Schema::table('users', fn (Blueprint $table) => $table->renameColumn('firebase_uid', 'account_uid'));
        }
    }
    public function down(): void {
        Schema::table('users', fn (Blueprint $table) => $table->renameColumn('account_uid', 'firebase_uid'));
    }
};

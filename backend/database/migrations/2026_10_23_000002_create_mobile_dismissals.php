<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('mobile_dismissals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('category', 20);
            $table->unsignedBigInteger('item_id');
            $table->unique(['user_id', 'category', 'item_id']);
        });
    }
    public function down(): void { Schema::dropIfExists('mobile_dismissals'); }
};

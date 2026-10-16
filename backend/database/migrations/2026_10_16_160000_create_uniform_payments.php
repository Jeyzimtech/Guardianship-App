<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void {
        Schema::create('uniform_payments', function (Blueprint $t) {
            $t->id();
            $t->foreignId('uniform_order_id')->constrained()->cascadeOnDelete();
            $t->string('reference')->nullable()->unique();
            $t->text('redirect_url')->nullable();
            $t->string('status')->default('INITIATING')->index();
            $t->boolean('sandbox');
            $t->timestamp('checked_at')->nullable();
            $t->timestamps();
        });
    }
    public function down(): void { Schema::dropIfExists('uniform_payments'); }
};

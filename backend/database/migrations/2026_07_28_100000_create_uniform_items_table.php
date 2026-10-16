<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('uniform_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('school_id')->nullable()->constrained('schools')->onDelete('cascade');
            $table->string('name');
            $table->string('item_code')->unique()->nullable();
            $table->string('category')->default('Formal Wear');
            $table->decimal('price_usd', 10, 2)->default(0.00);
            $table->decimal('price_zig', 10, 2)->default(0.00);
            $table->json('sizes')->nullable();
            $table->integer('stock_count')->default(50);
            $table->boolean('in_stock')->default(true);
            $table->string('image_url')->nullable();
            $table->text('description')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('uniform_items');
    }
};

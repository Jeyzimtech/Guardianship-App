<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration {
    public function up(): void
    {
        Schema::create('student_medical_profiles', function (Blueprint $t) {
            $t->id();
            $t->foreignId('student_id')->unique()->constrained()->cascadeOnDelete();
            $t->text('allergies')->nullable();
            $t->text('conditions')->nullable();
            $t->text('medications')->nullable();
            $t->text('care_instructions')->nullable();
            $t->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $t->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('student_medical_profiles');
    }
};

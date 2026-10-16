<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\{Schema,DB};

return new class extends Migration {
    public function up(): void {
        Schema::table('announcements', fn (Blueprint $t) => $t->string('grade')->nullable());
        // Preserve legacy class notices only when their class resolves unambiguously.
        foreach (DB::table('announcements')->whereNotNull('class_name')->get() as $notice) {
            $grades=DB::table('school_classes')->where('school_id',$notice->school_id)->where('class_name',$notice->class_name)->distinct()->pluck('grade');
            if ($grades->count()===1) DB::table('announcements')->where('id',$notice->id)->update(['grade'=>$grades->first()]);
        }
        Schema::table('fee_transactions', function (Blueprint $t) {
            $t->string('reference')->nullable();
            $t->foreignId('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $t->timestamp('verified_at')->nullable();
            $t->unique(['payment_method','reference']);
        });
    }
    public function down(): void {
        Schema::table('fee_transactions', function (Blueprint $t) {
            $t->dropUnique(['payment_method','reference']);
            $t->dropConstrainedForeignId('verified_by');
            $t->dropColumn(['reference','verified_at']);
        });
        Schema::table('announcements', fn (Blueprint $t) => $t->dropColumn('grade'));
    }
};

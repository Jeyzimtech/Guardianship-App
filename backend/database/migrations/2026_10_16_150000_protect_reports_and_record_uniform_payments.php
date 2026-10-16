<?php
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\{Schema,DB,Storage};

return new class extends Migration {
    public function up(): void {
        Schema::table('uniform_orders', function(Blueprint $t) {
            $t->string('payment_reference')->nullable()->unique();
            $t->string('payment_method')->nullable();
            $t->foreignId('verified_by')->nullable()->constrained('users')->nullOnDelete();
            $t->timestamp('verified_at')->nullable();
        });
        foreach(DB::table('report_documents')->get() as $report) {
            if (str_starts_with($report->file_path,'private:')) continue;
            $path=parse_url($report->file_path,PHP_URL_PATH);
            if (!$path || str_contains($path,'..') || !preg_match('#^(?:/storage/|storage/)?reports/[^/]+$#',$path)) continue;
            $relative='reports/'.basename($path);
            $source = Storage::disk('public')->exists($relative) ? 'public' : null;
            $oldPath = $relative;
            if (!$source && Storage::disk('local')->exists('public/'.$relative)) {
                $source='local'; $oldPath='public/'.$relative;
            }
            if (!$source && Storage::disk('local')->exists($relative)) {
                DB::table('report_documents')->where('id',$report->id)->update(['file_path'=>'private:'.$relative]);
                continue;
            }
            if (!$source) continue;
            $stream=Storage::disk($source)->readStream($oldPath);
            if (!is_resource($stream) || !Storage::disk('local')->put($relative,$stream)) throw new RuntimeException('Could not protect an existing report.');
            if (is_resource($stream)) fclose($stream);
            DB::table('report_documents')->where('id',$report->id)->update(['file_path'=>'private:'.$relative]);
            Storage::disk($source)->delete($oldPath);
        }
    }
    public function down(): void {
        Schema::table('uniform_orders', function(Blueprint $t) {
            $t->dropUnique(['payment_reference']);
            $t->dropConstrainedForeignId('verified_by');
            $t->dropColumn(['payment_reference','payment_method','verified_at']);
        });
        // Private report files stay private on rollback.
    }
};

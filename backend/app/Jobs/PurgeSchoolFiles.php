<?php
namespace App\Jobs;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\DB;
class PurgeSchoolFiles implements ShouldQueue
{
    use Queueable;
    public int $tries = 5;
    public function __construct(public array $files) {}
    public function handle(): void
    {
        foreach ($this->files as [$disk, $path]) {
            // A reused asset may still belong to a surviving school.
            if ($disk === 'local' && (DB::table('students')->where('photo_path', $path)->exists()
                || DB::table('school_documents')->where('file_path', $path)->exists()
                || DB::table('report_documents')->where('file_path', 'private:'.$path)->exists()
                || DB::table('fee_transactions')->where('proof_path', $path)->exists())) continue;
            if ($disk === 'public' && (DB::table('journal_entries')->where('media_url', 'like', '%/storage/'.$path)->exists()
                || DB::table('uniform_items')->where('image_url', 'like', '%/storage/'.$path)->exists())) continue;
            if (!Storage::disk($disk)->delete($path)) throw new \RuntimeException('School file cleanup failed; retrying.');
        }
    }
}

<?php

namespace App\Jobs;

use App\Models\User;
use App\Services\{FirebasePush, MobileUpdates};
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;
use Illuminate\Support\Facades\DB;

class SendMobilePush implements ShouldQueue
{
    use Queueable;

    public int $tries = 3;
    public int $timeout = 60;

    public function __construct(public string $category, public int $itemId, public ?int $userId = null) {}

    public function backoff(): array { return [30, 120, 300]; }

    public function handle(MobileUpdates $updates, FirebasePush $push): void
    {
        if (!config('services.firebase.credentials')) return;
        if ($this->userId === null) {
            // Each account gets its own delivery job, so a school-wide notice
            // cannot time out after sending only to the first few families.
            User::whereIn('role', ['guardian', 'teacher'])->whereIn('id', DB::table('mobile_devices')->select('user_id'))
                ->eachById(function ($user) use ($updates) {
                    if ($updates->unread($user, $this->category)->where('id', $this->itemId)->exists()) {
                        self::dispatch($this->category, $this->itemId, $user->id);
                    }
                });
            return;
        }
        // Recheck visibility at delivery: school/class assignments may have changed.
        User::whereKey($this->userId)->whereIn('role', ['guardian', 'teacher'])->whereIn('id', DB::table('mobile_devices')->select('user_id'))
            ->eachById(function ($user) use ($updates, $push) {
                $item = $updates->unread($user, $this->category)->where('id', $this->itemId)->first();
                if (!$item || (isset($item->author_id) && (int) $item->author_id === $user->id)) return;
                $title = match ($this->category) {
                    'notices' => 'New school notice', 'journal' => 'New journal entry', default => 'New message',
                };
                foreach (DB::table('mobile_devices')->where('user_id', $user->id)->get() as $device) {
                    $push->send($device, $title, $this->category, $this->itemId, $item->student_id ?? null);
                }
            });
    }
}

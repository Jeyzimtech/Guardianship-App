<?php

namespace App\Services;

use Illuminate\Support\Facades\DB;

class MessageReceipts
{
    /** A foreground sync acknowledges receipt without marking messages read. */
    public static function delivered(int $recipientId): void
    {
        DB::table('direct_messages')->where('recipient_id', $recipientId)
            ->whereNull('delivered_at')->update(['delivered_at' => now()]);
    }
}

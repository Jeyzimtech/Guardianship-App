<?php
namespace App\Services;

use Illuminate\Support\Facades\DB;

class MessageSafety
{
    public static function blocked(int $a, int $b): bool
    {
        return DB::table('message_blocks')->where(fn ($q) => $q->where('user_id', $a)->where('blocked_user_id', $b))
            ->orWhere(fn ($q) => $q->where('user_id', $b)->where('blocked_user_id', $a))->exists();
    }
    public static function blockedContacts(int $id): array
    {
        return DB::table('message_blocks')->where('user_id', $id)->pluck('blocked_user_id')
            ->merge(DB::table('message_blocks')->where('blocked_user_id', $id)->pluck('user_id'))->unique()->all();
    }
}

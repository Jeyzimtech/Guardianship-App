<?php
namespace App\Services;
use Illuminate\Support\Facades\DB;
class MessageRetention
{
    public static function purge(): int
    {
        return DB::transaction(function () {
            $expired = DB::table('direct_messages')->where('created_at', '<=', now()->subDays(7));
            foreach (['mobile_reads', 'mobile_dismissals'] as $table) {
                DB::table($table)->where('category', 'messages')->whereIn('item_id', (clone $expired)->select('id'))->delete();
            }
            return $expired->delete();
        });
    }
}

<?php

namespace App\Http\Controllers;

use App\Services\MobileUpdates;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MobileNotificationController extends Controller
{
    public function counts(Request $request, MobileUpdates $updates)
    {
        \App\Services\MessageReceipts::delivered($request->user()->id);
        $counts = [];
        foreach (['notices', 'journal', 'messages'] as $category) {
            $counts[$category] = $updates->unread($request->user(), $category)->count();
        }
        return response()->json(['counts' => $counts, 'notice_reads' => DB::table('mobile_reads')->where('user_id', $request->user()->id)->where('category', 'notices')->pluck('item_id')]);
    }

    public function read(Request $request, MobileUpdates $updates)
    {
        $data = $request->validate([
            'category' => 'required|in:notices,journal',
            'ids' => 'required|array|max:1000', 'ids.*' => 'required|integer|min:1',
        ]);
        $ids = $updates->visible($request->user(), $data['category'])->whereIn('id', $data['ids'])->pluck('id');
        DB::table('mobile_reads')->insertOrIgnore($ids->map(fn ($id) => [
            'user_id' => $request->user()->id, 'category' => $data['category'], 'item_id' => $id,
        ])->all());
        return response()->json(['status' => 'success']);
    }

    public function destroy(Request $request)
    {
        $data = $request->validate([
            'items' => 'required|array|min:1|max:1000',
            'items.*.category' => 'required|in:notices,sos',
            'items.*.id' => 'required|integer|min:1',
        ]);
        $user = $request->user();
        $items = collect($data['items'])->unique(fn ($item) => $item['category'].':'.$item['id']);
        foreach ($items->groupBy('category') as $category => $group) {
            $ids = $group->pluck('id');
            $query = $category === 'notices'
                ? AnnouncementController::visibleTo($user)->whereIn('audience_role', [$user->role, 'all'])
                : DB::table('sos_alerts')->whereIn('id', DB::table('sos_recipients')->where('guardian_id', $user->id)->select('sos_alert_id'));
            abort_unless($query->whereIn('id', $ids)->count() === $ids->count(), 403, 'You can only delete your own notifications.');
        }
        DB::transaction(function () use ($items, $user) {
            DB::table('mobile_dismissals')->insertOrIgnore($items->map(fn ($item) => [
                'user_id' => $user->id, 'category' => $item['category'], 'item_id' => $item['id'],
            ])->values()->all());
        });
        return response()->json(['status' => 'success']);
    }

    public function register(Request $request)
    {
        $data = $request->validate(['token' => 'required|string|max:512']);
        DB::table('mobile_devices')->updateOrInsert(['token' => $data['token']], [
            'user_id' => $request->user()->id, 'created_at' => now(), 'updated_at' => now(),
            'access_token_id' => $request->user()->currentAccessToken() instanceof \Laravel\Sanctum\PersonalAccessToken
                ? $request->user()->currentAccessToken()->id : null,
        ]);
        return response()->json(['status' => 'success']);
    }

    public function unregister(Request $request)
    {
        $data = $request->validate(['token' => 'required|string|max:512']);
        DB::table('mobile_devices')->where('user_id', $request->user()->id)->where('token', $data['token'])->delete();
        return response()->json(['status' => 'success']);
    }
}

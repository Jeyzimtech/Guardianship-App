<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\{Config, DB, Log, Mail};

class SupportReportController extends Controller
{
    public const CATEGORIES = ['bug', 'login', 'notifications', 'payments', 'feedback', 'safety', 'other'];

    public function index(Request $request)
    {
        // Safety reports may concern multiple schools; platform administrators review them centrally.
        abort_unless($request->user()->role === 'website_admin', 403);
        return response()->json(['reports' => DB::table('support_reports')->where('category', 'safety')->orderByDesc('id')->limit(100)->get()]);
    }

    public function review(Request $request, int $id)
    {
        abort_unless($request->user()->role === 'website_admin', 403);
        $data = $request->validate(['review_status' => 'required|in:pending,reviewing,resolved', 'review_notes' => 'required|string|min:5|max:5000', 'hide_message_id' => 'nullable|integer|min:1']);
        abort_unless(DB::table('support_reports')->where('id', $id)->where('category', 'safety')->exists(), 404);
        DB::transaction(function () use ($request, $id, $data) {
            $messageId = $data['hide_message_id'] ?? null;
            unset($data['hide_message_id']);
            if ($messageId) {
                abort_unless(DB::table('direct_messages')->where('id', $messageId)->exists(), 404);
                DB::table('direct_messages')->where('id', $messageId)->update(['sender_deleted_at' => now(), 'recipient_deleted_at' => now()]);
                $data['review_notes'] .= '\nRemoved message '.$messageId.' from both participants.';
            }
            DB::table('support_reports')->where('id', $id)->update($data + ['reviewed_by' => $request->user()->id, 'reviewed_at' => now(), 'updated_at' => now()]);
        });
        return response()->json(['status' => 'success']);
    }

    /**
     * Store a technical issue or feedback report from the mobile app and email it to support.
     */
    public function store(Request $request)
    {
        $data = $request->validate([
            'category' => 'required|in:' . implode(',', self::CATEGORIES),
            'message' => 'required|string|min:10|max:5000',
            'app_version' => 'nullable|string|max:40',
            'platform' => 'nullable|string|max:120',
        ]);
        $user = $request->user();
        $id = DB::table('support_reports')->insertGetId($data + ['user_id' => $user->id, 'created_at' => now(), 'updated_at' => now()]);

        // The report is kept even when mail is down; support can read it from the database.
        try {
            EmailSettingsController::configureMailTransport();
            $to = config('services.support.email', 'admin@teramark.co.zw');
            $body = "Report #{$id} ({$data['category']})\n"
                . "From: {$user->name} ({$user->role}) {$user->email} {$user->phone_number}\n"
                . 'App: ' . ($data['app_version'] ?? 'unknown') . ' on ' . ($data['platform'] ?? 'unknown') . "\n\n"
                . $data['message'];
            Mail::raw($body, fn ($m) => $m->to($to)
                ->from(Config::get('mail.from.address'), Config::get('mail.from.name', 'Edu Connect'))
                ->subject("Edu Connect support report #{$id}: {$data['category']}"));
            DB::table('support_reports')->where('id', $id)->update(['emailed' => true]);
        } catch (\Throwable $e) {
            Log::error('Support report email failed: ' . $e->getMessage());
        }

        return response()->json(['status' => 'success', 'message' => 'Thank you. Your report has been sent.', 'id' => $id], 201);
    }
}

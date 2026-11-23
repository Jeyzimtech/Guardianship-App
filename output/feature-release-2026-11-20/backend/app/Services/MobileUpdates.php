<?php

namespace App\Services;

use App\Http\Controllers\AnnouncementController;
use App\Models\{JournalEntry, Student, User};
use Illuminate\Support\Facades\DB;

class MobileUpdates
{
    public static function dismissedIds(User $user, string $category)
    {
        return DB::table('mobile_dismissals')->where('user_id', $user->id)->where('category', $category)->select('item_id');
    }

    public function visible(User $user, string $category)
    {
        if ($user->role === 'guardian' && !GuardianAccess::status($user)['access_allowed']) {
            if ($category === 'messages') return DB::table('direct_messages')->whereRaw('1 = 0');
            return ($category === 'journal' ? JournalEntry::query() : \App\Models\Announcement::query())->whereRaw('1 = 0');
        }
        if ($category === 'notices') {
            return AnnouncementController::visibleTo($user)->whereIn('audience_role', [$user->role, 'all'])->whereNotIn('id', self::dismissedIds($user, 'notices'));
        }
        if ($category === 'journal') {
            $students = $user->role === 'guardian'
                ? $user->students()->with('activeSubscription')->get()->filter(fn ($s) => GuardianAccess::active($s))->pluck('id')
                : Student::taughtBy($user->teacherProfile)->select('students.id');
            return JournalEntry::where('type', '!=', 'wellbeing')->whereIn('student_id', $students);
        }
        return DB::table('direct_messages')->where('created_at', '>', now()->subDays(7))->where('recipient_id', $user->id)->whereNull('recipient_deleted_at')
            ->whereNotIn('sender_id', MessageSafety::blockedContacts($user->id));
    }

    public function unread(User $user, string $category)
    {
        $query = $this->visible($user, $category);
        if ($category === 'messages') return $query->whereNull('read_at');
        return $query->where(fn ($q) => $q->whereNull('author_id')->orWhere('author_id', '!=', $user->id))->whereNotIn('id', DB::table('mobile_reads')->where('user_id', $user->id)
            ->where('category', $category)->select('item_id'));
    }
}

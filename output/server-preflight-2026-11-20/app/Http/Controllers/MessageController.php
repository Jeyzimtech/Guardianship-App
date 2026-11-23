<?php

namespace App\Http\Controllers;

use App\Models\{Student, Teacher, User};
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;

/** Direct teacher-guardian messages, limited to families of the teacher's assigned classes. */
class MessageController extends Controller
{
    public function block(Request $request, int $userId)
    {
        $me = $request->user()->id;
        if ($request->isMethod('delete')) {
            DB::table('message_blocks')->where('user_id', $me)->where('blocked_user_id', $userId)->delete();
        } else {
            abort_unless($this->allowedContacts($request->user())->has($userId), 403);
            DB::table('message_blocks')->insertOrIgnore(['user_id' => $me, 'blocked_user_id' => $userId, 'created_at' => now(), 'updated_at' => now()]);
        }
        return response()->json(['status' => 'success']);
    }
    /** People this user may message, keyed by user id, with the children that connect them. */
    private function allowedContacts(User $user): Collection
    {
        $contacts = collect();
        if ($user->role === 'teacher') {
            $teacher = $user->teacherProfile;
            abort_unless($teacher, 403, 'Teacher profile not found.');
            foreach (Student::taughtBy($teacher)->with('guardians')->get() as $student) {
                foreach ($student->guardians as $guardian) {
                    $entry = $contacts->get($guardian->id, ['id' => $guardian->id, 'name' => $guardian->name, 'role' => 'guardian', 'students' => []]);
                    $entry['students'][] = $student->name;
                    $contacts->put($guardian->id, $entry);
                }
            }
        } elseif ($user->role === 'guardian') {
            $children = $user->students()->get();
            $teachers = Teacher::whereIn('school_id', $children->pluck('school_id')->unique())->with(['user', 'assignedClasses'])->get();
            foreach ($teachers as $teacher) {
                if (!$teacher->user) continue;
                foreach ($children as $child) {
                    $teaches = (int) $teacher->school_id === (int) $child->school_id
                        && $teacher->assignedClasses->contains(fn ($c) => $c->grade === $child->grade && $c->class_name === $child->class_name);
                    if (!$teaches) continue;
                    $entry = $contacts->get($teacher->user->id, ['id' => $teacher->user->id, 'name' => $teacher->user->name, 'role' => 'teacher', 'students' => []]);
                    $entry['students'][] = $child->name;
                    $contacts->put($teacher->user->id, $entry);
                }
            }
        } else {
            abort(403);
        }
        return $contacts->map(fn ($c) => [...$c, 'students' => array_values(array_unique($c['students']))]);
    }

    private function between(int $a, int $b)
    {
        return DB::table('direct_messages')->where(fn ($q) => $q->where('sender_id', $a)->where('recipient_id', $b)->whereNull('sender_deleted_at'))
            ->orWhere(fn ($q) => $q->where('sender_id', $b)->where('recipient_id', $a)->whereNull('recipient_deleted_at'));
    }

    public function contacts(Request $request)
    {
        $me = $request->user()->id;
        \App\Services\MessageReceipts::delivered($me);
        $allowed = $this->allowedContacts($request->user());
        // Fetch every contact's summary in two queries rather than two per contact.
        $summaries = $allowed->isEmpty() ? collect() : DB::table('direct_messages')
            ->where(fn ($q) => $q->where('sender_id', $me)->whereIn('recipient_id', $allowed->keys())->whereNull('sender_deleted_at'))
            ->orWhere(fn ($q) => $q->where('recipient_id', $me)->whereIn('sender_id', $allowed->keys())->whereNull('recipient_deleted_at'))
            ->selectRaw('CASE WHEN sender_id = ? THEN recipient_id ELSE sender_id END AS contact_id, MAX(id) AS last_id, SUM(CASE WHEN recipient_id = ? AND read_at IS NULL THEN 1 ELSE 0 END) AS unread', [$me, $me])
            ->groupBy('contact_id')->get()->keyBy('contact_id');
        $latest = $summaries->isEmpty() ? collect() : DB::table('direct_messages')
            ->whereIn('id', $summaries->pluck('last_id'))->get()->keyBy('id');
        $contacts = $allowed->map(function ($contact) use ($me, $summaries, $latest) {
            $summary = $summaries->get($contact['id']);
            $last = $summary ? $latest->get($summary->last_id) : null;
            $unread = (int) ($summary->unread ?? 0);
            return [...$contact, 'last_message' => $last ? ['body' => $last->body, 'created_at' => $last->created_at, 'delivered_at' => $last->delivered_at, 'read_at' => $last->read_at, 'from_me' => (int) $last->sender_id === $me] : null, 'unread' => $unread];
        })->sortBy([fn ($a, $b) => strcmp($b['last_message']['created_at'] ?? '', $a['last_message']['created_at'] ?? ''), fn ($a, $b) => strcasecmp($a['name'], $b['name'])])->values();
        return response()->json(['status' => 'success', 'contacts' => $contacts, 'unread_total' => $contacts->sum('unread')]);
    }

    public function thread(Request $request, int $userId)
    {
        $me = $request->user()->id;
        $contact = $this->allowedContacts($request->user())->get($userId);
        abort_unless($contact, 403, 'You cannot message this person.');
        \App\Services\MessageReceipts::delivered($me);
        DB::table('direct_messages')->where('sender_id', $userId)->where('recipient_id', $me)->whereNull('read_at')->update(['read_at' => now()]);
        $messages = $this->between($me, $userId)->orderByDesc('id')->limit(200)->get()->reverse()->values()
            ->map(fn ($m) => ['id' => $m->id, 'body' => $m->body, 'created_at' => $m->created_at, 'delivered_at' => $m->delivered_at, 'read_at' => $m->read_at, 'from_me' => (int) $m->sender_id === $me]);
        return response()->json(['status' => 'success', 'contact' => $contact, 'messages' => $messages,
            'blocked' => DB::table('message_blocks')->where('user_id', $me)->where('blocked_user_id', $userId)->exists(),
            'messaging_unavailable' => \App\Services\MessageSafety::blocked($me, $userId)]);
    }

    public function destroy(Request $request, int $userId)
    {
        $me = $request->user()->id;
        abort_unless($this->allowedContacts($request->user())->has($userId), 403);
        $data = $request->validate([
            'all' => 'sometimes|boolean',
            'ids' => 'required_unless:all,true|array|min:1|max:200',
            'ids.*' => 'required|integer|distinct',
        ]);
        $query = DB::table('direct_messages')->where(fn ($q) =>
            $q->where(fn ($q) => $q->where('sender_id', $me)->where('recipient_id', $userId))
              ->orWhere(fn ($q) => $q->where('sender_id', $userId)->where('recipient_id', $me)));
        if (empty($data['all'])) {
            $query->whereIn('id', $data['ids']);
            abort_unless((clone $query)->count() === count($data['ids']), 403);
        }
        DB::transaction(function () use ($query, $me) {
            (clone $query)->where('sender_id', $me)->update(['sender_deleted_at' => now()]);
            (clone $query)->where('recipient_id', $me)->update(['recipient_deleted_at' => now()]);
        });
        return response()->json(['status' => 'success']);
    }

    public function store(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'body' => 'required|string|max:2000',
            'all_parents' => 'sometimes|boolean',
            'recipient_ids' => 'required_without:all_parents|array|min:1|max:500',
            'recipient_ids.*' => 'integer',
        ]);
        $body = trim($data['body']);
        abort_if($body === '', 422, 'Write a message before sending.');
        $allowed = $this->allowedContacts($user);
        if (!empty($data['all_parents'])) {
            abort_unless($user->role === 'teacher', 403, 'Only teachers can message all parents.');
            $recipients = $allowed->keys();
            abort_if($recipients->isEmpty(), 422, 'No parents are linked to your assigned classes yet.');
        } else {
            $recipients = collect($data['recipient_ids'])->map(fn ($id) => (int) $id)->unique()->values();
            abort_unless($recipients->every(fn ($id) => $allowed->has($id)), 403, 'You cannot message one or more of these people.');
        }
        $now = now();
        $blocked = \App\Services\MessageSafety::blockedContacts($user->id);
        if (!empty($data['all_parents'])) {
            $recipients = $recipients->diff($blocked)->values();
            abort_if($recipients->isEmpty(), 422, 'No available recipients.');
        } else {
            abort_if($recipients->intersect($blocked)->isNotEmpty(), 403, 'Messaging is unavailable for this contact.');
        }
        DB::transaction(function () use ($recipients, $user, $body, $now) {
            foreach ($recipients as $recipient) {
                $id = DB::table('direct_messages')->insertGetId([
                    'sender_id' => $user->id, 'recipient_id' => $recipient, 'body' => $body, 'created_at' => $now, 'updated_at' => $now,
                ]);
                \App\Jobs\SendMobilePush::dispatch('messages', $id)->afterCommit();
            }
        });
        $count = $recipients->count();
        return response()->json(['status' => 'success', 'sent' => $count,
            'message' => $count === 1 ? 'Message sent.' : "Message sent to $count parents."], 201);
    }
}

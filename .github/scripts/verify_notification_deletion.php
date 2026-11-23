<?php
// Run through server_session.py PHP: mode from the deployed backend directory.
// All write checks use a separate temporary school and are removed in finally.
require 'vendor/autoload.php';
$app = require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

use App\Models\{School, SchoolClass, Student, Subscription, Teacher, User};
use Illuminate\Support\Facades\{DB, Http, Schema, Storage};
use Illuminate\Support\Str;

function verify($condition, string $label): void {
    if (!$condition) throw new RuntimeException('FAIL '.$label);
    echo 'PASS '.$label.PHP_EOL;
}
function requestCheck($client, string $method, string $path, array $data = [], int $expected = 200) {
    global $base;
    $start = microtime(true);
    $response = $client->$method($base.$path, $data);
    verify($response->status() === $expected, $method.' '.$path.' HTTP '.$response->status().' ('.round((microtime(true)-$start)*1000).' ms server-side)');
    return $response;
}

$base = rtrim(config('app.url'), '/').'/api';
verify(app()->environment('production') && !config('app.debug'), 'Production mode with debug disabled');
foreach (['mobile_devices', 'mobile_reads'] as $table) verify(Schema::hasTable($table), $table.' migrated');
verify(Schema::hasColumn('direct_messages', 'delivered_at'), 'Delivery receipts migrated');
$teachers = Teacher::withCount('assignedClasses')->get();
echo json_encode([
    'teachers' => $teachers->count(),
    'teachers_with_classes' => $teachers->where('assigned_classes_count', '>', 0)->count(),
    'unassigned_teacher_profile_ids' => $teachers->where('assigned_classes_count', 0)->pluck('id')->values(),
    'queue_driver' => config('queue.default'),
    'firebase_server_configured' => (bool) config('services.firebase.credentials'),
    'registered_push_devices' => DB::table('mobile_devices')->count(),
    'failed_push_jobs' => DB::table('failed_jobs')->where('payload', 'like', '%SendMobilePush%')->count(),
], JSON_PRETTY_PRINT).PHP_EOL;
if (config('database.default') === 'sqlite') {
    verify(DB::selectOne('pragma integrity_check')->integrity_check === 'ok', 'Database integrity');
    verify(count(DB::select('pragma foreign_key_check')) === 0, 'Database foreign keys');
}

// Clean up the two isolated fixture accounts left by the initial cleanup ordering.
// Match both fixed IDs and the fixture account markers before deleting anything.
foreach (User::whereIn('id', [33, 34])->where('account_uid', 'like', 'verify_%')->whereIn('name', ['Deployment check teacher', 'Deployment check parent'])->get() as $fixture) {
    DB::transaction(function () use ($fixture) {
        DB::table('sos_alerts')->where('teacher_id', $fixture->id)->where('message', 'Temporary notification deletion check')->delete();
        $fixture->delete();
    });
    echo 'Removed previous temporary fixture account '.$fixture->id.PHP_EOL;
}

$school = $teacherUser = $parent = $student = null;
try {
    [$school, $teacherUser, $parent, $student] = DB::transaction(function () {
        $tag = (string) Str::uuid();
        $school = School::create(['name' => 'Temporary deployment verification '.$tag, 'type' => 'primary']);
        $class = SchoolClass::create(['school_id' => $school->id, 'grade' => '1', 'class_name' => 'Verification']);
        $teacherUser = User::create(['name' => 'Deployment check teacher', 'role' => 'teacher', 'account_uid' => 'verify_teacher_'.$tag]);
        $parent = User::create(['name' => 'Deployment check parent', 'role' => 'guardian', 'account_uid' => 'verify_parent_'.$tag]);
        Teacher::create(['user_id' => $teacherUser->id, 'school_id' => $school->id])->assignedClasses()->attach($class->id);
        $student = Student::create(['name' => 'Deployment check learner', 'school_id' => $school->id, 'grade' => '1', 'class_name' => 'Verification']);
        $student->feeAccount()->create(['balance_usd' => 0, 'balance_zig' => 0]);
        Subscription::create(['student_id' => $student->id, 'status' => 'active', 'start_date' => now()->toDateString()]);
        $parent->students()->attach($student->id);
        return [$school, $teacherUser, $parent, $student];
    });
    $teacherClient = Http::acceptJson()->timeout(20)->withToken($teacherUser->createToken('temporary-release-check')->plainTextToken);
    $parentClient = Http::acceptJson()->timeout(20)->withToken($parent->createToken('temporary-release-check')->plainTextToken);
    $date = now()->toDateString();
    $roster = requestCheck($teacherClient, 'get', '/attendance/roster', ['date' => $date]);
    verify($roster->json('roster.0.student_id') === $student->id && $roster->json('roster.0.marked') === false, 'Teacher sees assigned learner and unsaved register');
    foreach (['absent', 'present', 'late'] as $status) {
        requestCheck($teacherClient, 'post', '/attendance/mark', ['date' => $date, 'records' => [['student_id' => $student->id, 'status' => $status]]]);
        $roster = requestCheck($teacherClient, 'get', '/attendance/roster', ['date' => $date]);
        verify($roster->json('roster.0.marked') === true && $roster->json('roster.0.status') === $status, 'Teacher register saves '.$status);
        $history = requestCheck($parentClient, 'get', '/attendance/'.$student->id);
        verify(collect($history->json('attendance'))->contains('status', $status), 'Parent sees saved '.$status.' attendance');
    }
    verify(DB::table('attendance_records')->where('student_id', $student->id)->count() === 1, 'Register update replaces the day rather than duplicating it');
    requestCheck($parentClient, 'post', '/attendance/mark', ['date' => $date, 'records' => [['student_id' => $student->id, 'status' => 'present']]], 403);
    $realStudent = Student::where('school_id', '!=', $school->id)->first();
    if ($realStudent) requestCheck($teacherClient, 'post', '/attendance/mark', ['date' => $date, 'records' => [['student_id' => $realStudent->id, 'status' => 'present']]], 403);

    $image = base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aZx8AAAAASUVORK5CYII=');
    $upload = (clone $parentClient)->attach('photo', $image, 'verification.png')->post($base.'/students/'.$student->id.'/photo');
    verify($upload->ok() && (bool) $upload->json('photo_url'), 'Parent photo upload');
    $photo = $upload->json('photo_url');
    $roster = requestCheck($teacherClient, 'get', '/attendance/roster', ['date' => $date]);
    verify($roster->json('roster.0.photo_url') === $photo, 'Teacher register receives the parent photo');
    verify($teacherClient->get($photo)->ok(), 'Teacher can fetch protected student photo');

    requestCheck($teacherClient, 'post', '/messages', ['recipient_ids' => [$parent->id], 'body' => 'Temporary deployment verification'], 201);
    $sent = requestCheck($teacherClient, 'get', '/messages/contacts');
    verify(!$sent->json('contacts.0.last_message.delivered_at') && !$sent->json('contacts.0.last_message.read_at'), 'Sent receipt before recipient sync');
    $counts = requestCheck($parentClient, 'get', '/mobile-notifications/counts');
    verify($counts->json('counts.messages') === 1, 'Unread message badge increments');
    $contacts = requestCheck($teacherClient, 'get', '/messages/contacts');
    verify((bool) $contacts->json('contacts.0.last_message.delivered_at') && !$contacts->json('contacts.0.last_message.read_at'), 'Message delivered receipt');
    requestCheck($parentClient, 'get', '/messages/with/'.$teacherUser->id);
    $contacts = requestCheck($teacherClient, 'get', '/messages/contacts');
    verify((bool) $contacts->json('contacts.0.last_message.read_at'), 'Message read receipt');
    $counts = requestCheck($parentClient, 'get', '/mobile-notifications/counts');
    verify($counts->json('counts.messages') === 0, 'Unread message badge clears after reading');

    requestCheck($parentClient, 'post', '/messages', ['recipient_ids' => [$teacherUser->id], 'body' => 'Temporary parent reply'], 201);
    $counts = requestCheck($teacherClient, 'get', '/mobile-notifications/counts');
    verify($counts->json('counts.messages') === 1, 'Parent reply reaches teacher unread badge');
    $thread = requestCheck($teacherClient, 'get', '/messages/with/'.$parent->id);
    verify(count($thread->json('messages')) === 2 && $thread->json('messages.1.from_me') === false, 'Two-way conversation history');
    $broadcast = requestCheck($teacherClient, 'post', '/messages', ['all_parents' => true, 'body' => 'Temporary class message'], 201);
    verify($broadcast->json('sent') === 1, 'Class broadcast reaches only linked test parent');
    requestCheck($parentClient, 'post', '/messages', ['all_parents' => true, 'body' => 'Not allowed'], 403);
    $outside = User::where('role', 'guardian')->whereKeyNot($parent->id)->first();
    if ($outside) {
        requestCheck($teacherClient, 'post', '/messages', ['recipient_ids' => [$outside->id], 'body' => 'Must not be sent'], 403);
        requestCheck($teacherClient, 'get', '/messages/with/'.$outside->id, [], 403);
    }

    $notice = requestCheck($teacherClient, 'post', '/announcements', ['title' => 'Temporary notice', 'content' => 'Verification only', 'audience_role' => 'guardian'], 201);
    $journal = requestCheck($teacherClient, 'post', '/journal', ['student_id' => $student->id, 'type' => 'text', 'caption' => 'Temporary journal verification'], 201);
    $counts = requestCheck($parentClient, 'get', '/mobile-notifications/counts');
    verify($counts->json('counts.notices') === 1 && $counts->json('counts.journal') === 1, 'Notice and journal unread badges increment');
    requestCheck($parentClient, 'post', '/mobile-notifications/read', ['category' => 'notices', 'ids' => [$notice->json('announcement.id')]]);
    requestCheck($parentClient, 'post', '/mobile-notifications/read', ['category' => 'journal', 'ids' => [$journal->json('data.id')]]);
    $counts = requestCheck($parentClient, 'get', '/mobile-notifications/counts');
    verify($counts->json('counts.notices') === 0 && $counts->json('counts.journal') === 0, 'Notice and journal badges clear after reading');

    $csv = requestCheck($teacherClient, 'get', '/attendance/export', ['date' => $date]);
    verify(str_contains($csv->body(), 'Deployment check learner') && str_contains($csv->body(), 'late'), 'Saved CSV export contains learner and saved status');
    requestCheck($parentClient, 'get', '/attendance/export', ['date' => $date], 403);
    $thread = requestCheck($teacherClient, 'get', '/messages/with/'.$parent->id);
    $ids = collect($thread->json('messages'))->pluck('id')->take(2)->all();
    requestCheck($teacherClient, 'delete', '/messages/with/'.$parent->id, ['ids' => $ids]);
    $remaining = requestCheck($teacherClient, 'get', '/messages/with/'.$parent->id);
    verify(count($remaining->json('messages')) === 1, 'Selected bulk deletion hides only chosen messages');
    $other = requestCheck($parentClient, 'get', '/messages/with/'.$teacherUser->id);
    verify(count($other->json('messages')) === 3, 'Deletion preserves other participant copies');
    requestCheck($teacherClient, 'delete', '/messages/with/'.$parent->id, ['all' => true]);
    $remaining = requestCheck($teacherClient, 'get', '/messages/with/'.$parent->id);
    verify(count($remaining->json('messages')) === 0, 'Clear conversation removes all messages for caller');

    $notice = \App\Models\Announcement::create(['school_id' => $school->id, 'title' => 'Temporary shared notification', 'content' => 'Deletion check', 'audience_role' => 'all']);
    $payload = ['items' => [['category' => 'notices', 'id' => $notice->id]]];
    requestCheck($teacherClient, 'delete', '/mobile-notifications', $payload);
    $remaining = requestCheck($teacherClient, 'get', '/announcements');
    verify(!collect($remaining->json('announcements'))->contains('id', $notice->id), 'Teacher notification stays deleted on refresh');
    $remaining = requestCheck($parentClient, 'get', '/announcements');
    verify(collect($remaining->json('announcements'))->contains('id', $notice->id), 'Teacher deletion preserves parent copy');
    $alert = DB::table('sos_alerts')->insertGetId(['teacher_id' => $teacherUser->id, 'request_id' => (string) Str::uuid(), 'message' => 'Temporary notification deletion check', 'created_at' => now(), 'updated_at' => now()]);
    DB::table('sos_recipients')->insert(['sos_alert_id' => $alert, 'guardian_id' => $parent->id]);
    requestCheck($parentClient, 'delete', '/mobile-notifications', ['items' => [['category' => 'notices', 'id' => $notice->id], ['category' => 'sos', 'id' => $alert]]]);
    $remaining = requestCheck($parentClient, 'get', '/announcements');
    verify(!collect($remaining->json('announcements'))->contains('id', $notice->id), 'Parent notification stays deleted on refresh');
    requestCheck($parentClient, 'get', '/sos/history')->json('alerts');
    verify(!collect(requestCheck($parentClient, 'get', '/sos')->json('alerts'))->contains('id', $alert), 'Dismissed SOS does not reappear as an alarm');
    verify(DB::table('announcements')->where('id', $notice->id)->exists(), 'Original school announcement retained');
} finally {
    if ($student) {
        $path = $student->fresh()?->photo_path;
        if ($path) Storage::disk('local')->delete($path);
        $student->delete();
    }
    if ($school) $school->delete();
    if ($teacherUser) {
        DB::table('sos_alerts')->where('teacher_id', $teacherUser->id)->where('message', 'Temporary notification deletion check')->delete();
        $teacherUser->delete();
    }
    if ($parent) $parent->delete();
    echo 'Temporary verification school, learner, accounts, photo, attendance, messages and tokens removed.'.PHP_EOL;
}
echo 'LIVE NOTIFICATION DELETION VERIFICATION PASSED'.PHP_EOL;

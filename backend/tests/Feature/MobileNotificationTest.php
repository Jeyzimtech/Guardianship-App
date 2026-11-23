<?php

namespace Tests\Feature;

use App\Jobs\SendMobilePush;
use App\Models\{Announcement, JournalEntry, School, SchoolClass, Student, Teacher, User};
use App\Services\FirebasePush;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\{DB, Queue};
use Tests\TestCase;

class MobileNotificationTest extends TestCase
{
    use RefreshDatabase;

    private function classroom(): array
    {
        Queue::fake();
        $school = School::create(['name' => 'School', 'type' => 'primary']);
        $class = SchoolClass::create(['school_id' => $school->id, 'grade' => '1', 'class_name' => 'Blue']);
        $teacher = User::factory()->create(['role' => 'teacher']);
        Teacher::create(['user_id' => $teacher->id, 'school_id' => $school->id])->assignedClasses()->attach($class->id);
        $parent = User::factory()->create(['role' => 'guardian']);
        $other = User::factory()->create(['role' => 'guardian']);
        $student = Student::create(['school_id' => $school->id, 'grade' => '1', 'class_name' => 'Blue', 'name' => 'Child']);
        $parent->students()->attach($student->id);
        return [$school, $teacher, $parent, $other, $student];
    }

    public function test_retired_wellbeing_is_rejected_and_hidden_from_feeds_and_badges(): void
    {
        [$school, $teacher, $parent, $other, $student] = $this->classroom();
        $this->actingAs($teacher)->postJson('/api/journal', ['student_id' => $student->id, 'type' => 'wellbeing', 'wellbeing_data' => ['nap' => '30 minutes']])->assertUnprocessable();
        $this->postJson('/api/journal', ['student_id' => $student->id, 'type' => 'text', 'wellbeing_data' => ['mood' => 'happy']])->assertUnprocessable();
        $old = JournalEntry::create(['student_id' => $student->id, 'author_id' => $teacher->id, 'type' => 'wellbeing', 'caption' => 'Retired private entry']);
        $this->actingAs($teacher)->getJson('/api/journal')->assertOk()->assertJsonCount(0, 'entries');
        $this->actingAs($parent);
        $this->getJson('/api/journal/'.$student->id)->assertOk()->assertJsonCount(0, 'data.entries');
        $this->getJson('/api/mobile-notifications/counts')->assertOk()->assertJsonPath('counts.journal', 0);
        $this->assertDatabaseHas('journal_entries', ['id' => $old->id]);
    }

    public function test_badges_are_scoped_and_read_receipts_are_per_user(): void
    {
        [$school, $teacher, $parent, $other, $student] = $this->classroom();
        $notice = Announcement::create(['school_id' => $school->id, 'title' => 'Hello', 'content' => 'Welcome', 'audience_role' => 'guardian', 'author_id' => $teacher->id]);
        Announcement::create(['school_id' => $school->id, 'title' => 'Other class', 'content' => 'Private', 'audience_role' => 'all', 'grade' => '2', 'class_name' => 'Blue']);
        $entry = JournalEntry::create(['student_id' => $student->id, 'author_id' => $teacher->id, 'type' => 'text', 'caption' => 'Great work']);
        $this->actingAs($teacher)->postJson('/api/messages', ['recipient_ids' => [$parent->id], 'body' => 'Hi'])->assertCreated();
        Queue::assertPushed(SendMobilePush::class, fn ($job) => $job->category === 'messages');
        $this->actingAs($parent)->getJson('/api/mobile-notifications/counts')->assertOk()->assertJsonPath('counts', ['notices' => 1, 'journal' => 1, 'messages' => 1]);
        $this->postJson('/api/mobile-notifications/read', ['category' => 'journal', 'ids' => [$entry->id]])->assertOk();
        $this->postJson('/api/mobile-notifications/read', ['category' => 'notices', 'ids' => [$notice->id]])->assertOk();
        $this->getJson('/api/mobile-notifications/counts')->assertJsonPath('counts.journal', 0)->assertJsonPath('counts.notices', 0)->assertJsonPath('counts.messages', 1);
        $this->getJson('/api/messages/with/'.$teacher->id)->assertOk();
        $this->getJson('/api/mobile-notifications/counts')->assertJsonPath('counts.messages', 0);
        $this->actingAs($other)->getJson('/api/mobile-notifications/counts')->assertJsonPath('counts', ['notices' => 0, 'journal' => 0, 'messages' => 0]);
        $this->postJson('/api/mobile-notifications/read', ['category' => 'journal', 'ids' => [$entry->id]])->assertOk();
        $this->assertDatabaseMissing('mobile_reads', ['user_id' => $other->id, 'item_id' => $entry->id]);
    }

    public function test_devices_transfer_ownership_and_cannot_be_deleted_by_another_account(): void
    {
        [, , $parent, $other] = $this->classroom();
        $this->actingAs($parent)->postJson('/api/mobile-notifications/device', ['token' => 'device-token'])->assertOk();
        $this->actingAs($other)->deleteJson('/api/mobile-notifications/device', ['token' => 'device-token'])->assertOk();
        $this->assertDatabaseHas('mobile_devices', ['user_id' => $parent->id, 'token' => 'device-token']);
        $this->postJson('/api/mobile-notifications/device', ['token' => 'device-token'])->assertOk();
        $this->assertDatabaseCount('mobile_devices', 1);
        $this->assertDatabaseHas('mobile_devices', ['user_id' => $other->id]);
    }

    public function test_push_rechecks_visibility_and_does_not_send_read_updates(): void
    {
        [$school, $teacher, $parent, $other] = $this->classroom();
        config(['services.firebase.credentials' => 'configured']);
        foreach ([$parent, $other] as $user) DB::table('mobile_devices')->insert(['user_id' => $user->id, 'token' => 'token-'.$user->id]);
        $notice = Announcement::create(['school_id' => $school->id, 'title' => 'Hi', 'content' => 'Hello', 'audience_role' => 'guardian', 'author_id' => $teacher->id]);
        $push = $this->mock(FirebasePush::class);
        $push->shouldReceive('send')->once()->withArgs(fn ($device, $title, $category, $id, $studentId) => $device->user_id === $parent->id && $category === 'notices' && $id === $notice->id);
        $job = new SendMobilePush('notices', $notice->id, $parent->id);
        (new SendMobilePush('notices', $notice->id))->handle(app(\App\Services\MobileUpdates::class), $push);
        Queue::assertPushed(SendMobilePush::class, fn ($job) => $job->userId === $parent->id);
        Queue::assertNotPushed(SendMobilePush::class, fn ($job) => $job->userId === $other->id);
        $job->handle(app(\App\Services\MobileUpdates::class), $push);
        (new SendMobilePush('notices', $notice->id, $other->id))->handle(app(\App\Services\MobileUpdates::class), $push);
        $this->actingAs($parent)->postJson('/api/mobile-notifications/read', ['category' => 'notices', 'ids' => [$notice->id]])->assertOk();
        $job->handle(app(\App\Services\MobileUpdates::class), $push);
    }

    public function test_revoking_a_session_removes_its_push_device(): void
    {
        [, , $parent] = $this->classroom();
        $token = $parent->createToken('mobile');
        $this->withToken($token->plainTextToken)->postJson('/api/mobile-notifications/device', ['token' => 'signed-in-device'])->assertOk();
        $this->assertDatabaseHas('mobile_devices', ['access_token_id' => $token->accessToken->id]);
        $token->accessToken->delete();
        $this->assertDatabaseMissing('mobile_devices', ['token' => 'signed-in-device']);
    }

    public function test_teachers_and_parents_delete_notifications_only_for_themselves(): void
    {
        [$school, $teacher, $parent, $other] = $this->classroom();
        $notice = Announcement::create(['school_id' => $school->id, 'title' => 'Shared', 'content' => 'School update', 'audience_role' => 'all']);
        $payload = ['items' => [['category' => 'notices', 'id' => $notice->id]]];
        $this->actingAs($parent)->getJson('/api/mobile-notifications/counts')->assertJsonPath('counts.notices', 1);
        $this->deleteJson('/api/mobile-notifications', $payload)->assertOk();
        $this->deleteJson('/api/mobile-notifications', $payload)->assertOk();
        $this->getJson('/api/announcements')->assertJsonCount(0, 'announcements');
        $this->getJson('/api/mobile-notifications/counts')->assertJsonPath('counts.notices', 0);
        $this->actingAs($teacher)->getJson('/api/announcements')->assertJsonCount(1, 'announcements');
        $this->deleteJson('/api/mobile-notifications', $payload)->assertOk();
        $this->getJson('/api/announcements')->assertJsonCount(0, 'announcements');
        $this->actingAs($other)->deleteJson('/api/mobile-notifications', $payload)->assertForbidden();
        $this->assertDatabaseHas('announcements', ['id' => $notice->id]);
        $this->assertDatabaseCount('mobile_dismissals', 2);
    }

    public function test_mixed_sos_and_notice_bulk_deletion_is_scoped_and_atomic(): void
    {
        [$school, $teacher, $parent, $other] = $this->classroom();
        $notice = Announcement::create(['school_id' => $school->id, 'title' => 'Shared', 'content' => 'Update', 'audience_role' => 'all']);
        $alert = DB::table('sos_alerts')->insertGetId(['teacher_id' => $teacher->id, 'request_id' => (string) \Illuminate\Support\Str::uuid(), 'message' => 'Emergency', 'created_at' => now(), 'updated_at' => now()]);
        foreach ([$parent, $other] as $user) DB::table('sos_recipients')->insert(['sos_alert_id' => $alert, 'guardian_id' => $user->id]);
        $payload = ['items' => [['category' => 'notices', 'id' => $notice->id], ['category' => 'sos', 'id' => $alert]]];
        $this->actingAs($teacher)->deleteJson('/api/mobile-notifications', $payload)->assertForbidden();
        $this->assertDatabaseCount('mobile_dismissals', 0);
        $this->actingAs($parent)->deleteJson('/api/mobile-notifications', $payload)->assertOk();
        $this->getJson('/api/sos')->assertJsonCount(0, 'alerts');
        $this->getJson('/api/sos/history')->assertJsonCount(0, 'alerts');
        $this->getJson('/api/announcements')->assertJsonCount(0, 'announcements');
        $this->actingAs($other)->getJson('/api/sos')->assertJsonCount(1, 'alerts');
        $this->getJson('/api/sos/history')->assertJsonCount(1, 'alerts');
        $this->assertDatabaseHas('sos_alerts', ['id' => $alert]);
    }
}

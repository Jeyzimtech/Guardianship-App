<?php

namespace Tests\Feature;

use App\Models\{School, SchoolClass, Student, Teacher, User};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class DirectMessageTest extends TestCase
{
    use RefreshDatabase;

    private function user(string $name, string $role): User
    {
        return User::create(['name' => $name, 'role' => $role, 'phone_number' => '07'.random_int(10000000, 99999999), 'account_uid' => (string) Str::uuid()]);
    }

    /** Teacher of Grade 1 Blue with two linked parents, plus a parent in another class. */
    private function classroom(): array
    {
        $school = School::create(['name' => 'School', 'type' => 'primary']);
        $blue = SchoolClass::create(['school_id' => $school->id, 'grade' => 'Grade 1', 'class_name' => 'Blue']);
        SchoolClass::create(['school_id' => $school->id, 'grade' => 'Grade 2', 'class_name' => 'Red']);
        $teacher = $this->user('Teacher', 'teacher');
        Teacher::create(['user_id' => $teacher->id, 'school_id' => $school->id])->assignedClasses()->attach($blue->id);
        $parents = [];
        foreach (['Ann' => 'Blue', 'Ben' => 'Blue', 'Cat' => 'Red'] as $name => $class) {
            $student = Student::create(['name' => "$name Child", 'school_id' => $school->id, 'grade' => $class === 'Blue' ? 'Grade 1' : 'Grade 2', 'class_name' => $class]);
            $parent = $this->user("$name Parent", 'guardian');
            $parent->students()->attach($student->id);
            $parents[] = $parent;
        }
        return [$teacher, ...$parents];
    }

    public function test_teacher_sees_only_parents_of_assigned_classes(): void
    {
        [$teacher, $ann, $ben, $cat] = $this->classroom();
        $ids = collect($this->actingAs($teacher)->getJson('/api/messages/contacts')->assertOk()->json('contacts'))->pluck('id');
        $this->assertEqualsCanonicalizing([$ann->id, $ben->id], $ids->all());
    }

    public function test_teacher_messages_one_parent_and_parent_replies(): void
    {
        [$teacher, $ann, $ben] = $this->classroom();
        $this->actingAs($teacher)->postJson('/api/messages', ['recipient_ids' => [$ann->id], 'body' => 'Ann did well today.'])
            ->assertCreated()->assertJsonPath('sent', 1);
        $this->assertDatabaseMissing('direct_messages', ['recipient_id' => $ben->id]);

        $contact = collect($this->actingAs($ann)->getJson('/api/messages/contacts')->assertOk()->json('contacts'))->firstWhere('id', $teacher->id);
        $this->assertSame(1, $contact['unread']);
        $this->getJson("/api/messages/with/{$teacher->id}")->assertOk()->assertJsonPath('messages.0.body', 'Ann did well today.')->assertJsonPath('messages.0.from_me', false);
        $this->assertNotNull(DB::table('direct_messages')->value('read_at'));
        $this->postJson('/api/messages', ['recipient_ids' => [$teacher->id], 'body' => 'Thank you!'])->assertCreated();
        $this->actingAs($teacher)->getJson("/api/messages/with/{$ann->id}")->assertJsonCount(2, 'messages')->assertJsonPath('messages.1.body', 'Thank you!');
    }

    public function test_teacher_messages_all_parents_at_once(): void
    {
        [$teacher, $ann, $ben, $cat] = $this->classroom();
        $this->actingAs($teacher)->postJson('/api/messages', ['all_parents' => true, 'body' => 'Sports day is Friday.'])
            ->assertCreated()->assertJsonPath('sent', 2);
        $this->assertEqualsCanonicalizing([$ann->id, $ben->id], DB::table('direct_messages')->pluck('recipient_id')->all());
    }

    public function test_messages_outside_the_class_are_refused(): void
    {
        [$teacher, $ann, , $cat] = $this->classroom();
        $this->actingAs($teacher)->postJson('/api/messages', ['recipient_ids' => [$cat->id], 'body' => 'Hi'])->assertForbidden();
        $this->getJson("/api/messages/with/{$cat->id}")->assertForbidden();
        $this->actingAs($cat)->postJson('/api/messages', ['recipient_ids' => [$teacher->id], 'body' => 'Hi'])->assertForbidden();
        $this->actingAs($ann)->postJson('/api/messages', ['all_parents' => true, 'body' => 'Hi'])->assertForbidden();
        $this->assertDatabaseCount('direct_messages', 0);
    }

    public function test_receipts_progress_from_sent_to_delivered_to_read_per_recipient(): void
    {
        [$teacher, $ann, $ben] = $this->classroom();
        $this->actingAs($teacher)->postJson('/api/messages', ['all_parents' => true, 'body' => 'Hello'])->assertCreated();
        $this->getJson('/api/messages/with/'.$ann->id)->assertOk()
            ->assertJsonPath('messages.0.delivered_at', null)->assertJsonPath('messages.0.read_at', null);

        // Being online acknowledges delivery; it does not mean opening the chat.
        $this->actingAs($ann)->getJson('/api/mobile-notifications/counts')->assertOk()->assertJsonPath('counts.messages', 1);
        $delivered = DB::table('direct_messages')->where('recipient_id', $ann->id)->value('delivered_at');
        $this->assertNotNull($delivered);
        $this->assertDatabaseHas('direct_messages', ['recipient_id' => $ann->id, 'read_at' => null]);
        $this->assertDatabaseHas('direct_messages', ['recipient_id' => $ben->id, 'delivered_at' => null, 'read_at' => null]);
        $this->actingAs($teacher)->getJson('/api/messages/with/'.$ann->id)
            ->assertJsonPath('messages.0.delivered_at', $delivered)->assertJsonPath('messages.0.read_at', null);

        $this->actingAs($ann)->getJson('/api/messages/with/'.$teacher->id)->assertOk();
        $read = DB::table('direct_messages')->where('recipient_id', $ann->id)->value('read_at');
        $this->assertNotNull($read);
        $last = collect($this->actingAs($teacher)->getJson('/api/messages/contacts')->assertOk()->json('contacts'))->firstWhere('id', $ann->id)['last_message'];
        $this->assertSame($delivered, $last['delivered_at']);
        $this->assertSame($read, $last['read_at']);
        $this->assertTrue($last['from_me']);
        $this->actingAs($ann)->getJson('/api/messages/contacts')->assertOk();
        $this->assertSame($delivered, DB::table('direct_messages')->where('recipient_id', $ann->id)->value('delivered_at'));
    }

    public function test_contact_summaries_use_two_message_selects_and_keep_threads_separate(): void
    {
        [$teacher, $ann, $ben] = $this->classroom();
        $this->actingAs($teacher)->postJson('/api/messages', ['all_parents' => true, 'body' => 'For both families'])->assertCreated();
        $this->actingAs($ann)->postJson('/api/messages', ['recipient_ids' => [$teacher->id], 'body' => 'Ann reply'])->assertCreated();
        DB::enableQueryLog();
        DB::flushQueryLog();
        $contacts = collect($this->actingAs($teacher)->getJson('/api/messages/contacts')->assertOk()->assertJsonPath('unread_total', 1)->json('contacts'));
        $selects = collect(DB::getQueryLog())->filter(fn ($query) => str_starts_with(strtolower($query['query']), 'select') && str_contains($query['query'], 'direct_messages'));
        DB::disableQueryLog();
        $this->assertCount(2, $selects);
        $this->assertSame('Ann reply', $contacts->firstWhere('id', $ann->id)['last_message']['body']);
        $this->assertFalse($contacts->firstWhere('id', $ann->id)['last_message']['from_me']);
        $this->assertSame(1, $contacts->firstWhere('id', $ann->id)['unread']);
        $this->assertSame('For both families', $contacts->firstWhere('id', $ben->id)['last_message']['body']);
        $this->assertSame(0, $contacts->firstWhere('id', $ben->id)['unread']);
    }

    public function test_deletion_is_private_and_scoped(): void
    {
        [$teacher, $ann, $ben] = $this->classroom();
        $this->actingAs($teacher)->postJson('/api/messages', ['all_parents' => true, 'body' => 'Hello'])->assertCreated();
        $a = DB::table('direct_messages')->where('recipient_id', $ann->id)->value('id');
        $b = DB::table('direct_messages')->where('recipient_id', $ben->id)->value('id');
        $this->deleteJson('/api/messages/with/'.$ann->id, ['ids' => [$a, $b]])->assertForbidden();
        $this->actingAs($ann)->deleteJson('/api/messages/with/'.$teacher->id, ['ids' => [$a]])->assertOk();
        $this->getJson('/api/messages/with/'.$teacher->id)->assertJsonCount(0, 'messages');
        $this->getJson('/api/mobile-notifications/counts')->assertJsonPath('counts.messages', 0);
        $this->actingAs($teacher)->getJson('/api/messages/with/'.$ann->id)->assertJsonCount(1, 'messages');
        $this->deleteJson('/api/messages/with/'.$ann->id, ['all' => true])->assertOk();
        $this->getJson('/api/messages/with/'.$ann->id)->assertJsonCount(0, 'messages');
        $this->getJson('/api/messages/with/'.$ben->id)->assertJsonCount(1, 'messages');
    }

    public function test_csv_contains_only_saved_authorized_records(): void
    {
        [$teacher, $ann, , $cat] = $this->classroom();
        $this->actingAs($teacher)->postJson('/api/attendance/mark', [
            'date' => '2026-10-20', 'records' => [['student_id' => $ann->students()->first()->id, 'status' => 'late']],
        ])->assertOk();
        $csv = $this->get('/api/attendance/export?date=2026-10-20')->assertOk()->streamedContent();
        $this->assertStringContainsString('Ann Child', $csv);
        $this->assertStringNotContainsString('Ben Child', $csv);
        $this->assertStringNotContainsString('Cat Child', $csv);
        $this->getJson('/api/attendance/export?date=2026-10-19')->assertUnprocessable();
        $this->actingAs($cat)->getJson('/api/attendance/export?date=2026-10-20')->assertForbidden();
    }

    public function test_blocking_is_enforced_in_both_directions_and_bulk_messages_skip_blocked_contacts(): void
    {
        [$teacher, $ann, $ben] = $this->classroom();
        $this->actingAs($ann)->postJson('/api/messages/block/'.$teacher->id)->assertOk();
        $this->getJson('/api/messages/with/'.$teacher->id)->assertOk()->assertJsonPath('blocked', true)->assertJsonPath('messaging_unavailable', true);
        $this->postJson('/api/messages', ['recipient_ids'=>[$teacher->id], 'body'=>'Blocked'])->assertForbidden();
        $this->actingAs($teacher)->postJson('/api/messages', ['recipient_ids'=>[$ann->id], 'body'=>'Blocked'])->assertForbidden();
        $this->postJson('/api/messages', ['all_parents'=>true, 'body'=>'Available families'])->assertCreated()->assertJsonPath('sent', 1);
        $this->assertDatabaseMissing('direct_messages', ['recipient_id'=>$ann->id]);
        $this->assertDatabaseHas('direct_messages', ['recipient_id'=>$ben->id]);
        $this->actingAs($ann)->deleteJson('/api/messages/block/'.$teacher->id)->assertOk();
        $this->postJson('/api/messages', ['recipient_ids'=>[$teacher->id], 'body'=>'Unblocked'])->assertCreated();
    }

    public function test_blocking_outside_class_is_rejected_and_blocks_hide_queued_notifications(): void
    {
        [$teacher, $ann, , $cat] = $this->classroom();
        $this->actingAs($teacher)->postJson('/api/messages/block/'.$cat->id)->assertForbidden();
        $this->postJson('/api/messages', ['recipient_ids'=>[$ann->id], 'body'=>'Before block'])->assertCreated();
        $this->actingAs($ann)->postJson('/api/messages/block/'.$teacher->id)->assertOk();
        $this->assertSame(0, (new \App\Services\MobileUpdates)->unread($ann, 'messages')->count());
        $this->actingAs($teacher)->deleteJson('/api/messages/block/'.$ann->id)->assertOk();
        $this->assertDatabaseHas('message_blocks', ['user_id'=>$ann->id, 'blocked_user_id'=>$teacher->id]);
    }
}

<?php
namespace Tests\Feature;

use App\Models\{User,School,SchoolClass,Teacher,Student,Assignment,FeeAccount,FeeTransaction,ReportDocument,Subscription,UniformItem};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;


class RoleBoundaryRegressionTest extends TestCase
{
    use RefreshDatabase;
    private function fixture(): array {
        $s=School::create(['name'=>'A','type'=>'primary']);
        $other=School::create(['name'=>'B','type'=>'primary']);
        $c=SchoolClass::create(['school_id'=>$s->id,'grade'=>'1','class_name'=>'Blue']);
        SchoolClass::create(['school_id'=>$s->id,'grade'=>'2','class_name'=>'Blue']);
        $a=Student::create(['school_id'=>$s->id,'name'=>'Own','grade'=>'1','class_name'=>'Blue']);
        $b=Student::create(['school_id'=>$s->id,'name'=>'Other grade','grade'=>'2','class_name'=>'Blue']);
        $foreign=Student::create(['school_id'=>$other->id,'name'=>'Other school','grade'=>'1','class_name'=>'Blue']);
        $t=User::create(['name'=>'Teacher','role'=>'teacher','phone_number'=>'t','account_uid'=>'t']);
        Teacher::create(['user_id'=>$t->id,'school_id'=>$s->id])->assignedClasses()->attach($c->id,['subject_name'=>'Mathematics']);
        $admin=User::create(['name'=>'Admin','role'=>'admin','phone_number'=>'a','account_uid'=>'a','school_id'=>$s->id]);
        $p=User::create(['name'=>'Parent','role'=>'guardian','phone_number'=>'p','account_uid'=>'p']);
        $p->students()->attach($a->id);
        return [$s,$other,$c,$a,$b,$foreign,$t,$admin,$p];
    }
    public function test_teacher_roster_excludes_same_class_name_in_other_grade(): void {
        [,,,,,,$t]=$this->fixture();
        $this->actingAs($t)->getJson('/api/attendance/roster')->assertOk()->assertJsonCount(1,'roster');
    }
    public function test_teacher_cannot_mark_other_grade_with_same_class_name(): void {
        [,,,,$b,,$t]=$this->fixture();
        $this->actingAs($t)->postJson('/api/attendance/mark',['date'=>'2026-10-16','records'=>[['student_id'=>$b->id,'status'=>'present']]])->assertForbidden();
    }
    public function test_teacher_notices_exclude_other_grade_parents(): void {
        [,,,,$b,,$t]=$this->fixture();
        $p=User::create(['name'=>'Other parent','role'=>'guardian','phone_number'=>'op','account_uid'=>'op']);
        $p->students()->attach($b->id);
        $this->actingAs($t)->postJson('/api/announcements',['title'=>'Private class notice','content'=>'Only grade 1','audience_role'=>'guardian'])->assertCreated();
        $this->actingAs($p)->getJson('/api/announcements')->assertOk()->assertJsonCount(0,'announcements');
    }
    public function test_admin_cannot_pay_fees_at_another_school(): void {
        [,,,,,$foreign,,$admin]=$this->fixture();
        FeeAccount::create(['student_id'=>$foreign->id,'balance_usd'=>100,'balance_zig'=>0]);
        $this->actingAs($admin)->postJson('/api/fees/pay',['student_id'=>$foreign->id,'amount'=>10,'currency'=>'USD','payment_method'=>'Card'])->assertForbidden();
    }
    public function test_guardian_payment_is_not_completed_without_provider_verification(): void {
        [,,,$child,,,,,$parent]=$this->fixture();
        FeeAccount::create(['student_id'=>$child->id,'balance_usd'=>100,'balance_zig'=>0]);
        $this->actingAs($parent)->postJson('/api/fees/pay',['student_id'=>$child->id,'amount'=>10,'currency'=>'USD','payment_method'=>'Card']);
        $this->assertSame(0,FeeTransaction::where('status','completed')->count(),'A payment must be verified before completion.');
    }
    public function test_legacy_assignments_do_not_cross_school_boundaries(): void {
        [,$other,,$child,,,,,$parent]=$this->fixture();
        $author=User::create(['name'=>'Other admin','role'=>'admin','phone_number'=>'oa','account_uid'=>'oa','school_id'=>$other->id]);
        Assignment::create(['title'=>'Other school work','grade_name'=>'1','due_date'=>'2027-01-01','created_by'=>$author->id]);
        $this->actingAs($parent)->getJson('/api/assignments/'.$child->id)->assertOk()->assertJsonCount(0,'data.all');
    }
    public function test_teacher_cannot_assign_an_unassigned_subject(): void {
        [,,$class,,,,$teacher]=$this->fixture();
        $this->actingAs($teacher)->postJson('/api/assignments',['title'=>'English task','school_class_id'=>$class->id,'subject_name'=>'English','due_date'=>'2027-01-01'])->assertForbidden();
    }
    public function test_direct_report_download_respects_child_subscription(): void {
        [,,,$child,,,$teacher,,$parent]=$this->fixture();
        $report=ReportDocument::create(['student_id'=>$child->id,'title'=>'Report','file_path'=>'/storage/reports/test.pdf','type'=>'report','uploaded_by'=>$teacher->id]);
        Subscription::create(['student_id'=>$child->id,'status'=>'inactive','start_date'=>now()->toDateString()]);
        $this->actingAs($parent)->getJson('/api/reports/'.$child->id)->assertForbidden();
        $this->getJson('/api/reports/download/'.$report->id)->assertForbidden();
    }
    public function test_admin_cannot_edit_another_schools_uniform(): void {
        [,$other,,,,,,$admin]=$this->fixture();
        $item=UniformItem::create(['school_id'=>$other->id,'name'=>'Other school uniform','price_usd'=>10]);
        $this->actingAs($admin)->putJson('/api/uniforms/'.$item->id,['name'=>'Unauthorized edit'])->assertForbidden();
    }
    public function test_admin_cannot_delete_another_schools_uniform(): void {
        [,$other,,,,,,$admin]=$this->fixture();
        $item=UniformItem::create(['school_id'=>$other->id,'name'=>'Other school uniform','price_usd'=>10]);
        $this->actingAs($admin)->deleteJson('/api/uniforms/'.$item->id)->assertForbidden();
    }

    public function test_fee_reference_requires_school_verification_and_credits_once(): void {
        [,,,$child,,,,$admin,$parent]=$this->fixture();
        $account=FeeAccount::create(['student_id'=>$child->id,'balance_usd'=>100,'balance_zig'=>0]);
        $payload=['student_id'=>$child->id,'amount'=>10,'currency'=>'USD','payment_method'=>'EcoCash','reference'=>'receipt-001'];
        $id=$this->actingAs($parent)->postJson('/api/fees/pay',$payload)->assertStatus(202)->assertJsonPath('transaction.status','pending')->json('transaction.id');
        $this->assertEquals(100,$account->fresh()->balance_usd);
        $this->postJson('/api/fees/pay',$payload)->assertUnprocessable();
        $this->postJson('/api/fees/payments/'.$id.'/verify',['confirmed'=>true])->assertForbidden();
        $this->actingAs($admin)->getJson('/api/fees/payments/pending')->assertJsonCount(1,'payments');
        $this->postJson('/api/fees/payments/'.$id.'/verify',['confirmed'=>true])->assertOk();
        $this->postJson('/api/fees/payments/'.$id.'/verify',['confirmed'=>true])->assertOk();
        $this->assertEquals(90,$account->fresh()->balance_usd);
        $this->assertSame($admin->id,FeeTransaction::find($id)->verified_by);
    }

    public function test_other_school_admin_cannot_verify_payment(): void {
        [,$other,,$child,,,,,$parent]=$this->fixture();
        FeeAccount::create(['student_id'=>$child->id,'balance_usd'=>100,'balance_zig'=>0]);
        $id=$this->actingAs($parent)->postJson('/api/fees/pay',['student_id'=>$child->id,'amount'=>10,'currency'=>'USD','payment_method'=>'Card','reference'=>'receipt-002'])->assertStatus(202)->json('transaction.id');
        $admin=User::create(['name'=>'Foreign admin','role'=>'admin','school_id'=>$other->id,'phone_number'=>'foreign','account_uid'=>'foreign']);
        $this->actingAs($admin)->getJson('/api/fees/payments/pending')->assertJsonCount(0,'payments');
        $this->postJson('/api/fees/payments/'.$id.'/verify',['confirmed'=>true])->assertForbidden();
    }

    public function test_uniform_reference_stays_pending_until_school_verifies(): void {
        [,,,$child,,,,$admin,$parent]=$this->fixture();
        $order=\App\Models\UniformOrder::create(['student_id'=>$child->id,'items'=>[],'total_amount'=>10,'currency'=>'USD','payment_status'=>'pending']);
        $this->actingAs($parent)->postJson('/api/uniform-orders/'.$order->id.'/payment-reference',['payment_reference'=>'uniform-receipt','payment_method'=>'EcoCash'])->assertStatus(202);
        $this->assertSame('pending',$order->fresh()->payment_status);
        $this->postJson('/api/uniform-orders/'.$order->id.'/verify-payment',['confirmed'=>true])->assertForbidden();
        $this->actingAs($admin)->postJson('/api/uniform-orders/'.$order->id.'/verify-payment',['confirmed'=>true])->assertOk();
        $this->assertSame('paid',$order->fresh()->payment_status);
    }

    public function test_uploaded_reports_are_private_and_signed_links_recheck_subscription(): void {
        [,,,$child,,,$teacher,,$parent]=$this->fixture();
        \Illuminate\Support\Facades\Storage::fake('local');
        $id=$this->actingAs($teacher)->postJson('/api/reports/upload',[
            'student_id'=>$child->id,'title'=>'Term report','type'=>'report',
            'file'=>\Illuminate\Http\UploadedFile::fake()->create('report.pdf',10,'application/pdf'),
        ])->assertCreated()->json('report.id');
        $report=ReportDocument::find($id);
        $this->assertStringStartsWith('private:reports/',$report->file_path);
        $url=$this->actingAs($parent)->getJson('/api/reports/download/'.$id)->assertOk()->json('download_url');
        $this->get($url)->assertOk();
        $this->get($url.'&viewer='.$teacher->id)->assertForbidden();
        Subscription::create(['student_id'=>$child->id,'status'=>'inactive','start_date'=>now()->toDateString()]);
        $this->get($url)->assertForbidden();
    }

    public function test_mobile_journal_file_is_saved_and_missing_report_file_is_rejected(): void {
        [,,,$child,,,$teacher]=$this->fixture();
        \Illuminate\Support\Facades\Storage::fake('public');
        $this->actingAs($teacher)->postJson('/api/journal',[
            'student_id'=>$child->id,'type'=>'photo','caption'=>'Work sample','subject_name'=>'Mathematics',
            'file'=>\Illuminate\Http\UploadedFile::fake()->createWithContent('sample.png',base64_decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jZhoAAAAASUVORK5CYII=')),
        ])->assertCreated()->assertJsonPath('data.media_url',fn($url)=>str_contains($url,'/storage/journal/'));
        $this->postJson('/api/reports/upload',['student_id'=>$child->id,'title'=>'Missing file','type'=>'report'])->assertUnprocessable();
    }
}

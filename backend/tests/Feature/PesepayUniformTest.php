<?php
namespace Tests\Feature;
use App\Models\{School,Student,User,UniformOrder,UniformPayment};
use App\Services\Pesepay;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\{Http,Queue};
use Tests\TestCase;

class PesepayUniformTest extends TestCase {
    use RefreshDatabase;
    private function fixture(): array {
        config(['services.pesepay.integration_key'=>'test-integration','services.pesepay.encryption_key'=>'12345678901234567890123456789012','services.pesepay.sandbox'=>true]);
        Http::preventStrayRequests();
        $school=School::create(['name'=>'Test school','type'=>'primary']);
        $child=Student::create(['school_id'=>$school->id,'name'=>'Child','grade'=>'1','class_name'=>'Blue']);
        $parent=User::create(['name'=>'Parent','role'=>'guardian','account_uid'=>'parent','phone_number'=>'parent']);
        $parent->students()->attach($child->id);
        $order=UniformOrder::create(['student_id'=>$child->id,'items'=>[],'total_amount'=>2,'currency'=>'USD','payment_status'=>'pending']);
        return [$parent,$order,$school];
    }
    private function response(array $data) { return Http::response(['payload'=>app(Pesepay::class)->encrypt($data)]); }
    private function attempt(UniformOrder $order): UniformPayment {
        return UniformPayment::create(['uniform_order_id'=>$order->id,'reference'=>'sandbox-ref','redirect_url'=>'https://sandbox.pesepay.com/checkout/test','status'=>'INITIATED','sandbox'=>true]);
    }
    private function providerResult(string $status='SUCCESS',float $amount=2,string $currency='USD'): array {
        return ['referenceNumber'=>'sandbox-ref','transactionStatus'=>$status,'amountDetails'=>['amount'=>$amount,'currencyCode'=>$currency]];
    }
    public function test_checkout_encrypts_server_amount_and_reuses_pending_transaction(): void {
        [$parent,$order]=$this->fixture();
        Http::fake(['*/payments/initiate'=>$this->response(['referenceNumber'=>'sandbox-ref','redirectUrl'=>'https://pesepay-payments-sandbox-test.web.app/checkout/test'])]);
        $this->actingAs($parent)->postJson('/api/uniform-orders/'.$order->id.'/checkout',['amount'=>0.01])->assertOk()->assertJsonPath('sandbox',true);
        $this->postJson('/api/uniform-orders/'.$order->id.'/checkout')->assertOk();
        Http::assertSentCount(1);
        Http::assertSent(function($request) {
            $data=app(Pesepay::class)->decrypt($request['payload']);
            return $data['amountDetails']['amount']==2 && $request->hasHeader('authorization','test-integration') && str_contains($request->url(),'api.test.sandbox.pesepay.com');
        });
        $this->assertSame('pending',$order->fresh()->payment_status);
    }
    public function test_verified_success_is_idempotent(): void {
        [$parent,$order]=$this->fixture(); $this->attempt($order);
        Http::fake(['*/payments/check-payment*'=>$this->response($this->providerResult())]);
        $this->actingAs($parent)->getJson('/api/uniform-orders/'.$order->id.'/payment-status')->assertOk()->assertJsonPath('payment_status','paid');
        $this->getJson('/api/uniform-orders/'.$order->id.'/payment-status')->assertOk();
        $this->assertSame('PesePay',$order->fresh()->payment_method);
        $this->assertDatabaseCount('uniform_payments',1);
    }
    public function test_failed_partial_and_cancelled_payments_do_not_mark_order_paid(): void {
        [$parent,$order]=$this->fixture(); $this->attempt($order);
        foreach(['FAILED','PARTIALLY_PAID','CANCELLED'] as $status) {
            Http::fake(['*/payments/check-payment*'=>$this->response($this->providerResult($status))]);
            $this->actingAs($parent)->getJson('/api/uniform-orders/'.$order->id.'/payment-status')->assertOk()->assertJsonPath('payment_status','pending');
        }
    }
    public function test_mismatched_amount_currency_or_reference_is_not_credited(): void {
        [$parent,$order]=$this->fixture(); $this->attempt($order);
        foreach([$this->providerResult('SUCCESS',1),$this->providerResult('SUCCESS',2,'ZiG'),array_replace($this->providerResult(),['referenceNumber'=>'foreign-ref'])] as $result) {
            Http::fake(['*/payments/check-payment*'=>$this->response($result)]);
            $this->actingAs($parent)->getJson('/api/uniform-orders/'.$order->id.'/payment-status')->assertStatus(502);
            $this->assertSame('pending',$order->fresh()->payment_status);
        }
    }
    public function test_unlinked_parent_and_teacher_cannot_start_or_check_payment(): void {
        [$parent,$order]=$this->fixture(); $parent->students()->detach();
        $this->actingAs($parent)->postJson('/api/uniform-orders/'.$order->id.'/checkout')->assertForbidden();
        $this->getJson('/api/uniform-orders/'.$order->id.'/payment-status')->assertForbidden();
        $parent->update(['role'=>'teacher']);
        $this->postJson('/api/uniform-orders/'.$order->id.'/checkout')->assertForbidden();
        Http::assertNothingSent();
    }
    public function test_callback_requires_key_and_queues_server_verification(): void {
        [$parent,$order]=$this->fixture(); $payment=$this->attempt($order); Queue::fake();
        $this->postJson('/api/payments/pesepay/result',['referenceNumber'=>'sandbox-ref','transactionStatus'=>'SUCCESS'])->assertUnauthorized();
        $this->withHeader('authorization','test-integration')->postJson('/api/payments/pesepay/result',['referenceNumber'=>'sandbox-ref','transactionStatus'=>'SUCCESS'])->assertOk();
        Queue::assertPushed(\App\Jobs\ReconcileUniformPayment::class,fn($job)=>$job->paymentId===$payment->id);
        $this->assertSame('pending',$order->fresh()->payment_status);
    }
    public function test_provider_error_is_safe_and_does_not_blindly_retry_creation(): void {
        [$parent,$order]=$this->fixture(); Http::fake(['*'=>Http::response(['error'=>'sensitive-provider-detail'],500)]);
        $this->actingAs($parent)->postJson('/api/uniform-orders/'.$order->id.'/checkout')->assertStatus(502)->assertDontSee('sensitive-provider-detail');
        $this->postJson('/api/uniform-orders/'.$order->id.'/checkout')->assertStatus(409);
        Http::assertSentCount(1);
    }
    public function test_manual_verification_cannot_override_a_gateway_payment(): void {
        [$parent,$order,$school]=$this->fixture(); $this->attempt($order);
        $this->actingAs($parent)->postJson('/api/uniform-orders/'.$order->id.'/payment-reference',['payment_reference'=>'fake','payment_method'=>'Card'])->assertUnprocessable();
        $admin=User::create(['name'=>'Admin','role'=>'admin','school_id'=>$school->id,'account_uid'=>'admin','phone_number'=>'admin']);
        $this->actingAs($admin)->postJson('/api/uniform-orders/'.$order->id.'/verify-payment',['confirmed'=>true])->assertUnprocessable();
    }
    public function test_test_catalog_command_is_repeatable_and_school_scoped(): void {
        [,,$school]=$this->fixture();
        $this->artisan('uniforms:seed-payment-test',['school'=>$school->id])->assertSuccessful();
        $this->artisan('uniforms:seed-payment-test',['school'=>$school->id])->assertSuccessful();
        $this->assertDatabaseCount('uniform_items',2);
        $this->assertDatabaseHas('uniform_items',['school_id'=>$school->id,'item_code'=>'TEST-PESEPAY-SHIRT','price_usd'=>1]);
    }
}

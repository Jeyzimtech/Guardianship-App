<?php
// Sandbox-only gateway smoke check. No real customer information or money is used.
require 'vendor/autoload.php';
$app=require 'bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
use Illuminate\Support\Facades\{Http,DB};
$gateway=app(App\Services\Pesepay::class);
echo 'CONFIGURED='.($gateway->configured()?'yes':'no').PHP_EOL;
echo 'SANDBOX='.(config('services.pesepay.sandbox')?'yes':'no').PHP_EOL;
if (!$gateway->configured() || !config('services.pesepay.sandbox')) exit(1);
echo 'TEST_UNIFORMS='.App\Models\UniformItem::whereIn('item_code',['TEST-PESEPAY-SHIRT','TEST-PESEPAY-JERSEY'])->count().PHP_EOL;
echo 'DATABASE_INTEGRITY='.json_encode(DB::select('PRAGMA integrity_check')).PHP_EOL;
echo 'FOREIGN_KEY_VIOLATIONS='.count(DB::select('PRAGMA foreign_key_check')).PHP_EOL;
echo 'QUEUE='.config('queue.default').PHP_EOL;
$base=rtrim(config('app.url'),'/');
echo 'HEALTH_HTTP='.Http::get($base.'/api/health')->status().PHP_EOL;
echo 'REMOVED_DELIVERY_ROUTE_HTTP='.Http::acceptJson()->post($base.'/api/delivery/quote')->status().PHP_EOL;
echo 'UNAUTHENTICATED_CALLBACK_HTTP='.Http::acceptJson()->post($base.'/api/payments/pesepay/result',['referenceNumber'=>'not-a-real-payment'])->status().PHP_EOL;
$client=Http::acceptJson()->asJson()->withHeaders(['authorization'=>config('services.pesepay.integration_key')])->connectTimeout(10)->timeout(30);
try {
    $response=$client->post($gateway->base().'/payments/initiate',['payload'=>$gateway->encrypt([
        'amountDetails'=>['amount'=>1.0,'currencyCode'=>'USD'],
        'reasonForPayment'=>'Uniform sandbox integration verification - no fulfillment',
        'resultUrl'=>$base.'/api/payments/pesepay/result','returnUrl'=>$base.'/payments/pesepay/return',
    ])]);
    echo 'INITIATE_HTTP='.$response->status().PHP_EOL;
    if (!$response->successful()) exit(2);
    $data=$gateway->decrypt($response->json('payload',''));
    echo 'DECRYPTED_REFERENCE_PRESENT='.(!empty($data['referenceNumber'])?'yes':'no').PHP_EOL;
    echo 'CHECKOUT_HOST='.parse_url($data['redirectUrl']??'',PHP_URL_HOST).PHP_EOL;
    $status=$client->get($gateway->base().'/payments/check-payment',['referenceNumber'=>$data['referenceNumber']]);
    echo 'CHECK_HTTP='.$status->status().PHP_EOL;
    if (!$status->successful()) exit(3);
    $result=$gateway->decrypt($status->json('payload',''));
    echo 'GATEWAY_STATUS='.($result['transactionStatus']??'missing').PHP_EOL;
    echo 'AMOUNT_MATCH='.(($result['amountDetails']['amount']??null)==1.0?'yes':'no').PHP_EOL;
    // Exercise the application's persisted checkout/status path, then remove only this probe order.
    $item=App\Models\UniformItem::where('item_code','TEST-PESEPAY-SHIRT')->firstOrFail();
    $child=App\Models\Student::where('school_id',$item->school_id)->firstOrFail();
    $probe=App\Models\UniformOrder::create(['student_id'=>$child->id,'items'=>[['name'=>'Temporary sandbox verification - no fulfillment']],'total_amount'=>1,'currency'=>'USD','payment_status'=>'pending']);
    try {
        $payment=$gateway->start($probe);
        echo 'APPLICATION_CHECKOUT='.($payment->reference && $payment->redirect_url?'ok':'failed').PHP_EOL;
        echo 'HOSTED_CHECKOUT_HTTP='.Http::timeout(20)->get($payment->redirect_url)->status().PHP_EOL;
        $payment=$gateway->reconcile($payment);
        echo 'APPLICATION_GATEWAY_STATUS='.$payment->status.PHP_EOL;
        echo 'UNPAID_ORDER_STATUS='.$probe->fresh()->payment_status.PHP_EOL;
    } finally {
        $probe->delete(); // Cascades only this temporary probe's payment records. Stock was untouched.
    }
} catch (\Throwable $e) {
    echo 'GATEWAY_CHECK_ERROR='.get_class($e).PHP_EOL;
    exit(4);
}

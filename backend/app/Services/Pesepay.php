<?php
namespace App\Services;

use App\Models\{UniformOrder,UniformPayment};
use Illuminate\Support\Facades\{DB,Http};
use RuntimeException;

class Pesepay {
    public const UNPAID = ['FAILED','TERMINATED','TIME_OUT','CLOSED','CLOSED_PERIOD_ELAPSED','INSUFFICIENT_FUNDS','CANCELLED','ERROR','DECLINED','AUTHORIZATION_FAILED','SERVICE_UNAVAILABLE','REVERSED'];

    public function configured(): bool {
        return filled(config('services.pesepay.integration_key')) && strlen(config('services.pesepay.encryption_key','')) === 32;
    }
    public function base(): string {
        return config('services.pesepay.sandbox') ? 'https://api.test.sandbox.pesepay.com/payments-engine/v1' : 'https://api.pesepay.com/api/payments-engine/v1';
    }
    public function encrypt(array $data): string {
        $key=config('services.pesepay.encryption_key');
        return base64_encode(openssl_encrypt(json_encode($data,JSON_THROW_ON_ERROR),'aes-256-cbc',$key,OPENSSL_RAW_DATA,substr($key,0,16)));
    }
    public function decrypt(string $payload): array {
        $key=config('services.pesepay.encryption_key');
        $raw=base64_decode($payload,true);
        $plain=$raw === false ? false : openssl_decrypt($raw,'aes-256-cbc',$key,OPENSSL_RAW_DATA,substr($key,0,16));
        if ($plain === false) throw new RuntimeException('Invalid payment response.');
        $result=json_decode($plain,true,512,JSON_THROW_ON_ERROR);
        if (!is_array($result)) throw new RuntimeException('Invalid payment response.');
        return $result;
    }
    private function client() {
        if (!$this->configured()) throw new RuntimeException('PesePay is not configured.');
        return Http::acceptJson()->asJson()->withHeaders(['authorization'=>config('services.pesepay.integration_key')])->connectTimeout(10)->timeout(25);
    }
    public function start(UniformOrder $order): UniformPayment {
        abort_unless($this->configured(),503,'Uniform payments are temporarily unavailable.');
        abort_unless($order->currency === 'USD' && (float)$order->total_amount > 0,422,'PesePay checkout currently accepts USD orders with a positive total.');
        $payment=DB::transaction(function () use($order) {
            $locked=UniformOrder::lockForUpdate()->findOrFail($order->id);
            abort_if($locked->payment_status==='paid',422,'This order is already paid.');
            $latest=UniformPayment::where('uniform_order_id',$order->id)->latest('id')->first();
            if ($latest && !in_array($latest->status,self::UNPAID,true)) {
                abort_unless($latest->redirect_url,409,'A checkout is being prepared or requires reconciliation. Check payment status before trying again.');
                return $latest;
            }
            abort_if($locked->payment_reference && $locked->payment_method !== 'PesePay',422,'This order has a manual payment reference awaiting verification.');
            return UniformPayment::create(['uniform_order_id'=>$order->id,'sandbox'=>(bool)config('services.pesepay.sandbox')]);
        });
        if ($payment->redirect_url) return $payment;
        try {
            $response=$this->client()->post($this->base().'/payments/initiate',['payload'=>$this->encrypt([
                'amountDetails'=>['amount'=>(float)$order->total_amount,'currencyCode'=>'USD'],
                'reasonForPayment'=>'Uniform order #'.$order->id,
                'resultUrl'=>url('/api/payments/pesepay/result'),
                'returnUrl'=>url('/payments/pesepay/return'),
            ])])->throw();
            $data=$this->decrypt($response->json('payload',''));
            $url=$data['redirectUrl'] ?? '';
            $host=strtolower(parse_url($url,PHP_URL_HOST) ?? '');
            $trusted=$host==='pesepay.com' || str_ends_with($host,'.pesepay.com')
                || (config('services.pesepay.sandbox') && $host==='pesepay-payments-sandbox-test.web.app');
            if (parse_url($url,PHP_URL_SCHEME)!=='https' || !$trusted || empty($data['referenceNumber'])) throw new RuntimeException('Invalid checkout response.');
            $payment->update(['reference'=>$data['referenceNumber'],'redirect_url'=>$url,'status'=>'INITIATED']);
            return $payment;
        } catch (\Throwable $e) {
            $rejected=$e instanceof \Illuminate\Http\Client\RequestException && in_array($e->response->status(),[400,401,403,404,422],true);
            $payment->update(['status'=>$rejected ? 'FAILED' : 'UNKNOWN']);
            // Do not expose provider responses, request headers or keys in logs/errors.
            abort(502,'PesePay could not prepare checkout. No payment has been confirmed. Please contact the school if this persists.');
        }
    }
    public function reconcile(UniformPayment $payment): UniformPayment {
        abort_unless($payment->reference,409,'Checkout has no provider reference. Please contact the school before starting another payment.');
        abort_unless($payment->sandbox === (bool)config('services.pesepay.sandbox'),409,'This payment belongs to a different payment environment.');
        $response=$this->client()->get($this->base().'/payments/check-payment',['referenceNumber'=>$payment->reference])->throw();
        $data=$this->decrypt($response->json('payload',''));
        $order=$payment->order;
        $amount=$data['amountDetails']['amount'] ?? null;
        if (($data['referenceNumber'] ?? null)!==$payment->reference || !is_numeric($amount)
            || (int)round((float)$amount*100)!==(int)round((float)$order->total_amount*100)
            || ($data['amountDetails']['currencyCode'] ?? null)!==$order->currency) throw new RuntimeException('Payment details do not match the order.');
        $status=$data['transactionStatus'] ?? '';
        if (!in_array($status,array_merge(self::UNPAID,['INITIATED','PROCESSING','PENDING','PARTIALLY_PAID','SUCCESS']),true)) throw new RuntimeException('Unknown payment status.');
        DB::transaction(function () use($payment,$status) {
            $locked=UniformOrder::lockForUpdate()->findOrFail($payment->uniform_order_id);
            $payment->update(['status'=>$status,'checked_at'=>now()]);
            if ($status==='SUCCESS' && $locked->payment_status!=='paid') {
                $locked->update(['payment_status'=>'paid','payment_method'=>'PesePay','payment_reference'=>$payment->reference,'verified_at'=>now(),'verified_by'=>null]);
            } elseif ($status==='REVERSED' && $locked->payment_reference===$payment->reference) {
                $locked->update(['payment_status'=>'reversed']);
            }
        });
        return $payment->fresh();
    }
}

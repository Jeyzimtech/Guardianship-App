<?php
namespace App\Jobs;
use App\Models\UniformPayment;
use App\Services\Pesepay;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

class ReconcileUniformPayment implements ShouldQueue {
    use Queueable;
    public int $tries=3;
    public function __construct(public int $paymentId) {}
    public function backoff(): array { return [30,120,300]; }
    public function handle(Pesepay $gateway): void {
        $payment=UniformPayment::find($this->paymentId);
        if (!$payment) return;
        try { $gateway->reconcile($payment); }
        catch (\Throwable $e) { throw new \RuntimeException('PesePay reconciliation unavailable; no order was credited.'); }
    }
}

<?php
namespace App\Http\Controllers;
use App\Models\{UniformOrder,UniformPayment};
use App\Services\Pesepay;
use Illuminate\Http\Request;

class UniformPaymentController extends Controller {
    private function scoped(Request $request,int $id): UniformOrder {
        $order=UniformOrder::with('student')->findOrFail($id);
        $user=$request->user();
        abort_unless(($user->role==='guardian' && $user->students()->whereKey($order->student_id)->exists())
            || ($user->role==='admin' && $user->school_id && (int)$user->school_id===(int)$order->student->school_id),403);
        return $order;
    }
    public function checkout(Request $request,int $id,Pesepay $gateway) {
        $payment=$gateway->start($this->scoped($request,$id));
        return response()->json(['status'=>'success','redirect_url'=>$payment->redirect_url,'sandbox'=>$payment->sandbox]);
    }
    public function status(Request $request,int $id,Pesepay $gateway) {
        $order=$this->scoped($request,$id);
        $payment=UniformPayment::where('uniform_order_id',$id)->latest('id')->first();
        if ($payment) {
            try { $payment=$gateway->reconcile($payment); }
            catch (\Throwable $e) { return response()->json(['status'=>'error','message'=>'Payment status could not be verified. Please try again shortly.'],502); }
        }
        return response()->json(['status'=>'success','payment_status'=>$order->fresh()->payment_status,'gateway_status'=>$payment?->status,'sandbox'=>$payment?->sandbox]);
    }
    public function callback(Request $request,Pesepay $gateway) {
        $key=config('services.pesepay.integration_key','');
        abort_unless($key && hash_equals($key,$request->header('authorization','')),401);
        $data=$request->validate(['referenceNumber'=>'required|string|max:255']);
        $payment=UniformPayment::where('reference',$data['referenceNumber'])->first();
        if ($payment) \App\Jobs\ReconcileUniformPayment::dispatch($payment->id)->onQueue('payments');
        return response()->json(['received'=>true]);
    }
}

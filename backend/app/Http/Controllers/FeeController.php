<?php

namespace App\Http\Controllers;

use App\Models\FeeAccount;
use App\Models\FeeTransaction;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeeController extends Controller
{
    public function accounts(Request $request)
    {
        $user = $request->user();
        abort_unless($user?->role === 'admin' && $user->school_id, 403);
        $students = Student::with('feeAccount')->where('school_id', $user->school_id)
            ->orderBy('class_name')->orderBy('name')->get()
            ->map(fn ($student) => [
                'student_id' => $student->id,
                'name' => $student->name,
                'class_name' => $student->class_name,
                'grade' => $student->grade,
                'balance_usd' => (float) ($student->feeAccount?->balance_usd ?? 0),
                'balance_zig' => (float) ($student->feeAccount?->balance_zig ?? 0),
            ]);

        return response()->json(['status' => 'success', 'accounts' => $students]);
    }

    /**
     * Get fee balances and payment history for a student.
     */
    public function getFeeDetails(Request $request, $studentId)
    {
        $user = $request->user();
        $student = Student::findOrFail($studentId);

        // Access scoping
        if ($user->role === 'guardian') {
            $isLinked = $user->students()->where('students.id', $studentId)->exists();
            if (!$isLinked) {
                return response()->json([
                    'status' => 'error',
                    'message' => 'Unauthorized. This student is not linked to your account.'
                ], 403);
            }
        }
        // Fee accounts belong to school admins and guardians; teachers have no fee access.
        if (!in_array($user->role, ['guardian', 'admin', 'website_admin'], true)) {
            return response()->json(['status' => 'error', 'message' => 'Unauthorized to view fee details.'], 403);
        }

        $feeAccount = FeeAccount::firstOrCreate(
            ['student_id' => $studentId],
            ['balance_usd' => 0.00, 'balance_zig' => 0.00]
        );

        $transactions = FeeTransaction::where('fee_account_id', $feeAccount->id)
            ->orderBy('created_at', 'desc')
            ->get();

        return response()->json([
            'status' => 'success',
            'fee_account' => $feeAccount,
            'transactions' => $transactions
        ]);
    }

    /** Record a payment claim; only an administrator can verify and credit it. */
    public function processPayment(Request $request)
    {
        $student=Student::findOrFail($request->input('student_id'));
        $actor=$request->user();
        abort_unless(($actor->role==='guardian' && $actor->students()->whereKey($student->id)->exists())
            || ($actor->role==='admin' && $actor->school_id && (int)$actor->school_id===(int)$student->school_id),403);
        $data=$request->validate([
            'amount'=>'required|numeric|min:1','currency'=>'required|in:USD,ZiG',
            'payment_method'=>'required|in:EcoCash,OneMoney,Card',
            'reference'=>['required','string','max:100',\Illuminate\Validation\Rule::unique('fee_transactions')->where('payment_method',$request->payment_method)],
        ]);
        $account=FeeAccount::firstOrCreate(['student_id'=>$student->id],['balance_usd'=>0,'balance_zig'=>0]);
        $column=$data['currency']==='USD'?'balance_usd':'balance_zig';
        abort_if((float)$data['amount']>(float)$account->$column,422,'The amount exceeds the outstanding balance.');
        $payment=FeeTransaction::create($data+['fee_account_id'=>$account->id,'status'=>'pending']);
        return response()->json(['status'=>'success','message'=>'Payment reference submitted for school verification. Your balance changes only after verification.','transaction'=>$payment,'fee_account'=>$account],202);
    }

    public function pendingPayments(Request $request)
    {
        $school=$request->user()->school_id;
        abort_unless($school,403);
        $payments=FeeTransaction::with('feeAccount.student')->where('status','pending')
            ->whereHas('feeAccount.student',fn($q)=>$q->where('school_id',$school))->latest()->get();
        return response()->json(['status'=>'success','payments'=>$payments]);
    }

    public function verifyPayment(Request $request, int $id)
    {
        $request->validate(['confirmed'=>'required|accepted']);
        $actor=$request->user();
        $payment=DB::transaction(function() use($actor,$id) {
            $payment=FeeTransaction::lockForUpdate()->findOrFail($id);
            $account=FeeAccount::lockForUpdate()->findOrFail($payment->fee_account_id);
            abort_unless($actor->role==='admin' && $actor->school_id && (int)$account->student->school_id===(int)$actor->school_id,403);
            if($payment->status==='completed') return $payment;
            abort_unless($payment->reference,422,'A payment reference is required before verification.');
            $column=$payment->currency==='USD'?'balance_usd':'balance_zig';
            abort_if((float)$payment->amount>(float)$account->$column,422,'The current balance is smaller than this payment; reconcile the account before verification.');
            $account->$column=round((float)$account->$column-(float)$payment->amount,2);
            $account->save();
            $payment->update(['status'=>'completed','verified_by'=>$actor->id,'verified_at'=>now()]);
            return $payment;
        });
        return response()->json(['status'=>'success','message'=>'Payment verified and balance updated.','transaction'=>$payment]);
    }

    /**
     * Admin method to update fee balances (Admin only).
     */
    public function updateBalance(Request $request)
    {
        $user = $request->user();
        if ($user->role !== 'admin') {
            return response()->json([
                'status' => 'error',
                'message' => 'Unauthorized. Admin access only.'
            ], 403);
        }

        $request->validate([
            'student_id' => 'required|exists:students,id',
            'balance_usd' => 'required|numeric|min:0',
            'balance_zig' => 'required|numeric|min:0',
        ]);

        $student = Student::findOrFail($request->student_id);
        if (!$user->school_id || (int) $student->school_id !== (int) $user->school_id) {
            return response()->json(['status' => 'error', 'message' => 'You may only update fee balances at your school.'], 403);
        }

        $feeAccount = FeeAccount::updateOrCreate(
            ['student_id' => $request->student_id],
            [
                'balance_usd' => $request->balance_usd,
                'balance_zig' => $request->balance_zig,
            ]
        );

        return response()->json([
            'status' => 'success',
            'message' => 'Fee balance updated successfully.',
            'fee_account' => $feeAccount
        ]);
    }
}

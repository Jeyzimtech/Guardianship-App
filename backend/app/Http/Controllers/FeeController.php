<?php

namespace App\Http\Controllers;

use App\Models\FeeAccount;
use App\Models\FeeTransaction;
use App\Models\Student;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class FeeController extends Controller
{
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

    /**
     * Process simulated mobile money (EcoCash/OneMoney) or card payment.
     */
    public function processPayment(Request $request)
    {
        $request->validate([
            'student_id' => 'required|exists:students,id',
            'amount' => 'required|numeric|min:1',
            'currency' => 'required|in:USD,ZiG',
            'payment_method' => 'required|in:EcoCash,OneMoney,Card',
        ]);

        $user = $request->user();
        $studentId = $request->student_id;

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

        $feeAccount = FeeAccount::firstOrCreate(
            ['student_id' => $studentId],
            ['balance_usd' => 0.00, 'balance_zig' => 0.00]
        );

        // Perform transaction atomically
        $transaction = DB::transaction(function () use ($feeAccount, $request) {
            // Create transaction log
            $tx = FeeTransaction::create([
                'fee_account_id' => $feeAccount->id,
                'amount' => $request->amount,
                'currency' => $request->currency,
                'payment_method' => $request->payment_method,
                'status' => 'completed', // Immediately completed for simulation/MVP
            ]);

            // Subtract amount from fee account balance (ensure balance does not go below 0)
            if ($request->currency === 'USD') {
                $feeAccount->balance_usd = max(0, $feeAccount->balance_usd - $request->amount);
            } else {
                $feeAccount->balance_zig = max(0, $feeAccount->balance_zig - $request->amount);
            }
            $feeAccount->save();

            return $tx;
        });

        return response()->json([
            'status' => 'success',
            'message' => 'Payment processed successfully.',
            'transaction' => $transaction,
            'fee_account' => $feeAccount
        ]);
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

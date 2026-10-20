<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\SmsPop;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;

class PhoneAuthController extends Controller
{
    public function requestCode(Request $request, SmsPop $sms)
    {
        $data = $request->validate(['phone_number' => 'required|string|max:50']);
        $phone = SmsPop::phone($data['phone_number']);
        $key = 'phone-otp:'.hash('sha256', $phone);
        abort_if(RateLimiter::tooManyAttempts($key, 1), 429, 'Wait one minute before requesting another code.');
        RateLimiter::hit($key, 60);
        // Match legacy local-format numbers without changing existing account identifiers.
        $users = User::whereIn('phone_number', SmsPop::aliases($phone))
            ->whereIn('role', ['guardian', 'teacher'])->get();
        $id = (string) Str::uuid();
        if ($users->count() === 1) {
            $user = $users->first();
            $code = (string) random_int(100000, 999999);
            DB::table('phone_otps')->insert([
                'id' => $id, 'user_id' => $user->id, 'phone_number' => $phone,
                'code_hash' => Hash::make($code), 'expires_at' => now()->addMinutes(5),
                'created_at' => now(), 'updated_at' => now(),
            ]);
            try {
                $result = $sms->send([$phone], "EduConnect verification code: $code. Expires in 5 minutes. Do not share this code.", 'Account verification');
                if (($result['summary']['sent'] ?? 0) !== 1) throw new \RuntimeException('SMS not accepted.');
            } catch (\Throwable $e) {
                DB::table('phone_otps')->where('id', $id)->delete();
                return response()->json(['message' => 'Unable to send SMS. Please try again shortly or contact your school.'], 503);
            }
        }
        return response()->json(['challenge_id' => $id, 'message' => 'If your school has added this phone number, a verification code has been sent.', 'expires_in' => 300]);
    }

    public function verify(Request $request)
    {
        $data = $request->validate(['challenge_id' => 'required|uuid', 'code' => 'required|digits:6']);
        $result = DB::transaction(function () use ($data) {
            $otp = DB::table('phone_otps')->where('id', $data['challenge_id'])->lockForUpdate()->first();
            if (!$otp || $otp->consumed_at || $otp->attempts >= 5 || now()->gte($otp->expires_at)) return null;
            DB::table('phone_otps')->where('id', $otp->id)->increment('attempts');
            if (!Hash::check($data['code'], $otp->code_hash)) return null;
            $user = User::find($otp->user_id);
            if (!$user || !in_array($user->role, ['guardian', 'teacher'])) return null;
            try { if (SmsPop::phone($user->phone_number) !== $otp->phone_number) return null; }
            catch (\Throwable) { return null; }
            DB::table('phone_otps')->where('user_id', $user->id)->whereNull('consumed_at')->update(['consumed_at' => now()]);
            $user->forceFill(['phone_verified_at' => now()])->save();
            return ['status' => 'success', 'token' => $user->createToken('phone-login')->plainTextToken, 'user' => $user];
        });
        return $result ? response()->json($result) : response()->json(['message' => 'Invalid or expired code. Request a new code after five unsuccessful attempts.'], 422);
    }
}

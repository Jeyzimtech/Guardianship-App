<?php

namespace App\Http\Controllers;

use App\Models\SystemSetting;
use App\Models\User;
use Carbon\Carbon;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    /**
     * Authenticate a user with email/phone and password against the database.
     */
    public function login(Request $request)
    {
        $request->validate([
            'email' => 'nullable|string',
            'username' => 'nullable|string',
            'phone_number' => 'nullable|string',
            'password' => 'required|string',
        ]);

        $identifier = trim($request->input('username') ?? $request->input('email') ?? $request->input('phone_number') ?? '');

        if (empty($identifier)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Please provide an email, username, or phone number.'
            ], 422);
        }

        $user = User::where(function ($q) use ($identifier) {
            $lower = strtolower($identifier);
            $q->where('email', $lower)
              ->orWhere('name', $identifier)
              ->orWhereRaw('LOWER(name) = ?', [$lower])
              ->orWhere('phone_number', $identifier);
        })->first();

        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'No account found with these credentials.'
            ], 401);
        }

        $passwordMatches = Hash::check($request->password, $user->password);

        if (!$passwordMatches) {
            return response()->json([
                'status' => 'error',
                'message' => 'Incorrect password. Please try again.'
            ], 401);
        }

        // Student accounts are out of MVP scope.
        if (!in_array($user->role, ['website_admin', 'admin', 'teacher', 'guardian'], true)) {
            return response()->json([
                'status' => 'error',
                'message' => 'This account role does not have access yet.'
            ], 403);
        }

        // Create Sanctum Token
        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Login successful',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone_number' => $user->phone_number,
                'role' => $user->role,
            ]
        ]);
    }

    /**
     * Register a new user in the database.
     */
    public function register(Request $request)
    {
        return response()->json(['message' => 'Ask your teacher to add your parent account. School administrators add teachers.'], 403);
    }

    /**
     * Get the authenticated user profile.
     */
    public function profile(Request $request)
    {
        return response()->json([
            'status' => 'success',
            'user' => $request->user()
        ]);
    }

    /**
     * Log out the authenticated user.
     */
    public function logout(Request $request)
    {
        try {
            $user = $request->user();
            if ($user) {
                if ($user->currentAccessToken() && method_exists($user->currentAccessToken(), 'delete')) {
                    $user->currentAccessToken()->delete();
                } else if (method_exists($user, 'tokens')) {
                    $user->tokens()->delete();
                }
            }
        } catch (Exception $e) {
            // Safe fallback if token is invalid or mock token used
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Logged out successfully'
        ]);
    }

    /**
     * Change password for users (Teachers, Students/Guardians, Admins).
     */
    public function changePassword(Request $request)
    {
        $request->validate([
            'email' => 'nullable|string',
            'username' => 'nullable|string',
            'current_password' => 'required|string',
            'new_password' => 'required|string|min:6',
        ]);

        $user = null;
        if ($request->user()) {
            $user = $request->user();
        } else {
            $identifier = trim($request->input('username') ?? $request->input('email') ?? '');
            if (!empty($identifier)) {
                $user = User::where(function ($q) use ($identifier) {
                    $lower = strtolower($identifier);
                    $q->where('email', $lower)
                      ->orWhere('name', $identifier)
                      ->orWhereRaw('LOWER(name) = ?', [$lower])
                      ->orWhere('phone_number', $identifier);
                })->first();
            }
        }

        if (!$request->user()) {
            return response()->json(['status' => 'error', 'message' => 'Sign in before changing your password.'], 401);
        }

        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'No account found with this email or username.'
            ], 404);
        }

        $passwordMatches = Hash::check($request->current_password, $user->password);

        if (!$passwordMatches) {
            return response()->json([
                'status' => 'error',
                'message' => 'Current password does not match.'
            ], 401);
        }

        $user->password = Hash::make($request->new_password);
        $user->save();

        return response()->json([
            'status' => 'success',
            'message' => 'Password updated successfully! You can now log in with your new password.'
        ]);
    }

    /**
     * Send a password reset or creation link to the user's email.
     */
    public function forgotPassword(Request $request)
    {
        $request->validate([
            'email' => 'required|string',
        ]);

        $identifier = trim($request->input('email'));
        $user = User::whereRaw('LOWER(email) = ?', [strtolower($identifier)])->first();

        if (!$user || empty($user->email)) {
            return response()->json(['status' => 'success', 'message' => 'If an account exists for that email address, a password reset link will be sent.']);
        }

        // Generate token and save to password_reset_tokens
        $token = Str::random(60);
        DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $user->email],
            [
                'token' => Hash::make($token),
                'created_at' => now(),
            ]
        );

        EmailSettingsController::configureMailTransport();

        $portalBaseUrl = SystemSetting::get('portal_access_url', config('app.url', ''));
        if (!$portalBaseUrl) {
            return response()->json(['status' => 'error', 'message' => 'Password reset is not configured. Contact your administrator.'], 503);
        }
        $resetUrl = rtrim($portalBaseUrl, '/') . '/reset-password?token=' . $token . '&email=' . urlencode($user->email);

        $fromAddress = Config::get('mail.from.address', '');
        $fromName = Config::get('mail.from.name', 'Edu+Connect Guardianship');

        try {
            Mail::send('emails.forgot_password', [
                'name' => $user->name,
                'email' => $user->email,
                'resetUrl' => $resetUrl,
            ], function ($message) use ($user, $fromAddress, $fromName) {
                $message->to($user->email, $user->name)
                        ->from($fromAddress, $fromName)
                        ->subject('Edu+Connect - Reset Your Account Password');
            });

            return response()->json([
                'status' => 'success',
                'message' => 'Password reset link has been sent to your email.'
            ]);
        } catch (\Throwable $e) {
            Log::error('Forgot password email dispatch failed: ' . $e->getMessage());
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to dispatch email. Please contact administration or verify mail gateway.'
            ], 500);
        }
    }

    /**
     * Set or reset password using verified token.
     */
    public function resetPassword(Request $request)
    {
        $request->validate([
            'token' => 'required|string',
            'email' => 'required|email',
            'password' => 'required|string|min:6|confirmed',
        ]);

        $record = DB::table('password_reset_tokens')
            ->where('email', $request->email)
            ->first();

        if (!$record) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid or expired password reset link. Please request a new one.'
            ], 422);
        }

        // Verify token against hashed or stored token
        $tokenValid = Hash::check($request->token, $record->token) || ($request->token === $record->token);

        if (!$tokenValid) {
            return response()->json([
                'status' => 'error',
                'message' => 'Invalid or expired password reset link. Please request a new one.'
            ], 422);
        }

        // Allow up to 48 hours validity
        if ($record->created_at && Carbon::parse($record->created_at)->addHours(48)->isPast()) {
            return response()->json([
                'status' => 'error',
                'message' => 'This password link has expired. Please request a new one.'
            ], 422);
        }

        $user = User::where('email', $request->email)->first();
        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'No user found for this email address.'
            ], 404);
        }

        $user->password = Hash::make($request->password);
        $user->save();

        // Revoke existing sessions after changing credentials.
        $user->tokens()->delete();

        // Invalidate token after successful reset
        DB::table('password_reset_tokens')->where('email', $request->email)->delete();

        return response()->json([
            'status' => 'success',
            'message' => 'Your password has been successfully set! You can now log in to the mobile application.'
        ]);
    }
}

<?php

namespace App\Http\Controllers;

use App\Models\SystemSetting;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Config;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;

class EmailSettingsController extends Controller
{
    /**
     * Retrieve current mail settings with secrets masked.
     */
    public function getSettings(Request $request)
    {
        $provider = SystemSetting::get('mail_provider', 'SMTP');
        $host = SystemSetting::get('mail_host', '');
        $port = SystemSetting::get('mail_port', '587');
        $encryption = SystemSetting::get('mail_encryption', 'tls');
        $username = SystemSetting::get('mail_username', '');
        $password = SystemSetting::get('mail_password', '');
        $fromAddress = SystemSetting::get('mail_from_address', '');
        $fromName = SystemSetting::get('mail_from_name', 'Edu+Connect Guardianship');
        $sesRegion = SystemSetting::get('mail_ses_region', 'us-east-1');
        $portalUrl = SystemSetting::get('portal_access_url', config('app.url', ''));

        return response()->json([
            'status' => 'success',
            'settings' => [
                'mail_provider' => $provider,
                'mail_host' => $host,
                'mail_port' => $port,
                'mail_encryption' => $encryption,
                'mail_username' => $username,
                'mail_password_configured' => !empty($password),
                'mail_password' => '',
                'mail_from_address' => $fromAddress,
                'mail_from_name' => $fromName,
                'mail_ses_region' => $sesRegion,
                'portal_access_url' => $portalUrl,
            ],
            'presets' => [
                'gmail' => [
                    'provider' => 'gmail',
                    'host' => 'smtp.gmail.com',
                    'port' => '587',
                    'encryption' => 'tls',
                    'sender' => '',
                    'hint' => 'Enter the sender address and an app password for a Gmail account with two-step verification enabled.'
                ],
                'ses' => [
                    'provider' => 'ses',
                    'host' => 'email-smtp.us-east-1.amazonaws.com',
                    'port' => '587',
                    'encryption' => 'tls',
                    'sender' => '',
                    'hint' => 'Use AWS SES SMTP credentials (IAM -> SES -> SMTP Credentials: SMTP Username and SMTP Password) and ensure sender identity is verified in Amazon SES console.'
                ]
            ]
        ]);
    }

    /**
     * Save updated mail configuration settings.
     */
    public function saveSettings(Request $request)
    {
        $request->validate([
            'mail_provider' => 'required|string|in:gmail,ses,custom',
            'mail_host' => 'required|string|max:255',
            'mail_port' => 'required|integer',
            'mail_encryption' => 'required|string|in:tls,ssl,none',
            'mail_username' => 'nullable|string|max:255',
            'mail_password' => 'nullable|string|max:255',
            'mail_from_address' => 'required|email|max:255',
            'mail_from_name' => 'required|string|max:255',
            'mail_ses_region' => 'nullable|string|max:50',
            'portal_access_url' => 'nullable|url|max:255',
        ]);

        if (in_array($request->mail_encryption, ['tls', 'ssl'], true) && (int) $request->mail_port === 25) {
            return response()->json(['status' => 'error', 'message' => 'Port 25 does not support the selected TLS/SSL mode. Use port 587 for TLS or 465 for SSL.'], 422);
        }
        if ($request->mail_encryption === 'ssl' && (int) $request->mail_port === 587) {
            return response()->json(['status' => 'error', 'message' => 'Use port 465 for SSL or change encryption to TLS for port 587.'], 422);
        }

        SystemSetting::set('mail_provider', $request->mail_provider);
        SystemSetting::set('mail_host', $request->mail_host);
        SystemSetting::set('mail_port', (string) $request->mail_port);
        SystemSetting::set('mail_encryption', $request->mail_encryption);
        SystemSetting::set('mail_username', $request->mail_username ?? '');

        // Only update password if new value is provided and not masked
        if ($request->filled('mail_password') && !str_starts_with($request->mail_password, '•••')) {
            SystemSetting::set('mail_password', $request->mail_password);
        }

        SystemSetting::set('mail_from_address', $request->mail_from_address);
        SystemSetting::set('mail_from_name', $request->mail_from_name);

        if ($request->filled('mail_ses_region')) {
            SystemSetting::set('mail_ses_region', $request->mail_ses_region);
        }

        if ($request->filled('portal_access_url')) {
            SystemSetting::set('portal_access_url', rtrim($request->portal_access_url, '/'));
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Email configuration saved successfully.'
        ]);
    }

    /**
     * Dynamically apply mail settings into Laravel runtime configuration.
     */
    public static function configureMailTransport(): void
    {
        $host = SystemSetting::get('mail_host', config('mail.mailers.smtp.host', ''));
        $port = (int) SystemSetting::get('mail_port', config('mail.mailers.smtp.port', 587));
        $encryption = SystemSetting::get('mail_encryption', 'tls');
        if ($encryption === 'none') {
            $encryption = null;
        }
        $username = SystemSetting::get('mail_username', config('mail.mailers.smtp.username', ''));
        $password = SystemSetting::get('mail_password', config('mail.mailers.smtp.password', ''));
        $fromAddress = SystemSetting::get('mail_from_address', config('mail.from.address', ''));
        $fromName = SystemSetting::get('mail_from_name', config('mail.from.name', 'Edu+Connect Guardianship'));

        Config::set('mail.default', 'smtp');
        Config::set('mail.mailers.smtp.transport', 'smtp');
        Config::set('mail.mailers.smtp.host', $host);
        Config::set('mail.mailers.smtp.port', $port);
        Config::set('mail.mailers.smtp.encryption', $encryption);
        Config::set('mail.mailers.smtp.scheme', ($port === 465 || $encryption === 'ssl') ? 'smtps' : null);
        Config::set('mail.mailers.smtp.username', $username);
        Config::set('mail.mailers.smtp.password', $password);
        Config::set('mail.mailers.smtp.timeout', 15);
        Config::set('mail.from.address', $fromAddress);
        Config::set('mail.from.name', $fromName);

        try {
            Mail::purge('smtp');
        } catch (\Throwable $e) {
            // Ignored if mailer wasn't booted yet
        }
    }

    /**
     * Send a test verification email using active or provided configuration.
     */
    public function sendTestEmail(Request $request)
    {
        $request->validate([
            'recipient' => 'nullable|email|max:255',
        ]);

        $recipient = $request->recipient ?: SystemSetting::get('mail_from_address', '');
        if (!$recipient) {
            return response()->json(['status' => 'error', 'message' => 'Configure a sender or recipient email address first.'], 422);
        }

        self::configureMailTransport();

        $provider = SystemSetting::get('mail_provider', 'SMTP');
        $host = Config::get('mail.mailers.smtp.host');
        $port = Config::get('mail.mailers.smtp.port');
        $encryption = Config::get('mail.mailers.smtp.encryption');
        $fromAddress = Config::get('mail.from.address');
        $fromName = Config::get('mail.from.name');

        try {
            Mail::send('emails.test_email', [
                'provider' => strtoupper($provider),
                'host' => $host,
                'port' => $port,
                'encryption' => $encryption,
                'fromAddress' => $fromAddress,
                'recipient' => $recipient,
                'timestamp' => now()->format('Y-m-d H:i:s T')
            ], function ($message) use ($recipient, $fromAddress, $fromName) {
                $message->to($recipient)
                        ->from($fromAddress, $fromName)
                        ->subject('Edu+Connect Mail Test: Delivery Verified');
            });

            return response()->json([
                'status' => 'success',
                'message' => "Test email dispatched successfully to {$recipient} via {$provider} ({$host})."
            ]);
        } catch (\Throwable $e) {
            Log::error('SMTP/SES test email failure: ' . $e->getMessage(), [
                'exception' => $e
            ]);

            return response()->json([
                'status' => 'error',
                'message' => 'Failed to send test email: ' . $e->getMessage(),
                'details' => [
                    'host' => $host,
                    'port' => $port,
                    'provider' => $provider,
                    'from' => $fromAddress,
                ]
            ], 422);
        }
    }

    /**
     * Send password setup/reset link to an existing user.
     */
    public function sendUserAccessLink(Request $request, $id)
    {
        $user = User::findOrFail($id);
        $actor = $request->user();
        if ($actor?->role === 'admin' && (int) $actor->school_id !== (int) $user->school_id
            && (int) $actor->school_id !== (int) $user->teacherProfile?->school_id
            && !$user->students()->where('students.school_id', $actor->school_id)->exists()) {
            return response()->json(['status' => 'error', 'message' => 'You may only send account links for users at your school.'], 403);
        }

        if ($actor?->role === 'teacher') {
            abort_unless($user->role === 'guardian' && $actor->teacherProfile, 403);
            $children = $user->students()->get();
            abort_unless($children->contains(fn ($student) => $actor->teacherProfile->teachesStudent($student)), 403,
                'You may only invite guardians linked to your assigned classes.');
        }

        if (empty($user->email)) {
            return response()->json([
                'status' => 'error',
                'message' => 'Selected user does not have an email address configured.'
            ], 422);
        }

        $result = self::sendPasswordSetupLink($user);

        if ($result['success']) {
            return response()->json([
                'status' => 'success',
                'message' => "Password setup link sent successfully to {$user->email}."
            ]);
        } else {
            return response()->json([
                'status' => 'error',
                'message' => 'Failed to deliver setup email: ' . $result['message']
            ], 422);
        }
    }

    /**
     * Static helper to dispatch password creation/setup link to a new user.
     */
    public static function sendPasswordSetupLink(User $user): array
    {
        if (empty($user->email)) {
            return [
                'success' => false,
                'message' => 'User does not have an email address.'
            ];
        }

        // Generate token and record in password_reset_tokens
        $token = Str::random(60);
        \Illuminate\Support\Facades\DB::table('password_reset_tokens')->updateOrInsert(
            ['email' => $user->email],
            [
                'token' => \Illuminate\Support\Facades\Hash::make($token),
                'created_at' => now(),
            ]
        );

        self::configureMailTransport();

        $portalBaseUrl = SystemSetting::get('portal_access_url', config('app.url', ''));
        if (!$portalBaseUrl) {
            return ['success' => false, 'message' => 'Set the application URL before sending account links.'];
        }
        if (!filter_var($portalBaseUrl, FILTER_VALIDATE_URL) || !in_array(parse_url($portalBaseUrl, PHP_URL_SCHEME), ['http', 'https'], true)) {
            return ['success' => false, 'message' => 'Set a valid HTTP or HTTPS portal URL before sending account links.'];
        }
        $setupUrl = rtrim($portalBaseUrl, '/') . '/set-password?token=' . $token . '&email=' . urlencode($user->email);

        $fromAddress = Config::get('mail.from.address', '');
        $fromName = Config::get('mail.from.name', 'Edu+Connect Guardianship');

        try {
            Mail::send('emails.set_password', [
                'name' => $user->name,
                'email' => $user->email,
                'role' => $user->role,
                'setupUrl' => $setupUrl,
            ], function ($message) use ($user, $fromAddress, $fromName) {
                $message->to($user->email, $user->name)
                        ->from($fromAddress, $fromName)
                        ->subject('Welcome to Edu+Connect - Create Your Account Password');
            });

            return [
                'success' => true,
                'message' => 'Password creation link sent successfully.'
            ];
        } catch (\Throwable $e) {
            Log::error("Failed to send password setup email to {$user->email}: " . $e->getMessage());

            return [
                'success' => false,
                'message' => $e->getMessage()
            ];
        }
    }

    /**
     * Static helper to dispatch welcome/access link email to a user (legacy fallback).
     */
    public static function sendAccessLinkToUser(User $user, ?string $plainPassword = null, ?string $customLink = null): array
    {
        return self::sendPasswordSetupLink($user);
    }
}

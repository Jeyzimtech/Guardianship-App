<?php

namespace App\Services;

use Illuminate\Support\Facades\{Cache, DB, Http};

class FirebasePush
{
    public function send(object $device, string $title, string $category, int $id, ?int $studentId = null): void
    {
        $credentials = json_decode(file_get_contents(config('services.firebase.credentials')), true, 512, JSON_THROW_ON_ERROR);
        $accessToken = Cache::remember('fcm_oauth_'.hash('sha256', $credentials['client_email']), 3000, function () use ($credentials) {
            $encode = fn ($value) => rtrim(strtr(base64_encode($value), '+/', '-_'), '=');
            $now = time();
            $jwt = $encode(json_encode(['alg' => 'RS256', 'typ' => 'JWT'])).'.'.$encode(json_encode([
                'iss' => $credentials['client_email'], 'scope' => 'https://www.googleapis.com/auth/firebase.messaging',
                'aud' => 'https://oauth2.googleapis.com/token', 'iat' => $now, 'exp' => $now + 3600,
            ]));
            if (!openssl_sign($jwt, $signature, $credentials['private_key'], OPENSSL_ALGO_SHA256)) {
                throw new \RuntimeException('Could not sign Firebase credential.');
            }
            return Http::asForm()->timeout(15)->post('https://oauth2.googleapis.com/token', [
                'grant_type' => 'urn:ietf:params:oauth:grant-type:jwt-bearer', 'assertion' => $jwt.'.'.$encode($signature),
            ])->throw()->json('access_token');
        });
        $response = Http::withToken($accessToken)->timeout(15)->post(
            'https://fcm.googleapis.com/v1/projects/'.$credentials['project_id'].'/messages:send', [
                'message' => [
                    'token' => $device->token,
                    'notification' => ['title' => $title, 'body' => 'Open Edu Connect to view your update.'],
                    'data' => ['category' => $category, 'item_id' => (string) $id, 'student_id' => (string) ($studentId ?? '')],
                    'android' => ['priority' => 'high', 'notification' => [
                        'channel_id' => 'school_updates', 'tag' => $category.'_'.$id, 'sound' => 'default',
                    ]],
                    'apns' => ['payload' => ['aps' => ['sound' => 'default']]],
                ],
            ]);
        $codes = collect($response->json('error.details', []))->pluck('errorCode');
        if ($codes->contains('UNREGISTERED')) {
            DB::table('mobile_devices')->where('id', $device->id)->delete();
            return;
        }
        $response->throw();
    }
}

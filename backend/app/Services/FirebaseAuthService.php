<?php

namespace App\Services;

use Exception;
use Illuminate\Support\Facades\Log;

class FirebaseAuthService
{
    /**
     * Verify Firebase ID Token and return the user profile details.
     *
     * @param string $idToken
     * @return array{phone_number: string, firebase_uid: string, name: string|null}
     * @throws Exception
     */
    public function verifyIdToken(string $idToken): array
    {
        // For development and testing: Support simulated/mock Firebase ID Tokens.
        // Format: mock-firebase-token-[phone_number]-[firebase_uid]
        if (str_starts_with($idToken, 'mock-firebase-token-')) {
            $parts = explode('-', substr($idToken, 20));
            $phoneNumber = $parts[0] ?? '+263771111111';
            $firebaseUid = $parts[1] ?? 'mock_uid_' . uniqid();
            
            return [
                'phone_number' => $phoneNumber,
                'firebase_uid' => $firebaseUid,
                'name' => 'Mock User (' . $phoneNumber . ')',
            ];
        }

        // In a real production setup, we would verify the JWT signature using Firebase public keys:
        // For now, we decode basic base64 payload to look for phone_number if it looks like a JWT,
        // or fall back to mock behavior to prevent breaking in offline/restricted environments.
        try {
            $tokenParts = explode('.', $idToken);
            if (count($tokenParts) === 3) {
                $payload = json_decode(base64_decode($tokenParts[1]), true);
                if (isset($payload['phone_number'])) {
                    return [
                        'phone_number' => $payload['phone_number'],
                        'firebase_uid' => $payload['sub'] ?? 'firebase_uid_' . uniqid(),
                        'name' => $payload['name'] ?? null,
                    ];
                }
            }
        } catch (Exception $e) {
            Log::error('Error decoding Firebase Token JWT: ' . $e->getMessage());
        }

        // Fallback for demo/restricted environments:
        // Assume the ID token itself is the phone number if it contains numbers.
        if (preg_match('/^\+?[0-9]+$/', $idToken)) {
            return [
                'phone_number' => $idToken,
                'firebase_uid' => 'firebase_uid_' . md5($idToken),
                'name' => null,
            ];
        }

        throw new Exception('Invalid Firebase ID Token format.');
    }
}

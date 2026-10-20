<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Validation\ValidationException;

class SmsPop
{
    public static function phone(string $value): string
    {
        $phone = preg_replace('/[\s()+-]/', '', trim($value));
        if (str_starts_with($phone, '00')) $phone = substr($phone, 2);
        if (str_starts_with($phone, '0')) $phone = '263'.substr($phone, 1);
        if (strlen($phone) === 9) $phone = '263'.$phone;
        if (!preg_match('/^2637[178]\d{7}$/', $phone)) {
            throw ValidationException::withMessages(['phone_number' => 'Enter a Zimbabwe Econet (077/078) or NetOne (071) mobile number.']);
        }
        return $phone;
    }

    public static function aliases(string $value): array
    {
        $phone = self::phone($value);
        return [$phone, '+'.$phone, '0'.substr($phone, 3), substr($phone, 3)];
    }

    public function send(array $phones, string $message, string $name): array
    {
        if (!config('services.smspop.token')) throw new \RuntimeException('SMS service is not configured.');
        $phones = array_values(array_unique(array_map(self::phone(...), $phones)));
        if (!$phones) throw new \RuntimeException('No supported mobile numbers.');
        // Never automatically retry a campaign: a timeout may occur after SMS was sent.
        $response = Http::withToken(config('services.smspop.token'))->acceptJson()
            ->connectTimeout(10)->timeout(120)->post('https://smspop.co.zw/api/campaigns', [
                'name' => $name, 'message' => $message,
                'sender_id' => config('services.smspop.sender_id'),
                'contact_import_method' => 'manual', 'manual_contacts' => implode(',', $phones),
            ]);
        if (!$response->successful() || $response->json('success') !== true) {
            throw new \RuntimeException('SMS provider could not accept the message (HTTP '.$response->status().').');
        }
        return $response->json('data');
    }
}

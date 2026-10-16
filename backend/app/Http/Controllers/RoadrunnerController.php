<?php

namespace App\Http\Controllers;

use Illuminate\Http\Client\ConnectionException;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class RoadrunnerController extends Controller
{
    public function quote(Request $request)
    {
        $data = $request->validate([
            'destination_address' => ['required', 'string', 'min:8', 'max:500'],
            'recipient_name' => ['nullable', 'string', 'max:120'],
            'recipient_phone' => ['nullable', 'string', 'max:40'],
            'items' => ['nullable', 'array', 'max:100'],
            'items.*.name' => ['required_with:items', 'string', 'max:160'],
            'items.*.quantity' => ['required_with:items', 'integer', 'min:1', 'max:100'],
            'items.*.weight_kg' => ['nullable', 'numeric', 'min:0.01', 'max:1000'],
        ]);

        $key = config('services.roadrunner.api_key');
        $baseUrl = rtrim((string) config('services.roadrunner.base_url'), '/');
        $path = '/' . ltrim((string) config('services.roadrunner.quote_path'), '/');
        $pickup = config('services.roadrunner.pickup_address');

        if (!$key || !$pickup || !Str::startsWith($baseUrl, 'https://')) {
            return response()->json([
                'message' => 'Roadrunner delivery quotes are not configured. Set the Roadrunner server environment variables.',
            ], 503);
        }

        // Forward merchant, destination, and item details as provided by the
        // configured Roadrunner quote API. Never expose the API credential to mobile.
        $payload = array_filter([
            'merchant_public_id' => config('services.roadrunner.merchant_public_id'),
            'merchant_slug' => config('services.roadrunner.merchant_slug'),
            'pickup_address' => $pickup,
            'destination_address' => $data['destination_address'],
            'recipient_name' => $data['recipient_name'] ?? null,
            'recipient_phone' => $data['recipient_phone'] ?? null,
            'items' => $data['items'] ?? null,
        ], fn ($value) => $value !== null);

        try {
            $response = Http::acceptJson()
                ->asJson()
                ->withToken($key)
                ->timeout(15)
                ->post($baseUrl . $path, $payload);
        } catch (ConnectionException) {
            return response()->json(['message' => 'Roadrunner quote service is temporarily unavailable.'], 502);
        }

        if (!$response->successful()) {
            return response()->json([
                'message' => 'Roadrunner could not provide a delivery quote.',
                'provider_status' => $response->status(),
                'provider_error' => $response->json('message') ?? $response->json('error'),
            ], $response->status() >= 500 ? 502 : 422);
        }

        return response()->json(['quote' => $response->json()]);
    }
}

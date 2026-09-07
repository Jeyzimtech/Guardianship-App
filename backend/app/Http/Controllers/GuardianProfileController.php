<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class GuardianProfileController extends Controller
{
    /**
     * Fetch self-service guardian profile details
     */
    public function getProfile(Request $request)
    {
        $user = $request->user();

        return response()->json([
            'status' => 'success',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone_number' => $user->phone_number,
                'address' => $user->address,
                'preferred_language' => $user->preferred_language ?? 'English',
                'emergency_contact_name' => $user->emergency_contact_name,
                'emergency_contact_phone' => $user->emergency_contact_phone,
            ]
        ]);
    }

    /**
     * Self-update guardian contact, emergency contact, and language preference.
     * Note: Student identity/class/grade fields are never altered here.
     */
    public function updateProfile(Request $request)
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => 'nullable|string|max:255',
            'phone_number' => 'nullable|string|max:50',
            'email' => 'nullable|email|max:255',
            'address' => 'nullable|string|max:500',
            'preferred_language' => 'nullable|string|max:50',
            'emergency_contact_name' => 'nullable|string|max:255',
            'emergency_contact_phone' => 'nullable|string|max:50',
        ]);

        $user->update(array_filter([
            'name' => $validated['name'] ?? $user->name,
            'phone_number' => $validated['phone_number'] ?? $user->phone_number,
            'email' => $validated['email'] ?? $user->email,
            'address' => $validated['address'] ?? $user->address,
            'preferred_language' => $validated['preferred_language'] ?? $user->preferred_language,
            'emergency_contact_name' => $validated['emergency_contact_name'] ?? $user->emergency_contact_name,
            'emergency_contact_phone' => $validated['emergency_contact_phone'] ?? $user->emergency_contact_phone,
        ], fn($val) => !is_null($val)));

        return response()->json([
            'status' => 'success',
            'message' => 'Guardian profile updated successfully.',
            'data' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone_number' => $user->phone_number,
                'address' => $user->address,
                'preferred_language' => $user->preferred_language ?? 'English',
                'emergency_contact_name' => $user->emergency_contact_name,
                'emergency_contact_phone' => $user->emergency_contact_phone,
            ]
        ]);
    }
}

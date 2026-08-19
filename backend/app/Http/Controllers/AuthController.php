<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Services\FirebaseAuthService;
use Exception;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthController extends Controller
{
    protected $firebaseAuth;

    public function __construct(FirebaseAuthService $firebaseAuth)
    {
        $this->firebaseAuth = $firebaseAuth;
    }

    /**
     * Authenticate or register a user using a Firebase ID Token.
     */
    public function firebaseLogin(Request $request)
    {
        $request->validate([
            'id_token' => 'required|string',
            'name' => 'nullable|string',
            'role' => 'nullable|in:admin,teacher,guardian',
        ]);

        try {
            $firebaseProfile = $this->firebaseAuth->verifyIdToken($request->id_token);
            $phoneNumber = $firebaseProfile['phone_number'];
            $firebaseUid = $firebaseProfile['firebase_uid'];

            // Find user by phone number
            $user = User::where('phone_number', $phoneNumber)->first();

            if ($user) {
                // Update firebase UID if changed or empty
                if ($user->firebase_uid !== $firebaseUid) {
                    $user->firebase_uid = $firebaseUid;
                    $user->save();
                }
            } else {
                // Register new user
                $name = $request->name ?? $firebaseProfile['name'] ?? 'Guardian of Student';
                $role = $request->role ?? 'guardian';

                $user = User::create([
                    'name' => $name,
                    'phone_number' => $phoneNumber,
                    'firebase_uid' => $firebaseUid,
                    'role' => $role,
                    'email' => null,
                    'password' => Hash::make(Str::random(16)), // Dummy password
                ]);
            }

            // Create Sanctum Token
            $token = $user->createToken('auth-token')->plainTextToken;

            return response()->json([
                'status' => 'success',
                'token' => $token,
                'user' => [
                    'id' => $user->id,
                    'name' => $user->name,
                    'phone_number' => $user->phone_number,
                    'role' => $user->role,
                    'email' => $user->email,
                ]
            ]);

        } catch (Exception $e) {
            return response()->json([
                'status' => 'error',
                'message' => $e->getMessage()
            ], 401);
        }
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
}

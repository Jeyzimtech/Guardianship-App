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
            if (!str_contains($identifier, '@')) {
                $q->orWhere('email', $lower . '@hillside.ac.zw')
                  ->orWhere('email', $lower . '@chewe.tech')
                  ->orWhere('email', $lower . '@educonnect.co.zw')
                  ->orWhere('email', $lower . '@ctpulse.co.zw');
            }
        })->first();

        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'No account found with these credentials.'
            ], 401);
        }

        // Check password with bcrypt or fallback for seeded accounts
        $passwordMatches = Hash::check($request->password, $user->password)
            || ($request->password === 'chewetech4321#$' && Hash::check('chewetech4321#$', $user->password))
            || ($request->password === 'password123' && Hash::check('password', $user->password))
            || ($request->password === 'password' && Hash::check('password123', $user->password));

        if (!$passwordMatches) {
            return response()->json([
                'status' => 'error',
                'message' => 'Incorrect password. Please try again.'
            ], 401);
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
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email',
            'phone_number' => 'nullable|string|max:50',
            'password' => 'required|string|min:6',
            'role' => 'nullable|in:admin,teacher,guardian,website_admin',
            'school_id' => 'nullable|integer',
        ]);

        $email = strtolower(trim($request->email));
        $phoneNumber = $request->phone_number ? trim($request->phone_number) : null;

        if (!$phoneNumber) {
            $phoneNumber = '+2637' . rand(10000000, 99999999);
        }

        // Ensure unique phone number
        if (User::where('phone_number', $phoneNumber)->exists()) {
            $phoneNumber .= '-' . rand(10, 99);
        }

        $role = $request->role ?? 'guardian';

        $user = User::create([
            'name' => trim($request->name),
            'email' => $email,
            'phone_number' => $phoneNumber,
            'password' => Hash::make($request->password),
            'role' => $role,
            'firebase_uid' => 'uid_' . Str::random(20),
        ]);

        // If registered as teacher with school assignment, associate teacher profile
        if ($role === 'teacher' && $request->filled('school_id')) {
            \App\Models\Teacher::create([
                'user_id' => $user->id,
                'school_id' => $request->school_id,
                'subject_specialties' => ['General'],
            ]);
        }

        $token = $user->createToken('auth-token')->plainTextToken;

        return response()->json([
            'status' => 'success',
            'message' => 'Account created successfully',
            'token' => $token,
            'user' => [
                'id' => $user->id,
                'name' => $user->name,
                'email' => $user->email,
                'phone_number' => $user->phone_number,
                'role' => $user->role,
            ]
        ], 201);
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
                    if (!str_contains($identifier, '@')) {
                        $q->orWhere('email', $lower . '@hillside.ac.zw')
                          ->orWhere('email', $lower . '@chewe.tech')
                          ->orWhere('email', $lower . '@educonnect.co.zw')
                          ->orWhere('email', $lower . '@ctpulse.co.zw');
                    }
                })->first();
            }
        }

        if (!$user) {
            return response()->json([
                'status' => 'error',
                'message' => 'No account found with this email or username.'
            ], 404);
        }

        $passwordMatches = Hash::check($request->current_password, $user->password)
            || ($request->current_password === 'chewetech4321#$' && Hash::check('chewetech4321#$', $user->password))
            || ($request->current_password === 'password123' && Hash::check('password', $user->password))
            || ($request->current_password === 'password' && Hash::check('password123', $user->password));

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
}

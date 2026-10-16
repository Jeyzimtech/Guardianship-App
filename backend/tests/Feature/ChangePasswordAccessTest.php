<?php
namespace Tests\Feature;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ChangePasswordAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_bearer_token_allows_password_change_and_anonymous_requests_are_rejected(): void
    {
        $user = User::create(['name'=>'Parent','email'=>'parent@example.com','role'=>'guardian','phone_number'=>'123','account_uid'=>'parent','password'=>'Before-password-123']);
        $payload = ['current_password'=>'Before-password-123','new_password'=>'After-password-123'];
        $this->postJson('/api/auth/change-password', $payload)->assertUnauthorized();
        $this->withToken($user->createToken('password-test')->plainTextToken)->postJson('/api/auth/change-password', $payload)->assertOk();
        $this->postJson('/api/auth/login', ['email'=>$user->email,'password'=>'After-password-123'])->assertOk();
    }
}

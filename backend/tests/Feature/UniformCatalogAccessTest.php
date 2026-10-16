<?php
namespace Tests\Feature;

use App\Models\{School, Student, User, UniformItem};
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class UniformCatalogAccessTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_catalog_includes_only_own_school_and_global_items(): void
    {
        $school = School::create(['name' => 'School', 'type' => 'primary']);
        $other = School::create(['name' => 'Other', 'type' => 'primary']);
        $admin = User::create(['name' => 'Admin', 'role' => 'admin', 'school_id' => $school->id, 'phone_number' => 'admin-123', 'account_uid' => 'admin']);
        UniformItem::create(['school_id' => $school->id, 'name' => 'Own uniform', 'price_usd' => 10]);
        UniformItem::create(['school_id' => $other->id, 'name' => 'Other uniform', 'price_usd' => 10]);
        $this->actingAs($admin)->getJson('/api/uniforms')->assertOk()->assertJsonCount(1, 'uniforms')->assertJsonPath('uniforms.0.name', 'Own uniform');
    }

    public function test_optional_bearer_auth_identifies_guardians_on_public_catalog_route(): void
    {
        $school = School::create(['name' => 'School', 'type' => 'primary']);
        $student = Student::create(['name' => 'Child', 'school_id' => $school->id, 'grade' => '1', 'class_name' => 'Blue']);
        $parent = User::create(['name' => 'Parent', 'role' => 'guardian', 'phone_number' => '123', 'account_uid' => 'parent']);
        $parent->students()->attach($student->id);
        UniformItem::create(['school_id' => $school->id, 'name' => 'Uniform', 'price_usd' => 10]);
        $token = $parent->createToken('catalog-test')->plainTextToken;
        $this->withToken($token)->getJson('/api/uniforms?school_id='.$school->id)->assertOk()->assertJsonCount(1, 'uniforms');
    }
}

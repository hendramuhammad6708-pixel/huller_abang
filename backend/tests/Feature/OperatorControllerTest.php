<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OperatorControllerTest extends TestCase
{
    use RefreshDatabase;

    private function buatOwner(): User
    {
        return User::create([
            'nama' => 'Pemilik Huller',
            'username' => 'pemilik',
            'password' => 'rahasia123',
            'role' => 'owner',
            'aktif' => true,
        ]);
    }

    private function buatOperator(array $atribut = []): User
    {
        return User::create(array_merge([
            'nama' => 'Operator Satu',
            'username' => 'operator1',
            'password' => 'rahasia123',
            'role' => 'operator',
            'aktif' => true,
        ], $atribut));
    }

    public function test_operator_tidak_bisa_mengakses_crud(): void
    {
        Sanctum::actingAs($this->buatOperator());

        $this->getJson('/api/operators')->assertStatus(403);
        $this->postJson('/api/operators', [])->assertStatus(403);
        $this->putJson('/api/operators/1', [])->assertStatus(403);
        $this->deleteJson('/api/operators/1')->assertStatus(403);
    }

    public function test_tanpa_token_mendapat_401(): void
    {
        $this->getJson('/api/operators')->assertStatus(401);
    }

    public function test_owner_melihat_daftar_hanya_operator(): void
    {
        $owner = $this->buatOwner();
        $operator = $this->buatOperator();
        Sanctum::actingAs($owner);

        $respons = $this->getJson('/api/operators')->assertOk();

        $this->assertCount(1, $respons->json('data.operators'));
        $this->assertSame($operator->id, $respons->json('data.operators.0.id'));
    }

    public function test_owner_menambah_operator_dengan_password_terhash(): void
    {
        Sanctum::actingAs($this->buatOwner());

        $respons = $this->postJson('/api/operators', [
            'nama' => 'Operator Dua',
            'username' => 'operator2',
            'password' => 'rahasia456',
        ])->assertStatus(201);

        $this->assertDatabaseHas('users', [
            'id' => $respons->json('data.operator.id'),
            'role' => 'operator',
        ]);

        $this->assertTrue(Hash::check('rahasia456', User::find($respons->json('data.operator.id'))->password));
    }

    public function test_operator_baru_bisa_login_dengan_password_baru(): void
    {
        Sanctum::actingAs($this->buatOwner());
        $this->postJson('/api/operators', [
            'nama' => 'Operator Dua',
            'username' => 'operator2',
            'password' => 'rahasia456',
        ])->assertStatus(201);

        $this->postJson('/api/login', [
            'username' => 'operator2',
            'password' => 'rahasia456',
        ])->assertOk()->assertJsonPath('data.user.role', 'operator');
    }

    public function test_username_ditolak_jika_sudah_dipakai(): void
    {
        $this->buatOperator(['username' => 'sudah-ada']);
        Sanctum::actingAs($this->buatOwner());

        $this->postJson('/api/operators', [
            'nama' => 'Operator Baru',
            'username' => 'sudah-ada',
            'password' => 'rahasia456',
        ])->assertStatus(422)
            ->assertJsonPath('message', 'Data tidak valid')
            ->assertJsonPath('errors.0.field', 'username');
    }

    public function test_owner_melihat_detail_operator_saja(): void
    {
        $operator = $this->buatOperator();
        $owner = $this->buatOwner();
        Sanctum::actingAs($owner);

        $this->getJson('/api/operators/'.$operator->id)
            ->assertOk()
            ->assertJsonPath('data.operator.username', 'operator1');

        $this->getJson('/api/operators/'.$owner->id)->assertStatus(404);
    }

    public function test_owner_memperbarui_operator(): void
    {
        $operator = $this->buatOperator();
        Sanctum::actingAs($this->buatOwner());

        $this->putJson('/api/operators/'.$operator->id, [
            'nama' => 'Operator Diganti',
            'password' => 'barusandi1',
        ])->assertOk()->assertJsonPath('data.operator.nama', 'Operator Diganti');

        $operator->refresh();
        $this->assertSame('Operator Diganti', $operator->nama);
        $this->assertTrue(Hash::check('barusandi1', $operator->password));
        $this->assertFalse(Hash::check('rahasia123', $operator->password));
    }

    public function test_owner_menghapus_operator_dan_token_ikut_tercabut(): void
    {
        $operator = $this->buatOperator();
        $operator->createToken('auth');
        Sanctum::actingAs($this->buatOwner());

        $this->deleteJson('/api/operators/'.$operator->id)
            ->assertOk()
            ->assertJsonPath('data', null);

        $this->assertDatabaseMissing('users', ['id' => $operator->id]);
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }
}

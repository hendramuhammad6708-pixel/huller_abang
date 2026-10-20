<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    private function buatPengguna(array $atribut = []): User
    {
        return User::create(array_merge([
            'nama' => 'Owner Huller Abang',
            'username' => 'pemilik',
            'password' => 'rahasia123',
            'role' => 'owner',
            'aktif' => true,
        ], $atribut));
    }

    public function test_login_menghasilkan_token_bearer_dan_data_pengguna(): void
    {
        $this->buatPengguna();

        $respons = $this->postJson('/api/login', [
            'username' => 'pemilik',
            'password' => 'rahasia123',
        ]);

        $respons->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.token_type', 'Bearer')
            ->assertJsonPath('data.user.username', 'pemilik')
            ->assertJsonPath('data.user.role', 'owner')
            ->assertJsonPath('data.user.password', null);

        $this->assertNotEmpty($respons->json('data.token'));
        $this->assertDatabaseCount('personal_access_tokens', 1);
    }

    public function test_login_ditolak_jika_kata_sandi_salah(): void
    {
        $this->buatPengguna();

        $respons = $this->postJson('/api/login', [
            'username' => 'pemilik',
            'password' => 'salah',
        ]);

        $respons->assertStatus(401)->assertJsonPath('success', false);
    }

    public function test_login_ditolak_jika_username_tidak_terdaftar(): void
    {
        $respons = $this->postJson('/api/login', [
            'username' => 'tidak-ada',
            'password' => 'rahasia123',
        ]);

        $respons->assertStatus(401)->assertJsonPath('success', false);
    }

    public function test_login_ditolak_jika_akun_nonaktif(): void
    {
        $this->buatPengguna(['aktif' => false]);

        $this->postJson('/api/login', [
            'username' => 'pemilik',
            'password' => 'rahasia123',
        ])->assertStatus(403)->assertJsonPath('success', false);
    }

    public function test_login_memvalidasi_input_wajib(): void
    {
        $this->postJson('/api/login', [])->assertStatus(422);

        $this->postJson('/api/login', ['username' => 'pemilik'])
            ->assertStatus(422)
            ->assertJsonPath('message', 'Data tidak valid')
            ->assertJsonPath('errors.0.field', 'password');
    }

    public function test_me_membutuhkan_token(): void
    {
        $this->getJson('/api/me')->assertStatus(401);
    }

    public function test_me_mengembalikan_data_pengguna_terautentikasi(): void
    {
        $pengguna = $this->buatPengguna();
        $token = $pengguna->createToken('auth')->plainTextToken;

        $this->withToken($token)->getJson('/api/me')
            ->assertOk()
            ->assertJsonPath('data.id', $pengguna->id)
            ->assertJsonPath('data.username', 'pemilik')
            ->assertJsonPath('data.password', null);
    }

    public function test_logout_mencabut_token_dari_database(): void
    {
        $pengguna = $this->buatPengguna();
        $token = $pengguna->createToken('auth')->plainTextToken;

        $this->withToken($token)->postJson('/api/logout')
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertDatabaseCount('personal_access_tokens', 0);
    }

    public function test_token_yang_sudah_dicabut_ditolak(): void
    {
        $pengguna = $this->buatPengguna();
        $token = $pengguna->createToken('auth')->plainTextToken;
        $pengguna->tokens()->delete();

        $this->withToken($token)->getJson('/api/me')->assertStatus(401);
    }
}

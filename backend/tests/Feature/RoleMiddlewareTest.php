<?php

namespace Tests\Feature;

use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Route;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RoleMiddlewareTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Route::middleware(['auth:sanctum', 'role:owner'])->get('/api/_uji-hak-akses', function () {
            return ApiResponse::sukses('ok');
        });

        Route::middleware(['auth:sanctum', 'role:operator,owner'])->get('/api/_uji-hak-akses-ganda', function () {
            return ApiResponse::sukses('ok');
        });
    }

    private function buatPengguna(string $role): User
    {
        return User::create([
            'nama' => 'Pengguna '.ucfirst($role),
            'username' => $role.'_uji',
            'password' => 'rahasia123',
            'role' => $role,
            'aktif' => true,
        ]);
    }

    public function test_owner_diizinkan_mengakses_rute_role_owner(): void
    {
        Sanctum::actingAs($this->buatPengguna('owner'));

        $this->getJson('/api/_uji-hak-akses')
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    public function test_operator_mendapat_403_dengan_envelope_pesan(): void
    {
        Sanctum::actingAs($this->buatPengguna('operator'));

        $this->getJson('/api/_uji-hak-akses')
            ->assertStatus(403)
            ->assertJsonPath('success', false)
            ->assertJsonPath('message', 'Anda tidak memiliki akses untuk resource ini.');
    }

    public function test_tanpa_token_mendapat_401_bukan_403(): void
    {
        $this->getJson('/api/_uji-hak-akses')->assertStatus(401);
    }

    public function test_bebanagan_peran_didukung_misal_role_operator_atau_owner(): void
    {
        Sanctum::actingAs($this->buatPengguna('operator'));

        $this->getJson('/api/_uji-hak-akses-ganda')
            ->assertOk()
            ->assertJsonPath('success', true);
    }
}

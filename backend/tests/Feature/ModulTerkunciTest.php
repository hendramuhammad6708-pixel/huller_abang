<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ModulTerkunciTest extends TestCase
{
    use RefreshDatabase;

    // Alamat modul yang wajib terkunci (role owner).
    // GET /pelanggan, /pengaturan, dan /kelas-padi sengaja dikecualikan:
    // operator butuh data master itu untuk mengisi form padi masuk.
    // POST /pelanggan juga dikecualikan: operator boleh menambah pelanggan baru
    // (aturannya diuji di PelangganOperatorTest).
    private const ALAMAT = [
        ['GET', '/api/pelanggan/1'],
        ['GET', '/api/pelanggan/1/riwayat-transaksi'],
        ['PUT', '/api/pelanggan/1'],
        ['DELETE', '/api/pelanggan/1'],
        ['PUT', '/api/pengaturan'],
        ['POST', '/api/kelas-padi'],
        ['PUT', '/api/kelas-padi/1'],
        ['DELETE', '/api/kelas-padi/1'],
    ];

    public function test_tanpa_token_dapat_401(): void
    {
        foreach (self::ALAMAT as [$metode, $alamat]) {
            $this->json($metode, $alamat, [])
                ->assertStatus(401)
                ->assertJsonPath('success', false);
        }
    }

    public function test_tanpa_header_json_dapat_401_json_bukan_error(): void
    {
        // dulu 500 "Route [login] not defined" karena guest di-redirect ke route web
        $this->get('/api/pelanggan')
            ->assertStatus(401)
            ->assertHeader('Content-Type', 'application/json')
            ->assertJsonPath('success', false);
    }

    public function test_operator_mendapat_403(): void
    {
        Sanctum::actingAs(User::create([
            'nama' => 'Operator Satu',
            'username' => 'operator1',
            'password' => 'rahasia123',
            'role' => 'operator',
            'aktif' => true,
        ]));

        foreach (self::ALAMAT as [$metode, $alamat]) {
            $this->json($metode, $alamat, [])
                ->assertStatus(403)
                ->assertJsonPath('message', 'Anda tidak memiliki akses untuk resource ini.');
        }
    }

    public function test_operator_bisa_membaca_master_pendukung_form_padi_masuk(): void
    {
        Sanctum::actingAs(User::create([
            'nama' => 'Operator Satu',
            'username' => 'operator1',
            'password' => 'rahasia123',
            'role' => 'operator',
            'aktif' => true,
        ]));

        $this->getJson('/api/pelanggan?limit=100')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['items', 'meta']]);

        $this->getJson('/api/pengaturan')
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->getJson('/api/kelas-padi')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['items', 'meta']]);
    }

    public function test_login_dan_health_tetap_publik(): void
    {
        $this->getJson('/api/health')->assertOk();
        $this->postJson('/api/login', [])->assertStatus(422);
    }
}

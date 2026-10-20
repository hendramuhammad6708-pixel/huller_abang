<?php

namespace Tests\Feature;

use App\Models\Pelanggan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PelangganTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        $this->sebagaiOwner();
    }

    // Modul pelanggan terkunci: butuh token + role owner
    private function sebagaiOwner(): void
    {
        Sanctum::actingAs(User::create([
            'nama' => 'Pemilik Huller',
            'username' => 'pemilik',
            'password' => 'rahasia123',
            'role' => 'owner',
            'aktif' => true,
        ]));
    }

    private function data(array $ubah = []): array
    {
        return array_merge([
            'nama' => 'Pak Budi',
            'kontak' => '081234567890',
            'tipe_pelanggan' => 'petani',
        ], $ubah);
    }

    public function test_tambah_pelanggan_valid(): void
    {
        $this->postJson('/api/pelanggan', $this->data())
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonStructure(['data' => ['id']]);

        $this->assertDatabaseHas('pelanggan', ['nama' => 'Pak Budi']);
    }

    public function test_nama_kosong_ditolak(): void
    {
        $this->postJson('/api/pelanggan', $this->data(['nama' => '']))
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('errors.0.field', 'nama');
    }

    public function test_tipe_salah_ditolak(): void
    {
        $this->postJson('/api/pelanggan', $this->data(['tipe_pelanggan' => 'abc']))
            ->assertStatus(422)
            ->assertJsonPath('errors.0.field', 'tipe_pelanggan');
    }

    public function test_kontak_salah_ditolak(): void
    {
        $this->postJson('/api/pelanggan', $this->data(['kontak' => '12ab']))
            ->assertStatus(422)
            ->assertJsonPath('errors.0.field', 'kontak');
    }

    public function test_kontak_boleh_kosong(): void
    {
        $this->postJson('/api/pelanggan', ['nama' => 'Bu Sari', 'tipe_pelanggan' => 'pengepul'])
            ->assertStatus(201);
    }

    public function test_error_validasi_tanpa_header_accept_tetap_json(): void
    {
        // memakai post() biasa (bukan postJson) untuk memastikan bukan redirect
        $this->post('/api/pelanggan', ['nama' => ''])
            ->assertStatus(422)
            ->assertJsonPath('success', false);
    }

    public function test_daftar_cari_dan_filter_tipe(): void
    {
        Pelanggan::create($this->data(['nama' => 'Pak Budi']));
        Pelanggan::create($this->data(['nama' => 'Bu Sari', 'tipe_pelanggan' => 'pengepul']));

        $this->getJson('/api/pelanggan?search=bud')
            ->assertOk()
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.meta.total', 1);

        $this->getJson('/api/pelanggan?tipe=pengepul')
            ->assertOk()
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.items.0.nama', 'Bu Sari');

        $this->getJson('/api/pelanggan')
            ->assertOk()
            ->assertJsonPath('data.meta.total', 2);
    }

    public function test_detail_pelanggan(): void
    {
        $p = Pelanggan::create($this->data());

        $this->getJson('/api/pelanggan/'.$p->id)
            ->assertOk()
            ->assertJsonPath('data.nama', 'Pak Budi');
    }

    public function test_ubah_pelanggan(): void
    {
        $p = Pelanggan::create($this->data());

        $this->putJson('/api/pelanggan/'.$p->id, $this->data(['tipe_pelanggan' => 'pengepul']))
            ->assertOk();

        $this->assertDatabaseHas('pelanggan', ['id' => $p->id, 'tipe_pelanggan' => 'pengepul']);
    }

    public function test_hapus_aman_data_tetap_ada_di_database(): void
    {
        $p = Pelanggan::create($this->data());

        $this->deleteJson('/api/pelanggan/'.$p->id)->assertOk();

        $this->assertSoftDeleted('pelanggan', ['id' => $p->id]);
        $this->getJson('/api/pelanggan/'.$p->id)->assertStatus(404);
        $this->getJson('/api/pelanggan')->assertJsonCount(0, 'data.items');
        $this->deleteJson('/api/pelanggan/'.$p->id)->assertStatus(404);
    }

    public function test_id_tidak_ada_404(): void
    {
        $this->getJson('/api/pelanggan/99999999')
            ->assertStatus(404)
            ->assertJsonPath('success', false);
    }
}

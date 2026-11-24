<?php

namespace Tests\Feature;

use App\Models\KelasPadi;
use App\Models\PadiMasuk;
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

    private function padi(Pelanggan $pelanggan, KelasPadi $kelas, array $ubah = []): PadiMasuk
    {
        return PadiMasuk::create(array_merge([
            'tanggal' => '2026-10-26',
            'pelanggan_id' => $pelanggan->id,
            'kelas_padi_id' => $kelas->id,
            'berat_basah_kg' => 250.5,
            'status_transaksi' => PadiMasuk::STATUS_MASUK,
        ], $ubah));
    }

    public function test_tambah_pelanggan_valid(): void
    {
        $this->postJson('/api/pelanggan', $this->data())
            ->assertStatus(201)
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.nama', 'Pak Budi')
            ->assertJsonPath('data.kontak', '081234567890')
            ->assertJsonPath('data.tipe_pelanggan', 'petani')
            ->assertJsonStructure(['data' => ['id', 'nama', 'kontak', 'tipe_pelanggan']]);

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

    public function test_riwayat_transaksi_pelanggan(): void
    {
        $p = Pelanggan::create($this->data());
        $lain = Pelanggan::create($this->data(['nama' => 'Bu Sari']));
        $kelas = KelasPadi::create(['nama_kelas' => 'Premium']);
        $padi = $this->padi($p, $kelas);
        $this->padi($lain, $kelas);

        $this->getJson('/api/pelanggan/'.$p->id.'/riwayat-transaksi')
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Riwayat transaksi pelanggan')
            ->assertJsonPath('data.pelanggan.nama', 'Pak Budi')
            ->assertJsonPath('data.pelanggan.status_terakhir', 'masuk')
            ->assertJsonPath('data.pelanggan.status_terakhir_label', 'Masuk')
            ->assertJsonPath('data.pelanggan.tanggal_terakhir', '2026-10-26')
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.items.0.id', $padi->id)
            ->assertJsonPath('data.items.0.pelanggan.nama', 'Pak Budi')
            ->assertJsonPath('data.items.0.kelas_padi.nama_kelas', 'Premium')
            ->assertJsonPath('data.items.0.berat_basah_kg', 250.5)
            ->assertJsonPath('data.items.0.status_label', 'Masuk')
            ->assertJsonPath('data.meta.total', 1)
            ->assertJsonStructure(['data' => ['pelanggan', 'items', 'meta']]);
    }

    public function test_riwayat_transaksi_filter_status_tanggal_dan_halaman(): void
    {
        $p = Pelanggan::create($this->data());
        $kelas = KelasPadi::create(['nama_kelas' => 'Premium']);
        $lama = $this->padi($p, $kelas, ['tanggal' => '2026-10-20']);
        $baru = $this->padi($p, $kelas, [
            'tanggal' => '2026-10-26',
            'status_transaksi' => PadiMasuk::STATUS_SIAP_GILING,
        ]);

        $this->getJson('/api/pelanggan/'.$p->id.'/riwayat-transaksi?status=siap_giling&tanggal_dari=2026-10-25&tanggal_sampai=2026-10-27')
            ->assertOk()
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.items.0.id', $baru->id)
            ->assertJsonPath('data.meta.total', 1);

        $this->getJson('/api/pelanggan/'.$p->id.'/riwayat-transaksi?limit=1&page=2')
            ->assertOk()
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.items.0.id', $lama->id)
            ->assertJsonPath('data.meta.page', 2)
            ->assertJsonPath('data.meta.limit', 1)
            ->assertJsonPath('data.meta.total', 2);
    }

    public function test_status_terakhir_memakai_transaksi_aktif_terbaru(): void
    {
        $p = Pelanggan::create($this->data());
        $kelas = KelasPadi::create(['nama_kelas' => 'Premium']);

        $this->padi($p, $kelas, [
            'tanggal' => '2026-10-20',
            'status_transaksi' => PadiMasuk::STATUS_SELESAI_GILING,
        ]);
        $this->padi($p, $kelas, [
            'tanggal' => '2026-10-26',
            'status_transaksi' => PadiMasuk::STATUS_DIJEMUR,
        ]);
        $this->padi($p, $kelas, [
            'tanggal' => '2026-10-27',
            'status_transaksi' => PadiMasuk::STATUS_VOID,
        ]);

        $this->getJson('/api/pelanggan/'.$p->id.'/riwayat-transaksi')
            ->assertOk()
            ->assertJsonPath('data.pelanggan.status_terakhir', 'dijemur')
            ->assertJsonPath('data.pelanggan.status_terakhir_label', 'Dijemur')
            ->assertJsonPath('data.terakhir.status', 'dijemur')
            ->assertJsonPath('data.meta.total', 3);
    }

    public function test_riwayat_transaksi_validasi_filter(): void
    {
        $p = Pelanggan::create($this->data());

        $this->getJson('/api/pelanggan/'.$p->id.'/riwayat-transaksi?limit=101')
            ->assertStatus(422)
            ->assertJsonPath('errors.0.field', 'limit');

        $this->getJson('/api/pelanggan/'.$p->id.'/riwayat-transaksi?tanggal_dari=2026-10-27&tanggal_sampai=2026-10-26')
            ->assertStatus(422)
            ->assertJsonPath('errors.0.field', 'tanggal_sampai');

        $this->getJson('/api/pelanggan/'.$p->id.'/riwayat-transaksi?status=asal')
            ->assertStatus(422)
            ->assertJsonPath('errors.0.field', 'status');
    }

    public function test_riwayat_transaksi_pelanggan_tidak_ada_atau_terhapus_404(): void
    {
        $this->getJson('/api/pelanggan/99999999/riwayat-transaksi')->assertStatus(404);

        $p = Pelanggan::create($this->data());
        $p->delete();

        $this->getJson('/api/pelanggan/'.$p->id.'/riwayat-transaksi')->assertStatus(404);
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

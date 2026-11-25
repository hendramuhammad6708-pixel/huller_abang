<?php

namespace Tests\Feature;

use App\Models\KelasPadi;
use App\Models\PadiMasuk;
use App\Models\Pelanggan;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PadiMasukTest extends TestCase
{
    use RefreshDatabase;

    private User $operator;

    private Pelanggan $pelanggan;

    private KelasPadi $kelas;

    protected function setUp(): void
    {
        parent::setUp();

        // Operator adalah pengguna utama modul ini
        $this->operator = User::create([
            'nama' => 'Operator Satu',
            'username' => 'operator1',
            'password' => 'rahasia123',
            'role' => 'operator',
            'aktif' => true,
        ]);
        Sanctum::actingAs($this->operator);

        $this->pelanggan = Pelanggan::create(['nama' => 'Pak Budi', 'tipe_pelanggan' => 'petani']);
        $this->kelas = KelasPadi::create(['nama_kelas' => 'Premium']);
    }

    private function data(array $ubah = []): array
    {
        return array_merge([
            'tanggal' => now()->toDateString(),
            'pelanggan_id' => $this->pelanggan->id,
            'kelas_padi_id' => $this->kelas->id,
            'berat_basah_kg' => 250.5,
            'catatan' => 'Agak basah',
        ], $ubah);
    }

    private function buat(array $ubah = []): PadiMasuk
    {
        return PadiMasuk::create(array_merge([
            'tanggal' => now()->toDateString(),
            'pelanggan_id' => $this->pelanggan->id,
            'kelas_padi_id' => $this->kelas->id,
            'berat_basah_kg' => 100,
            'status_transaksi' => PadiMasuk::STATUS_MASUK,
        ], $ubah));
    }

    public function test_catat_padi_masuk(): void
    {
        $respons = $this->postJson('/api/padi-masuk', $this->data())
            ->assertCreated()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.status', 'masuk')
            ->assertJsonPath('data.status_label', 'Masuk')
            ->assertJsonPath('data.berat_basah_kg', 250.5)
            ->assertJsonPath('data.nama_pelanggan', 'Pak Budi')
            ->assertJsonPath('data.nama_kelas', 'Premium')
            ->assertJsonPath('data.catatan', 'Agak basah');

        $id = $respons->json('data.id');
        $this->assertSame(
            'PM-'.now()->format('Ymd').'-'.str_pad((string) $id, 4, '0', STR_PAD_LEFT),
            $respons->json('data.nomor_transaksi')
        );
        $this->assertDatabaseHas('padi_masuk', ['id' => $id, 'dibuat_oleh' => $this->operator->id]);
        $this->assertDatabaseHas('log_padi_masuk', ['padi_masuk_id' => $id, 'aksi' => 'dibuat']);
    }

    public function test_catatan_boleh_kosong(): void
    {
        $this->postJson('/api/padi-masuk', $this->data(['catatan' => null]))
            ->assertCreated()
            ->assertJsonPath('data.catatan', null);
    }

    public function test_validasi_catat_padi_masuk(): void
    {
        $this->postJson('/api/padi-masuk', [])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonFragment(['field' => 'tanggal'])
            ->assertJsonFragment(['field' => 'pelanggan_id'])
            ->assertJsonFragment(['field' => 'kelas_padi_id'])
            ->assertJsonFragment(['field' => 'berat_basah_kg']);

        $this->postJson('/api/padi-masuk', $this->data(['berat_basah_kg' => 0]))
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'berat_basah_kg');

        $this->postJson('/api/padi-masuk', $this->data(['tanggal' => now()->addDay()->toDateString()]))
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'tanggal');

        $this->postJson('/api/padi-masuk', $this->data(['pelanggan_id' => 99999]))
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'pelanggan_id');

        $this->postJson('/api/padi-masuk', $this->data(['catatan' => str_repeat('a', 256)]))
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'catatan');
    }

    public function test_pelanggan_terhapus_tidak_bisa_dipilih(): void
    {
        $this->pelanggan->delete();

        $this->postJson('/api/padi-masuk', $this->data())
            ->assertStatus(422)
            ->assertJsonPath('errors.0.field', 'pelanggan_id');
    }

    public function test_daftar_memakai_items_dan_meta_serta_filter(): void
    {
        $lain = Pelanggan::create(['nama' => 'Bu Sari', 'tipe_pelanggan' => 'pengepul']);
        $lama = $this->buat(['tanggal' => '2026-10-20']);
        $baru = $this->buat(['tanggal' => '2026-10-26']);
        $this->buat(['tanggal' => '2026-10-26', 'pelanggan_id' => $lain->id]);

        $this->getJson('/api/padi-masuk?limit=100')
            ->assertOk()
            ->assertJsonPath('data.meta.total', 3)
            ->assertJsonPath('data.meta.limit', 100)
            ->assertJsonStructure(['data' => ['items' => [['id', 'nomor_transaksi', 'tanggal']], 'meta']]);

        $this->getJson('/api/padi-masuk?dari=2026-10-25&sampai=2026-10-27&pelanggan_id='.$this->pelanggan->id)
            ->assertOk()
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.items.0.id', $baru->id);

        $this->getJson('/api/padi-masuk?limit=1&page=2&pelanggan_id='.$this->pelanggan->id)
            ->assertOk()
            ->assertJsonPath('data.items.0.id', $lama->id)
            ->assertJsonPath('data.meta.page', 2);
    }

    public function test_meta_berisi_ringkasan_seluruh_hasil_filter_tanpa_void(): void
    {
        $this->buat(['berat_basah_kg' => 100]);
        $this->buat(['berat_basah_kg' => 50.5]);
        $this->buat(['berat_basah_kg' => 999, 'status_transaksi' => PadiMasuk::STATUS_VOID]);

        // limit=1 hanya memuat satu baris, tetapi ringkasan mencakup semua transaksi aktif
        $this->getJson('/api/padi-masuk?limit=1')
            ->assertOk()
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.meta.total', 3)
            ->assertJsonPath('data.meta.jumlah_aktif', 2)
            ->assertJsonPath('data.meta.total_berat_kg', 150.5);
    }

    public function test_daftar_menampilkan_void_dan_validasi_filter(): void
    {
        $padi = $this->buat();
        $this->postJson("/api/padi-masuk/{$padi->id}/void", ['alasan' => 'Salah input'])->assertOk();

        $this->getJson('/api/padi-masuk?status=void')
            ->assertOk()
            ->assertJsonCount(1, 'data.items')
            ->assertJsonPath('data.items.0.void_reason', 'Salah input')
            ->assertJsonPath('data.items.0.void_by', $this->operator->id);

        $this->getJson('/api/padi-masuk?limit=101')->assertStatus(422)->assertJsonPath('errors.0.field', 'limit');
        $this->getJson('/api/padi-masuk?status=asal')->assertStatus(422)->assertJsonPath('errors.0.field', 'status');
        $this->getJson('/api/padi-masuk?dari=2026-10-27&sampai=2026-10-26')
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'sampai');
    }

    public function test_detail_dan_404(): void
    {
        $padi = $this->buat();

        $this->getJson("/api/padi-masuk/{$padi->id}")
            ->assertOk()
            ->assertJsonPath('data.id', $padi->id)
            ->assertJsonPath('data.pelanggan.nama', 'Pak Budi')
            ->assertJsonPath('data.kelas_padi.nama_kelas', 'Premium')
            ->assertJsonPath('data.penjemuran', null);

        $this->getJson('/api/padi-masuk/99999')->assertStatus(404);
    }

    public function test_ubah_hanya_saat_status_masuk(): void
    {
        $padi = $this->buat();

        $this->putJson("/api/padi-masuk/{$padi->id}", $this->data(['berat_basah_kg' => 300]))
            ->assertOk()
            ->assertJsonPath('data.berat_basah_kg', 300);

        $padi->update(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);

        $this->putJson("/api/padi-masuk/{$padi->id}", $this->data())
            ->assertStatus(409)
            ->assertJsonPath('success', false);
    }

    public function test_void_wajib_alasan_dan_tidak_bisa_dua_kali(): void
    {
        $padi = $this->buat();

        $this->postJson("/api/padi-masuk/{$padi->id}/void", [])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'alasan');
        $this->postJson("/api/padi-masuk/{$padi->id}/void", ['alasan' => 'ab'])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'alasan');

        $this->postJson("/api/padi-masuk/{$padi->id}/void", ['alasan' => 'Salah input'])
            ->assertOk()
            ->assertJsonPath('data.status', 'void');

        $this->assertDatabaseHas('padi_masuk', ['id' => $padi->id, 'status_transaksi' => 'void', 'void_by' => $this->operator->id]);
        $this->assertDatabaseHas('log_padi_masuk', ['padi_masuk_id' => $padi->id, 'aksi' => 'void', 'keterangan' => 'Salah input']);

        $this->postJson("/api/padi-masuk/{$padi->id}/void", ['alasan' => 'Salah input'])->assertStatus(409);
    }

    public function test_void_ditolak_bila_sudah_selesai_giling(): void
    {
        $padi = $this->buat(['status_transaksi' => PadiMasuk::STATUS_SELESAI_GILING]);

        $this->postJson("/api/padi-masuk/{$padi->id}/void", ['alasan' => 'Salah input'])->assertStatus(409);
    }

    public function test_selesai_giling_hanya_dari_siap_giling(): void
    {
        $padi = $this->buat();

        $this->postJson("/api/padi-masuk/{$padi->id}/selesai-giling")->assertStatus(409);

        $padi->update(['status_transaksi' => PadiMasuk::STATUS_SIAP_GILING]);

        $this->postJson("/api/padi-masuk/{$padi->id}/selesai-giling")
            ->assertOk()
            ->assertJsonPath('data.status', 'selesai_giling')
            ->assertJsonPath('data.tanggal_selesai_giling', now()->toDateString());
    }

    public function test_log_transaksi(): void
    {
        $respons = $this->postJson('/api/padi-masuk', $this->data())->assertCreated();
        $id = $respons->json('data.id');

        $this->getJson("/api/padi-masuk/{$id}/log")
            ->assertOk()
            ->assertJsonPath('data.meta.total', 1)
            ->assertJsonPath('data.items.0.aksi', 'dibuat')
            ->assertJsonPath('data.items.0.user.nama', 'Operator Satu');
    }
}

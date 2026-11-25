<?php

namespace Tests\Feature;

use App\Models\KelasPadi;
use App\Models\PadiMasuk;
use App\Models\Pelanggan;
use App\Models\Penjemuran;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PenjemuranTest extends TestCase
{
    use RefreshDatabase;

    private Pelanggan $pelanggan;

    private KelasPadi $kelas;

    protected function setUp(): void
    {
        parent::setUp();

        Sanctum::actingAs(User::create([
            'nama' => 'Operator Satu',
            'username' => 'operator1',
            'password' => 'rahasia123',
            'role' => 'operator',
            'aktif' => true,
        ]));

        $this->pelanggan = Pelanggan::create(['nama' => 'Pak Budi', 'tipe_pelanggan' => 'petani']);
        $this->kelas = KelasPadi::create(['nama_kelas' => 'Premium']);
    }

    private function padi(array $ubah = []): PadiMasuk
    {
        return PadiMasuk::create(array_merge([
            'tanggal' => now()->subDays(3)->toDateString(),
            'pelanggan_id' => $this->pelanggan->id,
            'kelas_padi_id' => $this->kelas->id,
            'berat_basah_kg' => 200,
            'status_transaksi' => PadiMasuk::STATUS_MASUK,
        ], $ubah));
    }

    public function test_alur_masuk_dijemur_siap_giling(): void
    {
        $padi = $this->padi();
        // Jemur minimal 2 hari: mulai 3 hari lalu, selesai kemarin = 2 hari
        $mulai = now()->subDays(3)->toDateString();
        $selesai = now()->subDay()->toDateString();

        $this->postJson("/api/penjemuran/{$padi->id}/mulai", ['tanggal_mulai' => $mulai])
            ->assertOk()
            ->assertJsonPath('data.status', 'dijemur')
            ->assertJsonPath('data.tanggal_mulai', $mulai)
            ->assertJsonPath('data.pelanggan', 'Pak Budi')
            ->assertJsonPath('data.kelas', 'Premium');

        $this->postJson("/api/penjemuran/{$padi->id}/selesai", ['tanggal_selesai' => $selesai, 'berat_kering' => 170])
            ->assertOk()
            ->assertJsonPath('data.status', 'siap_giling')
            ->assertJsonPath('data.berat_kering', 170)
            ->assertJsonPath('data.tanggal_selesai', $selesai);

        // Persen susut = (200 - 170) / 200 x 100 = 15
        $this->assertDatabaseHas('padi_masuk', ['id' => $padi->id, 'status_transaksi' => 'siap_giling', 'persen_susut' => 15]);
        $this->assertDatabaseHas('log_padi_masuk', ['padi_masuk_id' => $padi->id, 'aksi' => 'mulai_jemur']);
        $this->assertDatabaseHas('log_padi_masuk', ['padi_masuk_id' => $padi->id, 'aksi' => 'selesai_jemur']);
    }

    public function test_penjemuran_kurang_dari_2_hari_tidak_bisa_diselesaikan(): void
    {
        $padi = $this->padi(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);
        // Mulai kemarin: hari ini baru hari ke-1
        Penjemuran::create(['padi_masuk_id' => $padi->id, 'tanggal_mulai' => now()->subDay()->toDateString()]);
        $paling = now()->addDay()->toDateString();

        $this->postJson("/api/penjemuran/{$padi->id}/selesai", [
            'tanggal_selesai' => now()->toDateString(),
            'berat_kering' => 150,
        ])
            ->assertStatus(422)
            ->assertJsonPath('success', false)
            ->assertJsonPath('errors.0.field', 'tanggal_selesai')
            ->assertJsonPath('errors.0.message', "Penjemuran minimal 2 hari. Paling cepat bisa diselesaikan pada {$paling}.");

        // Tidak ada yang berubah
        $this->assertDatabaseHas('padi_masuk', ['id' => $padi->id, 'status_transaksi' => 'dijemur', 'berat_kering_kg' => null]);
    }

    public function test_penjemuran_tepat_2_hari_boleh_diselesaikan(): void
    {
        $padi = $this->padi(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);
        Penjemuran::create(['padi_masuk_id' => $padi->id, 'tanggal_mulai' => now()->subDays(2)->toDateString()]);

        $this->postJson("/api/penjemuran/{$padi->id}/selesai", [
            'tanggal_selesai' => now()->toDateString(),
            'berat_kering' => 150,
        ])
            ->assertOk()
            ->assertJsonPath('data.status', 'siap_giling')
            ->assertJsonPath('data.durasi_hari', 2);
    }

    public function test_tanggal_selesai_di_masa_depan_tetap_ditolak(): void
    {
        $padi = $this->padi(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);
        Penjemuran::create(['padi_masuk_id' => $padi->id, 'tanggal_mulai' => now()->subDays(5)->toDateString()]);

        $this->postJson("/api/penjemuran/{$padi->id}/selesai", [
            'tanggal_selesai' => now()->addDay()->toDateString(),
            'berat_kering' => 150,
        ])->assertStatus(422)->assertJsonPath('errors.0.field', 'tanggal_selesai');
    }

    public function test_daftar_memberi_tahu_apakah_sudah_boleh_diselesaikan(): void
    {
        $baru = $this->padi(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);
        Penjemuran::create(['padi_masuk_id' => $baru->id, 'tanggal_mulai' => now()->subDay()->toDateString()]);

        $cukup = $this->padi(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);
        Penjemuran::create(['padi_masuk_id' => $cukup->id, 'tanggal_mulai' => now()->subDays(2)->toDateString()]);

        $belumMulai = $this->padi();

        $baris = collect($this->getJson('/api/penjemuran')->assertOk()->json('data'))->keyBy('id');

        $this->assertFalse($baris[$baru->id]['boleh_diselesaikan']);
        $this->assertSame(now()->addDay()->toDateString(), $baris[$baru->id]['tanggal_paling_cepat_selesai']);
        $this->assertTrue($baris[$cukup->id]['boleh_diselesaikan']);
        $this->assertSame(now()->toDateString(), $baris[$cukup->id]['tanggal_paling_cepat_selesai']);
        $this->assertFalse($baris[$belumMulai->id]['boleh_diselesaikan']);
        $this->assertNull($baris[$belumMulai->id]['tanggal_paling_cepat_selesai']);
    }

    public function test_koreksi_tidak_boleh_membuat_penjemuran_selesai_kurang_dari_2_hari(): void
    {
        $padi = $this->padi(['status_transaksi' => PadiMasuk::STATUS_SIAP_GILING, 'tanggal' => now()->subDays(6)->toDateString()]);
        Penjemuran::create([
            'padi_masuk_id' => $padi->id,
            'tanggal_mulai' => now()->subDays(5)->toDateString(),
            'tanggal_selesai' => now()->subDays(2)->toDateString(),
            'berat_kering_kg' => 150,
        ]);

        // Menggeser mulai ke 1 hari sebelum selesai = durasi 1 hari
        $this->putJson("/api/padi-masuk/{$padi->id}/penjemuran", ['tanggal_mulai' => now()->subDays(3)->toDateString()])
            ->assertStatus(409)
            ->assertJsonPath('success', false);

        $this->assertDatabaseHas('penjemuran', ['padi_masuk_id' => $padi->id, 'tanggal_mulai' => now()->subDays(5)->toDateString().' 00:00:00']);

        // Koreksi yang tetap 2 hari atau lebih diterima
        $this->putJson("/api/padi-masuk/{$padi->id}/penjemuran", ['tanggal_mulai' => now()->subDays(4)->toDateString()])
            ->assertOk();
    }

    public function test_durasi_jemur_dihitung_server_dan_ditandai_terlalu_lama(): void
    {
        $normal = $this->padi(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);
        Penjemuran::create(['padi_masuk_id' => $normal->id, 'tanggal_mulai' => now()->subDays(2)->toDateString()]);

        $lama = $this->padi(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);
        Penjemuran::create(['padi_masuk_id' => $lama->id, 'tanggal_mulai' => now()->subDays(5)->toDateString()]);

        $belum = $this->padi();

        $baris = collect($this->getJson('/api/penjemuran')->assertOk()->json('data'))->keyBy('id');

        $this->assertSame(2, $baris[$normal->id]['durasi_hari']);
        $this->assertFalse($baris[$normal->id]['terlalu_lama']);
        $this->assertSame(5, $baris[$lama->id]['durasi_hari']);
        $this->assertTrue($baris[$lama->id]['terlalu_lama']);
        $this->assertNull($baris[$belum->id]['durasi_hari']);
        $this->assertFalse($baris[$belum->id]['terlalu_lama']);
    }

    public function test_durasi_berhenti_di_tanggal_selesai_dan_tidak_terlalu_lama(): void
    {
        $padi = $this->padi(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR, 'tanggal' => now()->subDays(10)->toDateString()]);
        Penjemuran::create(['padi_masuk_id' => $padi->id, 'tanggal_mulai' => now()->subDays(9)->toDateString()]);

        $this->postJson("/api/penjemuran/{$padi->id}/selesai", [
            'tanggal_selesai' => now()->subDays(6)->toDateString(),
            'berat_kering' => 150,
        ])
            ->assertOk()
            ->assertJsonPath('data.durasi_hari', 3)
            ->assertJsonPath('data.terlalu_lama', false)
            ->assertJsonPath('data.persen_susut', 25);

        $this->getJson("/api/padi-masuk/{$padi->id}")->assertJsonPath('data.penjemuran.durasi_hari', 3);
    }

    public function test_daftar_penjemuran_memakai_kontrak_flutter(): void
    {
        $masuk = $this->padi();
        $this->padi(['status_transaksi' => PadiMasuk::STATUS_SELESAI_GILING]);
        $this->padi(['status_transaksi' => PadiMasuk::STATUS_VOID]);
        $dijemur = $this->padi(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);

        // Daftar biasa (bukan items/meta); void dan selesai giling tidak tampil
        $this->getJson('/api/penjemuran')
            ->assertOk()
            ->assertJsonCount(2, 'data')
            ->assertJsonStructure(['data' => [[
                'id', 'pelanggan', 'kelas', 'tanggal_masuk', 'berat_basah',
                'tanggal_mulai', 'tanggal_selesai', 'berat_kering', 'status',
            ]]]);

        $this->getJson('/api/penjemuran?status=dijemur')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $dijemur->id);

        $this->getJson('/api/penjemuran?status=masuk&pelanggan_id='.$this->pelanggan->id)
            ->assertOk()
            ->assertJsonPath('data.0.id', $masuk->id);

        $this->getJson('/api/penjemuran?status=void')->assertStatus(422);
    }

    public function test_mulai_hanya_dari_status_masuk(): void
    {
        $padi = $this->padi(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);

        $this->postJson("/api/penjemuran/{$padi->id}/mulai", ['tanggal_mulai' => now()->toDateString()])
            ->assertStatus(409)
            ->assertJsonPath('success', false);
    }

    public function test_validasi_tanggal_mulai(): void
    {
        $padi = $this->padi();

        $this->postJson("/api/penjemuran/{$padi->id}/mulai", [])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'tanggal_mulai');
        $this->postJson("/api/penjemuran/{$padi->id}/mulai", ['tanggal_mulai' => now()->addDay()->toDateString()])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'tanggal_mulai');
        // Tidak boleh sebelum padi masuk
        $this->postJson("/api/penjemuran/{$padi->id}/mulai", ['tanggal_mulai' => now()->subDays(10)->toDateString()])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'tanggal_mulai');
    }

    public function test_selesai_hanya_dari_dijemur_dan_validasi_berat(): void
    {
        $padi = $this->padi();
        $hariIni = now()->toDateString();

        $this->postJson("/api/penjemuran/{$padi->id}/selesai", ['tanggal_selesai' => $hariIni, 'berat_kering' => 150])
            ->assertStatus(409);

        $padi->update(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);

        $this->postJson("/api/penjemuran/{$padi->id}/selesai", ['tanggal_selesai' => $hariIni])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'berat_kering');
        $this->postJson("/api/penjemuran/{$padi->id}/selesai", ['tanggal_selesai' => $hariIni, 'berat_kering' => 0])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'berat_kering');
        // Berat kering tidak boleh melebihi berat basah
        $this->postJson("/api/penjemuran/{$padi->id}/selesai", ['tanggal_selesai' => $hariIni, 'berat_kering' => 250])
            ->assertStatus(422)->assertJsonPath('errors.0.field', 'berat_kering');
    }

    public function test_store_dan_update_lewat_padi_masuk(): void
    {
        $padi = $this->padi();
        $mulai = now()->subDays(2)->toDateString();
        $baru = now()->subDays(1)->toDateString();

        $this->postJson("/api/padi-masuk/{$padi->id}/penjemuran", ['tanggal_mulai' => $mulai])
            ->assertCreated()
            ->assertJsonPath('data.status', 'dijemur');

        $this->putJson("/api/padi-masuk/{$padi->id}/penjemuran", ['tanggal_mulai' => $baru])
            ->assertOk()
            ->assertJsonPath('data.tanggal_mulai', $baru);

        $this->assertDatabaseHas('penjemuran', ['padi_masuk_id' => $padi->id, 'tanggal_mulai' => $baru.' 00:00:00']);
    }

    public function test_update_tanpa_data_penjemuran_ditolak(): void
    {
        $padi = $this->padi();

        $this->putJson("/api/padi-masuk/{$padi->id}/penjemuran", ['tanggal_mulai' => now()->toDateString()])
            ->assertStatus(409);
    }

    public function test_penjemuran_tidak_ditemukan_404(): void
    {
        $this->postJson('/api/penjemuran/99999/mulai', ['tanggal_mulai' => now()->toDateString()])->assertStatus(404);
    }
}

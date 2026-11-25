<?php

namespace App\Services;

use App\Models\LogPadiMasuk;
use App\Models\PadiMasuk;
use App\Models\Penjemuran;
use App\Models\User;
use DomainException;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;

/**
 * Aturan bisnis padi masuk dan penjemuran.
 *
 * Alur status: masuk -> dijemur -> siap_giling -> selesai_giling.
 * Transaksi bisa dibatalkan (void) selama belum selesai giling.
 * Pelanggaran aturan dilempar sebagai DomainException; controller mengubahnya
 * menjadi respons 409.
 */
class PadiMasukService
{
    /** Padi yang masih dijemur lebih dari ini (hari) ditandai terlalu lama. */
    public const BATAS_TERLALU_LAMA_HARI = 3;

    /** Penjemuran baru boleh diselesaikan setelah minimal sekian hari sejak tanggal mulai. */
    public const MIN_JEMUR_HARI = 2;

    /** Bentuk JSON satu transaksi padi masuk (dipakai riwayat, detail, dan pelanggan). */
    public function format(PadiMasuk $padi): array
    {
        $padi->loadMissing(['pelanggan', 'kelasPadi', 'penjemuran']);

        $jemur = $padi->penjemuran;

        return [
            'id' => $padi->id,
            'nomor_transaksi' => $padi->nomor_transaksi,
            'tanggal' => $padi->tanggal?->toDateString(),
            'pelanggan_id' => $padi->pelanggan_id,
            'nama_pelanggan' => $padi->pelanggan?->nama,
            'pelanggan' => $padi->pelanggan?->only(['id', 'nama', 'kontak', 'tipe_pelanggan']),
            'kelas_padi_id' => $padi->kelas_padi_id,
            'nama_kelas' => $padi->kelasPadi?->nama_kelas,
            'kelas_padi' => $padi->kelasPadi?->only(['id', 'nama_kelas']),
            'berat_basah_kg' => $padi->berat_basah_kg,
            'catatan' => $padi->catatan,
            'status' => $padi->status_transaksi,
            'status_label' => PadiMasuk::LABEL_STATUS[$padi->status_transaksi] ?? $padi->status_transaksi,
            'berat_kering_kg' => $padi->berat_kering_kg,
            'persen_susut' => $padi->persen_susut,
            'tanggal_selesai_giling' => $padi->tanggal_selesai_giling?->toDateString(),
            'void_reason' => $padi->void_reason,
            'void_by' => $padi->void_by,
            'penjemuran' => $jemur ? [
                'tanggal_mulai' => $jemur->tanggal_mulai?->toDateString(),
                'tanggal_selesai' => $jemur->tanggal_selesai?->toDateString(),
                'berat_kering_kg' => $jemur->berat_kering_kg,
                'durasi_hari' => $this->durasiJemurHari($padi),
            ] : null,
            'created_at' => $padi->created_at?->toISOString(),
        ];
    }

    /** Bentuk JSON satu baris halaman penjemuran (kontrak model Penjemuran di Flutter). */
    public function formatPenjemuran(PadiMasuk $padi): array
    {
        $padi->loadMissing(['pelanggan', 'kelasPadi', 'penjemuran']);

        $jemur = $padi->penjemuran;

        return [
            'id' => $padi->id,
            'nomor_transaksi' => $padi->nomor_transaksi,
            'pelanggan' => $padi->pelanggan?->nama ?? '-',
            'kelas' => $padi->kelasPadi?->nama_kelas ?? '-',
            'tanggal_masuk' => $padi->tanggal?->toDateString(),
            'berat_basah' => $padi->berat_basah_kg,
            'tanggal_mulai' => $jemur?->tanggal_mulai?->toDateString(),
            'tanggal_selesai' => $jemur?->tanggal_selesai?->toDateString(),
            'berat_kering' => $padi->berat_kering_kg ?? $jemur?->berat_kering_kg,
            'persen_susut' => $padi->persen_susut,
            'durasi_hari' => $this->durasiJemurHari($padi),
            'terlalu_lama' => $padi->status_transaksi === PadiMasuk::STATUS_DIJEMUR
                && ($this->durasiJemurHari($padi) ?? 0) > self::BATAS_TERLALU_LAMA_HARI,
            // Sebelum minimal 2 hari penjemuran belum boleh diselesaikan; aplikasi
            // menonaktifkan tombol dan menampilkan tanggal paling cepat.
            'boleh_diselesaikan' => $padi->status_transaksi === PadiMasuk::STATUS_DIJEMUR
                && ($this->durasiJemurHari($padi) ?? 0) >= self::MIN_JEMUR_HARI,
            'tanggal_paling_cepat_selesai' => $jemur?->tanggal_mulai?->copy()->addDays(self::MIN_JEMUR_HARI)->toDateString(),
            'status' => $padi->status_transaksi,
            'status_label' => PadiMasuk::LABEL_STATUS[$padi->status_transaksi] ?? $padi->status_transaksi,
        ];
    }

    /**
     * Lama penjemuran dalam hari kalender (zona waktu aplikasi). Selama masih
     * dijemur dihitung sampai hari ini; setelah selesai sampai tanggal selesai.
     * Null bila penjemuran belum dimulai.
     */
    public function durasiJemurHari(PadiMasuk $padi): ?int
    {
        $padi->loadMissing('penjemuran');
        $jemur = $padi->penjemuran;

        if (! $jemur?->tanggal_mulai) {
            return null;
        }

        $akhir = $padi->status_transaksi === PadiMasuk::STATUS_DIJEMUR || ! $jemur->tanggal_selesai
            ? now()
            : $jemur->tanggal_selesai;

        return max(0, (int) $jemur->tanggal_mulai->copy()->startOfDay()->diffInDays($akhir->copy()->startOfDay(), false));
    }

    public function catat(PadiMasuk $padi, ?User $user, string $aksi, ?string $keterangan = null): void
    {
        LogPadiMasuk::create([
            'padi_masuk_id' => $padi->id,
            'user_id' => $user?->id,
            'aksi' => $aksi,
            'keterangan' => $keterangan,
        ]);
    }

    public function buat(array $data, ?User $user): PadiMasuk
    {
        return DB::transaction(function () use ($data, $user) {
            $padi = PadiMasuk::create([
                'tanggal' => $data['tanggal'],
                'pelanggan_id' => $data['pelanggan_id'],
                'kelas_padi_id' => $data['kelas_padi_id'],
                'berat_basah_kg' => $data['berat_basah_kg'],
                'catatan' => $data['catatan'] ?? null,
                'status_transaksi' => PadiMasuk::STATUS_MASUK,
                'dibuat_oleh' => $user?->id,
            ]);

            $this->catat($padi, $user, 'dibuat', 'Padi masuk '.$padi->berat_basah_kg.' kg');

            return $padi->fresh();
        });
    }

    public function ubah(PadiMasuk $padi, array $data, ?User $user): PadiMasuk
    {
        return DB::transaction(function () use ($padi, $data, $user) {
            $padi = $this->kunci($padi);

            if ($padi->status_transaksi !== PadiMasuk::STATUS_MASUK) {
                throw new DomainException('Transaksi yang sudah diproses atau dibatalkan tidak dapat diubah.');
            }

            $padi->update([
                'tanggal' => $data['tanggal'],
                'pelanggan_id' => $data['pelanggan_id'],
                'kelas_padi_id' => $data['kelas_padi_id'],
                'berat_basah_kg' => $data['berat_basah_kg'],
                'catatan' => $data['catatan'] ?? null,
            ]);

            $this->catat($padi, $user, 'diubah');

            return $padi->fresh();
        });
    }

    public function batalkan(PadiMasuk $padi, string $alasan, ?User $user): PadiMasuk
    {
        return DB::transaction(function () use ($padi, $alasan, $user) {
            $padi = $this->kunci($padi);

            if ($padi->status_transaksi === PadiMasuk::STATUS_VOID) {
                throw new DomainException('Transaksi ini sudah dibatalkan.');
            }
            if ($padi->status_transaksi === PadiMasuk::STATUS_SELESAI_GILING) {
                throw new DomainException('Transaksi yang sudah selesai giling tidak dapat dibatalkan.');
            }

            $padi->update([
                'status_transaksi' => PadiMasuk::STATUS_VOID,
                'void_reason' => $alasan,
                'void_by' => $user?->id,
                'voided_at' => now(),
            ]);

            $this->catat($padi, $user, 'void', $alasan);

            return $padi->fresh();
        });
    }

    public function selesaikanGiling(PadiMasuk $padi, ?string $tanggal, ?User $user): PadiMasuk
    {
        return DB::transaction(function () use ($padi, $tanggal, $user) {
            $padi = $this->kunci($padi);

            if ($padi->status_transaksi !== PadiMasuk::STATUS_SIAP_GILING) {
                throw new DomainException('Hanya padi berstatus Siap Giling yang dapat diselesaikan.');
            }

            $padi->update([
                'status_transaksi' => PadiMasuk::STATUS_SELESAI_GILING,
                'tanggal_selesai_giling' => $tanggal ?? now()->toDateString(),
            ]);

            $this->catat($padi, $user, 'selesai_giling');

            return $padi->fresh();
        });
    }

    public function mulaiJemur(PadiMasuk $padi, string $tanggalMulai, ?User $user): PadiMasuk
    {
        return DB::transaction(function () use ($padi, $tanggalMulai, $user) {
            $padi = $this->kunci($padi);

            if ($padi->status_transaksi !== PadiMasuk::STATUS_MASUK) {
                throw new DomainException('Penjemuran hanya bisa dimulai untuk padi berstatus Masuk.');
            }

            Penjemuran::updateOrCreate(
                ['padi_masuk_id' => $padi->id],
                ['tanggal_mulai' => $tanggalMulai, 'tanggal_selesai' => null, 'berat_kering_kg' => null]
            );
            $padi->update(['status_transaksi' => PadiMasuk::STATUS_DIJEMUR]);

            $this->catat($padi, $user, 'mulai_jemur', 'Mulai '.$tanggalMulai);

            return $padi->fresh();
        });
    }

    public function selesaiJemur(PadiMasuk $padi, string $tanggalSelesai, float $beratKering, ?User $user): PadiMasuk
    {
        return DB::transaction(function () use ($padi, $tanggalSelesai, $beratKering, $user) {
            $padi = $this->kunci($padi);

            if ($padi->status_transaksi !== PadiMasuk::STATUS_DIJEMUR) {
                throw new DomainException('Penjemuran hanya bisa diselesaikan untuk padi berstatus Dijemur.');
            }

            $this->pastikanDurasiCukup($padi->penjemuran?->tanggal_mulai ?? $padi->tanggal, $tanggalSelesai);

            $padi->penjemuran()->update([
                'tanggal_selesai' => $tanggalSelesai,
                'berat_kering_kg' => $beratKering,
            ]);
            $padi->update([
                'status_transaksi' => PadiMasuk::STATUS_SIAP_GILING,
                'berat_kering_kg' => $beratKering,
                'persen_susut' => $this->hitungSusut($padi->berat_basah_kg, $beratKering),
            ]);

            $this->catat($padi, $user, 'selesai_jemur', 'Berat kering '.$beratKering.' kg');

            return $padi->fresh();
        });
    }

    /** Ubah data penjemuran yang sudah ada (tanggal mulai; dan hasil bila sudah selesai). */
    public function ubahJemur(PadiMasuk $padi, array $data, ?User $user): PadiMasuk
    {
        return DB::transaction(function () use ($padi, $data, $user) {
            $padi = $this->kunci($padi);
            $jemur = $padi->penjemuran;

            if (! $jemur || ! in_array($padi->status_transaksi, [PadiMasuk::STATUS_DIJEMUR, PadiMasuk::STATUS_SIAP_GILING], true)) {
                throw new DomainException('Belum ada data penjemuran yang dapat diubah.');
            }

            if (isset($data['tanggal_mulai'])) {
                $jemur->tanggal_mulai = $data['tanggal_mulai'];
            }

            if ($padi->status_transaksi === PadiMasuk::STATUS_SIAP_GILING) {
                if (isset($data['tanggal_selesai'])) {
                    $jemur->tanggal_selesai = $data['tanggal_selesai'];
                }
                if (isset($data['berat_kering'])) {
                    $jemur->berat_kering_kg = $data['berat_kering'];
                    $padi->update([
                        'berat_kering_kg' => $data['berat_kering'],
                        'persen_susut' => $this->hitungSusut($padi->berat_basah_kg, (float) $data['berat_kering']),
                    ]);
                }
            }

            // Koreksi tidak boleh membuat penjemuran yang sudah selesai jadi kurang dari 2 hari
            if ($padi->status_transaksi === PadiMasuk::STATUS_SIAP_GILING && $jemur->tanggal_selesai) {
                $this->pastikanDurasiCukup($jemur->tanggal_mulai, $jemur->tanggal_selesai);
            }

            $jemur->save();
            $this->catat($padi, $user, 'ubah_jemur');

            return $padi->fresh();
        });
    }

    /**
     * Penjemuran minimal MIN_JEMUR_HARI hari: tanggal selesai paling cepat dua hari
     * setelah tanggal mulai. Dipakai juga oleh controller (lihat PenjemuranController::selesai).
     */
    public function pastikanDurasiCukup(Carbon|string $mulai, Carbon|string $selesai): void
    {
        $mulai = Carbon::parse($mulai)->startOfDay();
        $selesai = Carbon::parse($selesai)->startOfDay();

        if ($mulai->diffInDays($selesai, false) < self::MIN_JEMUR_HARI) {
            throw new DomainException($this->pesanDurasiMinimal($mulai));
        }
    }

    public function pesanDurasiMinimal(Carbon|string $mulai): string
    {
        $paling = Carbon::parse($mulai)->startOfDay()->addDays(self::MIN_JEMUR_HARI)->toDateString();

        return 'Penjemuran minimal '.self::MIN_JEMUR_HARI.' hari. Paling cepat bisa diselesaikan pada '.$paling.'.';
    }

    /** Persen susut = (basah - kering) / basah x 100, dibulatkan 2 desimal. */
    public function hitungSusut(float $basah, float $kering): float
    {
        return $basah > 0 ? round(($basah - $kering) / $basah * 100, 2) : 0.0;
    }

    /** Ambil ulang baris dengan kunci tulis agar dua permintaan bersamaan tidak saling menimpa. */
    private function kunci(PadiMasuk $padi): PadiMasuk
    {
        return PadiMasuk::with('penjemuran')->lockForUpdate()->findOrFail($padi->id);
    }
}

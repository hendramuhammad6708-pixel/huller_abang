<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;

class PadiMasuk extends Model
{
    public const STATUS_MASUK = 'masuk';

    public const STATUS_DIJEMUR = 'dijemur';

    public const STATUS_SIAP_GILING = 'siap_giling';

    public const STATUS_SELESAI_GILING = 'selesai_giling';

    public const STATUS_VOID = 'void';

    public const LABEL_STATUS = [
        self::STATUS_MASUK => 'Masuk',
        self::STATUS_DIJEMUR => 'Dijemur',
        self::STATUS_SIAP_GILING => 'Siap Giling',
        self::STATUS_SELESAI_GILING => 'Selesai Giling',
        self::STATUS_VOID => 'Void',
    ];

    protected $table = 'padi_masuk';

    protected $fillable = [
        'tanggal',
        'pelanggan_id',
        'kelas_padi_id',
        'berat_basah_kg',
        'catatan',
        'status_transaksi',
        'berat_kering_kg',
        'persen_susut',
        'tanggal_selesai_giling',
        'void_reason',
        'void_by',
        'voided_at',
        'dibuat_oleh',
    ];

    protected $casts = [
        'tanggal' => 'date',
        'tanggal_selesai_giling' => 'date',
        'voided_at' => 'datetime',
        'berat_basah_kg' => 'float',
        'berat_kering_kg' => 'float',
        'persen_susut' => 'float',
    ];

    /** Daftar status yang valid (untuk validasi filter). */
    public static function daftarStatus(): array
    {
        return array_keys(self::LABEL_STATUS);
    }

    protected static function booted(): void
    {
        // Nomor transaksi: PM-20261027-0007 (tanggal + id, 4 digit)
        static::created(function (PadiMasuk $padi) {
            $padi->nomor_transaksi = 'PM-'.$padi->tanggal->format('Ymd').'-'.str_pad((string) $padi->id, 4, '0', STR_PAD_LEFT);
            $padi->saveQuietly();
        });
    }

    public function pelanggan(): BelongsTo
    {
        // Pelanggan yang sudah dihapus (soft delete) tetap tampil di riwayat
        return $this->belongsTo(Pelanggan::class)->withTrashed();
    }

    public function kelasPadi(): BelongsTo
    {
        return $this->belongsTo(KelasPadi::class);
    }

    public function penjemuran(): HasOne
    {
        return $this->hasOne(Penjemuran::class);
    }

    public function log(): HasMany
    {
        return $this->hasMany(LogPadiMasuk::class);
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\SoftDeletes;

class Pelanggan extends Model
{
    use SoftDeletes; // hapus aman: hanya mengisi kolom deleted_at

    public const TIPE = ['pengepul', 'petani', 'milik_huller'];

    /** Tipe yang boleh dibuat operator; milik_huller khusus owner. */
    public const TIPE_OPERATOR = ['pengepul', 'petani'];

    protected $table = 'pelanggan';

    protected $fillable = ['nama', 'kontak', 'tipe_pelanggan', 'dibuat_oleh'];

    public function pembuat(): BelongsTo
    {
        return $this->belongsTo(User::class, 'dibuat_oleh');
    }
}

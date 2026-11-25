<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Penjemuran extends Model
{
    protected $table = 'penjemuran';

    protected $fillable = ['padi_masuk_id', 'tanggal_mulai', 'tanggal_selesai', 'berat_kering_kg'];

    protected $casts = [
        'tanggal_mulai' => 'date',
        'tanggal_selesai' => 'date',
        'berat_kering_kg' => 'float',
    ];

    public function padiMasuk(): BelongsTo
    {
        return $this->belongsTo(PadiMasuk::class);
    }
}

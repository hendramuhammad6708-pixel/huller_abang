<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class LogPadiMasuk extends Model
{
    // Hanya created_at; log tidak pernah diubah
    public const UPDATED_AT = null;

    protected $table = 'log_padi_masuk';

    protected $fillable = ['padi_masuk_id', 'user_id', 'aksi', 'keterangan'];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}

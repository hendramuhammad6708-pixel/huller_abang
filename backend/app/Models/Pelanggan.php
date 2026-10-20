<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\SoftDeletes;

class Pelanggan extends Model
{
    use SoftDeletes; // hapus aman: hanya mengisi kolom deleted_at

    public const TIPE = ['pengepul', 'petani', 'milik_huller'];

    protected $table = 'pelanggan';

    protected $fillable = ['nama', 'kontak', 'tipe_pelanggan'];
}

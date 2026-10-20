<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class KelasPadi extends Model
{
    protected $table = 'kelas_padi';

    protected $fillable = ['nama_kelas'];
}

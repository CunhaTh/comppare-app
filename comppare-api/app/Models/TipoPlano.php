<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class TipoPlano extends Model
{
    /** @use HasFactory<\Database\Factories\TipoPlanoFactory> */
    use HasFactory;

    protected $fillable = ['nome', 'status'];

    public function planos()
    {
        return $this->hasMany(Planos::class);
    }

}

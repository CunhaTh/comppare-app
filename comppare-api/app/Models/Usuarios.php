<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Usuarios extends Model
{
    use HasFactory;

    protected $fillable = ['nome', 'senha', 'cpf', 'status'];

    public function plano(): BelongsTo
    {
        return $this->belongsTo(Planos::class);
    }
}

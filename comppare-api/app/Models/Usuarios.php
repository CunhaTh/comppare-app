<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Tymon\JWTAuth\Contracts\JWTSubject;



class Usuarios extends Authenticatable implements JWTSubject
{
    use HasFactory;
    use Notifiable;

    protected $fillable = [
        'nome',
        'senha',
        'cpf',
        'status',
        'dataLimiteCompra',
        'idPlano',
        'telefone' ,
        'dataUltimoPagamento'
    ];

    protected $hidden = ['senha'];

    public function plano(): BelongsTo
    {
        return $this->belongsTo(Planos::class);
    }

    public function getJWTIdentifier()
    {
        return $this->getKey();
    }

    public function getJWTCustomClaims()
    {
        return [];
    }

}

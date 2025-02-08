<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Planos extends Model
{
    use HasFactory;

    protected $fillable = ['nome', 'descricao', 'valor', 'tempoGratuidade', 'status'];
}

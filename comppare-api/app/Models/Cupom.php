<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Cupom extends Model
{

    protected $fillable = ['cupom', 'percentualDesconto', 'status', 'dataExpiracao'];

    //
}

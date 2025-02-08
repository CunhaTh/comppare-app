<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\UsuarioController;

Route::middleware('api')->group(function () {
    Route::get('/api/test', function () {
        $apiVersion = env('APP_VERSION');  // 'default_version' é o valor padrão caso a variável não exista

        return response()->json(['message' => 'API works on version:' . $apiVersion]);
    });

    Route::post('/api/autenticar', [UsuarioController::class, 'autenticar']);
    Route::post('/api/cadastrar', [UsuarioController::class, 'cadastrarUsuario']);
});

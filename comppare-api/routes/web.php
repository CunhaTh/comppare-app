<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\UsuarioController;
use App\Http\Controllers\Api\PlanoController;

Route::middleware('api')->group(function () {
    Route::get('/api/test', function () {
        $apiVersion = env('APP_VERSION');  // 'default_version' é o valor padrão caso a variável não exista

        return response()->json(['message' => 'API works on version:' . $apiVersion]);
    });

    Route::post('/api/usuarios/autenticar', [UsuarioController::class, 'autenticar']);
    Route::post('/api/usuarios/cadastrar', [UsuarioController::class, 'cadastrarUsuario']);
    Route::get('/api/usuarios/listar', [UsuarioController::class, 'index']);
    Route::post('/api/usuarios/recuperar', [UsuarioController::class, 'getUser']);
    Route::get('/api/planos/listar', [PlanoController::class, 'index']);
    Route::post('/api/planos/recuperar', [PlanoController::class, 'getPlano']);
    Route::post('/api/planos/cadastrar', [PlanoController::class, 'cadastrarPlano']);
});

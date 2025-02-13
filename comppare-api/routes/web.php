<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\Api\UsuarioController;
use App\Http\Controllers\Api\PlanoController;
use App\Http\Controllers\Api\CupomController;
use App\Http\Controllers\Api\TipoPlanoController;
Route::middleware('api')->group(function () {
    Route::get('/api/test', function () {
        $apiVersion = env('APP_VERSION');  // 'default_version' é o valor padrão caso a variável não exista

        return response()->json(['message' => 'API funcional na versão: ' . $apiVersion]);
    });
    //Rotas user
    Route::post('/api/usuarios/autenticar', [UsuarioController::class, 'autenticar']);
    Route::post('/api/usuarios/cadastrar', [UsuarioController::class, 'cadastrarUsuario']);
    Route::get('/api/usuarios/listar', [UsuarioController::class, 'index']);
    Route::post('/api/usuarios/recuperar', [UsuarioController::class, 'getUser']);
    Route::post('/api/usuarios/atualizar-status', [UsuarioController::class, 'atualizarStatus']);
    Route::post('/api/usuarios/atualizar-dados', [UsuarioController::class, 'atualizarDados']);
    Route::post('/api/usuarios/valida-existencia-usuario', [UsuarioController::class, 'validaExistenciaUsuario']);
    Route::post('/api/usuarios/atualizar-senha', [UsuarioController::class, 'atualizarSenha']);
    //Rotas planos
    Route::get('/api/planos/listar', [PlanoController::class, 'index']);
    Route::post('/api/planos/recuperar', [PlanoController::class, 'getPlano']);
    Route::post('/api/planos/cadastrar', [PlanoController::class, 'cadastrarPlano']);
    Route::post('/api/planos/atualizar-status', [PlanoController::class, 'atualizarStatus']);
    Route::post('/api/planos/atualizar-dados', [PlanoController::class, 'atualizarDados']);
    //Rotas cupons
    Route::post('/api/cupons/cadastrar', [CupomController::class, 'saveTicket']);
    Route::get('/api/cupons/listar', [CupomController::class, 'index']);
    Route::post('/api/cupons/recuperar', [CupomController::class, 'getTicketDiscount']);
    Route::post('/api/cupons/atualizar-status', [CupomController::class, 'atualizarStatus']);
    Route::post('/api/cupons/atualizar-dados', [CupomController::class, 'atualizarDados']);
// Rotas tipo plano
    Route::get('/api/tipo-planos/listar', [TipoPlanoController::class, 'index']);
    Route::post('/api/tipo-planos/recuperar', [TipoPlanoController::class, 'getTipoPlano']);
    Route::post('/api/tipo-planos/cadastrar', [TipoPlanoController::class, 'cadastrarTipoPlano']);
    Route::post('/api/tipo-planos/atualizar-status', [TipoPlanoController::class, 'atualizarStatus']);
    Route::post('/api/tipo-planos/atualizar-dados', [TipoPlanoController::class, 'atualizarDados']);


});

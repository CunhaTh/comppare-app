<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Usuarios;
use Illuminate\Support\Facades\Hash;
use App\Http\Util\Helper;

class UsuarioController extends Controller
{
    private $codes = [];
    public function __construct()
    {
        $this->codes = Helper::getHttpCodes();
    }

    public function index()
    {
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200],
            'data' => Usuarios::all()

        ];
        return response()->json($response);
    }

    public function cadastrarUsuario(Request $request)
    {

        $exists = Usuarios::where('cpf', $request->cpf)->exists();

        if ($exists) {
            return response()->json([
                'codRetorno' => 409,
                'message' => $this->codes[409],
            ], 409);
        } else {


            $usuario = Usuarios::create([
                'nome' => $request->nome,
                'senha' => bcrypt($request->senha), // 
                'cpf' => $request->cpf
            ]);
            isset($usuario->id) ?
                $response = [
                    'codRetorno' => 200,
                    'message' => $this->codes[200]
                ] :  $response = [
                    'codRetorno' => 500,
                    'message' => $this->codes[500]
                ];
            return response()->json($response);
        }
    }

    public function getUser(Request $request)
    {
        $usuario = Usuarios::find($request->idUsuario);
        isset($usuario->id) ?
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200],
                'data' => $usuario
            ] :  $response = [
                'codRetorno' => 404,
                'message' => $this->codes[404]
            ];
        return response()->json($response);
    }

    public function atualizarDados(Request $request)
    {
        $usuario = Usuarios::findOrFail($request->idUsuario);
        $usuario->update($request->all());
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200]
        ];
        return response()->json($response);
    }

    public function atualizarStatus(Request $request)
    {
        //Falta criar o campo status para desativar logicamente
        $usuario = Usuarios::findOrFail($request->idUsuario);
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200],
        ];
        return response()->json($response);
    }

    public function autenticar(Request $request)
    {
        // Chama a função para pegar os códigos e mensagens

        // Validar os dados de entrada
        $request->validate([
            'cpf' => 'required|string',
            'senha' => 'required|string',
        ]);

        // Recuperar o usuário com base no CPF
        $user = Usuarios::where('cpf', $request->input('cpf'))->first();

        // Verificar se a senha fornecida corresponde à senha armazenada no banco
        if (!$user || !Hash::check($request->input('senha'), $user->senha)) {
            return response()->json(
                [
                    'message' => $this->codes[404], // Mensagem associada ao código 404
                    'codRetorno' => 404
                ],
                404
            );
        } else {
            // Sucesso na autenticação
            return response()->json([
                'codRetorno' => 200,
                'message' => $this->codes[200], // Mensagem associada ao código 200
                'data' => $user->only('id', 'nome', 'cpf') // Retornar informações do usuário, sem a senha
            ]);
        }
    }
}

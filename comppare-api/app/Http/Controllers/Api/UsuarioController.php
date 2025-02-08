<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Usuarios;
use Illuminate\Support\Facades\Hash;


class UsuarioController extends Controller
{

    public function index()
    {
        $response = [
            'data' => Usuarios::all(),
            'codRetorno' => 200
        ];
        return response()->json($response);
    }

    public function cadastrarUsuario(Request $request)
    {

        $usuario = Usuarios::create([
            'nome' => $request->nome,
            'senha' => bcrypt($request->senha), // Hash the password before storing it
            'cpf' => $request->cpf,
        ]);
        isset($usuario->id) ?
            $response = [
                'message' => 'Usuário salvo com sucesso',
                'codRetorno' => 200
            ] :  $response = [
                'message' => 'Erro ao salvar o usuário',
                'codRetorno' => 500
            ];
        return response()->json($response);
    }

    public function show($id)
    {
        return response()->json(Usuarios::findOrFail($id));
    }

    public function update(Request $request, $id)
    {
        $usuario = Usuarios::findOrFail($id);
        $usuario->update($request->all());
        $response = [
            'message' => 'Usuário alterado com sucesso!',
            'codRetorno' => 200
        ];
        return response()->json($response);
    }

    public function destroy($id)
    {
        Usuarios::findOrFail($id)->delete();
        $response = [
            'message' => 'Usuário deletado com sucesso!',
            'codRetorno' => 200
        ];
        return response()->json($response);
    }

    public function autenticar(Request $request)
    {
        // Validar os dados de entrada
        $request->validate([
            'cpf' => 'required|string',
            'senha' => 'required|string',
        ]);

        // Recuperar o usuário com base no CPF
        $user = Usuarios::where('cpf', $request->input('cpf'))->first();

        // Verificar se a senha fornecida corresponde à senha armazenada no banco
        if (!$user || !Hash::check($request->input('senha'), $user->senha)) {
            // Senha correta, autenticação bem-sucedida
            return response()->json(
                [
                    'message' => 'Credenciais inválidas.',
                    'codRetorno' => 404
                ],
                404
            );
        } else {
            return response()->json([
                'codRetorno' => 200,
                'data' => $user->only('id', 'nome', 'cpf') // Retornar informações do usuário, sem a senha
            ]);
        }
    }
}

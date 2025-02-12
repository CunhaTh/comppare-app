<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use App\Models\Usuarios;
use Illuminate\Support\Facades\Hash;
use App\Http\Util\Helper;
use Carbon\Carbon;



class UsuarioController extends Controller
{
    private $codes = [];
    private int $gratuidade = 0;
    public function __construct()
    {
        $this->codes = Helper::getHttpCodes();
        $this->gratuidade = config('app.gratuidadePlano');
    }

    public function index() : object
    {
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200],
            'data' => Usuarios::all()

        ];
        return response()->json($response);
    }

    public function cadastrarUsuario(Request $request): object
    {

        if (!Helper::validaCPF($request->cpf)) {
            $response = [
                'codRetorno' => 400,
                'message' => $this->codes[-2]
            ];
            return response()->json($response);
        } else {
            $exists = Usuarios::where('cpf', $request->cpf)->exists();

            if ($exists) {
                 $response = [
                     'codRetorno' => 400,
                     'message' => $this->codes[-6]
                 ];
                 return response()->json($response);

            } else {


                $usuario = Usuarios::create([
                    'nome' => $request->nome,
                    'senha' => bcrypt($request->senha), //
                    'cpf' => $request->cpf,
                    'idPlano' => $request->idPlano
                ]);
             if(isset($usuario->id)){
                 $usuario->dataLimiteCompra = $usuario->created_at->addDays($this->gratuidade);
                 $usuario->save();
                     $response = [
                         'codRetorno' => 200,
                         'message' => $this->codes[200]
                     ];
             }else{
                 $response = [
                     'codRetorno' => 500,
                     'message' => $this->codes[500]
                 ];

             }
                return response()->json($response);
            }
        }
    }

    public function getUser(Request $request): object
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

    public function atualizarDados(Request $request): object
    {
        if (!Helper::validaCPF($request->cpf)) {
            $response = [
                'codRetorno' => 400,
                'message' => $this->codes[400]
            ];
            return response()->json($response);
        } else {
            $usuario = Usuarios::findOrFail($request->idUsuario);
            if (isset($usuario->id)) {
                $usuario->nome = $request->nome;
                $usuario->senha = bcrypt($request->senha);
                $usuario->cpf = $request->cpf;
                $usuario->save();
                $response = [
                    'codRetorno' => 200,
                    'message' => $this->codes[200]
                ];
            } else {
                $response = [
                    'codRetorno' => 500,
                    'message' => $this->codes[500]
                ];
            }
        }
        return response()->json($response);
    }




    public function atualizarStatus(Request $request): object
    {
        //Falta criar o campo status para desativar logicamente
        $usuario = Usuarios::findOrFail($request->idUsuario);
        if (isset($usuario->id)) {
            $usuario->status = $request->status;
            $usuario->save();
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200]
            ];
        } else {

            $response = [
                'codRetorno' => 500,
                'message' => $this->codes[500]
            ];
        }
        return response()->json($response);
    }

    public function autenticar(Request $request): object
    {
        $now = Carbon::now();

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
            $response = [
                'codRetorno' => 404,
                'message' => $this->codes[404]
            ];
        } else {
            if($user->dataLimiteCompra < $now){
                $response = [
                    'codRetorno' => 400,
                    'message' => $this->codes[-7]
                ];
                return response()->json($response);
            }
            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200],
                'data' => $user->only('id', 'nome', 'cpf')
            ];
        }

        return response()->json($response);
    }
}

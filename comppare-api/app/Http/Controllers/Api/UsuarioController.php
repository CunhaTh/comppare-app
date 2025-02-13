<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Planos;
use Illuminate\Http\Request;
use App\Models\Usuarios;
use Illuminate\Support\Facades\Hash;
use App\Http\Util\Helper;
use Carbon\Carbon;
use Tymon\JWTAuth\Facades\JWTAuth;



class UsuarioController extends Controller
{
    private array $codes= [];
    private int $planoGratuito = 1;
    private int $planoPremium = 2;

    private int $planoEmpresarial = 3;

    private int $tempoRenovacao = 30;


    public function __construct()
    {
        $this->codes = Helper::getHttpCodes();

    }

    public function index(): object
    {
        $usuariosAtivos = Usuarios::where('status', 1)->count();
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200],
            'totalUsuarios' => Usuarios::count(),
            'usuariosAtivos' => $usuariosAtivos,
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
            if ($this->confirmaUser($request)) {
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
                    'telefone' => $request->telefone,
                    'idPlano' => $request->idPlano
                ]);
                $token = JWTAuth::fromUser($usuario);

                if (isset($usuario->id)) {
                    $idPlano = $usuario->idPlano;
                    if ($idPlano != $this->planoGratuito) {
                        $usuario->dataLimiteCompra = $usuario->created_at->addDays(Planos::find($idPlano)->tempoGratuidade)->setTimezone('America/Recife');;
                        $usuario->save();
                    }
                    $response = [
                        'codRetorno' => 200,
                        'message' => $this->codes[200],
                        'token' => $token
                    ];
                } else {
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
            ] : $response = [
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
                $usuario->telefone = $request->telefone;
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

        // Validar os dados de entrada
        $request->validate([
            'cpf' => 'required|string',
            'senha' => 'required|string',
        ]);

        // Recuperar o usuário com base no CPF
        $user = Usuarios::where('cpf', $request->input('cpf'))->first();

       $response = $this->checaPermissoes($user, $request);

        return response()->json($response);
    }

    private function confirmaUser(Request $request): bool
    {
        $exists = Usuarios::where('cpf', $request->cpf)->exists();
        return $exists;

    }

    public function validaExistenciaUsuario(Request $request): object
    {
        $existe = $this->confirmaUser($request);
        $existe ?
        $response = [
            'codRetorno' => 200,
            'message' => $this->codes[200]
        ]:
            $response = [
                'codRetorno' => 404,
                'message' => $this->codes[404]
            ];
        return response()->json($response);
    }

    public function atualizarSenha(Request $request): object
    {
        $usuario = Usuarios::findOrFail($request->cpf);
        if (isset($usuario->cpf)) {
            $usuario->senha = bcrypt($request->senha);
            $usuario->save();
            $token = JWTAuth::fromUser($usuario);

            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200],
                'token' => $token
            ];
        } else {

            $response = [
                'codRetorno' => 500,
                'message' => $this->codes[500]
            ];
        }
        return response()->json($response);
    }

    private function checaPermissoes(Usuarios $user, Request $request): object{
        $osTime = Carbon::now()->setTimezone('America/Recife');
        $daLimiteAcesso = $user->dataUltimoPagamento->addDays($this->tempoRenovacao)->setTimezone('America/Recife');
        $dataLimiteCompra = Carbon::parse($user->dataLimiteCompra)->setTimezone('America/Recife');

        // Verificar se a senha fornecida corresponde à senha armazenada no banco
        if (!$user || !Hash::check($request->input('senha'), $user->senha)) {
            $response = [
                'codRetorno' => 404,
                'message' => $this->codes[404]
            ];
        } else {
            //Verifica validade de perio de testes para planos pagos
            if ( ($user->idPlano != $this->planoGratuito) && $dataLimiteCompra > $osTime) {
                $response = [
                    'codRetorno' => 400,
                    'message' => $this->codes[-7]
                ];
                return response()->json($response);
            }
            //Verifica data do ultimo pagamento
            if ( ($user->idPlano != $this->planoGratuito) && $daLimiteAcesso > $osTime) {
                $response = [
                    'codRetorno' => 400,
                    'message' => $this->codes[-8]
                ];
                return response()->json($response);
            }
            $token = JWTAuth::fromUser($user);

            $response = [
                'codRetorno' => 200,
                'message' => $this->codes[200],
                'token' => $token,
                'data' => $user->only('id', 'nome', 'cpf', 'telefone')
            ];
        }
        return response()->json($response);
    }

    //Criar metodo para recuperar informações de pagamento com base no retorno da API de pagamentos
}

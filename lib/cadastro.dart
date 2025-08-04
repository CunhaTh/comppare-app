import 'dart:developer';

import 'package:application_progress/login.dart';
import 'package:application_progress/main.dart';
import 'package:application_progress/models/folder_model.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/pagemconstrucao.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'helpers/snackbar/snackbar.dart';
import 'infra/api_endponts.dart';
import 'views/awaiting_payment.dart';
import 'infra/user_helper.dart'; // Importa o UserHelper (agora com a classe User)

class CadastroScreen extends StatefulWidget {
  final int? idPlano;

  const CadastroScreen({super.key, required this.idPlano});

  static const route = '/cadastro';

  @override
  CadastroScreenState createState() => CadastroScreenState();
}

class CadastroScreenState extends State<CadastroScreen> {
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _nasciController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _nascimentoDate;
  bool _isLoading = false;
  //final String _baseUrl = 'https://api.comppare.com.br/api';

  // Método para mostrar o seletor de data
  Future<void> _selectDataNascimento(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _nascimentoDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _nascimentoDate) {
      setState(() {
        _nascimentoDate = picked;
        _nasciController.text =
            "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  bool _isValidCpf(String cpf) {
    if (cpf.length != 11) return false;
    return true;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isMaiorDeIdade(DateTime nascimento) {
    final hoje = DateTime.now();
    final idade = hoje.year - nascimento.year;
    final hasHadBirthdayThisYear = (hoje.month > nascimento.month) ||
        (hoje.month == nascimento.month && hoje.day >= nascimento.day);
    return (idade > 18) || (idade == 18 && hasHadBirthdayThisYear);
  }

  Future<bool> _checarExistenciaCpf(String cpf) async {
    try {
      log('URL BASE PARA VALIDAR CPF: ${ApiEndpoints.baseUrl}/usuarios/valida-existencia-usuario');
      final verificaExistenciaResponse = await http.post(
        Uri.parse('${ApiEndpoints.baseUrl}/usuarios/valida-existencia-usuario'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"cpf": cpf}),
      );

      if (verificaExistenciaResponse.statusCode == 200) {
        final responseData = jsonDecode(verificaExistenciaResponse.body);
        return responseData['codRetorno'] == 200 &&
            responseData['message'] == 'OK';
      } else {
        _showErrorDialog('Erro ao verificar CPF. Tente novamente.');
        return false;
      }
    } catch (e) {
      _showErrorDialog('Erro ao conectar com a API. Tente novamente.');
      return false;
    }
  }

  Future<void> _cadastrarUsuario(
      String nome,
      String sobrenome,
      String apelido,
      String cpf,
      String email,
      String telefone,
      String senha,
      String nascimento) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      log('URL BASE PARA CADASTRO: ${ApiEndpoints.baseUrl}/usuarios/cadastrar');
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/usuarios/cadastrar'),
      //   headers: {"Content-Type": "application/json"},
      //   body: jsonEncode({
      //     "primeiroNome": nome,
      //     "sobrenome": sobrenome,
      //     "apelido": apelido,
      //     "cpf": cpf,
      //     "nascimento": nascimento,
      //     "email": email,
      //     "senha": senha,
      //     "telefone": telefone,
      //     //"idPlano": widget.idPlano,
      //     "idPlano": 1,
      //   }),
      // );

      // if (response.statusCode > 200 && response.statusCode < 300) {
      //   Navigator.push(
      //     context,
      //     MaterialPageRoute(builder: (_) => const LoginScreen()),
      //   );
      //   appSnackBar(
      //     context: context,
      //     message: 'Cadastro realizado com sucesso',
      //   );
      // } else {
      //   appSnackBar(
      //     context: context,
      //     message: 'Erro ao cadastrar usuário',
      //   );
      // }

      ///TODO(Abimael): Verificar este fluxo com o Andrew - Sugestão para criar o usuário inicialmente setando com plano gratúito
      // if (response.statusCode == 200) {
      //   final responseData = jsonDecode(response.body);
      //   if (responseData['sucesso'] == true ||
      //       responseData['codigoRetorno'] == 200) {
      //     if (![1, 2].contains(widget.idPlano)) {
      //       final userId = responseData['idUser'];
      //       final redirected = await launchUrl(
      //         Uri.parse(
      //             'https://dev.comppare.com.br/payment.php?pid=${widget.idPlano}&uid=$userId'),
      //       );
      //       if (redirected && mounted) {
      //         Navigator.pushNamed(context, AwaitingPayment.route);
      //       }
      //     } else {
      //       final success = await _loginAfterCadastro(cpf, senha);
      //       if (success && mounted) {
      //         if (mounted) {
      //           Navigator.pushReplacement(
      //             context,
      //             MaterialPageRoute(
      //                 builder: (context) => const PrincipalPage()),
      //           );
      //         }
      //       }
      //     }
      //   } else {
      //     _showErrorDialog(responseData['mensagem'] ?? 'Erro ao cadastrar.');
      //   }
      // } else {
      //   final errResponse = jsonDecode(response.body);
      //   late String msg = '';
      //   if (errResponse["codRetorno"] == 201) {
      //     msg = '''Cadastro concluido com sucesso''';
      //   } else {
      //     msg = 'falha';
      //   }
      //   _showErrorDialog(msg);
      // }
    } catch (e) {
      _showErrorDialog('Erro ao conectar com a API. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _loginAfterCadastro(String cpf, String senha) async {
    if (!mounted) return false;

    setState(() {
      _isLoading = true;
    });

    final String url = '${ApiEndpoints.baseUrl}/usuarios/autenticar';
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Access-Control-Allow-Origin': '*',
    };
    final Map<String, dynamic> body = {
      'cpf': cpf,
      'senha': senha,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: json.encode(body),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('token') &&
            data.containsKey('dados') &&
            data['dados'] is Map) {
          final String token = data['token'];
          final Map<String, dynamic> userData = data['dados'];

          // Cria um objeto User a partir dos dados recebidos
          // Certifique-se de que a classe User tem um construtor que aceita esses parâmetros
          final User loggedInUser = User(
            // <--- CORRIGIDO: Usando a classe User
            id: userData['id'] as int?,
            nome: '${userData['primeiroNome']} ${userData['sobrenome']}',
            cpf: userData['cpf'] as String?,
            telefone: userData['telefone'] as String?,
            idPlano: userData['idPlano'] as int?,
            email: userData['email'] as String?, // Adicionado o email
            token: token,
          );

          // Extrai e anexa a lista de pastas ao objeto User
          if (data.containsKey('pastas') && data['pastas'] is List) {
            final List<dynamic> pastasJson = data['pastas'] as List<dynamic>;
            loggedInUser.pastas = pastasJson
                .map((item) => Folder.fromMap(item as Map<String, dynamic>))
                .toList();
          } else {
            loggedInUser.pastas =
                []; // Garante que a lista de pastas não seja nula
          }

          await UserHelper().setUser(
              loggedInUser); // <--- CORRIGIDO: Passando o objeto User completo
          print(
              'User saved: $loggedInUser'); // Imprime o objeto completo para debug
          return true;
        } else {
          _showErrorDialog('Resposta da API inválida ou estrutura inesperada.');
          return false;
        }
      } else {
        String errorMessage = 'Credenciais inválidas. Tente novamente.';
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          if (errorData.containsKey('message')) {
            errorMessage = errorData['message'];
          }
        } catch (_) {}
        _showErrorDialog(errorMessage);
        return false;
      }
    } catch (error) {
      _showErrorDialog('Erro de conexão: $error. Tente novamente mais tarde.');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Fecha o diálogo
              // Se o erro for de login, não tente fazer login novamente automaticamente aqui.
              // O usuário deve corrigir as credenciais.
              // Removido o _loginAfterCadastro automático aqui para evitar loops de erro.
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showNoPlanSelectedDialog() {
    if (mounted) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Atenção'),
          content: const Text('Escolha um plano para cadastrar.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            const Pagemconstrucao()) // MyHomePage(title: '')),
                    );
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void _sendCadastroData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    ///TODO(Abimael): Verificar este fluxo com o Andrew
    // if (widget.idPlano == null) {
    //   setState(() {
    //     _isLoading = false;
    //   });

    //   //_showNoPlanSelectedDialog();
    //   return;
    // }

    String nome = _nameController.text.trim();
    String sobrenome = _surnameController.text.trim();
    String apelido = _nicknameController.text.trim();
    String cpf = _cpfController.text.trim().replaceAll(RegExp(r'\D'), '');
    String email = _emailController.text.trim();
    String nascimento = _nasciController.text.trim();
    String telefone = _phoneController.text.trim();
    String senha = _passwordController.text.trim();
    String confirmSenha = _confirmPasswordController.text.trim();

    if ([
      nome,
      sobrenome,
      apelido,
      cpf,
      email,
      nascimento,
      telefone,
      senha,
      confirmSenha
    ].any((field) => field.isEmpty)) {
      _showErrorDialog('Por favor, preencha todos os campos!');
      setState(() => _isLoading = false);
      return;
    }

    if (!_isValidCpf(cpf)) {
      _showErrorDialog('CPF inválido!');
      setState(() => _isLoading = false);
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorDialog('E-mail inválido!');
      setState(() => _isLoading = false);
      return;
    }

    if (senha != confirmSenha) {
      _showErrorDialog('As senhas não coincidem!');
      setState(() => _isLoading = false);
      return;
    }

    final parts = nascimento.split('/');
    if (parts.length == 3) {
      try {
        _nascimentoDate = DateTime(
            int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } catch (e) {
        _showErrorDialog('Data de nascimento inválida!');
        setState(() => _isLoading = false);
        return;
      }
    } else {
      _showErrorDialog('Data de nascimento inválida!');
      setState(() => _isLoading = false);
      return;
    }

    if (!_isMaiorDeIdade(_nascimentoDate!)) {
      _showErrorDialog('Você precisa ser maior de idade!');
      setState(() => _isLoading = false);
      return;
    }

    try {
      final cpfExiste = await _checarExistenciaCpf(cpf);
      if (cpfExiste) {
        _showErrorDialog('Usuário já cadastrado com este CPF!');
        setState(() => _isLoading = false);
      } else {
        await _cadastrarUsuario(
            nome, sobrenome, apelido, cpf, email, telefone, senha, nascimento);
      }
    } catch (e) {
      _showErrorDialog('Erro ao conectar com a API. Tente novamente.');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _nicknameController.dispose();
    _cpfController.dispose();
    _emailController.dispose();
    _nasciController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 100),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => /*Pagemconstrucao()*/
                                      const MyHomePage(
                                    title: '',
                                  ),
                                ),
                              );
                            },
                            child: Image.asset(
                              "assets/logo_cortada.png",
                              width: 150,
                              height: 50,
                            ),
                          ),
                        ),
                      ),
                      const Text(
                        'Registre-se!',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(_nameController, 'Nome'),
                      const SizedBox(height: 15),
                      _buildTextField(_surnameController, 'Sobrenome'),
                      const SizedBox(height: 15),
                      _buildTextField(_nicknameController, 'Apelido'),
                      const SizedBox(height: 15),
                      _buildTextField(_cpfController, 'CPF'),
                      const SizedBox(height: 15),
                      _buildTextField(_emailController, 'E-mail'),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () => _selectDataNascimento(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                              _nasciController, 'Data de Nascimento'),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(_phoneController, 'Celular'),
                      const SizedBox(height: 15),
                      _buildTextField(_passwordController, 'Senha',
                          obscureText: true),
                      const SizedBox(height: 15),
                      _buildTextField(
                          _confirmPasswordController, 'Confirmar Senha',
                          obscureText: true),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.only(top: 100),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 80, vertical: 20),
                                  textStyle: const TextStyle(fontSize: 18),
                                ),
                                onPressed: _sendCadastroData,
                                child: const Text('Avançar',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }
}

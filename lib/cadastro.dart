import 'package:application_progress/login.dart';
import 'package:application_progress/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Gamificado',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CadastroScreen(idPlano: null),
    );
  }
}

class CadastroScreen extends StatefulWidget {
  final int? idPlano;

  const CadastroScreen({super.key, required this.idPlano});

  @override
  _CadastroScreenState createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final String _baseUrl = 'https://api.comppare.com.br/api';
  bool _isLoading = false;

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _sendCadastroData() async {
    String nome = _nameController.text.trim();
    String cpf = _cpfController.text.trim().replaceAll(RegExp(r'\D'), '');
    String email = _emailController.text.trim();
    String telefone = _phoneController.text.trim();
    String senha = _passwordController.text.trim();
    String confirmSenha = _confirmPasswordController.text.trim();

    if ([nome, cpf, email, telefone, senha, confirmSenha].any((field) => field.isEmpty)) {
      _showErrorDialog('Por favor, preencha todos os campos!');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorDialog('E-mail inválido! Verifique e tente novamente.');
      return;
    }

    if (senha != confirmSenha) {
      _showErrorDialog('As senhas não coincidem!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cpfExiste = await _checarExistenciaCpf(cpf);

      if (cpfExiste) {
        setState(() {
          _isLoading = false;
        });
        _showErrorDialog('Usuário já cadastrado com este CPF!');
      } else {
        await _cadastrarUsuario(nome, cpf, email, telefone, senha);
        _navigateToLogin();  // Navega para a tela de login somente após o cadastro bem-sucedido
      }
    } catch (e) {
      _showErrorDialog('Erro ao conectar com a API. Tente novamente.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<bool> _checarExistenciaCpf(String cpf) async {
    try {
      final verificaExistenciaResponse = await http.post(
        Uri.parse('$_baseUrl/usuarios/valida-existencia-usuario'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"cpf": cpf}),
      );

      if (verificaExistenciaResponse.statusCode == 200) {
        final responseData = jsonDecode(verificaExistenciaResponse.body);
        print('Resposta da API: $responseData'); // Adicione este log
        return responseData['codRetorno'] == 200 && responseData['message'] == 'OK';  // Verifica se o código de retorno e a mensagem indicam existência
      } else {
        _showErrorDialog('Erro ao verificar CPF. Tente novamente.');
        return false;  // Considerar o CPF como não existente em caso de erro na verificação
      }
    } catch (e) {
      _showErrorDialog('Erro ao conectar com a API. Tente novamente.');
      return false;  // Considerar o CPF como não existente em caso de erro na verificação
    }
  }

  Future<void> _cadastrarUsuario(String nome, String cpf, String email, String telefone, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usuarios/cadastrar'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "nome": nome,
          "cpf": cpf,
          "email": email,
          "senha": senha,
          "telefone": telefone,
          "idPlano": widget.idPlano,
        }),
      );

      if (response.statusCode != 200) {
        final errorResponse = jsonDecode(response.body);
        _showErrorDialog(errorResponse['mensagem'] ?? 'Erro ao cadastrar. Tente novamente.');
      }
    } catch (e) {
      _showErrorDialog('Erro ao conectar com a API. Tente novamente.');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 20,right: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                ),
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(child: 
        Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: GestureDetector(
            onTap: (){
              Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MyHomePage(title: '',),
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
                      Text(
                          'Registre-se!',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                      const SizedBox(height: 10),
                      _buildTextField(_nameController, 'Nome Completo'),
                      SizedBox(height: 15,),
                      _buildTextField(_cpfController, 'CPF'),
                      SizedBox(height: 15,),
                      _buildTextField(_emailController, 'E-mail'),
                      SizedBox(height: 15,),
                      _buildTextField(_phoneController, 'Celular'),
                      SizedBox(height: 15,),
                      _buildTextField(_passwordController, 'Senha', obscureText: true),
                      SizedBox(height: 15,),
                      _buildTextField(_confirmPasswordController, 'Confirmar Senha', obscureText: true),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Padding(
                            padding: const EdgeInsets.only(top: 100),
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                foregroundColor: Color.fromARGB(255, 251, 255, 250), backgroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                                textStyle: TextStyle(fontSize: 18),
                                ),
                                onPressed: _sendCadastroData,
                                child: const Text('Avançar', style: TextStyle(color: Colors.white)),
                              ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          //inputs do cadastro
          Positioned(top: 50, left: -50, child: _buildCloud()),
          Positioned(top: 100, right: -50, child: _buildCloud()),
          Positioned(bottom: 100, left: 50, child: _buildCloud()),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool obscureText = false}) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.black),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.black)),
        ),
      ),
    );
  }

  Widget _buildCloud() {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.8), borderRadius: BorderRadius.circular(30)),
    );
  }
}
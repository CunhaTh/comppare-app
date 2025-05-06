import 'package:application_progress/login.dart';
import 'package:application_progress/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'views/awaiting_payment.dart';

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
  final _nasciController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  DateTime? _nascimentoDate;
  bool _isLoading = false;
  final String _baseUrl = 'https://api.comppare.com.br/api';

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
    // Implementação básica (adicione validação de dígitos se necessário)
    return true;
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  bool _isMaiorDeIdade(DateTime nascimento) {
    final hoje = DateTime.now();
    final idade = hoje.year - nascimento.year;
    final hasHadBirthdayThisYear =
        (hoje.month > nascimento.month) || (hoje.month == nascimento.month && hoje.day >= nascimento.day);
    return (idade > 18) || (idade == 18 && hasHadBirthdayThisYear);
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
        return responseData['codRetorno'] == 200 && responseData['message'] == 'OK';
      } else {
        _showErrorDialog('Erro ao verificar CPF. Tente novamente.');
        return false;
      }
    } catch (e) {
      _showErrorDialog('Erro ao conectar com a API. Tente novamente.');
      return false;
    }
  }

  Future<void> _cadastrarUsuario(String nome, String cpf, String email, String telefone, String senha, String nascimento) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/usuarios/cadastrar'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "primeiroNome": nome,
          "sobrenome": 'Silva',
          "cpf": cpf,
          "nascimento": nascimento,
          "email": email,
          "senha": senha,
          "telefone": telefone,
          "idPlano": widget.idPlano,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['sucesso'] == true || responseData['codigoRetorno'] == 200) {
          if (widget.idPlano != 1) {
            final userId = responseData['idUser'];
            final redirected = await launchUrl(
              Uri.parse('https://dev.comppare.com.br/payment.php?pid=${widget.idPlano}&uid=$userId'),
            );
            if (redirected && mounted) {
              Navigator.pushNamed(context, AwaitingPayment.route);
            }
          } else {
            _navigateToLogin();
          }
        } else {
          _showErrorDialog(responseData['mensagem'] ?? 'Erro ao cadastrar.');
        }
      } else {
        final errorResponse = jsonDecode(response.body);
        _showErrorDialog(errorResponse['mensagem'] ?? 'Erro ao conectar com a API.');
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

  void _sendCadastroData() async {
    setState(() {
      _isLoading = true;
    });

    String nome = _nameController.text.trim();
    String cpf = _cpfController.text.trim().replaceAll(RegExp(r'\D'), '');
    String email = _emailController.text.trim();
    String nascimento = _nasciController.text.trim();
    String telefone = _phoneController.text.trim();
    String senha = _passwordController.text.trim();
    String confirmSenha = _confirmPasswordController.text.trim();

    // Validações
    if ([nome, cpf, email, nascimento, telefone, senha, confirmSenha].any((field) => field.isEmpty)) {
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

    // Parse da data para validação de idade
    final parts = nascimento.split('/');
    if (parts.length == 3) {
      try {
        _nascimentoDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
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
        await _cadastrarUsuario(nome, cpf, email, telefone, senha, nascimento);
      }
    } catch (e) {
      _showErrorDialog('Erro ao conectar com a API. Tente novamente.');
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
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
                decoration: BoxDecoration(
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
                                  builder: (context) => MyHomePage(
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
                      Text(
                        'Registre-se!',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      _buildTextField(_nameController, 'Nome Completo'),
                      const SizedBox(height: 15),
                      _buildTextField(_cpfController, 'CPF'),
                      const SizedBox(height: 15),
                      _buildTextField(_emailController, 'E-mail'),
                      const SizedBox(height: 15),
                      GestureDetector(
                        onTap: () => _selectDataNascimento(context),
                        child: AbsorbPointer(
                          child: _buildTextField(_nasciController, 'Data de Nascimento'),
                        ),
                      ),
                      const SizedBox(height: 15),
                      _buildTextField(_phoneController, 'Celular'),
                      const SizedBox(height: 15),
                      _buildTextField(_passwordController, 'Senha', obscureText: true),
                      const SizedBox(height: 15),
                      _buildTextField(_confirmPasswordController, 'Confirmar Senha', obscureText: true),
                      const SizedBox(height: 10),
                      _isLoading
                          ? const CircularProgressIndicator()
                          : Padding(
                              padding: const EdgeInsets.only(top: 100),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: const Color.fromARGB(255, 251, 255, 250),
                                  backgroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                                  textStyle: const TextStyle(fontSize: 18),
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
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildCloud() {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}
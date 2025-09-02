// lib/screens/login_screen.dart (Renomeado para clareza)

import 'package:application_progress/infra/api_exception.dart';
import 'package:flutter/material.dart';
import 'dart:convert'; // Para json.decode
// Importa o TokenHelper corrigido
import 'package:application_progress/infra/api_services.dart'; // Importa o ApiService
// Importa o UserHelper
import 'package:application_progress/cadastro.dart'; // Ajuste o nome do arquivo se for diferente
import 'package:application_progress/views/recupera_senha.dart';
import 'package:application_progress/principal.dart';

import 'package:application_progress/models/plan_model.dart';
// Importa a PrincipalPage

// Removendo MyApp e AuthWrapper daqui, eles devem estar em main.dart
// class MyApp extends StatelessWidget { ... }
// class AuthWrapper extends StatelessWidget { ... }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  final ApiService _apiService = ApiService(); // Instância do ApiService

  @override
  void dispose() {
    _cpfController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final String cpfDigitado =
        _cpfController.text.trim().replaceAll(RegExp(r'\D'), '');
    final String senhaDigitada = _passwordController.text;

    print('CPF a ser enviado: $cpfDigitado');
    print('Senha a ser enviada: $senhaDigitada');

    try {
      // ⭐ Delega a autenticação para o ApiService
      final Map<String, dynamic> responseData =
          await _apiService.authenticateUser(
        cpfDigitado,
        senhaDigitada,
      );
      print(
          'Corpo da requisição de autenticação: ${json.encode(responseData)}');

      // Se authenticateUser não lançou exceção, significa que foi sucesso
      // O TokenHelper e UserHelper já foram atualizados dentro de authenticateUser
      // pelo ApiService.

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login bem-sucedido!')),
        );
        // Navega para PrincipalPage sem passar CPF e Senha
        // A PrincipalPage deve obter o userId do TokenHelper
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const PrincipalPage(), // PrincipalPage agora não precisa de CPF/Senha
          ),
        );
      }
    } catch (error) {
      String errorMessage = 'Erro desconhecido. Tente novamente.';
      if (error is ApiException) {
        errorMessage = error.message;
        // Se for 401, o ApiService já lida, mas podemos adicionar um log específico aqui
        if (error.statusCode == 401) {
          errorMessage = 'Credenciais inválidas. Verifique seu CPF e senha.';
        }
      }
      _showErrorDialog(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erro de Login'), // Título mais específico
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(top: 50, left: -50, child: _buildCloud()),
          Positioned(top: 100, right: -50, child: _buildCloud()),
          Positioned(bottom: 100, left: 50, child: _buildCloud()),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                      Radius.circular(12)), // Adicionado arredondamento
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Se você quer que o logo volte para a página inicial do app (main.dart)
                        // Navigator.pushAndRemoveUntil(
                        //   context,
                        //   MaterialPageRoute(builder: (context) => const MyHomePage(title: '')),
                        //   (Route<dynamic> route) => false,
                        // );
                      },
                      child: Image.asset(
                        "assets/logo_cortada.png",
                        width: 450,
                        height: 60,
                      ),
                    ),
                    const SizedBox(height: 50),
                    TextField(
                      controller: _cpfController,
                      decoration: const InputDecoration(
                        labelText: 'CPF',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                      keyboardType:
                          TextInputType.number, // Ajuda na entrada de CPF
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Senha',
                        labelStyle: TextStyle(color: Colors.black),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black),
                        ),
                      ),
                      style: const TextStyle(color: Colors.black),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            // Para que o botão ocupe o espaço disponível
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 20,),
                                textStyle: const TextStyle(fontSize: 18),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        8)), // Arredondamento
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Entrar',
                                      style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 15),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                      Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const RecoverPasswordScreen()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Color(0xFFaed513),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)), // Arredondamento
                        ),
                        child: Text('Esqueceu a senha?'),
                      )
                    ),
                    SizedBox(width: 50),
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Expanded(
                            // Para que o botão ocupe o espaço disponível
                            child: _buildActionButton(
                                context,
                                'Deseja se cadastrar?',
                                CadastroScreen(
                                  plan: PlanModel.empty()..id = 1,
                                )),
                          ),
                    ),
                    ],)
                    
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloud() {
    return Container(
      width: 100,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, Widget targetPage) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Color(0xFFaed513),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)), // Arredondamento
      ),
      child: Text(label),
    );
  }
}

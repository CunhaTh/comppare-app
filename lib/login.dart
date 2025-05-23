import 'package:application_progress/cadastro.dart';
import 'package:application_progress/main.dart';
import 'package:application_progress/principal.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'infra/token_helper.dart';
import 'infra/user_helper.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login',
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: const Color.fromARGB(255, 212, 213, 206),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        colorScheme:
            ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFaed513)),
      ),
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _cpfController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    const String url = 'https://api.comppare.com.br/api/usuarios/autenticar';
    final Map<String, String> headers = {'Content-Type': 'application/json'};
    final Map<String, dynamic> body = {
      'cpf': _cpfController.text.trim().replaceAll(RegExp(r'\D'), ''),
      'senha': _passwordController.text,
    };

    try {
      final response = await http.post(Uri.parse(url),
          headers: headers, body: json.encode(body));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        print('RESPONSE DO LOGIN: $data');

        if (data.containsKey('original') &&
            data['original'].containsKey('token')) {
          final String token = data['original']['token'];

          TokenHelper.instance.setToken(token);
          UserHelper.instance.setUser(
            UserModel.fromMap(data['original']['dados']),
          );

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PrincipalPage()),
          );
        } else {
          _showErrorDialog('Credenciais inválidas. Tente novamente.');
        }
      } else {
        final Map<String, dynamic> errorData = json.decode(response.body);
        _showErrorDialog('Credenciais inválidas. Tente novamente.');
      }
    } catch (error) {
      _showErrorDialog('Erro de conexão. Tente novamente mais tarde.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erro'),
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

  Widget _buildActionButton(
      BuildContext context, String label, Widget targetPage) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => targetPage,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color.fromARGB(255, 251, 255, 250),
        backgroundColor: const Color(0xFF637700),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        textStyle: const TextStyle(fontSize: 18),
      ),
      child: Text(label),
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
                ),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MyHomePage(
                              title: '',
                            ),
                          ),
                        );
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
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 80, vertical: 20),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Entrar',
                                      style: TextStyle(color: Colors.white)),
                            ),
                            const SizedBox(width: 20),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60, vertical: 20),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CadastroScreen(
                                      idPlano: null,
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Cadastrar',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ]),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: GestureDetector(
                        onTap: () {},
                        child: const Text(
                          'Esqueceu a senha?',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color.fromARGB(165, 0, 0, 0)),
                        ),
                      ),
                    )
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
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(30),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String token;
  const HomeScreen({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 30),
      child: Stack(children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Tela Principal'),
            actions: [
              // Aqui você pode adicionar mais botões no menu superior
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF637700), // Cor do botão
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  /*  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())); */
                },
                child: const Text(
                  'Cadastrar',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF637700), // Cor do botão
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  /*  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())); */
                },
                child: const Text(
                  'Cadastrar',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF637700), // Cor do botão
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  /*  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())); */
                },
                child: const Text(
                  'Cadastrar',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF637700), // Cor do botão
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  /*  Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen())); */
                },
                child: const Text(
                  'Cadastrar',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
            ],
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Aqui você pode customizar seus cards!',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const CustomScreen()));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color(0xFF637700),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: const Text('Ir para Custom Screen',
                        style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

// Certifique-se de criar a CustomScreen
class CustomScreen extends StatelessWidget {
  const CustomScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tela de Customização'),
      ),
      body: const Center(
        child: Text('Aqui é a tela de customização!'),
      ),
    );
  }
}

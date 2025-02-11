import 'package:application_progress/login.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Gamificado',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CadastroScreen(),
    );
  }
}

class CadastroScreen extends StatefulWidget {
  const CadastroScreen({super.key});

  @override
  _CadastroScreenState createState() => _CadastroScreenState();
}

class _CadastroScreenState extends State<CadastroScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _login() {
    // Aqui você deve implementar a lógica para autenticar o usuário
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children:[
          Positioned(top: 50, left: -50, child: _buildCloud()),
          Positioned(top: 100, right: -50, child: _buildCloud()),
          Positioned(bottom: 100, left: 50, child: _buildCloud()),
          Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
                  color: Color.fromARGB(255, 216, 250, 217), // Fundo do container
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Cadastre-se!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF637700)),
                ),
                const SizedBox(height: 20),
                TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Completo',
                          labelStyle: TextStyle(color: Color(0xFF637700)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF637700)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'CPF',
                          labelStyle: TextStyle(color: Color(0xFF637700)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF637700)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                const SizedBox(height: 10),
                TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'e-mail',
                          labelStyle: TextStyle(color: Color(0xFF637700)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF637700)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                const SizedBox(height: 10),
                TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'celular',
                          labelStyle: TextStyle(color: Color(0xFF637700)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF637700)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                const SizedBox(height: 10),
                TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'senha',
                          labelStyle: TextStyle(color: Color(0xFF637700)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF637700)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                const SizedBox(height: 10),
                TextField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'confirmar senha',
                          labelStyle: TextStyle(color: Color(0xFF637700)),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF637700)),
                          ),
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                      const SizedBox(height: 20),
                 ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF637700), // Cor do botão
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
                        },
                        child: const Text(
                  'Cadastrar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                      ),
              ],
            ),
          ),
        ),
        ] 
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
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tela Principal'),
      ),
      body: const Center(
        child: Text(
          'Aqui você pode customizar seus cards!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}

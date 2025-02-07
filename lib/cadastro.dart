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
    // por meio de uma requisição HTTP para o backend.
    // Por exemplo:
    // final response = await http.post('http://seu_backend/login', body: {
    //   'username': _usernameController.text,
    //   'password': _passwordController.text,
    // });

    // Se a autenticação for bem-sucedida, navegue para a tela de cards.
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Registre-se!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: /*_login*/(){
          Navigator.push(context, MaterialPageRoute(builder: (context) => LoginScreen()));
        },
                child: const Text('Registrar'),
              ),
            ],
          ),
        ),
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

import 'package:application_progress/cadastro.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/comparepage.dart';
import 'package:application_progress/views/pagamento.dart';
import 'package:application_progress/views/admpage.dart';
import 'package:application_progress/views/shopping_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppProgress',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'AppProgress'),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Imagem de fundo com responsividade
          Positioned.fill(
            child: Image.asset(
              "assets/tela_principal.png",
              fit: BoxFit.cover,
            ),
          ),
          // Botão ADM no canto superior direito
          Positioned(
            top: 40,
            right: 20,
            child: _buildAdmButton(context),
          ),
          // Área de botões na parte inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(context, 'Assinar', HomePage()),
                  _buildActionButton(context, 'Login', LoginScreen()),
                  _buildActionButton(context, 'Cadastro', CadastroScreen(idPlano: null)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Método para criar o botão ADM
  Widget _buildAdmButton(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrincipalPage(),
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: const Color.fromARGB(255, 255, 68, 68), // Cor de fundo personalizada
        textStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white, // Cor do texto
        ),
      ),
      child: const Text('ADM',style: TextStyle(color: Colors.white),),
    );
  }

  // Método para criar botões com design melhorado
  Widget _buildActionButton(BuildContext context, String label, Widget targetPage) {
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
      foregroundColor: Color.fromARGB(255, 251, 255, 250), 
      backgroundColor: Color(0xFF637700),
      padding: EdgeInsets.symmetric(horizontal: 45, vertical: 20),
      textStyle: TextStyle(fontSize: 18),),
      child: Text(label),
    );
  }
}

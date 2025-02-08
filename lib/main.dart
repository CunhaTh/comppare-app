import 'package:application_progress/cadastro.dart';
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
      home: const MyHomePage(title: 'Meu Progresso'),
      debugShowCheckedModeBanner: false
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
          // Imagem de fundo
          Center(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 4), // Borda branca
                borderRadius: BorderRadius.circular(12), // Bordas arredondadas
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12), // Arredondar a imagem
                child: Image.asset(
                  "assets/tela_principal.png",
                  fit: BoxFit.cover,
                  width: 2400, // Defina a largura desejada
                  height: 1080, // Defina a altura desejada
                ),
              ),
            ),
          ),

          // Botão "Assinar" na parte inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Adiciona espaçamento ao redor do botão
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => HomePage()));
                },
                tooltip: 'Click',
                child: const Text('Assinar'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

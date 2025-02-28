import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parceiros',
      theme: ThemeData(
        primaryColor: Color(0xFF637700), // Cor primária
        scaffoldBackgroundColor: Color.fromARGB(255, 212, 213, 206), // Cor de fundo
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: Color(0xFFaed513)),
      ),
      home: AdmPage(),
    );
  }
}

class AdmPage extends StatelessWidget {
  const AdmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tela Gerencial'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Aqui você pode customizar / Configurar "TODO" o APP',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: (){},
              child: Container(
                padding: EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color:  Color(0xFF637700),
                  borderRadius: BorderRadius.circular(12.0), // Mais arredondado
                  
                ),
                child: Text(
                'BOTÂO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white
                  ),
                ),
              ),
            )
           
          ],
        ),
      ),
    );
  }
}

class Gerenciar extends StatelessWidget {
  const Gerenciar({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tela Parceiros'),
      ),
      body: const Center(
        child: Text(
          'Aqui você Ve todos os nossos parceiros',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}



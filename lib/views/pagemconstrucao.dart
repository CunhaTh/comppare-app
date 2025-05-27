import 'package:flutter/material.dart';



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Exibindo uma Imagem'),
        ),
        body: Center(
          child: Image.asset(
            'assets/pag-em-construcao.png',
          ),
        ),
      ),
    );
  }
}

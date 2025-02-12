import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//blbnaisbhfuisdbfghbasduhfgbjdshbgvjhsdfabhj

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ApiScreen(),
    );
  }
}

class ApiScreen extends StatefulWidget {
  @override
  _ApiScreenState createState() => _ApiScreenState();
}

class _ApiScreenState extends State<ApiScreen> {
  String _data = "Pressione o botão para buscar os dados";

  Future<void> fetchData() async {
    final url = Uri.parse('https://comppare-app.onrender.com/api/test');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          _data = "Título: ${jsonResponse['title']}";
        });
      } else {
        setState(() {
          _data = "Erro ao buscar os dados";
        });
      }
    } catch (e) {
      setState(() {
        _data = "Erro: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Flutter API Call")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(_data, textAlign: TextAlign.center),
            ),
            ElevatedButton(
              onPressed: fetchData,
              child: Text("Buscar Dados"),
            ),
          ],
        ),
      ),
    );
  }
}

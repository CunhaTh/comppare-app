import 'package:application_progress/cadastro.dart';
import 'package:application_progress/main.dart';
import 'package:application_progress/views/pagamento.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SelectPlan',
      theme: ThemeData(primarySwatch: Colors.green),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedPlan = 1;
  bool isLoading = false;

  final List<Map<String, dynamic>> plans = [
    {
      "idPlano": 1,
      "nome": "Basic Plan",
      "descricao": "For beginner use",
      "valor": 19.0,
      "quantidadeTags": 1,
      "gratuidade": 3
    },
    {
      "idPlano": 2,
      "nome": "Standard Plan",
      "descricao": "For professional use",
      "valor": 99.0,
      "quantidadeTags": 3,
      "gratuidade": 5
    },
    {
      "idPlano": 3,
      "nome": "Team Plan",
      "descricao": "For team collaboration",
      "valor": 49.0,
      "quantidadeTags": 2,
      "gratuidade": 4
    },
  ];

  void selectPlan(int index) {
    setState(() {
      selectedPlan = index;
    });
  }

  Future<void> navigateToCadastro() async {
    setState(() {
      isLoading = true;
    });

    final selectedPlanDetails = plans[selectedPlan - 1];
    final int idPlano = selectedPlanDetails['idPlano'];

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CheckoutScreen(idPlano: idPlano),
        ),
      );
    } catch (e) {
      showErrorDialog("Erro ao navegar para a tela de cadastro.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Erro"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Fechar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MyHomePage(title: '',)),
            );
          },
          child: Image.asset('assets/logo_escura.png', width: 30),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Precisa de ajuda? contate-nos ',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
          InkWell(
            onTap: () {
            },
            child: Text(
              'comppare-app@comppare.com.br',
              style: TextStyle(color: Color(0xFF637700)),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Escolha seu Plano',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < plans.length; i++)
                      _buildPlanButton(plans[i]['nome'], i + 1),
                  ],
                ),
                Expanded(child: _buildPlanDetails()),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                              foregroundColor: Color.fromARGB(255, 251, 255, 250), backgroundColor: Color(0xFF637700),
                              padding: EdgeInsets.symmetric(horizontal: 80, vertical: 20),
                              textStyle: TextStyle(fontSize: 18),
                              ),
                onPressed: isLoading ? null : navigateToCadastro,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Assinar'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanButton(String title, int index) {
    return GestureDetector(
      onTap: () => selectPlan(index),
      child: Container(
        padding: EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: selectedPlan == index ? Color(0xFF637700) : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selectedPlan == index ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanDetails() {
    final selectedPlanDetails = plans[selectedPlan - 1];

    return Card(
      elevation: 10,
      margin: EdgeInsets.only(top: 30,bottom: 100, left: 80,right: 80),
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Text(
              '\$${selectedPlanDetails['valor']}',
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            ),
            Text(selectedPlanDetails['descricao']),
            SizedBox(height: 20.0),
            ...selectedPlanDetails.entries.where((entry) =>
                entry.key != 'nome' &&
                entry.key != 'descricao' &&
                entry.key != 'valor').map<Widget>((entry) {
              return Padding(
                padding: const EdgeInsets.only(left: 100,top: 20),
                child: Row(
                  children: [
                    Icon(FontAwesomeIcons.check, color: Colors.green),
                    SizedBox(width: 8.0),
                     Text(
                        '${entry.key}: ${entry.value}',style: TextStyle(fontSize: 16),
                      ),
                    
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
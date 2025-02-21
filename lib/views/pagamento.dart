import 'package:application_progress/cadastro.dart';
import 'package:application_progress/main.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SelectPlan',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: Pagamento(),
    );
  }
}

class Pagamento extends StatefulWidget {
  @override
  _PlanosPage createState() => _PlanosPage();
}

class _PlanosPage extends State<Pagamento> {
  int selectedPlan = 1; // Default to Standard Plan

  void selectPlan(int index) {
    setState(() {
      selectedPlan = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MyHomePage(title: 'HomePage')));
              },
              child: Image.asset('assets/logo_escura.png', width: 30),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Center(
              child: Text(
                'Precisa de ajuda? contate-nos ',
                style: TextStyle(color: Colors.black54),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              // Implementar ação para contato
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Text(
                'contato-comppare@comppare.com.br',
                style: TextStyle(color: Color(0xFF637700)),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'Escolha seu Plano',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 80),
            Expanded(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildPlanButton('Basic', 1),
                      _buildPlanButton('Standard', 2),
                      _buildPlanButton('Team', 3),
                    ],
                  ),
                  SizedBox(height: 20), // Espaço entre os botões e detalhes
                  Expanded(
                    child: _buildPlanDetails(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            Center(
              child: GestureDetector(
                onTap: (){Navigator.push(context,
                      MaterialPageRoute(builder: (context) => CadastroScreen(idPlano: null,)));},
                child: Container(
                  padding: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color:  Color(0xFF637700),
                    borderRadius: BorderRadius.circular(12.0), // Mais arredondado
                    
                  ),
                  child: Text(
                  'Assinar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white
                    ),
                  ),
                ),
              ),
            ),
            Row(
              children: [
                TextField(inputFormatters: [],)
              ],
            ) 
          ],
        ),
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
          borderRadius: BorderRadius.circular(12.0), // Mais arredondado
          boxShadow: [
            if (selectedPlan == index)
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8.0,
                offset: Offset(0, 4),
              ),
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: selectedPlan == index ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanDetails() {
    List<Map<String, dynamic>> plans = [
      {
        'price': '19',
        'description': 'For beginner use',
        'features': [
          '100 GB Premium Bandwidth',
          'FREE 50+ Installation Scripts WordPress Supported',
          'One FREE Domain Registration .com and .np extensions only',
          'Unlimited Email Accounts & Databases',
        ],
      }
      
    ];

    var selectedPlanDetails = plans[selectedPlan - 1];

    return Card(
      elevation: 6,
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${selectedPlanDetails['price']}',
              style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF637700)),
            ),
            SizedBox(height: 10),
            Text(
              selectedPlanDetails['description'],
              style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
            ),
            SizedBox(height: 16.0),
            Text(
              'Características:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8.0),
            ...selectedPlanDetails['features'].map<Widget>((feature) {
              return Row(
                children: [
                  Icon(FontAwesomeIcons.check, color: Colors.green),
                  SizedBox(width: 8.0),
                  Expanded(child: Text(feature)),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nutrafix',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _PlanosPage createState() => _PlanosPage();
}

class _PlanosPage extends State<HomePage> {
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
        title: Image.asset('imgs/NutraFix_Logo.webp', width: 200),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                'Precisa de ajuda? contate-nos ',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
          InkWell(
            onTap: () {
              // Implementar ação para contato
            },
            child: Text(
              'suporte@nutrafix.com.br',
              style: TextStyle(color: Colors.white, decoration: TextDecoration.underline),
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
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
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
                Expanded(
                  child: _buildPlanDetails(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Implementar ação para escolher o plano
              },
              child: Text('Choose plan'),
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
          color: selectedPlan == index ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Text(
          title,
          style: TextStyle(color: selectedPlan == index ? Colors.white : Colors.black),
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
      },
      {
        'price': '99',
        'description': 'For professional use',
        'features': [
          'Unlimited GB Premium Bandwidth',
          'FREE 200+ Installation Scripts WordPress Supported',
          'Five FREE Domain Registration .com and .np extensions only',
          'Unlimited Email Accounts & Databases',
        ],
      },
      {
        'price': '49',
        'description': 'For team collaboration',
        'features': [
          '200 GB Premium Bandwidth',
          'FREE 100+ Installation Scripts WordPress Supported',
          'Two FREE Domain Registration .com and .np extensions only',
          'Unlimited Email Accounts & Databases',
        ],
      },
    ];

    var selectedPlanDetails = plans[selectedPlan - 1];

    return Card(
      elevation: 4,
      margin: EdgeInsets.all(16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '\$${selectedPlanDetails['price']}',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            Text(selectedPlanDetails['description']),
            SizedBox(height: 16.0),
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

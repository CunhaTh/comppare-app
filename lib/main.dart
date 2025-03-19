import 'package:application_progress/cadastro.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/pagamento.dart';
import 'package:application_progress/views/shopping_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

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
  int selectedPlan = 1;
  bool isLoading = false;

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

  final List<Map<String, dynamic>> plans = [
    {
      "idPlano": 1,
      "nome": "Plano Básico",
      "descricao": "Descrição do plano básico.",
      "valor": 19.0,
    },
    {
      "idPlano": 2,
      "nome": "Plano Intermediário",
      "descricao": "Descrição do plano intermediário.",
      "valor": 99.0,
    },
    {
      "idPlano": 3,
      "nome": "Plano Avançado",
      "descricao": "Descrição do plano avançado.",
      "valor": 49.0,
    },
  ];
   void selectPlan(int index) {
    setState(() {
      selectedPlan = index;
    });
  }
 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Imagem de fundo com responsividade
            Image.asset(
              "assets/tela_principal.png",
              fit: BoxFit.cover,
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.3,
            ),
            // Área de botões na parte superior
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 25,top: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(context, 'ENTRAR', LoginScreen()),
                      _buildAdmButton(context),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                // Área do meio da tela
                Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Escolha seu Plano',
              style: TextStyle(color: Colors.white,fontSize: 25, fontWeight: FontWeight.bold),
            ),
          ),
          Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    for (int i = 0; i < plans.length; i++)
                      _buildPlanButton(plans[i]['nome'], i + 1),
                  ],
                ),
                Column(children:[ _buildPlanDetails()]),
              ],
            ),
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                              foregroundColor: Color.fromARGB(255, 251, 255, 250), backgroundColor: Color(0xFF637700),
                              padding: EdgeInsets.symmetric(horizontal: 140, vertical: 25),
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
             /* Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, -2)),
                  ],
                ),
                child: Column(
                 crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Nossos Planos',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Column(
                      
                      children: plans.map((plan) {
                        return _buildPlanCard(plan);
                        
                      }).toList(),
                    ),
                    ElevatedButton(
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
                  ],
                ),
              ),*/
            
              ],
            ),
            
            
          ],
        ),
      ),
    );
  }

   Widget _buildPlanDetails() {
    final selectedPlanDetails = plans[selectedPlan - 1];
    return Card(
      elevation: 10,
      margin: EdgeInsets.only(top: 30,bottom: 20, left: 80,right: 80),
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Column(
          children: [
            Text(
              '\$${selectedPlanDetails['valor']}',
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            ),
            Text(selectedPlanDetails['descricao']),
            SizedBox(height: 10.0),
            ...selectedPlanDetails.entries.where((entry) =>
                entry.key != 'nome' &&
                entry.key != 'descricao' &&
                entry.key != 'valor').map<Widget>((entry) {
              return Padding(
                padding: const EdgeInsets.only(left: 30,top: 10,bottom: 300),
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

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    return GestureDetector(
      onTap: () => setState(() {
        selectedPlan = plan['idPlano'];
      }),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: selectedPlan == plan['idPlano'] ? Color(0xFF637700) : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Text(
              plan['nome'],
              style: TextStyle(
                color: selectedPlan == plan['idPlano'] ? Colors.white : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              plan['descricao'],
              style: TextStyle(
                color: selectedPlan == plan['idPlano'] ? Colors.white : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Preço: R\$ ${plan['valor'].toStringAsFixed(2)}',
              style: TextStyle(
                color: selectedPlan == plan['idPlano'] ? Colors.white : Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdmButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 20,bottom: 40),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: const Color.fromARGB(255, 255, 68, 68),
          textStyle: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        child: const Text('ADM',style: TextStyle(color: Colors.white),),
      ),
    );
  }

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
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        textStyle: TextStyle(fontSize: 18),
      ),
      child: Text(label),
    );
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
}

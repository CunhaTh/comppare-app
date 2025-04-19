import 'dart:io';

import 'package:application_progress/cadastro.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/planos.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/admpage.dart';
import 'package:application_progress/views/compparepage.dart';
import 'package:application_progress/views/pagamento.dart';
import 'package:application_progress/views/shopping_page.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'views/pagamento_teste.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'comppare',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: MyHomePage(
        title: '',
      ),
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
  int? selectedQuestionIndex;
  List<Plano> plans = [];

  @override
  void initState() {
    super.initState();
    fetchPlans();
  }

  Future<void> fetchPlans() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http
          .get(Uri.parse("https://api.comppare.com.br/api/planos/listar"));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> planosJson = data['data'];
        plans = planosJson.map((json) => Plano.fromJson(json)).toList();
      } else {
        showErrorDialog("Erro ao buscar planos: ${response.reasonPhrase}");
      }
    } catch (e) {
      showErrorDialog("Erro ao buscar planos: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> navigateToCadastro() async {
    setState(() {
      isLoading = true;
    });

    if (plans.isEmpty || selectedPlan < 1 || selectedPlan > plans.length) {
      showErrorDialog("Nenhum plano disponível para seleção.");
      setState(() {
        isLoading = false; // Certifique-se de parar o loading
      });
      return; // Retorna para não continuar
    }

    final selectedPlanDetails = plans[selectedPlan - 1];
    final int idPlano =
        selectedPlanDetails.id; // Acesse usando notação de ponto

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

  // Lista de perguntas e respostas
  final List<Map<String, String>> faqs = [
    {
      "question": "Como faço para assinar um plano?",
      "answer":
          "Para assinar um plano, escolha um dos planos disponíveis e clique no botão 'Assinar'."
    },
    {
      "question": "Quais são os métodos de pagamento aceitos?",
      "answer": "Aceitamos cartões de crédito, débito e PayPal."
    },
    {
      "question": "Posso cancelar minha assinatura?",
      "answer":
          "Sim, você pode cancelar sua assinatura a qualquer momento através da sua conta."
    },
    {
      "question": "Como posso mudar meu plano?",
      "answer":
          "Para mudar seu plano, entre em contato com o suporte ao cliente."
    },
  ];
  // Lista de planos
  /*final List<Map<String, dynamic>> plans = [
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
  ];*/
  void selectPlan(int index) {
    setState(() {
      selectedPlan = index;
    });
  }

// Widget principal com todo conteudo
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            // Imagem de fundo com responsividade
            Image.asset(
              "assets/bg-comppare.jpeg",
              fit: BoxFit.cover,
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.2,
            ),
            // Área de botões na parte superior
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 15, top: 5),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildActionButton(context, 'ENTRAR', LoginScreen()),
                      _buildAdmButton(context),
                      Padding(
                        padding: const EdgeInsets.only(right: 30, bottom: 15),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PrincipalPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 20),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor:
                                const Color.fromARGB(255, 255, 68, 68),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          child: const Text(
                            'ADM',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
                // Área do meio da tela
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10),
                      child: Text(
                        'NOSSOS PLANOS',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 25,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 30),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              for (int i = 0; i < plans.length; i++)
                                _buildPlanButton(plans[i].nome, i + 1),
                            ],
                          ),
                          Column(children: [_buildPlanDetails()]),
                        ],
                      ),
                    ),
                    Padding(padding: EdgeInsets.only(top: 20, bottom: 20)),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Perguntas Frequentes',
                            style: TextStyle(
                                fontSize: 25, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: faqs.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedQuestionIndex =
                                        selectedQuestionIndex == index
                                            ? null
                                            : index;
                                  });
                                },
                                child: Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        faqs[index]["question"]!,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold),
                                      ),
                                      if (selectedQuestionIndex == index) ...[
                                        const SizedBox(height: 5),
                                        Text(faqs[index]["answer"]!)
                                      ]
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 60, bottom: 15),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(
                          child: Text(
                            'Precisa de ajuda? contate-nos ',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        Padding(
                            padding:
                                EdgeInsets.only(top: 10, bottom: 10, left: 10)),
                        InkWell(
                          onTap: () {},
                          child: Text(
                            'comppare-app@comppare.com.br',
                            style: TextStyle(color: Color(0xFF637700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  /*Widget _buildPlanDetails() {
    final selectedPlanDetails = plans[selectedPlan - 1];
    return Card(
      color: const Color(0xFF99cc00),
      elevation: 10,
      margin: EdgeInsets.only(left: 44,right: 44,),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
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
                child: Column(
                  children: [
                    Column(children: [
                      Row(children: [
                        Icon(FontAwesomeIcons.check, color: Colors.black),
                        SizedBox(width: 10.0),
                        Text(
                        '${entry.key}: ${entry.value}',style: TextStyle(fontSize: 16),
                      ),
                      ],),
                      Row(children: [
                        Icon(FontAwesomeIcons.check, color: Colors.black),
                        SizedBox(width: 10.0),
                    Text(
                        '${entry.key}: ${entry.value}',style: TextStyle(fontSize: 16),
                      ),
                      ],),
                      Row(children: [
                        Icon(FontAwesomeIcons.check, color: Colors.black),
                        SizedBox(width: 10.0),
                      Text(
                        '${entry.key}: ${entry.value}',style: TextStyle(fontSize: 16),
                      ),
                        ],
                          ),
                            ],
                            ),
                            
                          ],
                ),
              );
            }).toList(),
            Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                         foregroundColor: Color.fromARGB(255, 251, 255, 250), backgroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(horizontal: 100, vertical: 25),
                              textStyle: TextStyle(fontSize: 18),
                              ),
                                onPressed: isLoading ? null : navigateToCadastro,
                                  child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text('ASSINE'),
                                ),
                              ),
                            ),
          ],
        ),
      ),
    );
  }*/

  Widget _buildPlanDetails() {
    final selectedPlanDetails = plans[selectedPlan - 1];
    return Card(
      color: const Color(0xFF99cc00),
      elevation: 10,
      margin: EdgeInsets.only(
        left: 44,
        right: 44,
      ),
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Column(
          children: [
            Text(
              '\$${selectedPlanDetails.valor.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
            ),
            Text(selectedPlanDetails.descricao),
            SizedBox(height: 10.0),
            // Exibir outros detalhes do plano
            Text('Quantidade de Tags: ${selectedPlanDetails.quantidadeTags}'),
            Text('Quantidade de Fotos: ${selectedPlanDetails.quantidadeFotos}'),
            // Adicione outros detalhes conforme necessário
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
          color: selectedPlan == index ? Colors.black : Colors.grey[300],
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
          color: selectedPlan == plan['idPlano']
              ? Color(0xFF637700)
              : Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          children: [
            Text(
              plan['nome'],
              style: TextStyle(
                color: selectedPlan == plan['idPlano']
                    ? Colors.white
                    : Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              plan['descricao'],
              style: TextStyle(
                color: selectedPlan == plan['idPlano']
                    ? Colors.white
                    : Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Preço: R\$ ${plan['valor'].toStringAsFixed(2)}',
              style: TextStyle(
                color: selectedPlan == plan['idPlano']
                    ? Colors.white
                    : Colors.black,
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
      padding: const EdgeInsets.only(top: 30, right: 20, bottom: 40),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const EfiTokenPage()
                //  CheckoutScreen(idPlano: null,)
                //CompparePage(images: [],category: '',folderName: '',),
                ),
          );
        },
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
        child: const Text(
          'ADM',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildActionButton(
      BuildContext context, String label, Widget targetPage) {
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
        backgroundColor: Colors.black,
        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        textStyle: TextStyle(fontSize: 16),
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

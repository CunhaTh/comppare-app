import 'package:application_progress/cadastro.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/planos.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/admpage.dart';
import 'package:application_progress/views/compparepage.dart';
import 'package:application_progress/views/pagamento.dart';
import 'package:application_progress/views/shopping_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'chat_button.dart';
import 'views/awaiting_payment.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MobileAds.instance.initialize();
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
      initialRoute: Uri.base.path,
      routes: {
        '/': (_) => const MyHomePage(title: ''),
        AwaitingPayment.route: (_) => const AwaitingPayment(),
      },
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AwaitingPayment.route:
            return MaterialPageRoute(builder: (_) => const AwaitingPayment());
          default:
            return MaterialPageRoute(
              builder: (_) => const MyHomePage(title: ''),
            );
        }
      },
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

class _HintArrowButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _HintArrowButton({Key? key, required this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      iconSize: 48.0,
      tooltip: 'Down Arrow', // equivalente ao aria-label
      icon: SvgPicture.string(
        '''
        <svg class="daq0j418" data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
          <rect width="48" height="48" fill="none"></rect>
          <path d="M36.63,18.37a1.37,1.37,0,0,1,2.15.37,1.7,1.7,0,0,1-.3,2.06L25.4,32.64a1.37,1.37,0,0,1-1.85,0l-13-11.84a1.71,1.71,0,0,1-.29-2.06,1.37,1.37,0,0,1,2.15-.37l12.11,11ZM24.25,31.42a.38.38,0,0,1,.46,0l-.23-.21ZM11.71,19.55s0,.06,0,0Zm25.61,0h0Z"></path>
        </svg>
        ''',
        // É necessário usar o pacote flutter_svg para renderizar SVGs
        // Certifique-se de adicioná-lo ao seu pubspec.yaml
      ),
      onPressed: onPressed,
    );
  }
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

  void selectPlan(int index) {
    setState(() {
      selectedPlan = index;
    });
  }

// Widget principal com todo conteudo
  /* @override
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
                                child: const Text('ADM',style: TextStyle(color: Colors.white),),
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
                    style: TextStyle(color: Colors.black,fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30),
                    child: Column(
                          children: [
                            for (int i = 0; i < plans.length; i++)
                              _buildPlanCard(
                                plans[i], // passa o plano individual
                                selectedPlan == plans[i], // exemplo: verifica se é o plano selecionado
                                () => setState(() {
                                  selectedPlan = plans[i] as int; // define o plano selecionado
                                }),
                                () {} /* lógica para cadastrar */,
                                context,
                              ),
                          ],
                        ),
                  ),
                    Padding(padding: EdgeInsets.only(top: 20,bottom: 20)),
                   Padding(padding: const EdgeInsets.all(16.0),
                   child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Perguntas Frequentes',
                       style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: 10,),
                       ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: faqs.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState((){
                                selectedQuestionIndex = selectedQuestionIndex == index ? null : index;
                              });
                            },
                            child: Card(margin: const EdgeInsets.symmetric(vertical: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(faqs[index]["question"]!,
                                style: TextStyle(fontWeight: FontWeight.bold),
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
                      child: Row(mainAxisAlignment: MainAxisAlignment.center,children: [
                      Center(
                          child: Text(
                            'Precisa de ajuda? contate-nos ',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        Padding(padding: EdgeInsets.only(top: 10,bottom: 10, left: 10)),
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
                    ),
                   )
              ],
            ),
            
          ],
        ),
      ),
      
    );
  }  */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ChatButton(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Seção de destaque com imagem e textos
            _buildHeroSection(),
            SizedBox(
              height: 10,
            ),
            Column(
              children: [
                Text(
                  'VER PLANOS',
                  style: TextStyle(fontSize: 13),
                ),
                IconButton(
                  iconSize: 48.0,
                  tooltip: 'Down Arrow', // equivalente ao aria-label
                  icon: SvgPicture.string(
                    '''
                <svg class="daq0j418" data-name="Layer 1" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
                  <rect width="48" height="48" fill="none"></rect>
                  <path d="M36.63,18.37a1.37,1.37,0,0,1,2.15.37,1.7,1.7,0,0,1-.3,2.06L25.4,32.64a1.37,1.37,0,0,1-1.85,0l-13-11.84a1.71,1.71,0,0,1-.29-2.06,1.37,1.37,0,0,1,2.15-.37l12.11,11ZM24.25,31.42a.38.38,0,0,1,.46,0l-.23-.21ZM11.71,19.55s0,.06,0,0Zm25.61,0h0Z"></path>
                </svg>
                ''',
                    // É necessário usar o pacote flutter_svg para renderizar SVGs
                    // Certifique-se de adicioná-lo ao seu pubspec.yaml
                  ),
                  onPressed: () {},
                )
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Column(
                children: [
                  for (int i = 0; i < plans.length; i++)
                    _buildPlanCard(
                      plans[i], // passa o plano individual
                      selectedPlan ==
                          plans[
                              i], // exemplo: verifica se é o plano selecionado
                      () => setState(() {
                        selectedPlan =
                            plans[i] as int; // define o plano selecionado
                      }),
                      () {} /* lógica para cadastrar */,
                      context,
                    ),
                ],
              ),
            ),
            // Seção de planos
            // _buildPlanDetails(plans,selectedPlan),

            // Seção de perguntas frequentes
            //_buildFaqSection(),

            // Rodapé
            Padding(padding: EdgeInsets.only(top: 20, bottom: 20)),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Perguntas Frequentes',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
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
                                selectedQuestionIndex == index ? null : index;
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                faqs[index]["question"]!,
                                style: TextStyle(fontWeight: FontWeight.bold),
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
            Padding(
              padding: const EdgeInsets.all(8.0),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Stack(children: [
      // Imagem de fundo (substitua pelo seu asset ou rede)
      Image.asset(
        'assets/bg-comppare.jpeg', // ou NetworkImage com sua URL
        fit: BoxFit.cover,
        width: double.infinity,
        height: 600,
      ),
      // Sobreposição com textos e botões
      Positioned.fill(
          child: Column(children: [
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: _buildHeader(context),
        ),
        SizedBox(
          height: 230,
        ),
        Text(
          'Planos exclusivos para Flamenguistas, e muito mais',
          style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                    blurRadius: 4, color: Colors.black45, offset: Offset(2, 2))
              ]),
          textAlign: TextAlign.center,
        ),
        Text(
          '''                                        Planos a partir de R\$ 27,99/mês''',
          style: TextStyle(color: Colors.white, fontSize: 16),
          textAlign: TextAlign.center,
        ),
      ]))
    ]);
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botão "ENTRAR"
          TextButton(
              onPressed: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => LoginScreen()));
              },
              child: _buildActionButton(context, 'ENTRAR', LoginScreen())),
          // Botão "ADM"
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => PrincipalPage()));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: Text('ADM', style: TextStyle(color: Colors.white)),
          )
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

Widget _buildPlanCard(Plano plan, bool isSelected, VoidCallback onSelect,
    VoidCallback onCadastrar, BuildContext context) {
  // Define o tamanho do card de acordo com a largura da tela
  final screenWidth = MediaQuery.of(context).size.width;
  final cardWidth = screenWidth * 0.9; // ocupa 90% da largura da tela

  return Center(
    child: GestureDetector(
      onTap: onSelect,
      child: Container(
        width: cardWidth,
        margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? Colors.green : Colors.grey[300]!,
            width: 2,
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Título do plano
            Text(
              plan.nome,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green[800] : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            // Descrição do plano
            Text(
              plan.descricao,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            // Preço
            Text(
              'Preço: R\$ ${plan.valor.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.green[900] : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            // Botão de seleção
            ElevatedButton(
              onPressed: isSelected ? onCadastrar : onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor: isSelected ? Colors.green : Colors.grey[300],
                foregroundColor: isSelected ? Colors.white : Colors.black,
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isSelected ? 'Selecionado' : 'Selecionar'),
            ),
            SizedBox(height: 12),
            // Botão de assinatura
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CadastroScreen(idPlano: plan.id),
                  ),
                );
              },
              child: Text(
                'Assinar',
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildPlanDetails(dynamic plans, dynamic selectedPlan) {
  if (plans.isEmpty || selectedPlan < 1 || selectedPlan > plans.length) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text('Nenhum plano disponível no momento.'),
    );
  }
  final selectedPlanDetails = plans[selectedPlan - 1];
  return Card(
    color: const Color(0xFF99cc00),
    elevation: 10,
    margin: EdgeInsets.only(
      left: 20,
      right: 20,
    ),
    child: Padding(
      padding: const EdgeInsets.only(top: 30, left: 40, right: 40, bottom: 200),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text(
                    '\$${selectedPlanDetails.valor.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(selectedPlanDetails.descricao),
                  SizedBox(height: 60),
                  Text('Tags: ${selectedPlanDetails.quantidadeTags}'),
                  Text('Fotos: ${selectedPlanDetails.quantidadeFotos}'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '\$${selectedPlanDetails.valor.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(selectedPlanDetails.descricao),
                  SizedBox(height: 60),
                  Text('Tags: ${selectedPlanDetails.quantidadeTags}'),
                  Text('Fotos: ${selectedPlanDetails.quantidadeFotos}'),
                ],
              ),
              Column(
                children: [
                  Text(
                    '\$${selectedPlanDetails.valor.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Text(selectedPlanDetails.descricao),
                  SizedBox(height: 60),
                  Text('Tags: ${selectedPlanDetails.quantidadeTags}'),
                  Text('Fotos: ${selectedPlanDetails.quantidadeFotos}'),
                ],
              )
            ],
          ),
          TextButton(
            onPressed: () {
              // Aqui você pode definir a ação de assinatura
            },
            child: Text(
              'Assinar',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),
    ),
  );
}

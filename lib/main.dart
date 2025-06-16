import 'package:application_progress/albuns_criados.dart';
import 'package:application_progress/cadastro.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/planos.dart';
import 'package:application_progress/principal.dart' hide LoginScreen;
import 'package:application_progress/views/admpage.dart';
import 'package:application_progress/views/comppareimg.dart';
import 'package:application_progress/views/pagamento.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'chat_button.dart';
import 'views/awaiting_payment.dart';

// Placeholder Plano class (replace with your actual Plano class)
class Plano {
  final int id;
  final String nome;
  final String descricao;
  final double valor;
  final int quantidadeTags;
  final int quantidadeFotos;
  final int quantidadeConvites;
  final int quantidadePastas;
  final int status;
  final int frequenciaCobranca;
  final int tempoGratuidade;

  Plano({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.valor,
    required this.quantidadeTags,
    required this.quantidadeFotos,
    required this.quantidadeConvites,
    required this.quantidadePastas,
    required this.status,
    required this.frequenciaCobranca,
    required this.tempoGratuidade,
  });

  factory Plano.fromJson(Map<String, dynamic> json) {
    return Plano(
      id: json['id'] ?? 0,
      nome: json['nome'] ?? '',
      descricao: json['descricao'] ?? '',
      valor: (json['valor'] ?? 0.0).toDouble(),
      quantidadeTags: json['quantidadeTags'] ?? 0,
      quantidadeFotos: json['quantidadeFotos'] ?? 0,
      quantidadeConvites: json['quantidadeConvites'] ?? 0,
      quantidadePastas: json['quantidadePastas'] ?? 0,
      status: json['status'] ?? 1,
      frequenciaCobranca: json['frequenciaCobranca'] ?? 1,
      tempoGratuidade: json['tempoGratuidade'] ?? 1,
    );
  }
}

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit( // Adiciona o ScreenUtilInit para inicializar o flutter_screenutil
      designSize: const Size(360, 690), // Tamanho base do design (ajuste conforme necessário)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          title: 'comppare',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
            useMaterial3: true,
          ),
          initialRoute: Uri.base.path,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case AwaitingPayment.route:
                return MaterialPageRoute(builder: (_) => const AwaitingPayment());
              case CadastroScreen.route:
                return MaterialPageRoute(
                  builder: (_) => CadastroScreen(
                    idPlano: int.tryParse(Uri.base.queryParameters['pId'] ?? ''),
                  ),
                );
              default:
                return MaterialPageRoute(
                  builder: (_) => const MyHomePage(title: ''),
                );
            }
          },
          debugShowCheckedModeBanner: false,
        );
      },
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
  bool isLoading = false;
  int? selectedQuestionIndex;
  List<Plano> plans = [];
  bool showMonthlyPlans = true; // Controla se exibe planos mensais ou anuais
  Map<int, bool> selectedPlans =
      {}; // Mapeia o id do plano para o estado de seleção

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
      final response = await http.get(Uri.parse("https://api.comppare.com.br/api/planos/listar"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> planosJson = data['data'];
        setState(() {
          plans = planosJson.map((json) => Plano.fromJson(json)).toList();
          selectedPlans = {for (var plan in plans) plan.id: false};
        });
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

  Future<void> navigateToCadastro(int idPlano) async {
    setState(() {
      isLoading = true;
    });
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CadastroScreen(idPlano: idPlano),
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

  final List<Map<String, String>> faqs = [
    {
      "question": "Como faço para assinar um plano?",
      "answer": "Para assinar um plano, escolha um dos planos disponíveis e clique no botão 'Assinar'."
    },
    {
      "question": "Quais são os métodos de pagamento aceitos?",
      "answer": "Aceitamos cartões de crédito, débito e PayPal."
    },
    {
      "question": "Posso cancelar minha assinatura?",
      "answer": "Sim, você pode cancelar sua assinatura a qualquer momento através da sua conta."
    },
    {
      "question": "Como posso mudar meu plano?",
      "answer": "Para mudar seu plano, entre em contato com o suporte ao cliente."
    },
  ];

  void selectPlan(int id) {
    setState(() {
      selectedPlans.updateAll((key, value) => false);
      selectedPlans[id] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: const ChatButton(),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(),
            const SizedBox(height: 20),
            _buildPlansSection(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Perguntas Frequentes',
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: faqs.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedQuestionIndex = selectedQuestionIndex == index ? null : index;
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  faqs[index]["question"]!,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (selectedQuestionIndex == index) ...[
                                  const SizedBox(height: 5),
                                  Text(faqs[index]["answer"]!)
                                ]
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Precisa de ajuda? contate-nos ',
                      style: TextStyle(color: Colors.black54),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () {},
                      child: const Text(
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
    return Stack(
      children: [
        Image.asset(
          'assets/bg-comppare.jpeg',
          fit: BoxFit.cover,
          width: double.infinity,
          height: 600,
        ),
        Positioned.fill(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: _buildHeader(context),
              ),
              const SizedBox(height: 230),
              /*const Text(
                '''Quer acompanhar a evolução de clientes e projetos de forma prática e interativa? Aqui é o lugar''',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 4,
                      color: Colors.black45,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),*/
             /* const Text(
                '''                                  Planos a partir de R\$ 27,99/mês''',
                style: TextStyle(color: Colors.white, fontSize: 15),
                textAlign: TextAlign.center,
              ),*/
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: _buildActionButton(context, 'ENTRAR', const LoginScreen()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const PrincipalPage()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('ADM', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    final monthlyPlans = plans
        .where((plan) =>
            plan.nome.toLowerCase().contains('mensal') ||
            plan.nome.toLowerCase().contains('gratuito'))
        .toList();
    final annualPlans = plans
        .where((plan) => plan.nome.toLowerCase().contains('anual'))
        .toList();

    final allMonthlyPlans = _buildMonthlyPlans(monthlyPlans);
    final allAnnualPlans = _buildAnnualPlans(annualPlans);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Nossos Planos',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showMonthlyPlans = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: showMonthlyPlans
                      ? const Color(0xFFaed513)
                      : Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 62, vertical: 20),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(0),
                        bottomRight: Radius.circular(0),
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8)),
                  ),
                ),
                child: const Text('Mensal'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    showMonthlyPlans = false;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: showMonthlyPlans
                      ? Colors.grey[300]
                      : const Color(0xFFaed513),
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 72, vertical: 20),
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                        topLeft: Radius.circular(0),
                        bottomLeft: Radius.circular(0)),
                  ),
                ),
                child: const Text('Anual'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : showMonthlyPlans
                  ? (allMonthlyPlans.isNotEmpty
                      ? Column(children: allMonthlyPlans)
                      : const Center(child: Text('Nenhum plano mensal disponível')))
                  : (allAnnualPlans.isNotEmpty
                      ? Column(children: allAnnualPlans)
                      : const Center(child: Text('Nenhum plano anual disponível'))),
        ],
      ),
    );
  }

  List<Widget> _buildMonthlyPlans(List<Plano> monthlyPlans) {
    // Initialize list to hold plan cards
    List<Widget> planCards = [];

    // Try to find the "Gratuito" plan
    final gratuito = monthlyPlans.firstWhere(
      (plan) => plan.nome.toLowerCase().contains('gratuito'),
      orElse: () => Plano(
        id: 0,
        nome: 'Gratuito',
        descricao: 'Plano gratuito com funcionalidades básicas',
        valor: 0.0,
        quantidadeTags: 0,
        quantidadeFotos: 0,
        quantidadeConvites: 1,
        quantidadePastas: 1,
        status: 1,
        frequenciaCobranca: 1,
        tempoGratuidade: 1,
      ),
    );

    // Try to find the "Básico Mensal" plan
    final basico = monthlyPlans.firstWhere(
      (plan) =>
          plan.nome.toLowerCase().contains('básico') &&
          !plan.nome.toLowerCase().contains('anual'),
      orElse: () => Plano(
        id: 1,
        nome: 'Básico Mensal',
        descricao: 'Plano básico mensal com acesso a mais funcionalidades',
        valor: 24.90,
        quantidadeTags: 5,
        quantidadeFotos: 50,
        quantidadeConvites: 1,
        quantidadePastas: 1,
        status: 1,
        frequenciaCobranca: 1,
        tempoGratuidade: 1,
      ),
    );

    // Try to find the "Avançado Mensal" plan
    final avancado = monthlyPlans.firstWhere(
      (plan) =>
          plan.nome.toLowerCase().contains('avançado') &&
          !plan.nome.toLowerCase().contains('anual'),
      orElse: () => Plano(
        id: 2,
        nome: 'Avançado Mensal',
        descricao: 'Plano avançado mensal com todos os recursos',
        valor: 39.90,
        quantidadeTags: 10,
        quantidadeFotos: 100,
        quantidadeConvites: 1,
        quantidadePastas: 1,
        status: 1,
        frequenciaCobranca: 1,
        tempoGratuidade: 1,
      ),
    );

    // Add plans to selectedPlans if not already present
    if (!selectedPlans.containsKey(gratuito.id)) {
      selectedPlans[gratuito.id] = false;
    }
    if (!selectedPlans.containsKey(basico.id)) {
      selectedPlans[basico.id] = false;
    }
    if (!selectedPlans.containsKey(avancado.id)) {
      selectedPlans[avancado.id] = false;
    }

    // Add plan cards only for plans that were found or have valid fallbacks
    planCards.add(
      _buildPlanCard(
        gratuito,
        selectedPlans[gratuito.id] ?? false,
        () => selectPlan(gratuito.id),
        () => navigateToCadastro(gratuito.id),
        context,
        isPopular: false,
      ),
    );
    planCards.add(
      _buildPlanCard(
        basico,
        selectedPlans[basico.id] ?? false,
        () => selectPlan(basico.id),
        () => navigateToCadastro(basico.id),
        context,
        isPopular: false,
      ),
    );
    planCards.add(
      _buildPlanCard(
        avancado,
        selectedPlans[avancado.id] ?? false,
        () => selectPlan(avancado.id),
        () => navigateToCadastro(avancado.id),
        context,
        isPopular: true,
      ),
    );

    return planCards;
  }

  List<Widget> _buildAnnualPlans(List<Plano> annualPlans) {
    // Initialize list to hold plan cards
    List<Widget> planCards = [];

    // Try to find the "Básico Anual" plan
    final basicoAnual = annualPlans.firstWhere(
      (plan) => plan.nome.toLowerCase().contains('básico'),
      orElse: () => Plano(
        id: 3,
        nome: 'Básico Anual',
        descricao: 'Plano básico anual com economia',
        valor: 299.99,
        quantidadeTags: 5,
        quantidadeFotos: 50,
        quantidadeConvites: 1,
        quantidadePastas: 1,
        status: 1,
        frequenciaCobranca: 1,
        tempoGratuidade: 1,
      ),
    );

    // Try to find the "Avançado Anual" plan
    final avancadoAnual = annualPlans.firstWhere(
      (plan) => plan.nome.toLowerCase().contains('avançado'),
      orElse: () => Plano(
        id: 4,
        nome: 'Avançado Anual',
        descricao: 'Plano avançado anual com todos os recursos',
        valor: 499.99,
        quantidadeTags: 10,
        quantidadeFotos: 100,
        quantidadeConvites: 1,
        quantidadePastas: 1,
        status: 1,
        frequenciaCobranca: 1,
        tempoGratuidade: 1,
      ),
    );

    // Add plans to selectedPlans if not already present
    if (!selectedPlans.containsKey(basicoAnual.id)) {
      selectedPlans[basicoAnual.id] = false;
    }
    if (!selectedPlans.containsKey(avancadoAnual.id)) {
      selectedPlans[avancadoAnual.id] = false;
    }

    // Add plan cards only for plans that were found or have valid fallbacks
    planCards.add(
      _buildPlanCard(
        basicoAnual,
        selectedPlans[basicoAnual.id] ?? false,
        () => selectPlan(basicoAnual.id),
        () => navigateToCadastro(basicoAnual.id),
        context,
        isPopular: false,
      ),
    );
    planCards.add(
      _buildPlanCard(
        avancadoAnual,
        selectedPlans[avancadoAnual.id] ?? false,
        () => selectPlan(avancadoAnual.id),
        () => navigateToCadastro(avancadoAnual.id),
        context,
        isPopular: true,
      ),
    );

    return planCards;
  }

  Widget _buildPlanCard(
    Plano plan,
    bool isSelected,
    VoidCallback onSelect,
    VoidCallback onCadastrar,
    BuildContext context, {
    bool isPopular = false,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = screenWidth * 0.7;

    return Center(
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[50] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: isSelected ? const Color(0xFFaed513) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isPopular)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFaed513),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Mais Popular',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            if (isPopular) const SizedBox(height: 12),
            Text(
              plan.nome,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFaed513) : Colors.black87,
              ),
              textAlign: TextAlign.center,

            ),
            const SizedBox(height: 12),
            Text(
              plan.descricao,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'R\$ ${plan.valor.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSelected ? const Color(0xFFaed513) : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tags: ${plan.quantidadeTags}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Fotos: ${plan.quantidadeFotos}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Convites: ${plan.quantidadeConvites}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Pastas: ${plan.quantidadePastas}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Status: ${plan.status == 1 ? 'Ativo' : 'Inativo'}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Frequência: ${plan.frequenciaCobranca} mês(es)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              'Gratuidade: ${plan.tempoGratuidade} mês(es)',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onSelect,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isSelected ? const Color(0xFFaed513) : Colors.grey[300],
                foregroundColor: isSelected ? Colors.black : Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(isSelected ? 'Selecionado' : 'Selecionar'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onCadastrar,
              child: const Text(
                'Assinar',
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
            ),
          ],
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
          MaterialPageRoute(builder: (context) => targetPage),
        );
      },
      style: ElevatedButton.styleFrom(
        foregroundColor: const Color.fromARGB(255, 251, 255, 250),
        backgroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
        textStyle: const TextStyle(fontSize: 16),
      ),
      child: Text(label),
    );
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Erro"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fechar"),
          ),
        ],
      ),
    );
  }
}
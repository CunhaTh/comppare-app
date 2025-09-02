import 'package:application_progress/cadastro.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/principal.dart' hide LoginScreen;
import 'package:application_progress/views/SplashScreen.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'chat_button.dart';
import 'infra/api_endponts.dart';
import 'models/plan_model.dart';
import 'views/awaiting_payment.dart';

// Placeholder Plano class (replace with your actual Plano class)

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  await GetStorage.init();
  debugPrint(
      'GetStorage inicializado e TokenHelper pronto.'); // <--- Adicione este
  debugPrint(
      'Token na inicialização do app: ${TokenHelper().token}'); // <--- E este
  debugPrint('User ID na inicialização do app: ${TokenHelper().userId}');
  await TokenHelper().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // Adiciona o ScreenUtilInit para inicializar o flutter_screenutil
      designSize: const Size(
          360, 690), // Tamanho base do design (ajuste conforme necessário)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'comppare',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
            useMaterial3: true,
          ),
          initialRoute: Uri.base.path,
          onGenerateRoute: (settings) {
            switch (settings.name) {
              case AwaitingPayment.route:
                return MaterialPageRoute(
                    builder: (_) => const AwaitingPayment());
              case CadastroScreen.route:
                return MaterialPageRoute(
                  builder: (_) => CadastroScreen(
                    plan: PlanModel.empty(),
                  ),
                );
              default:
                return MaterialPageRoute(builder: (_) => const SplashScreen()
                    //PrincipalPage()
                    // const AuthWrapper(),
                    //Urlimg()
                    // const MyHomePage(title: ''),
                    //const Pagemconstrucao()
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
  List<PlanModel> plans = [];
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
      final response =
          await http.get(Uri.parse("${ApiEndpoints.baseUrl}/planos/listar"));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> planosJson = data['data'];
        setState(() {
          plans = planosJson.map((json) => PlanModel.fromJson(json)).toList();
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

  Future<void> navigateToCadastro(PlanModel plan) async {
    setState(() {
      isLoading = true;
    });
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CadastroScreen(plan: plan),
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
            _featuresTitle(isLoading),
            _buildPlansSection(),            
            const SizedBox(height: 40),
            // Texto e Botão abaixo
            _buildTextContent(context, isMobile: true),
            const SizedBox(height: 40),
            _buildCommentsOne(context),
            const SizedBox(height: 40),
            _buildCommentstwo(context),
            const SizedBox(height: 40),
            _buildCommentstree(context),
            const SizedBox(height: 40),
            _buildCommentsfor(context),
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
                            selectedQuestionIndex =
                                selectedQuestionIndex == index ? null : index;
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
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
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
    return Container(
      width: double.infinity,
      color: Colors.grey[50], // Cor de fundo suave
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildHeader(),
          const SizedBox(height: 80),
          const Text(
            'Comppare imagens de forma interativa e inteligente',
            style: TextStyle(
              fontSize: 35,
              fontWeight: FontWeight.bold,
              height: 1.1,
              color: Color(0xFF222222),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Transforme a maneira como você acompanha a evolução dos seus projetos e resultados com a plataforma visual mais avançada do mercado.',
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // 1. Define o PlanModel para o plano gratuito.
                // Isso garante que mesmo que a lista de planos não esteja disponível,
                // o botão ainda possa passar um plano válido.
                final gratuito = PlanModel(
                  id: 1,
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
                );

                // 2. Chama a função de navegação passando o modelo do plano gratuito.
                navigateToCadastro(gratuito);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFaed513),
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Crie sua conta grátis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Image.asset('assets/logo_cortada.png',
                  height: 40), // Adicione sua logo aqui
              const SizedBox(width: 8),
            ],
          ),
          SizedBox(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFaed513),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Entrar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
                      : const Center(
                          child: Text('Nenhum plano mensal disponível')))
                  : (allAnnualPlans.isNotEmpty
                      ? Column(children: allAnnualPlans)
                      : const Center(
                          child: Text('Nenhum plano anual disponível'))),
        ],
      ),
    );
  }

  List<Widget> _buildMonthlyPlans(List<PlanModel> monthlyPlans) {
    // Initialize list to hold plan cards
    List<Widget> planCards = [];

    // Try to find the "Gratuito" plan
    final gratuito = monthlyPlans.firstWhere(
      (plan) => plan.nome.toLowerCase().contains('gratuito'),
      orElse: () => PlanModel(
        id: 1,
        nome: 'Gratuito',
        descricao: 'Plano gratuito com funcionalidades básicas',
        valor: 0.0,
        quantidadeTags: 2,
        quantidadeFotos: 10,
        quantidadeConvites: 1,
        quantidadePastas: 2,
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
      orElse: () => PlanModel(
        id: 3,
        nome: 'Avançado Mensal',
        descricao: 'Plano Avançado mensal com acesso a mais funcionalidades',
        valor: 29.90,
        quantidadeTags: 5,
        quantidadeFotos: 50,
        quantidadeConvites: 1,
        quantidadePastas: 1,
        status: 1,
        frequenciaCobranca: 1,
        tempoGratuidade: 1,
      ),
    );

    // Add plan cards only for plans that were found or have valid fallbacks
    planCards.add(
      _buildPlanCard(
        gratuito,
        selectedPlans[gratuito.id] ?? false,
        () => selectPlan(gratuito.id),
        () => navigateToCadastro(gratuito),
        context,
        isPopular: false,
      ),
    );
    planCards.add(
      _buildPlanCard(
        basico,
        selectedPlans[basico.id] ?? false,
        () => selectPlan(basico.id),
        () => navigateToCadastro(basico),
        context,
        isPopular: false,
      ),
    );

    return planCards;
  }

  List<Widget> _buildAnnualPlans(List<PlanModel> annualPlans) {
    // Initialize list to hold plan cards
    List<Widget> planCards = [];

    // Try to find the "Avançado Anual" plan
    final avancadoAnual = annualPlans.firstWhere(
      (plan) => plan.nome.toLowerCase().contains('avançado'),
      orElse: () => PlanModel(
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
    if (!selectedPlans.containsKey(avancadoAnual.id)) {
      selectedPlans[avancadoAnual.id] = false;
    }

    // Add plan cards only for plans that were found or have valid fallbacks
    planCards.add(
      _buildPlanCard(
        avancadoAnual,
        selectedPlans[avancadoAnual.id] ?? false,
        () => selectPlan(avancadoAnual.id),
        () => navigateToCadastro(avancadoAnual),
        context,
        isPopular: true,
      ),
    );

    return planCards;
  }

// Refatoração sugerida para o widget _buildPlanCard
  Widget _buildPlanCard(
    PlanModel plan,
    bool isSelected,
    VoidCallback onSelect,
    VoidCallback onCadastrar,
    BuildContext context, {
    bool isPopular = false,
  }) {
    return GestureDetector(
      onTap:
          onSelect, // Permite que o usuário toque em qualquer lugar do cartão para selecionar
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? const Color(0xFFaed513) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isPopular) // Destaque para o plano mais popular
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFaed513),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              const SizedBox(height: 8),
              Text(
                'R\$ ${plan.valor.toStringAsFixed(2)}/${plan.frequenciaCobranca == 1 ? 'mês' : 'ano'}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFaed513),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Utilize uma lista de widgets para os recursos
              _buildFeatureRow('Álbuns', plan.quantidadePastas.toString()),
              _buildFeatureRow(
                  'Subálbuns por álbum', plan.quantidadeTags.toString()),
              _buildFeatureRow('Categorias', plan.quantidadeTags.toString()),
              _buildFeatureRow('Sem anúncios', 'Sim'),
              _buildFeatureRow('Compartilhamento em redes sociais', 'Sim'),
              // Adicione os demais recursos

              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: onCadastrar,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isSelected ? const Color(0xFFaed513) : Colors.grey[300],
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Assinar Agora',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
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

// Widget auxiliar para as linhas de recursos
  Widget _buildFeatureRow(String feature, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(Icons.check, color: const Color(0xFFaed513)),
          const SizedBox(width: 8),
          Text(
            '$feature: $value',
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  /// Constrói o conteúdo de texto (título, parágrafo).
  /// É reutilizável para ambos os layouts.
  Widget _buildTextContent(BuildContext context, {required bool isMobile}) {
    final headlineStyle = TextStyle(
      // O `Theme.of(context)` permite que você use fontes definidas no seu app.
      fontFamily: Theme.of(context).textTheme.headlineMedium!.fontFamily,
      fontSize: isMobile ? 28 : 38, // Fonte menor no mobile
      fontWeight: FontWeight.bold,
      color: Colors.black87,
      height: 1.2,
    );

    final paragraphStyle = TextStyle(
      fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
      fontSize: isMobile ? 16 : 18,
      color: Colors.black54,
      height: 1.5,
    );

    return Column(
      crossAxisAlignment:
          isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 30),
         //box Texto principal
        Container(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
            SizedBox(height: 33,),
                    Text(
                '''Principais
Funcionalidades''',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: 30,fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,),
              ),
              SizedBox(height: 10),
                        // Linha Decorativa com Gradiente
          Container(
            height: 4,
            width: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 108, 127, 1),Color(0xFFaed513), Color(0xFF9bc412)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
              const SizedBox(height: 24),
              Text(
                'Nossa plataforma reúne recursos tecnológicos projetados para maximizar sua produtividade e encantar seus clientes.',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: paragraphStyle,
              ),
            ],
          )
        ),
        const SizedBox(height: 30),
        //box 1
        Container(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
              Icon(
              // Este ícone é visualmente similar ao do print
              Icons.photo_library_outlined,
              size: 80, // Tamanho grande para destaque
              color: const Color(0xFFaed513), // Cor da marca
            ),
            SizedBox(height: 20,),
                    Text(
                'Comparação de Imagens',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: headlineStyle,
              ),
              const SizedBox(height: 24),
              Text(
                'Controle, compare e visualize sua evolução de forma inteligente. A ferramenta definitiva para acompanhar seu progresso com precisão e alcançar seus objetivos.',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: paragraphStyle,
              ),
            ],
          )
        ),
        const SizedBox(height: 30),
        //box 2
        Container(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
              Icon(
              // Este ícone é visualmente similar ao do print
              Icons.local_offer_outlined,
              size: 80, // Tamanho grande para destaque
              color: const Color(0xFFaed513), // Cor da marca
            ),
            SizedBox(height: 20,),
                    Text(
                'Tags Personalizadas',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: headlineStyle,
              ),
              const SizedBox(height: 24),
              Text(
                'Crie  marcações especificas e anotações nas imagens para mostrar detalhes importantes.',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: paragraphStyle,
              ),
            ],
          )
        ),
        const SizedBox(height: 30),
         //box 3
        Container(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
        decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
              Icon(
              // Este ícone é visualmente similar ao do print
              Icons.emoji_events_outlined,
              size: 80, // Tamanho grande para destaque
              color: const Color(0xFFaed513), // Cor da marca
            ),
            SizedBox(height: 20,),
                    Text(
                'Gamificação',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: headlineStyle,
              ),
              const SizedBox(height: 24),
              Text(
                'Engaje seus clientes com elementos de gamificação que incentivam o acompanhamento continuo',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: paragraphStyle,
              ),
            ],
          )
        ),
        const SizedBox(height: 30),

        Container(
        padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 40),
      child: Column(
        children: [
            SizedBox(height: 33,),
                    Text(
                '''O que dizem nossos 
Usuários''',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: 30,fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  height: 1.2,),
              ),
              SizedBox(height: 10),
                        // Linha Decorativa com Gradiente
          Container(
            height: 4,
            width: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 108, 127, 1),Color(0xFFaed513), Color(0xFF9bc412)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
              const SizedBox(height: 24),
              Text(
                '''Veja como a Comppare está
  transformando o dia dia de
  profissionais como você.''',
                textAlign: isMobile ? TextAlign.center : TextAlign.start,
                style: paragraphStyle,
              ),
            ],
          )
        ),
      ],
    );
  }
    // texto antes dos planos
    Widget  _featuresTitle ( bool isMobile ) {
      final paragraphStyle = TextStyle(
      fontFamily: Theme.of(context).textTheme.bodySmall?.fontFamily,
      fontSize: isMobile ? 16 : 18,
      color: Colors.black54,
      height: 1.5,
    );
    return Container(
              decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        
        children: [
          // Título Principal
          const Text(
            '''Planos para todos os
Perfis   ''',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Linha Decorativa com Gradiente
          Container(
            height: 4,
            width: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color.fromARGB(255, 108, 127, 1),Color(0xFFaed513), Color(0xFF9bc412)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          // Subtítulo/Parágrafo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child:               Text(
                  'Escolhe o plano ideal para o seu negócio e comece a transformar sua comunicação visual.',
                  textAlign: isMobile ? TextAlign.center : TextAlign.start,
                  style: paragraphStyle,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsOne(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Avaliação por Estrelas
          _buildRatingStars(),
          const SizedBox(height: 16),

          // 2. Texto do Depoimento (Citação)
          Text(
            '" A Comppare transformou o acompanhamento do meu pacientes"',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
               // Avatar circular com a inicial do autor
              // 4° comentário 
              const  Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFaed513), // Cor da marca
                child: Text(
                  'T',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Coluna com Nome e Cargo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Thiago Gomes",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Plano Avançado",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildCommentstwo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Avaliação por Estrelas
          _buildRatingStars(),
          const SizedBox(height: 16),

          // 2. Texto do Depoimento (Citação)
          Text(
            '" A Comppare transformou o acompanhamento do meu pacientes"',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
               // Avatar circular com a inicial do autor
              // 4° comentário 
              const  Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFaed513), // Cor da marca
                child: Text(
                  'B',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Coluna com Nome e Cargo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Bruno Silva",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Plano Avançado",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildCommentstree(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Avaliação por Estrelas
          _buildRatingStars(),
          const SizedBox(height: 16),

          // 2. Texto do Depoimento (Citação)
          Text(
            '" A Comppare transformou o acompanhamento do meu pacientes"',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
               // Avatar circular com a inicial do autor
              // 4° comentário 
              const  Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFaed513), // Cor da marca
                child: Text(
                  'L',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Coluna com Nome e Cargo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Larissa Conde",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Plano Avançado",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    Widget _buildCommentsfor(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Avaliação por Estrelas
          _buildRatingStars(),
          const SizedBox(height: 16),

          // 2. Texto do Depoimento (Citação)
          Text(
            '" A Comppare transformou o acompanhamento do meu pacientes"',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black54,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 24),
               // Avatar circular com a inicial do autor
              // 4° comentário 
              const  Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFFaed513), // Cor da marca
                child: Text(
                  'C',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Coluna com Nome e Cargo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Claudia Medeiros",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Plano Avançado",
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

    /// Constrói a linha de estrelas de avaliação.
  Widget _buildRatingStars() {
    return Row(
      children: List.generate(
        5,
        (index) => const Icon(
          Icons.star,
          color: Colors.amber,
          size: 20,
        ),
      ),
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

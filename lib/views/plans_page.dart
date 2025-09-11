import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/views/awaiting_payment.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../controllers/controller.dart';

import '../infra/api_services.dart';
import '../models/models.dart';
import 'pagamento_page.dart';

class SubscriptionPage extends StatefulWidget {
  final PlanModel initialPlan;
  final List<PlanModel>?
      availablePlans; // Lista opcional de planos para escolha

  const SubscriptionPage(
      {super.key, required this.initialPlan, this.availablePlans});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage>
    with TickerProviderStateMixin {
  bool loading = false;
  late PlanModel selectedPlan; // Plano selecionado pelo usuário
  late PageController _pageController;
  int _currentPageIndex = 0;

  late PlansController controller;
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Inicializa com o plano passado ou o primeiro da lista, se disponível
    controller = PlansController(apiService: ApiService());

    selectedPlan = widget.availablePlans?.isNotEmpty == true
        ? widget.availablePlans!.first
        : widget.initialPlan;

    _pageController = PageController(viewportFraction: 0.9);

    // Configuração das animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    setState(() => loading = true);
    final userId = UserHelper().user?.id;
    if (userId != null) {
      final url = Uri.parse(
          'https://dev.comppare.com.br/payment.php?pid=${selectedPlan.id}&uid=$userId');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AwaitingPayment()),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog('Não foi possível iniciar o pagamento.');
        }
      }
    } else {
      if (mounted) {
        _showErrorDialog('Usuário não autenticado.');
      }
    }
    setState(() => loading = false);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final plans = widget.availablePlans ?? [widget.initialPlan];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Escolha seu Plano',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header com título
              FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  'Planos Disponíveis',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Escolha o plano ideal para suas necessidades',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Carrossel de planos com navegação
              Stack(
                children: [
                  SizedBox(
                    height: 500,
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: plans.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPageIndex = index;
                          selectedPlan = plans[index];
                        });
                      },
                      itemBuilder: (context, index) {
                        final plan = plans[index];
                        final isSelected = plan.id == selectedPlan.id;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedPlan = plan;
                            });
                          },
                          child: Center(
                            child: PlanCard(
                              plan: plan,
                              isSelected: isSelected,
                              onSubscribe: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PagamentoPage(
                                      plano: plan,
                                    ),
                                  ),
                                );
                              },
                              loading: loading,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Botão anterior (esquerda)
                  if (_currentPageIndex > 0)
                    Positioned(
                      left: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xFFaed513),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Botão próximo (direita)
                  if (_currentPageIndex < plans.length - 1)
                    Positioned(
                      right: 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward_ios,
                              color: Color(0xFFaed513),
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Indicadores de página
              Container(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    plans.length,
                    (index) => Container(
                      width: 8.w,
                      height: 8.h,
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: plans[index].id == selectedPlan.id
                            ? const Color(0xFFaed513)
                            : Colors.grey[300],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanCard extends StatelessWidget {
  final PlanModel plan;
  final bool isSelected;
  final VoidCallback onSubscribe;
  final bool loading;

  const PlanCard({
    super.key,
    required this.plan,
    required this.isSelected,
    required this.onSubscribe,
    required this.loading,
  });

  // Cores baseadas no tipo de plano
  Color _getPlanColor() {
    switch (plan.nome.toLowerCase()) {
      case 'básico':
      case 'individual':
        return const Color(0xFFFF9500); // Laranja
      case 'premium':
      case 'familiar':
        return const Color(0xFFFF3B30); // Vermelho
      case 'pro':
      case 'enterprise':
        return const Color(0xFFAF52DE); // Roxo
      default:
        return const Color(0xFFaed513); // Verde padrão
    }
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getPlanColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getPlanColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _getPlanColor(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey[50]!,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? _getPlanColor().withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isSelected ? _getPlanColor() : Colors.grey[200]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header do plano com gradiente
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _getPlanColor().withValues(alpha: 0.1),
                  _getPlanColor().withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Título do plano
                Text(
                  plan.nome,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Preço com destaque
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _getPlanColor(),
                      ),
                    ),
                    const SizedBox(width: 4),
                                    Text(
                                      plan.valor.toStringAsFixed(2).replaceAll('.', ','),
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: _getPlanColor(),
                                        height: 1.0,
                                      ),
                                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        // Adicione a verificação aqui
                        plan.nome.toLowerCase().contains('anual') ? '/ano' : '/mês',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Conteúdo do plano
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24).copyWith(top: 0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Descrição
                  Text(
                    plan.descricao,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Recursos do plano
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      // _buildFeatureChip('📸 ${plan.quantidadeFotos} Fotos'),
                      _buildFeatureChip(
                          '🏷️ ${plan.quantidadeTags} Categorias'),
                      _buildFeatureChip('📁 ${plan.quantidadePastas} Álbum'/*+ (plan.nome.toLowerCase().contains('gratuito') ? 'Álbum' : 'Álbuns'),*/),

                      ///Todo(Thiago): Verificar plan.quantidadeConvites que está dando erro
                      // _buildFeatureChip(
                      //     '📂 ${plan.quantidadeSubPastas} Subálbuns'),
                      //_buildFeatureChip(
                      //  '👥 ${plan.quantidadeConvites} Convites'),
                      if (plan.frequenciaCobranca > 0) ...[
                        _buildFeatureChip('🏆 Ranking'),
                        _buildFeatureChip('🚫 Sem anúncios'),
                      ],
                      if (plan.frequenciaCobranca == 0)
                        _buildFeatureChip('📢 Com anúncios'),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Botão de assinatura
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : onSubscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getPlanColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor: _getPlanColor().withValues(alpha: 0.3),
                      ),
                      child: loading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Processando...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Assinar Agora',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/main.dart';
import 'package:application_progress/views/awaiting_payment.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SubscriptionPage extends StatefulWidget {
  final Plano initialPlan;
  final List<Plano>? availablePlans; // Lista opcional de planos para escolha

  const SubscriptionPage(
      {super.key, required this.initialPlan, this.availablePlans});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool loading = false;
  late Plano selectedPlan; // Plano selecionado pelo usuário
  late PageController _pageController;
  int _currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    // Inicializa com o plano passado ou o primeiro da lista, se disponível
    selectedPlan = widget.availablePlans?.isNotEmpty == true
        ? widget.availablePlans!.first
        : widget.initialPlan;

    _pageController = PageController(viewportFraction: 0.9);
  }

  @override
  void dispose() {
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
      backgroundColor: const Color(0xFFF5F5F7), // Fundo cinza claro como Apple
      appBar: AppBar(
        title: Text(
          'Escolha seu Plano',
          style: TextStyle(
            fontSize: 28.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Header com título e subtítulo
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                child: Column(
                  children: [
                    Text(
                      'Comppare Premium',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      'Acesse todos os recursos premium',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Carrossel de planos com botões de navegação
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
                              onSubscribe: _subscribe,
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
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                              color: Colors.black87,
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
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
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
                              color: Colors.black87,
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
                      width: 6.w,
                      height: 6.h,
                      margin: EdgeInsets.symmetric(horizontal: 3.w),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: plans[index].id == selectedPlan.id
                            ? const Color(0xFF007AFF)
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
  final Plano plan;
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

  @override
  Widget build(BuildContext context) {
    // Cores baseadas no tipo de plano (inspirado na Apple One)
    Color getPlanColor() {
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
          return const Color(0xFF007AFF); // Azul padrão
      }
    }

    return Container(
      width: 400,
      height: 500,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? getPlanColor().withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isSelected ? getPlanColor() : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header do plano
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: getPlanColor().withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Título do plano
                Text(
                  plan.nome,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),

                // Preço
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: getPlanColor(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plan.valor.toStringAsFixed(2).replaceAll('.', ','),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: getPlanColor(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '/mês',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Descrição
                  Text(
                    plan.descricao,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  // Recursos do plano
                  Wrap(
                    children: [
                      _buildFeature('📸 ${plan.quantidadeFotos} fotos',
                          Icons.photo_library),
                      _buildFeature(
                          '🏷️ ${plan.quantidadeTags} tags', Icons.label),
                      _buildFeature(
                          '📁 ${plan.quantidadePastas} pastas', Icons.folder),
                      _buildFeature('👥 ${plan.quantidadeConvites} convites',
                          Icons.people),
                    ],
                  ),
                  const Spacer(),

                  // Botão de assinatura
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : onSubscribe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: getPlanColor(),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Assinar Agora',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
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

  Widget _buildFeature(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.grey,
        ),
      ),
    );
  }
}

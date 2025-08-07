import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../controllers/controller.dart';
import '../helpers/helpers.dart';
import '../infra/api_services.dart';
import '../models/models.dart';
import '../principal.dart';
import '../services/efipay_service.dart';

// Formatter para data de validade do cartão
class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Remove todos os caracteres não numéricos
    String text = newValue.text.replaceAll(RegExp(r'[^\d]'), '');

    // Limita a 4 dígitos
    if (text.length > 4) {
      text = text.substring(0, 4);
    }

    // Aplica a máscara MM/AAAA
    if (text.length >= 2) {
      text = '${text.substring(0, 2)}/${text.substring(2)}';
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

class PagamentoPage extends StatefulWidget {
  final PlanModel plano;

  const PagamentoPage({super.key, required this.plano});

  @override
  _PagamentoPageState createState() => _PagamentoPageState();
}

class _PagamentoPageState extends State<PagamentoPage>
    with TickerProviderStateMixin {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _holderDocument = TextEditingController();

  String? _qrCodeData;
  bool _isProcessingPayment = false;
  bool _showQrCode = false;

  late PaymentController paymentController;
  late AnimationController _animationController;
  late AnimationController _fadeController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    paymentController = PaymentController(
        apiService: ApiService(), efipayService: EfipayService());

    paymentController.setPlan(widget.plano ?? PlanModel.empty());

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
    super.dispose();
  }

  // Cores baseadas no tipo de plano
  Color _getPlanColor() {
    switch (widget.plano.nome.toLowerCase()) {
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

  Widget _buildPlanSummaryCard() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
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
                color: _getPlanColor().withValues(alpha: 0.15),
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
              color: _getPlanColor().withValues(alpha: 0.2),
              width: 1.5,
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
                      widget.plano.nome,
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
                          widget.plano.valor
                              .toStringAsFixed(2)
                              .replaceAll('.', ','),
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
                          child: const Text(
                            '/mês',
                            style: TextStyle(
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

              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildFeatureChip('📸 ${widget.plano.quantidadeFotos} fotos'),
                  _buildFeatureChip('🏷️ ${widget.plano.quantidadeTags} tags'),
                  _buildFeatureChip(
                      '📁 ${widget.plano.quantidadePastas} pastas'),
                  _buildFeatureChip(
                      '👥 ${widget.plano.quantidadeConvites} convites'),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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

  Widget _buildPaymentMethodSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        )),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Colors.grey[200]!,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Header da seção
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFaed513).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.payment,
                        color: Color(0xFFaed513),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Método de Pagamento',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),

              // Opções de pagamento
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Cartão de Crédito
                    _buildPaymentOption(
                      icon: Icons.credit_card,
                      title: 'Cartão de Crédito',
                      subtitle: 'Pague com segurança',
                      isSelected: paymentController.state.paymentType ==
                          EnumPaymentType.creditCard,
                      onTap: () {
                        setState(() {
                          paymentController
                              .setPaymentType(EnumPaymentType.creditCard);
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // PIX
                    _buildPaymentOption(
                      icon: Icons.qr_code,
                      title: 'PIX',
                      subtitle: 'Pagamento instantâneo',
                      isSelected: paymentController.state.paymentType ==
                          EnumPaymentType.pix,
                      onTap: () {
                        setState(() {
                          paymentController.setPaymentType(EnumPaymentType.pix);
                        });
                      },
                    ),

                    // Campos do cartão de crédito
                    if (paymentController.state.paymentType ==
                        EnumPaymentType.creditCard) ...[
                      const SizedBox(height: 24),
                      _buildCreditCardForm(),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFaed513).withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFFaed513) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? const Color(0xFFaed513) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : Colors.grey[600],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? const Color(0xFFaed513)
                              : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected
                              ? const Color(0xFFaed513).withValues(alpha: 0.8)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFaed513),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreditCardForm() {
    return Column(
      children: [
        // Número do cartão
        _buildTextField(
          controller: _cardNumberController,
          label: 'Número do Cartão',
          hint: '0000 0000 0000 0000',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),

        // Nome do titular
        _buildTextField(
          controller: _cardHolderController,
          label: 'Nome do Titular',
          hint: 'Como está no cartão',
          icon: Icons.person,
        ),
        const SizedBox(height: 16),

        // Linha com data de validade, CVV e CPF
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _expiryDateController,
                label: 'Validade',
                hint: 'MM/AAAA',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
                inputFormatters: [ExpiryDateFormatter()],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _cvvController,
                label: 'CVV',
                hint: '123',
                icon: Icons.security,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildTextField(
                controller: _holderDocument,
                label: 'CPF',
                hint: '000.000.000-00',
                icon: Icons.badge,
                keyboardType: TextInputType.number,
                inputFormatters: [CpfInputFormatter()],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: Colors.grey[600],
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          labelStyle: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
          hintStyle: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildQrCodeSection() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: Colors.grey[200]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFaed513).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.qr_code_scanner,
                color: Color(0xFFaed513),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Escaneie o QR Code para pagar',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'R\$ ${widget.plano.valor.toStringAsFixed(2).replaceAll('.', ',')}',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getPlanColor(),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: QrImageView(
                data: _qrCodeData!,
                version: QrVersions.auto,
                size: 200,
                backgroundColor: Colors.white,
                gapless: true,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Código PIX: $_qrCodeData',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: const Color(0xFFaed513),
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          shadowColor: const Color(0xFFaed513).withValues(alpha: 0.3),
        ),
        onPressed: _isProcessingPayment
            ? null
            : () async {
                if (_qrCodeData == null) {
                  setState(() {
                    _isProcessingPayment = true;
                  });

                  final response = await paymentController.switchPaymentType(
                    number: _cardNumberController.text,
                    cvv: _cvvController.text,
                    expirationMonth: _expiryDateController.text.split('/')[0],
                    expirationYear: _expiryDateController.text.split('/')[1],
                    holderName: _cardHolderController.text,
                    holderDocument: _holderDocument.text,
                  );

                  log('RETORNO DO PAGAMENTO NA PAGE: ${response.toMap()}');
                  log('paymentController.state.paymentType: ${paymentController.state.paymentType.name}');

                  if (response.success &&
                      paymentController.state.paymentType ==
                          EnumPaymentType.creditCard) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PrincipalPage(),
                      ),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Pagamento via cartão de crédito efetuado com sucesso!'),
                        backgroundColor: Color(0xFFaed513),
                      ),
                    );
                  } else if (response.success &&
                      paymentController.state.paymentType ==
                          EnumPaymentType.pix) {
                    setState(() {
                      _qrCodeData = response.data;
                      _showQrCode = true;
                    });
                  }
                  setState(() {
                    _isProcessingPayment = false;
                  });
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrincipalPage(),
                    ),
                  );
                }
              },
        child: _isProcessingPayment
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Processando pagamento...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              )
            : _qrCodeData == null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.payment,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Finalizar Compra - R\$ ${widget.plano.valor.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ir para a tela principal',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pagamento',
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
                  'Resumo do Pedido',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 24),

              // Card do plano selecionado
              _buildPlanSummaryCard(),
              const SizedBox(height: 24),

              // Seção de método de pagamento ou QR Code
              if (!_showQrCode) ...[
                _buildPaymentMethodSection(),
              ] else ...[
                _buildQrCodeSection(),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: _buildActionButton(),
      ),
    );
  }
}

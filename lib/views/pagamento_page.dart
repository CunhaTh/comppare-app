import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../controllers/controller.dart';
import '../helpers/helpers.dart';
import '../infra/api_services.dart';
import '../models/models.dart';
import '../principal.dart';
import '../services/efipay_service.dart';

class PagamentoPage extends StatefulWidget {
  final int? idPlano;
  final PlanModel? plano;

  const PagamentoPage({super.key, required this.idPlano, this.plano});

  @override
  _PagamentoPageState createState() => _PagamentoPageState();
}

class _PagamentoPageState extends State<PagamentoPage> {
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _holderDocument = TextEditingController();

  String? _qrCodeData;
  bool _isProcessingPayment = false;

  bool _showQrCode = false;

  late PaymentController paymentController;

  @override
  void initState() {
    super.initState();
    paymentController = PaymentController(
        apiService: ApiService(), efipayService: EfipayService());

    paymentController.setPlan(widget.plano ?? PlanModel.empty());
  }

  // bool _validateCreditCardFields() {
  //   return _cardNumberController.text.isNotEmpty &&
  //       _cardHolderController.text.isNotEmpty &&
  //       _expiryDateController.text.isNotEmpty &&
  //       _cvvController.text.isNotEmpty;
  // }

  // void _generatePixQRCode() {
  //   const uuid = Uuid();
  //   String pixCode = uuid.v4();
  //   String value = widget.plano?.valor.toStringAsFixed(2) ?? '80.00';

  //   setState(() {
  //     _qrCodeData =
  //         '00020101021129370014BR.GOV.BCB.PIX0136$pixCode${('${value.replaceAll('.', '')}0000')}';
  //   });
  // }

  // void _handleTokenGenerated(String token) {
  //   setState(() {
  //     _generatedToken = token;
  //   });

  //   ScaffoldMessenger.of(context).showSnackBar(
  //     SnackBar(
  //       content: Text('Token gerado com sucesso: $token'),
  //       backgroundColor: const Color(0xFFaed513),
  //     ),
  //   );
  // }

  Widget _buildPlanCard(PlanModel plano) {
    // Cores baseadas no tipo de plano (inspirado na Apple One)
    Color getPlanColor() {
      switch (plano.nome.toLowerCase()) {
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
          return const Color(0xFFaed513); // Verde da PrincipalPage
      }
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[900], // Cor similar aos cards da PrincipalPage
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: getPlanColor().withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: getPlanColor(),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header do plano
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: getPlanColor().withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                // Título do plano
                Text(
                  plano.nome,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Texto branco como PrincipalPage
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Preço
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R\$',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: getPlanColor(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      plano.valor.toStringAsFixed(2).replaceAll('.', ','),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: getPlanColor(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '/mês',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Conteúdo do plano
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Descrição
                Text(
                  plano.descricao,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white54, // Cor similar ao PrincipalPage
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Recursos do plano
                Wrap(
                  spacing: 20,
                  runSpacing: 15,
                  children: [
                    _buildFeature('📸 ${plano.quantidadeFotos} fotos',
                        Icons.photo_library),
                    _buildFeature(
                        '🏷️ ${plano.quantidadeTags} categorias', Icons.label),
                    _buildFeature(
                        '📁 ${plano.quantidadePastas} pastas', Icons.folder),
                    _buildFeature('👥 ${plano.quantidadeConvites} convites',
                        Icons.people),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white54, // Cor similar ao PrincipalPage
        ),
      ),
    );
  }

  Widget _buildGenericPlanCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900], // Cor similar aos cards da SubscriptionPage
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: const Column(
        children: [
          Text(
            'Plano Selecionado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'R\$ 80,00',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFaed513), // Cor verde da SubscriptionPage
            ),
          ),
          SizedBox(height: 8),
          Text(
            '/mês',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fundo preto como SubscriptionPage
      appBar: AppBar(
        backgroundColor: Colors.black, // Fundo preto como SubscriptionPage
        title: const Text(
          'Pagamento',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Color(0xFFaed513), // Cor verde da SubscriptionPage
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFaed513)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header com título
                const Text(
                  'Resumo do Pedido',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, // Texto branco como SubscriptionPage
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),

                // Card do plano selecionado
                if (widget.plano != null)
                  _buildPlanCard(widget.plano!)
                else
                  _buildGenericPlanCard(),
                const SizedBox(height: 30),

                if (!_showQrCode) ...[
                  const Text(
                    'Método de Pagamento',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white, // Texto branco como SubscriptionPage
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Card de métodos de pagamento
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[
                          900], // Cor similar aos cards da SubscriptionPage
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[800]!),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text(
                            'Cartão de Crédito',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          leading: Radio<EnumPaymentType>(
                            value: EnumPaymentType.creditCard,
                            groupValue: paymentController.state.paymentType,
                            activeColor: const Color(
                                0xFFaed513), // Cor verde da SubscriptionPage
                            onChanged: (value) {
                              setState(() {
                                paymentController.setPaymentType(
                                    value ?? EnumPaymentType.creditCard);
                              });
                            },
                          ),
                        ),
                        ListTile(
                          title: const Text(
                            'PIX',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          leading: Radio<EnumPaymentType>(
                            value: EnumPaymentType.pix,
                            groupValue: paymentController.state.paymentType,
                            activeColor: const Color(
                                0xFFaed513), // Cor verde da SubscriptionPage
                            onChanged: (value) {
                              setState(() {
                                paymentController.setPaymentType(
                                    value ?? EnumPaymentType.pix);
                              });
                            },
                          ),
                        ),
                        if (paymentController.state.paymentType ==
                            EnumPaymentType.creditCard) ...[
                          const SizedBox(height: 20),
                          TextField(
                            controller: _cardNumberController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Número do Cartão',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFaed513)),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _cardHolderController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(
                              labelText: 'Nome do Titular',
                              labelStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Color(0xFFaed513)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _expiryDateController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Data de Validade (MM/AAAA)',
                                    labelStyle:
                                        TextStyle(color: Colors.white70),
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFFaed513)),
                                    ),
                                  ),
                                  keyboardType: TextInputType.datetime,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _cvvController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'CVV',
                                    labelStyle:
                                        TextStyle(color: Colors.white70),
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFFaed513)),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _holderDocument,
                                  inputFormatters: [CpfInputFormatter()],
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'CPF do Titular',
                                    labelStyle:
                                        TextStyle(color: Colors.white70),
                                    border: OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Colors.grey),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide:
                                          BorderSide(color: Color(0xFFaed513)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                if (paymentController.state.paymentType ==
                        EnumPaymentType.pix &&
                    _showQrCode) ...[
                  const SizedBox(height: 20),
                  Text(
                    'Escaneie o QR Code para pagar R\$ ${widget.plano?.valor.toStringAsFixed(2).replaceAll('.', ',') ?? '80,00'}:',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  QrImageView(
                    data: _qrCodeData!,
                    version: QrVersions.auto,
                    size: 200,
                    backgroundColor: Colors.white,
                    gapless: true,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Código PIX: $_qrCodeData',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor:
                      const Color(0xFFaed513), // Cor verde da SubscriptionPage
                  padding:
                      const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
                  textStyle: const TextStyle(fontSize: 17),
                ),
                onPressed: _isProcessingPayment
                    ? null
                    : () async {
                        if (_qrCodeData == null) {
                          setState(() {
                            _isProcessingPayment = true;
                          });

                          final response =
                              await paymentController.switchPaymentType(
                            number: _cardNumberController.text,
                            cvv: _cvvController.text,
                            expirationMonth:
                                _expiryDateController.text.split('/')[0],
                            expirationYear:
                                _expiryDateController.text.split('/')[1],
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
                                      'Pagamento via cartão de crédito efetuado com sucesso!')),
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
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Processando pagamento...',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : _qrCodeData == null
                        ? Text(
                            'Finalizar Compra - R\$ ${widget.plano?.valor.toStringAsFixed(2).replaceAll('.', ',') ?? '80,00'}',
                          )
                        : Text(
                            'Ir para a tela principal',
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

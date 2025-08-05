import 'dart:convert';

import 'package:application_progress/principal.dart';
import 'package:application_progress/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../controllers/controller.dart';
import '../infra/api_services.dart';
import '../models/models.dart';
import '../services/efipay_service.dart';

class PagamentoPage extends StatefulWidget {
  final int? idPlano;
  final PlanModel? plano;

  const PagamentoPage({super.key, required this.idPlano, this.plano});

  @override
  _PagamentoPageState createState() => _PagamentoPageState();
}

class _PagamentoPageState extends State<PagamentoPage> {
  String? _selectedPaymentMethod;
  final TextEditingController _cardNumberController =
      TextEditingController(text: "4192801899905047");
  final TextEditingController _cardHolderController =
      TextEditingController(text: "ABIMAEL TESTE");
  final TextEditingController _expiryDateController =
      TextEditingController(text: "01/2026");
  final TextEditingController _cvvController =
      TextEditingController(text: "622");
  String? _qrCodeData;

  late PaymentController paymentController;

  @override
  void initState() {
    super.initState();
    paymentController = PaymentController(
        apiService: ApiService(), efipayService: EfipayService());
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
            color: getPlanColor().withOpacity(0.3),
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
                        '🏷️ ${plano.quantidadeTags} tags', Icons.label),
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
      child: Column(
        children: [
          const Text(
            'Plano Selecionado',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'R\$ 80,00',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFaed513), // Cor verde da SubscriptionPage
            ),
          ),
          const SizedBox(height: 8),
          const Text(
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
                Text(
                  'Resumo do Pedido',
                  style: const TextStyle(
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

                Text(
                  'Método de Pagamento',
                  style: const TextStyle(
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
                    color: Colors
                        .grey[900], // Cor similar aos cards da SubscriptionPage
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[800]!),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        title: const Text(
                          'Cartão de Crédito/Débito',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        leading: Radio<String>(
                          value: 'cartao',
                          groupValue: _selectedPaymentMethod,
                          activeColor: const Color(
                              0xFFaed513), // Cor verde da SubscriptionPage
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value;
                              _qrCodeData =
                                  null; // Limpar QR Code ao mudar de método
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
                        leading: Radio<String>(
                          value: 'pix',
                          groupValue: _selectedPaymentMethod,
                          activeColor: const Color(
                              0xFFaed513), // Cor verde da SubscriptionPage
                          onChanged: (value) {
                            // Método para gerar o QR Code
                            void generatePixQRCode(String pixCode) {
                              setState(() {
                                _qrCodeData =
                                    pixCode; // Defina a chave PIX ou o código que deseja usar para gerar o QR Code
                              });
                            }

                            setState(() {
                              _selectedPaymentMethod = value;
                              generatePixQRCode(
                                  'pixCode5204000053039865405'); // Gerar QR Code imediatamente
                            });
                          },
                        ),
                      ),
                      if (_selectedPaymentMethod == 'pix' &&
                          _qrCodeData != null) ...[
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
                          size: 200.0,
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
                      if (_selectedPaymentMethod == 'cartao') ...[
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
                              borderSide: BorderSide(color: Color(0xFFaed513)),
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
                              borderSide: BorderSide(color: Color(0xFFaed513)),
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
                                  labelText: 'Data de Validade (MM/AA)',
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
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                onPressed: () async {
                  if (_selectedPaymentMethod == 'cartao') {
                    await paymentController.generateCardToken(
                      number: _cardNumberController.text,
                      cvv: _cvvController.text,
                      expirationMonth: _expiryDateController.text.split('/')[0],
                      expirationYear: _expiryDateController.text.split('/')[1],
                      holderName: _cardHolderController.text,
                      holderDocument: '94271564656',
                    );
                  }
                },
                child: Text(
                  'Finalizar Compra - R\$ ${widget.plano?.valor.toStringAsFixed(2).replaceAll('.', ',') ?? '80,00'}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

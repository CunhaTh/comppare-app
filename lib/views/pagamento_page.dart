import 'dart:convert';

import 'package:application_progress/principal.dart';
import 'package:application_progress/main.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

import '../controllers/controller.dart';
import '../infra/api_services.dart';

// class PagamentoPage extends StatelessWidget {
//   const PagamentoPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Checkout',
//       theme: ThemeData(
//         primaryColor: const Color(0xFFaed513),
//         hintColor: const Color(0xFF3483FA),
//         appBarTheme: const AppBarTheme(
//           backgroundColor: Color(0xFFaed513),
//           titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
//         ),
//         elevatedButtonTheme: ElevatedButtonThemeData(
//           style: ElevatedButton.styleFrom(
//             foregroundColor: Colors.white,
//             backgroundColor: const Color(0xFF3483FA),
//           ),
//         ),
//         textTheme: const TextTheme(
//           titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//           bodyLarge: TextStyle(fontSize: 16),
//         ),
//       ),
//       home: const CheckoutScreen(idPlano: null),
//     );
//   }
// }

class PagamentoPage extends StatefulWidget {
  final int? idPlano;
  final Plano? plano;

  const PagamentoPage({super.key, required this.idPlano, this.plano});

  @override
  _PagamentoPageState createState() => _PagamentoPageState();
}

class _PagamentoPageState extends State<PagamentoPage> {
  String? _selectedPaymentMethod;
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  String? _qrCodeData;

  late PaymentController paymentController;

  @override
  void initState() {
    super.initState();
    paymentController = PaymentController(apiService: ApiService());
  }

  // Future<String?> _generatePaymentToken() async {
  //   const url =
  //       'https://seu-backend.com/generate_payment_token'; // Altere para o seu endpoint
  //   final response = await http.post(
  //     Uri.parse(url),
  //     headers: {'Content-Type': 'application/json'},
  //     body: json.encode({
  //       'card_number': _cardNumberController.text,
  //       'card_holder': _cardHolderController.text,
  //       'expiry_date': _expiryDateController.text,
  //       'cvv': _cvvController.text,
  //       'reuse': true // para permitir reutilização do token
  //     }),
  //   );

  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     return data['payment_token']; // Ajuste conforme a resposta da sua API
  //   } else {
  //     throw Exception('Falha ao gerar o payment_token');
  //   }
  // }

  // void _generatePixQRCode(dynamic pixCode5204000053039865405) {
  //   const uuid = Uuid();
  //   String pixCode = uuid.v4(); // Gera um código único para o PIX
  //   String value = widget.plano?.valor.toStringAsFixed(2) ??
  //       '80.00'; // Valor do plano selecionado

  //   _qrCodeData =
  //       '00020101021129370014BR.GOV.BCB.PIX0136$pixCode5204000053039865405${('${value.replaceAll('.', '')}0000')}';

  //   setState(() {});
  // }

  bool _validateCreditCardFields() {
    return _cardNumberController.text.isNotEmpty &&
        _cardHolderController.text.isNotEmpty &&
        _expiryDateController.text.isNotEmpty &&
        _cvvController.text.isNotEmpty;
  }

  Widget _buildPlanCard(Plano plano) {
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
                          decoration: const InputDecoration(
                            labelText: 'Número do Cartão',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _cardHolderController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do Titular',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _expiryDateController,
                                decoration: const InputDecoration(
                                  labelText: 'Data de Validade (MM/AA)',
                                  border: OutlineInputBorder(),
                                ),
                                keyboardType: TextInputType.datetime,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _cvvController,
                                decoration: const InputDecoration(
                                  labelText: 'CVV',
                                  border: OutlineInputBorder(),
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
                  if (_selectedPaymentMethod != null) {
                    if (_selectedPaymentMethod == 'cartao' &&
                        !_validateCreditCardFields()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Por favor, preencha todos os campos do cartão.')),
                      );
                    } else {
                      if (_selectedPaymentMethod == 'cartao') {
                        String? paymentToken =
                            await paymentController.generateCardToken(
                                number: _cardNumberController.text,
                                cvv: _cvvController.text,
                                expirationMonth:
                                    _expiryDateController.text.split('/')[0],
                                expirationYear:
                                    _expiryDateController.text.split('/')[1]);
                      }
                      // try {
                      //   String? paymentToken = await _generatePaymentToken();
                      //   if (paymentToken != null) {
                      //     // Aqui você pode prosseguir com o pagamento usando o paymentToken
                      //     showDialog(
                      //       context: context,
                      //       builder: (context) {
                      //         return AlertDialog(
                      //           title: const Text('Pagamento Realizado'),
                      //           content: Text(
                      //               'Pagamento realizado com sucesso. Token: $paymentToken'),
                      //           actions: [
                      //             TextButton(
                      //               onPressed: () {
                      //                 Navigator.of(context)
                      //                     .pop(); // Fechar o diálogo
                      //                 Navigator.of(context).push(
                      //                   MaterialPageRoute(
                      //                     builder: (context) =>
                      //                         const PrincipalPage(),
                      //                   ),
                      //                 );
                      //               },
                      //               child: const Text('OK'),
                      //             ),
                      //           ],
                      //         );
                      //       },
                      //     );

                      //   }
                      // } catch (e) {
                      //   ScaffoldMessenger.of(context).showSnackBar(
                      //     SnackBar(
                      //         content: Text('Erro ao gerar payment token: $e')),
                      //   );
                      // }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Por favor, selecione um método de pagamento.')),
                    );
                  }
                },
                child: Text(
                  'Finalizar Compra - R\$ ${widget.plano?.valor.toStringAsFixed(2).replaceAll('.', ',') ?? '80,00'}',
                ),
              ),
            ),
            // const SizedBox(width: 16),
            // Expanded(
            //   child: ElevatedButton(
            //     style: ElevatedButton.styleFrom(
            //       foregroundColor: Colors.white,
            //       backgroundColor: Colors
            //           .grey[800], // Cor cinza escura como SubscriptionPage
            //       padding:
            //           const EdgeInsets.symmetric(horizontal: 45, vertical: 25),
            //       textStyle: const TextStyle(fontSize: 18),
            //     ),
            //     onPressed: () async {
            //       // const url =
            //       //     'https://www.mercadopago.com.br/subscriptions/checkout?preapproval_plan_id=2c9380849564460a01958274c6b70f23';
            //       // if (await canLaunch(url)) {
            //       //   await launch(url);
            //       // } else {
            //       //   throw 'Não foi possível abrir o URL: $url';
            //       // }
            //     },
            //     child: const Text(
            //       'Mercado Pago',
            //       style: TextStyle(fontSize: 16),
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }
}

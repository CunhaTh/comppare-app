import 'dart:convert';

import 'package:application_progress/principal.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';

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

  const PagamentoPage({super.key, required this.idPlano});

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

  Future<String?> _generatePaymentToken() async {
    const url =
        'https://seu-backend.com/generate_payment_token'; // Altere para o seu endpoint
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'card_number': _cardNumberController.text,
        'card_holder': _cardHolderController.text,
        'expiry_date': _expiryDateController.text,
        'cvv': _cvvController.text,
        'reuse': true // para permitir reutilização do token
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['payment_token']; // Ajuste conforme a resposta da sua API
    } else {
      throw Exception('Falha ao gerar o payment_token');
    }
  }

  void _generatePixQRCode(dynamic pixCode5204000053039865405) {
    const uuid = Uuid();
    String pixCode = uuid.v4(); // Gera um código único para o PIX
    String value = '80.00'; // Valor da compra (ajuste conforme necessário)

    _qrCodeData =
        '00020101021129370014BR.GOV.BCB.PIX0136$pixCode5204000053039865405${('${value.replaceAll('.', '')}0000')}';

    setState(() {});
  }

  bool _validateCreditCardFields() {
    return _cardNumberController.text.isNotEmpty &&
        _cardHolderController.text.isNotEmpty &&
        _expiryDateController.text.isNotEmpty &&
        _cvvController.text.isNotEmpty;
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

              // Card de resumo
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
                    const Text(
                      'Produto 1: R\$ 50,00',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white54,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Produto 2: R\$ 30,00',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white54,
                      ),
                    ),
                    const Divider(color: Colors.grey),
                    const Text(
                      'Total: R\$ 80,00',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            Color(0xFFaed513), // Cor verde da SubscriptionPage
                      ),
                    ),
                  ],
                ),
              ),
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
                      const Text('Escaneie o QR Code para pagar:'),
                      QrImageView(
                        data: _qrCodeData!,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                      const SizedBox(height: 10),
                      Text('Código PIX: $_qrCodeData'),
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
                      try {
                        String? paymentToken = await _generatePaymentToken();
                        if (paymentToken != null) {
                          // Aqui você pode prosseguir com o pagamento usando o paymentToken
                          showDialog(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Pagamento Realizado'),
                                content: Text(
                                    'Pagamento realizado com sucesso. Token: $paymentToken'),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Fechar o diálogo
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PrincipalPage(),
                                        ),
                                      );
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Erro ao gerar payment token: $e')),
                        );
                      }
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Por favor, selecione um método de pagamento.')),
                    );
                  }
                },
                child: const Text('Finalizar Compra'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors
                      .grey[800], // Cor cinza escura como SubscriptionPage
                  padding:
                      const EdgeInsets.symmetric(horizontal: 45, vertical: 25),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                onPressed: () async {
                  const url =
                      'https://www.mercadopago.com.br/subscriptions/checkout?preapproval_plan_id=2c9380849564460a01958274c6b70f23';
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    throw 'Não foi possível abrir o URL: $url';
                  }
                },
                child: const Text(
                  'Mercado Pago',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

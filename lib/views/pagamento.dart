import 'dart:convert';

import 'package:application_progress/main.dart';
import 'package:application_progress/principal.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:application_progress/cartao-token.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checkout',
      theme: ThemeData(
        primaryColor: const Color(0xFFaed513),
        hintColor: const Color(0xFF3483FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFaed513),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF3483FA),
          ),
        ),
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16),
        ),
      ),
      home: const CheckoutScreen(idPlano: null),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final int? idPlano;

  const CheckoutScreen({super.key, required this.idPlano});

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                },
                child: Image.asset(
                  "assets/logo_cortada.png",
                  width: 150,
                  height: 50,
                ),
              ),
              Row(
                children: [
                  Builder(
                    builder: (BuildContext context) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: GestureDetector(
                            onTap: () {
                           /*   Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const MyHomePage(
                                    title: '',
                                  ),
                                ),
                              );*/
                            },
                            child: const Icon(Icons.logout)),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Resumo do Pedido',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            const Text('Produto 1: R\$ 50,00'),
            const Text('Produto 2: R\$ 30,00'),
            const Divider(),
            const Text('Total: R\$ 80,00',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Text(
              'Método de Pagamento',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ListTile(
                  title: const Text('Cartão de Crédito/Débito'),
                  leading: Radio<String>(
                    value: 'cartao',
                    groupValue: _selectedPaymentMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedPaymentMethod = value;
                        _qrCodeData = null; // Limpar QR Code ao mudar de método
                      });
                    },
                  ),
                ),
                ListTile(
                  title: const Text('PIX'),
                  leading: Radio<String>(
                    value: 'pix',
                    groupValue: _selectedPaymentMethod,
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
                if (_selectedPaymentMethod == 'pix' && _qrCodeData != null) ...[
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
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF637700),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 25),
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
                                        builder: (context) => const PrincipalPage(),
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
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF3483FA),
                padding: const EdgeInsets.symmetric(horizontal: 45, vertical: 25),
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
          ],
        ),
      ),
    );
  }
}

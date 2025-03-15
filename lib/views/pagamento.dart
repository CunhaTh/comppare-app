import 'package:application_progress/principal.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:application_progress/views/comparepage.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Checkout',
      theme: ThemeData(
        primaryColor: Color(0xFFaed513),
        hintColor: Color(0xFF3483FA),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFaed513),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Color(0xFF3483FA),
          ),
        ),
        textTheme: TextTheme(
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

  const CheckoutScreen({Key? key, required this.idPlano}) : super(key: key);

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

  void _generatePixQRCode(dynamic pixCode5204000053039865405) {
    const uuid = Uuid();
    String pixCode = uuid.v4(); // Gera um código único para o PIX
    String value = '80.00'; // Valor da compra (ajuste conforme necessário)

    _qrCodeData = '00020101021129370014BR.GOV.BCB.PIX0136$pixCode5204000053039865405${(value.replaceAll('.', '') + '0000')}';
    
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
      title: Text('Tela de Checkout'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumo do Pedido',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 10),
          Text('Produto 1: R\$ 50,00'),
          Text('Produto 2: R\$ 30,00'),
          Divider(),
          Text('Total: R\$ 80,00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          Text(
            'Método de Pagamento',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          ListTile(
            title: Text('Cartão de Crédito/Débito'),
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
            title: Text('PIX'),
            leading: Radio<String>(
              value: 'pix',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                // Método para gerar o QR Code
                  void _generatePixQRCode(String pixCode) {
                    setState(() {
                      _qrCodeData = pixCode; // Defina a chave PIX ou o código que deseja usar para gerar o QR Code
                    });
                  }
                setState(() {
                  _selectedPaymentMethod = value;
                  _generatePixQRCode('pixCode5204000053039865405'); // Gerar QR Code imediatamente
                });
              },
            ),
          ),
          if (_selectedPaymentMethod == 'pix' && _qrCodeData != null) ...[
            SizedBox(height: 20),
            Text('Escaneie o QR Code para pagar:'),
            QrImageView(
              data: _qrCodeData!,
              version: QrVersions.auto,
              size: 200.0,
            ),
            SizedBox(height: 10),
            Text('Código PIX: $_qrCodeData'),
          ],
          if (_selectedPaymentMethod == 'cartao') ...[
            SizedBox(height: 20),
            TextField(
              controller: _cardNumberController,
              decoration: InputDecoration(
                labelText: 'Número do Cartão',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _cardHolderController,
              decoration: InputDecoration(
                labelText: 'Nome do Titular',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryDateController,
                    decoration: InputDecoration(
                      labelText: 'Data de Validade (MM/AA)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.datetime,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    decoration: InputDecoration(
                      labelText: 'CVV',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: 20),    
        ],
        
      ),
    ),
    bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
               style: ElevatedButton.styleFrom(
                        foregroundColor: Color.fromARGB(255, 70, 137, 64), backgroundColor: Color.fromARGB(179, 196, 255, 211),
                        padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        textStyle: TextStyle(fontSize: 18),
                      ),
              onPressed: () {
  if (_selectedPaymentMethod != null) {
    if (_selectedPaymentMethod == 'cartao' && !_validateCreditCardFields()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, preencha todos os campos do cartão.')),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Pagamento Realizado'),
            content: Text('Você escolheu pagar com $_selectedPaymentMethod.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Fechar o diálogo
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PrincipalPage(),
                    ),
                  );
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Por favor, selecione um método de pagamento.')),
    );
  }
},
              child: Text('Finalizar Compra'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                        foregroundColor: Color.fromARGB(255, 219, 231, 249), backgroundColor: Color(0xFF3483FA),
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                        textStyle: TextStyle(fontSize: 18),
                      ),
              onPressed: () async {
                const url = 'https://www.mercadopago.com.br/subscriptions/checkout?preapproval_plan_id=2c9380849564460a01958274c6b70f23';
                if (await canLaunch(url)) {
                  await launch(url);
                } else {
                  throw 'Não foi possível abrir o URL: $url';
                }
              },
              child: Text(
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

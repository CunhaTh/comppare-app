import 'package:flutter/material.dart';

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
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFaed513),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, backgroundColor: Color(0xFFaed513), // Cor do texto do botão
          ),
        ),
        
      ),
      home: CheckoutScreen(),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String? _selectedPaymentMethod;

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
            Text('Total: R\$ 80,00', style: TextStyle(fontSize: 18)),
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
                  setState(() {
                    _selectedPaymentMethod = value;
                  });
                },
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Aqui você pode adicionar a lógica para processar o pagamento
                if (_selectedPaymentMethod != null) {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Pagamento Realizado'),
                        content: Text('Você escolheu pagar com $_selectedPaymentMethod.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('OK'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  // Alertar o usuário para selecionar um método de pagamento
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor, selecione um método de pagamento.')),
                  );
                }
              },
              child: Text('Finalizar Compra'),
            ),
          ],
        ),
      ),
    );
  }
}

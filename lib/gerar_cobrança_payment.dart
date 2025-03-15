  import 'dart:convert';

import 'package:http/http.dart' as http;

  Future<String?> gerarPaymentToken(String numeroCartao, String codigoSeguranca, String validade) async {
  final url = 'https://dev.efipay.com.br/docs/api-cobrancas/cartao'; // URL fictícia, substitua pela correta
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'First-Name': 'application/json',
      'Last-Name': 'application/json',
      'Street': 'application/json',
      'Postcode': 'application/json',
      'City': 'application/json',
      'Country/Region': 'application/json',
      'Phone': 'application/json'
      // Adicione outros cabeçalhos que a API exigir, como autenticação
    },
    body: jsonEncode({
      'numero_cartao': numeroCartao,
      'codigo_seguranca': codigoSeguranca,
      'validade': validade,
      'reuse': true, // Se você deseja reutilizar o token
    }),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['payment_token']; // Substitua pela chave correta do JSON retornado
  } else {
    print('Erro: ${response.body}');
    return null;
  }
}

Future<bool> criarCobranca(String paymentToken, double valor) async {
  final url = 'https://dev.efipay.com.br/docs/api-cobrancas/cartao'; // URL fictícia, substitua pela correta
  final response = await http.post(
    Uri.parse(url),
    headers: {
      'Content-Type': 'application/json',
      'First-Name': 'application/json',
      'Last-Name': 'application/json',
      'Street': 'application/json',
      'Postcode': 'application/json',
      'City': 'application/json',
      'Country/Region': 'application/json',
      'Phone': 'application/json'
      // Adicione outros cabeçalhos que a API exigir, como autenticação
    },
    body: jsonEncode({
      'payment_token': paymentToken,
      'valor': valor,
    }),
  );

  if (response.statusCode == 200) {
    // Aqui você deve verificar a resposta para confirmar que a cobrança foi criada
    final data = jsonDecode(response.body);
    return data['success']; // Substitua pela chave correta do JSON retornado
  } else {
    print('Erro: ${response.body}');
    return false;
  }
}

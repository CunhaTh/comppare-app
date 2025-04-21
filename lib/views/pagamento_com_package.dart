import 'package:efipay/efipay.dart';

Future<String?> gerarPaymentToken(
//   {
//   required String numero,
//   required String validadeMes,
//   required String validadeAno,
//   required String cvc,
//   required String nomeTitular,
//   String bandeira = 'visa',
// }
    ) async {
  try {
    final efipay = EfiPay({
      'client_id': 'Client_Id_a2aadb09b1c3f0d71a6c10cb7406f3076d8d1db0',
      'client_secret': 'Client_Secret_b8f50953e25c459c8962ab7509cdebae629e7b9b',
      'sandbox': true,
    });

    final body = {
      "data": {
        "number": '5226268872411681',
        "brand": 'mastercard',
        "expiration_month": '05',
        "expiration_year": '2032',
        "security_code": '542',
        "cardholder": {"name": "Andrew S Vieira"}
      }
    };

    final response = await efipay.call(
      'getPaymentToken',
      params: {},
      body: body,
    );

    print('PAYMENT TOKEN: ${response['payment_token']}');

    return response['payment_token'];
  } catch (e) {
    print('Erro ao gerar payment_token: $e');
    return null;
  }
}

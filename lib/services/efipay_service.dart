import 'dart:async';
import 'dart:js';
import 'dart:js_util';

class EfipayService {
  static Future<String?> generatePaymentToken({
    required String brand,
    required String number,
    required String cvv,
    required String expirationMonth,
    required String expirationYear,
  }) async {
    final cardData = jsify({
      'brand': brand,
      'number': number,
      'cvv': cvv,
      'expiration_month': expirationMonth,
      'expiration_year': expirationYear,
    });

    final completer = Completer<String?>();

    final callback = allowInterop((response) {
      if (response['code'] == '200') {
        completer.complete(response['data']['payment_token']);
      } else {
        print('Erro ao gerar token: ${response['error_description']}');
        completer.complete(null);
      }
    });

    context.callMethod('getPaymentToken', [cardData, callback]);

    return completer.future;
  }
}

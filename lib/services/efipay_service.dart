import 'dart:async';
import 'dart:developer';
import 'dart:js' as js;

class EfipayService {
  Future<String> generateCardToken({
    required String number,
    required String cvv,
    required String expirationMonth,
    required String expirationYear,
    required String holderName,
    required String holderDocument,
  }) async {
    // final card = js.JsObject.jsify({
    //   'number': '4192801899905047',
    //   'cvv': '123',
    //   'expirationMonth': '08',
    //   'expirationYear': '2026',
    //   'holderName': 'Gorbadoc Oldbuck',
    //   'holderDocument': '94271564656',
    //   'reuse': false,
    // });
    final card = js.JsObject.jsify({
      'number': number,
      'cvv': cvv,
      'expirationMonth': expirationMonth,
      'expirationYear': expirationYear,
      'holderName': holderName,
      'holderDocument': holderDocument,
      'reuse': false,
    });

    try {
      // Chama a função JS e obtém a Promise
      final jsPromise = js.context.callMethod('generateToken', [card]);

      // Converte a Promise em um Future do Dart e espera a sua resolução
      final result = await promiseToFuture(jsPromise);

      log('Resultado da geração de token: $result');
      log('Tipo do resultado: ${result.runtimeType}');

      if (result is String && result.startsWith('Erro:')) {
        throw Exception(result);
      }

      if (result != null) {
        // O resultado agora é o objeto retornado pela Promise
        // Você pode acessá-lo como um objeto JsObject
        final jsObject = result as js.JsObject;
        final token = jsObject['payment_token'];

        if (token != null) {
          final tokenString = token.toString();
          log('Token extraído do no DART vindo do JS: $tokenString');
          // Sucesso, retorna o token
          return tokenString;
        } else {
          log('Token não encontrado no objeto');
          throw Exception('Token não encontrado no resultado');
        }
      } else {
        throw Exception('Token não foi gerado, resultado nulo');
      }
    } catch (e) {
      log('Erro ao gerar token: $e');
      // Em caso de erro, trate e propague a exceção
      rethrow;
    }
  }
}

// Helper para converter uma Promise do JS em um Future do Dart
Future<T> promiseToFuture<T>(js.JsObject jsPromise) {
  final completer = Completer<T>();
  jsPromise.callMethod('then', [
    js.allowInterop((result) {
      completer.complete(result);
    }),
    js.allowInterop((error) {
      completer.completeError(error);
    }),
  ]);
  return completer.future;
}

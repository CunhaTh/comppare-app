import 'package:get_storage/get_storage.dart';

class TokenHelper {
  TokenHelper._();

  static TokenHelper instance = TokenHelper._();

  String get token => GetStorage().read('token') ?? '';

  bool hasToken() => token.isNotEmpty;

  Future<void> setToken(String? token) async {
    await GetStorage().write('token', token);
  }
}

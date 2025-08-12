import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'user_helper.dart';

class TokenHelper {
  TokenHelper._internal();
  static final TokenHelper _instance = TokenHelper._internal();
  factory TokenHelper() => _instance;

  final _box = GetStorage();
  static const String _tokenKey = 'authToken';
  static const String _userIdKey = 'currentUserId';

  String? _token; // Cache interno para o token
  int? _userId;   // Cache interno para o ID do usuário

  bool _isInitialized = false; // Flag para garantir que a inicialização ocorra apenas uma vez

  /// Inicializa o TokenHelper carregando os dados do GetStorage para o cache interno.
  /// Deve ser chamado uma única vez no início do aplicativo (ex: em main.dart).
  Future<void> init() async {
    if (_isInitialized) {
      return; // Já inicializado, evita recarregar
    }

    try {
      _token = _box.read(_tokenKey);
      _userId = _box.read(_userIdKey);
      _isInitialized = true;
      foundation.debugPrint(
          'TokenHelper inicializado: Token: ${_token?.substring(0, 10)}..., User ID: $_userId');
    } catch (e) {
      foundation.debugPrint('TokenHelper: Erro ao inicializar: $e');
      _token = null;
      _userId = null;
    }
  }

  String? get token => _token;

  int? get userId => _userId;

  /// Salva o token no cache interno e no GetStorage.
  Future<void> saveToken(String token) async {
    if (token.isEmpty) {
      foundation.debugPrint('TokenHelper: Tentativa de salvar token inválido.');
      return;
    }
    _token = token; // Atualiza o cache interno
    await _box.write(_tokenKey, token);
    foundation.debugPrint('TokenHelper: Token salvo no storage e cache.');
  }

  /// Salva o ID do usuário no cache interno e no GetStorage.
  Future<void> saveUserId(int userId) async {
    if (userId <= 0) {
      foundation.debugPrint('TokenHelper: Tentativa de salvar ID de usuário inválido.');
      return;
    }
    _userId = userId; // Atualiza o cache interno
    await _box.write(_userIdKey, userId);
    foundation.debugPrint('TokenHelper: User ID salvo no storage e cache.');
  }

  /// Limpa o token e o ID do usuário do cache interno e do GetStorage.
  Future<void> clear() async {
    _token = null;
    _userId = null;
    await _box.remove(_tokenKey);
    await _box.remove(_userIdKey);
    await UserHelper().removeUser(); // Limpa os dados do usuário também
    foundation.debugPrint('TokenHelper: Token e User ID limpos do storage e cache.');
  }

  /// Verifica se um token válido está disponível.
  bool hasToken() {
    return _token != null && _token!.isNotEmpty;
  }
}
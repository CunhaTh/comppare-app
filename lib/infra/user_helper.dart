import 'dart:convert';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/models/folder_model.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' as foundation;

class User {
  final int? id;
  final String? nome;
  final String? cpf;
  final String? senha;
  final String? telefone;
  final int? idPlano;
  final String? email;
  final String? token;
  List<Folder>? pastas;

  User({
    required this.id,
    this.nome,
    this.cpf,
    this.senha,
    this.telefone,
    this.idPlano,
    this.email,
    this.token,
    this.pastas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cpf': cpf,
      'telefone': telefone,
      'idPlano': idPlano,
      'email': email,
      'token': token,
      'pastas': pastas?.map((pasta) => pasta.toMap()).toList(),
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    List<Folder>? parsedPastas;
    if (map.containsKey('pastas') && map['pastas'] is List) {
      parsedPastas = (map['pastas'] as List)
          .map((item) => Folder.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    return User(
      id: map['id'] as int?,
      nome: map['nome'] as String?,
      cpf: map['cpf'] as String?,
      telefone: map['telefone'] as String?,
      idPlano: map['idPlano'] as int?,
      email: map['email'] as String?,
      token: map['token'] as String?,
      pastas: parsedPastas,
    );
  }
}

class UserHelper {
  UserHelper._internal();
  static final UserHelper _instance = UserHelper._internal();
  factory UserHelper() => _instance;

  final _box = GetStorage();
  static const String _userKey = 'currentUser';

  User? _user;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final userData = _box.read(_userKey);
      if (userData != null) {
        _user = User.fromMap(json.decode(userData));
        foundation.debugPrint('UserHelper: Usuário carregado do storage: ${_user?.nome}');
      }
    } catch (e) {
      foundation.debugPrint('UserHelper: Erro ao carregar usuário do storage: $e');
      _user = null;
      await _box.remove(_userKey);
    }
    _isInitialized = true;
  }

  User? get user => _user;

  Future<void> setUser(User user) async {
    if (user.id == null) {
      foundation.debugPrint('UserHelper: Tentativa de salvar usuário sem ID.');
      return;
    }
    _user = user;
    await _box.write(_userKey, json.encode(user.toMap()));
    foundation.debugPrint('UserHelper: Usuário salvo no storage e cache.');
  }

  Future<void> updateUserFolders(List<Folder> folders) async {
    if (_user != null) {
      _user!.pastas = folders;
      await _box.write(_userKey, json.encode(_user!.toMap()));
      foundation.debugPrint('UserHelper: Pastas do usuário atualizadas no storage e cache.');
    } else {
      foundation.debugPrint('UserHelper: Não foi possível atualizar pastas, usuário não está no cache.');
    }
  }

  Future<void> refreshUser() async {
    final tokenHelper = TokenHelper();
    final apiService = ApiService();
    final userId = tokenHelper.userId;
    final token = tokenHelper.token;

    if (userId != null && userId > 0 && token != null && token.isNotEmpty) {
      try {
        // Chama authenticateUser com o token existente para refresh
        final response = await apiService.authenticateUser('', '', token: token);
        foundation.debugPrint('[_refreshUser] Resposta da API: ${json.encode(response)}');

        if (response.containsKey('dados') && response['dados'] is Map<String, dynamic>) {
          final userData = response['dados'] as Map<String, dynamic>;
          final User updatedUser = User(
            id: userData['id'] as int?,
            nome: '${userData['primeiroNome']} ${userData['sobrenome']}',
            cpf: userData['cpf'] as String?,
            telefone: userData['telefone'] as String?,
            idPlano: userData['idPlano'] as int?,
            email: userData['email'] as String?,
            token: token,
          );
          if (response.containsKey('pastas') && response['pastas'] is List) {
            final List<dynamic> pastasJson = response['pastas'] as List<dynamic>;
            updatedUser.pastas = pastasJson.map((item) => Folder.fromMap(item as Map<String, dynamic>)).toList();
            foundation.debugPrint('[_refreshUser] Pastas atualizadas: ${updatedUser.pastas?.length}');
          } else {
            updatedUser.pastas = [];
            foundation.debugPrint('[_refreshUser] Nenhuma pasta encontrada na resposta.');
          }
          await setUser(updatedUser);
        } else {
          foundation.debugPrint('[_refreshUser] Resposta inválida: dados ou pastas ausentes.');
        }
      } catch (e) {
        foundation.debugPrint('[_refreshUser] Erro ao atualizar usuário: $e');
      }
    } else {
      foundation.debugPrint('[_refreshUser] Usuário não autenticado ou token inválido.');
    }
  }

  Future<void> removeUser() async {
    _user = null;
    await _box.remove(_userKey);
    foundation.debugPrint('UserHelper: Usuário removido do storage e cache.');
  }
}
// lib/infra/user_helper.dart
import 'dart:convert';
import 'package:get_storage/get_storage.dart';
import 'package:flutter/foundation.dart' as foundation; // Para debugPrint
import 'package:application_progress/models/folder_model.dart'; // Importa Folder
import 'package:application_progress/models/image_model.dart'; // Importa ImageModel

class User {
  final int? id;
  final String? nome;
  final String? cpf;
  final String? telefone;
  final int? idPlano;
  final String? email;
  final String? token; // O token de autenticação do usuário
  List<Folder>? pastas; // Lista de pastas do usuário

  User({
    required this.id,
    this.nome,
    this.cpf,
    this.telefone,
    this.idPlano,
    this.email,
    this.token,
    this.pastas,
  });

  // Converte um objeto User para um Map (para salvar no GetStorage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'cpf': cpf,
      'telefone': telefone,
      'idPlano': idPlano,
      'email': email,
      'token': token,
      'pastas': pastas?.map((pasta) => pasta.toMap()).toList(), // Converte pastas para Map
    };
  }

  // Cria um objeto User a partir de um Map (lido do GetStorage)
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

  User? _user; // Cache interno para o usuário

  bool _isInitialized = false; // Flag para garantir inicialização única

  /// Inicializa o UserHelper carregando o usuário do GetStorage para o cache interno.
  /// Deve ser chamado uma única vez no início do aplicativo (ex: em main.dart ou AuthWrapper).
  Future<void> init() async {
    if (_isInitialized) {
      return; // Já inicializado, evita recarregar
    }

    final userData = _box.read(_userKey);
    if (userData != null) {
      try {
        _user = User.fromMap(json.decode(userData));
        foundation.debugPrint('UserHelper: Usuário carregado do storage: ${_user?.nome}');
      } catch (e) {
        foundation.debugPrint('UserHelper: Erro ao carregar usuário do storage: $e');
        _user = null; // Limpa o usuário se houver erro de decodificação
        await _box.remove(_userKey); // Remove dados corrompidos
      }
    }
    _isInitialized = true;
  }

  User? get user => _user;

  /// Salva o objeto User completo no cache interno e no GetStorage.
  Future<void> setUser(User user) async {
    _user = user; // Atualiza o cache interno
    await _box.write(_userKey, json.encode(user.toMap()));
    foundation.debugPrint('UserHelper: Usuário salvo no storage e cache.');
  }

  /// Atualiza apenas a lista de pastas do usuário no cache e no storage.
  Future<void> updateUserFolders(List<Folder> folders) async {
    if (_user != null) {
      _user!.pastas = folders; // Atualiza a lista de pastas no objeto User em cache
      await _box.write(_userKey, json.encode(_user!.toMap())); // Salva o User atualizado
      foundation.debugPrint('UserHelper: Pastas do usuário atualizadas no storage e cache.');
    } else {
      foundation.debugPrint('UserHelper: Não foi possível atualizar pastas, usuário não está no cache.');
    }
  }

  /// Remove o usuário do cache interno e do GetStorage.
  Future<void> removeUser() async {
    _user = null;
    await _box.remove(_userKey);
    foundation.debugPrint('UserHelper: Usuário removido do storage e cache.');
  }
}

import 'package:get_storage/get_storage.dart';

class UserHelper {
  UserHelper._();

  static UserHelper instance = UserHelper._();

  UserModel? get user {
    final data = GetStorage().read('user');
    if (data != null) return UserModel.fromMap(data);
    return null;
  }

  Future<void> setUser(UserModel user) async {
    await GetStorage().write('user', user.toMap());
  }

  Future<void> removeUser() async {
    await GetStorage().remove('user');
  }
}

class UserModel {
  final int? id;
  final int? idPlano;
  final String? nome;
  final String? cpf;
  final String? telefone;

  UserModel({
    required this.id,
    required this.nome,
    required this.cpf,
    required this.telefone,
    required this.idPlano,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'idPlano': idPlano,
      'nome': nome,
      'cpf': cpf,
      'telefone': telefone,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      idPlano: map['idPlano'],
      nome: map['nome'],
      cpf: map['cpf'],
      telefone: map['telefone'],
    );
  }
}

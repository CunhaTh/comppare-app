import 'package:flutter/foundation.dart';

class FormModel extends ChangeNotifier {
  String _name = '';
  String _email = '';
  String _celular = '';
  String _cpf = '';

  String get name => _name;
  String get email => _email;
  String get cpf => _cpf;
  String get celular => _celular;

  void updateName(String newName) {
    _name = newName;
    notifyListeners();
  }

  void updateEmail(String newEmail) {
    _email = newEmail;
    notifyListeners();
  }

   void updateCpf(String newCpf) {
    _email = newCpf;
    notifyListeners();
  }

   void updateCelular(String newCelular) {
    _email = newCelular;
    notifyListeners();
  }

  
}

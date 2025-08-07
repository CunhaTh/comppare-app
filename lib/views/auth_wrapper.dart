// lib/auth_wrapper.dart
import 'package:flutter/material.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/infra/api_services.dart'; // Importar ApiService

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Garante que AMBOS os Helpers estão inicializados e carregaram os dados do storage
    await TokenHelper().init();
    await UserHelper().init();

    // Pequeno atraso para garantir que a UI tenha tempo de renderizar o CircularProgressIndicator
    await Future.delayed(const Duration(milliseconds: 500));

    final String? token = TokenHelper().token;
    final int? userId = TokenHelper().userId;
    User? userFromHelper = UserHelper().user;

    // Condição de autenticação:
    // 1. Token deve existir e não ser vazio.
    // 2. User ID deve existir e não ser 0.
    // 3. O objeto User no UserHelper deve existir E seu ID deve corresponder ao userId do TokenHelper.
    if (token != null && token.isNotEmpty && userId != 0 && userFromHelper != null && userFromHelper.id == userId) {
      debugPrint('AuthWrapper: Autenticação completa e consistente. Navegando para PrincipalPage.');
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PrincipalPage()),
        );
      }
    } else {
      // Se qualquer parte da autenticação estiver faltando ou inconsistente,
      // limpa todos os dados e redireciona para a tela de login.
      debugPrint('AuthWrapper: Autenticação falhou ou inconsistente. Limpando dados e redirecionando para login.');
      await TokenHelper().clear();
      await UserHelper().removeUser();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

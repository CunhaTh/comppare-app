import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/principal.dart';
import 'package:flutter/material.dart';

// Importe sua tela de Landing Page/Login aqui
// No seu caso, a tela inicial para não logados parece ser MyHomePage
import 'main.dart'; 

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

// Enum para deixar o estado mais claro
enum AuthStatus { loading, authenticated, unauthenticated }

class _AuthWrapperState extends State<AuthWrapper> {
  AuthStatus _authStatus = AuthStatus.loading;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // Agora que a função de refresh está corrigida, podemos confiar no TokenHelper
    // A inicialização já deve ter sido feita no main.dart
    final tokenHelper = TokenHelper();
    
    // Simplesmente verificamos se há um token válido.
    // O refreshTokenIfNeeded será chamado em outro lugar, quando uma chamada de API for feita.
    // Ou, se preferir, pode chamá-lo aqui também para forçar uma renovação na inicialização.
    if (tokenHelper.hasToken()) {
      // Se tiver um token, consideramos autenticado por enquanto.
      // A própria PrincipalPage ou o ApiService irá lidar com um token expirado depois.
      setState(() {
        _authStatus = AuthStatus.authenticated;
      });
    } else {
      setState(() {
        _authStatus = AuthStatus.unauthenticated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_authStatus) {
      case AuthStatus.loading:
        // Enquanto verifica, mostramos uma tela de loading.
        // Pode ser a sua SplashScreen ou um simples indicador.
        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFFaed513)),
          ),
        );
      case AuthStatus.authenticated:
        // Se autenticado, mostramos a tela principal.
        return const PrincipalPage();
      case AuthStatus.unauthenticated:
        // Se não autenticado, mostramos a landing page/login.
        return const MyHomePage(title: 'Comppare');
    }
  }
}
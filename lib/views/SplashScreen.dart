import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/main.dart';
import 'package:application_progress/principal.dart';
import 'package:flutter/material.dart';
import 'package:application_progress/infra/api_services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await TokenHelper().init();
    await UserHelper().init();
    final token = TokenHelper().token;
    final user = UserHelper().user;

    if (token != null && token.isNotEmpty && user != null) {
      await ApiService().refreshTokenIfNeeded();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PrincipalPage()),
        );
      }
    } else {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MyHomePage(title: '',)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              "assets/logo_cortada.png",
              width: 150,
              height: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              color: Color(0xFFaed513),
              strokeWidth: 3,
            ),
          ],
        ),
      ),
    );
  }
}
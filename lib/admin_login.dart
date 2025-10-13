import 'package:flutter/material.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/views/admpage.dart';
import 'package:application_progress/infra/api_exception.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // WARNING: This is a simple local check for an admin route. Replace with
  // real authentication (ApiService + TokenHelper) for production.
  Future<void> _login() async {
    setState(() => _isLoading = true);
    final String cpf = _userController.text.trim();
    final String senha = _passwordController.text;
    try {
      final api = ApiService();
      final response = await api.authenticateUser(cpf, senha);
      // On success authenticateUser saves token and user via TokenHelper/UserHelper
      if (mounted) {
        // Use named route so browser URL becomes /admin/dashboard on web
        Navigator.pushReplacementNamed(context, '/admin/dashboard');
      }
    } catch (e) {
      String message = 'Erro ao autenticar. Confira credenciais.';
      if (e is ApiException) message = e.message;
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Falha de autenticação'),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fechar'))
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _userController,
                  decoration: const InputDecoration(labelText: 'Usuário'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Senha'),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading ? const CircularProgressIndicator() : const Text('Entrar como admin'),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Acesse /admin no navegador para esta tela.'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

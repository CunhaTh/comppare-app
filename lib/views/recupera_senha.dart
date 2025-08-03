import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// Importe conforme necessário

// MyApp (Ponto de entrada da aplicação)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recuperação de Senha',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const RecoverPasswordScreen(), // Inicia na tela de recuperação de senha
    );
  }
}

// RecoverPasswordScreen (Tela para solicitar a recuperação de senha via e-mail)
class RecoverPasswordScreen extends StatefulWidget {
  const RecoverPasswordScreen({super.key});

  @override
  State<RecoverPasswordScreen> createState() => _RecoverPasswordScreenState();
}

class _RecoverPasswordScreenState extends State<RecoverPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message; // Para exibir mensagens de sucesso ou erro
  bool _isSuccess = false; // Para controlar o tipo de mensagem (sucesso/erro)

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Função para validar o formato do e-mail
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // Função para enviar a requisição de recuperação de senha
  Future<void> _recuperaSenha() async {
    final email = _emailController.text.trim();

    // 1. Validação do e-mail
    if (email.isEmpty) {
      _showMessage('Por favor, digite seu e-mail.', false);
      return;
    }
    if (!_isValidEmail(email)) {
      _showMessage('Por favor, digite um e-mail válido.', false);
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null; // Limpa a mensagem anterior
    });

    try {
      final response = await http.post(
        Uri.parse('https://api.comppare.com.br/api/usuarios/esqueceu-senha'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
        }),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Tempo limite excedido ao conectar à API.');
      });

      if (response.statusCode == 200) {
        // Sucesso: Navegar para VerifyCodeScreen e passar o e-mail
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifyCodeScreen(email: email),
            ),
          );
          _emailController.clear(); // Limpa o campo de e-mail após o envio bem-sucedido
        }
      } else if (response.statusCode == 404) {
        _showMessage('E-mail não encontrado. Verifique e tente novamente.', false);
      } else if (response.statusCode == 400) {
        final errorBody = jsonDecode(response.body);
        _showMessage(errorBody['message'] ?? 'Erro na requisição. Tente novamente.', false);
      } else {
        _showMessage(
            'Erro ao recuperar a senha. Código: ${response.statusCode}. Tente novamente.',
            false);
      }
    } on Exception catch (e) {
      _showMessage('Ocorreu um erro: ${e.toString()}', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função auxiliar para mostrar mensagens ao usuário
  void _showMessage(String message, bool isSuccess) {
    setState(() {
      _message = message;
      _isSuccess = isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green[700]!, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/logo_cortada.png",
                        height: 60,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Recuperar senha',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Digite no campo abaixo o e-mail usado no cadastro para\nenvio do link com a redefinição de senha.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.email),
                    labelText: 'E-mail',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _recuperaSenha,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Enviar',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(height: 10),
                if (_message != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isSuccess ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.error,
                          color: _isSuccess ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _message!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _isSuccess ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: _isSuccess ? Colors.green[700] : Colors.red[700]),
                          onPressed: () {
                            setState(() {
                              _message = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// VerifyCodeScreen (Tela para o usuário inserir o código de verificação)
class VerifyCodeScreen extends StatefulWidget {
  final String email; // Recebe o e-mail da tela anterior

  const VerifyCodeScreen({super.key, required this.email});

  @override
  State<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends State<VerifyCodeScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool _isLoading = false; // Mantido para consistência de UI
  String? _message;
  bool _isSuccess = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  // Função para "verificar" o código (apenas valida o preenchimento e navega)
  Future<void> _verifyCodeAndNavigate() async {
    final code = _codeController.text.trim();

    if (code.isEmpty) {
      _showMessage('Por favor, digite o código de verificação.', false);
      return;
    }
    // Adicione validações adicionais para o formato do código aqui se necessário
    // Ex: if (code.length != 6) { _showMessage('O código deve ter 6 dígitos.', false); return; }

    setState(() {
      _isLoading = true; // Ativa o indicador enquanto simula o processamento
      _message = null;
    });

    // Simula um pequeno delay para a UI (como se estivesse "processando" localmente)
    await Future.delayed(const Duration(milliseconds: 500));

    // Tudo pronto, navega para a próxima tela com o email e o código
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResetPasswordScreen(
            email: widget.email, // E-mail vindo da tela anterior
            code: code,          // Código digitado nesta tela
          ),
        ),
      );
      _codeController.clear(); // Limpa o campo de código após a navegação
    }

    setState(() {
      _isLoading = false; // Desativa o indicador
    });
  }

  void _showMessage(String message, bool isSuccess) {
    setState(() {
      _message = message;
      _isSuccess = isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verificar Código'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green[700]!, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/logo_cortada.png",
                        height: 60,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Verificar código',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Digite o código enviado para o seu e-mail (${widget.email})\npara prosseguir com a redefinição de senha.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.vpn_key),
                    labelText: 'Digite o código',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyCodeAndNavigate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Confirmar',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(height: 10),
                if (_message != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isSuccess ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.error,
                          color: _isSuccess ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _message!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _isSuccess ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: _isSuccess ? Colors.green[700] : Colors.red[700]),
                          onPressed: () {
                            setState(() {
                              _message = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ResetPasswordScreen (Tela para o usuário definir a nova senha)
class ResetPasswordScreen extends StatefulWidget {
  final String email; // Recebe o e-mail da tela anterior
  final String code;  // Recebe o código de verificação da tela anterior

  const ResetPasswordScreen({super.key, required this.email, required this.code});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isSuccess = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Função para redefinir a senha via API
  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validações dos campos de senha
    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      _showMessage('Por favor, preencha todos os campos de senha.', false);
      return;
    }
    if (newPassword != confirmPassword) {
      _showMessage('As senhas não coincidem.', false);
      return;
    }
    if (newPassword.length < 6) { // Exemplo de validação de comprimento mínimo
      _showMessage('A nova senha deve ter pelo menos 6 caracteres.', false);
      return;
    }
    // TODO: Adicione validações de complexidade de senha aqui (ex: letras maiúsculas, minúsculas, números, caracteres especiais)

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      // ATENÇÃO: Endpoint ajustado conforme sua última instrução.
      // Verifique com seu backend se este é o endpoint correto para FINALIZAR a redefinição de senha.
      final response = await http.post(
        Uri.parse('https://api.comppare.com.br/api/usuarios/atualizar-senha'), // Endpoint ajustado
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': widget.email, // E-mail recebido da tela anterior
          'codigo': widget.code,   // Código de verificação recebido da tela anterior
          'senha': newPassword,  // Nova senha
        }),
      ).timeout(const Duration(seconds: 10), onTimeout: () {
        throw Exception('Tempo limite excedido ao redefinir a senha.');
      });

      if (response.statusCode == 200) {
        _showMessage('Senha redefinida com sucesso! Você pode fazer login agora.', true);
        if (mounted) {
          // Navega de volta para a primeira tela da pilha (geralmente a tela de login)
          Navigator.popUntil(context, (route) => route.isFirst);
          // Ou você pode navegar para uma tela de sucesso específica:
          // Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
        }
      } else if (response.statusCode == 400) {
        // Tenta decodificar a mensagem de erro do corpo da resposta da API
        final errorBody = jsonDecode(response.body);
        _showMessage(errorBody['message'] ?? 'Erro ao redefinir a senha. Tente novamente.', false);
      } else {
        _showMessage(
            'Erro ao redefinir a senha. Código: ${response.statusCode}. Tente novamente.',
            false);
      }
    } on Exception catch (e) {
      _showMessage('Ocorreu um erro: ${e.toString()}', false);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Função auxiliar para mostrar mensagens ao usuário
  void _showMessage(String message, bool isSuccess) {
    setState(() {
      _message = message;
      _isSuccess = isSuccess;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Redefinir Senha'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
        ),
        child: Center(
          child: Container(
            width: 300,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.green[700]!, width: 2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Image.asset(
                        "assets/logo_cortada.png",
                        height: 60,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Redefinir Senha',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Digite sua nova senha para o e-mail (${widget.email}).',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _newPasswordController,
                  obscureText: _obscureNewPassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock),
                    labelText: 'Nova Senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureNewPassword = !_obscureNewPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_reset),
                    labelText: 'Confirmar Nova Senha',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        )
                      : const Text(
                          'Redefinir Senha',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
                const SizedBox(height: 10),
                if (_message != null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _isSuccess ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isSuccess ? Icons.check_circle : Icons.error,
                          color: _isSuccess ? Colors.green[700] : Colors.red[700],
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _message!,
                            style: TextStyle(
                              fontSize: 12,
                              color: _isSuccess ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close,
                              color: _isSuccess ? Colors.green[700] : Colors.red[700]),
                          onPressed: () {
                            setState(() {
                              _message = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
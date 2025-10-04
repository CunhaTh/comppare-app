// Exemplo de como a tela de convite ficaria, chamando o serviço que criamos
import 'dart:convert';
import 'package:application_progress/infra/invitation_service.dart';
import 'package:flutter/material.dart';

 class InviteScreen extends StatefulWidget {
  final int folderId;
  final int loggedInUserId;

  const InviteScreen({required this.folderId, required this.loggedInUserId, Key? key}) : super(key: key);

  @override
  _InviteScreenState createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final TextEditingController _emailController = TextEditingController();
  final InvitationService _invitationService = InvitationService();
  bool _isLoading = false;

  Future<void> _sendInvite() async {
    if (_emailController.text.isEmpty) return;

    setState(() => _isLoading = true);

    final String email = _emailController.text;
    
    // O service agora espera que 404 signifique "Usuário não cadastrado"
    final result = await _invitationService.sendInvitation(
      email: email,
      loggedInUserId: widget.loggedInUserId,
      folderId: widget.folderId,
    );

    setState(() => _isLoading = false);

    // Exibir o resultado com SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"]),
        backgroundColor: result["success"] ? Colors.green : Colors.red,
      ),
    );
    
    if (result["success"]) {
      // Se for sucesso, pode fechar a tela ou limpar o campo
      _emailController.clear();
      // Opcional: Atualizar a lista de álbuns para mostrar o status de compartilhado
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Convidar Usuário')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Atenção: Apenas um usuário cadastrado pode ser convidado para este álbum.',
              style: TextStyle(color: Colors.orange, fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'E-mail do Convidado',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _sendInvite,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar Convite'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
} 
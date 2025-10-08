// Importações e Modelos (Mantenha o mesmo)
import 'dart:convert';
import 'package:application_progress/infra/invitation_service.dart';
import 'package:flutter/material.dart';

// 1. MODELO DE DADOS PARA USUÁRIOS COMPARTILHADOS
class Invitation {
  final int userId;
  final String email;

  Invitation({required this.userId, required this.email});

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      userId: json['userId'] as int,
      email: json['email'] as String, 
    );
  }
}

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
  
  List<Invitation> _activeInvites = [];
  bool _isInvitesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActiveInvites();
  }

  // Novo método para exclusão geral (chamado pela AppBar)
  Future<void> _handleGeneralDelete() async {
    // 1. Inicia o loading
    setState(() => _isLoading = true);

    // 2. Confirmação do usuário
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Convite Geral?'),
        content: const Text(
          'Esta ação removerá todos os convites pendentes e/ou o acesso geral ao álbum. Deseja continuar?',
          style: TextStyle(color: Colors.red),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (confirm) {
      // 3. Chama o serviço de exclusão.
      // Usamos '0' como placeholder para invitedUserId, pois o endpoint /convite/excluir
      // utiliza apenas o 'idPasta' para a exclusão geral.
      final result = await _invitationService.deleteFolderInvite(widget.folderId, widget.loggedInUserId); 
      
      // 4. Exibe o resultado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result["message"]),
          backgroundColor: result["success"] ? Colors.green : Colors.red,
        ),
      );

      // 5. Se for sucesso, recarrega a lista
      if (result["success"]) {
        _loadActiveInvites(); 
      }
    }

    // 6. Finaliza o loading
    setState(() => _isLoading = false);
  }
  
  // O restante dos métodos (_loadActiveInvites, _sendInvite, _deleteInvite)
  // permanece inalterado.
  Future<void> _loadActiveInvites() async {
    setState(() => _isInvitesLoading = true);
    
    try {
      final List<Map<String, dynamic>> data = await _invitationService.getFolderInvites(widget.folderId);
      
      setState(() {
        _activeInvites = data.map((item) => Invitation.fromJson(item)).toList();
        _isInvitesLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar convites: $e');
      setState(() => _isInvitesLoading = false);
    }
  }

  Future<void> _sendInvite() async {
    if (_emailController.text.isEmpty) return;
    setState(() => _isLoading = true);
    final String emailToSend = _emailController.text;
    
    final result = await _invitationService.sendInvitation(
      email: emailToSend,
      loggedInUserId: widget.loggedInUserId,
      folderId: widget.folderId,
    );
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"]),
        backgroundColor: result["success"] ? Colors.green : Colors.red,
      ),
    );
    
    if (result["success"]) {
      _emailController.clear();
      _loadActiveInvites(); 
    }
  }

  Future<void> _deleteInvite(int userIdToDelete, String userEmail) async {
    setState(() => _isLoading = true);
    final bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja remover o acesso de "$userEmail"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Excluir', style: TextStyle(color: Colors.red))),
        ],
      ),
    ) ?? false;

    if (!confirm) {
      setState(() => _isLoading = false);
      return;
    }

    final result = await _invitationService.deleteFolderInvite(
      widget.folderId,
      userIdToDelete,
    );

    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result["message"]),
        backgroundColor: result["success"] ? Colors.green : Colors.red,
      ),
    );

    if (result["success"]) {
      _loadActiveInvites();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 💡 IMPLEMENTAÇÃO DO BOTÃO NA APP BAR (Canto superior direito)
      appBar: AppBar(
        title: const Text('Convidar e Gerenciar Acesso'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.red), // Ícone de exclusão geral
            tooltip: 'Excluir convite geral',
            // Chama a nova função _handleGeneralDelete
            onPressed: _isLoading ? null : _handleGeneralDelete, 
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Seção de Envio de Convite
            const Text(
              'Enviar novo convite por e-mail:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
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
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _sendInvite,
                    icon: const Icon(Icons.send),
                    label: const Text('Enviar Convite'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
            
            // --- Seção de Gerenciamento de Convites ---
            const SizedBox(height: 32),
       
        // implementação da lista de usuário permitidos a ver esse album
        /*    const Text(
              'Usuários com Acesso:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 16),

            // Lista de Convites Ativos
            Expanded(
              child: _buildInvitesList(),
            ), */
          ],
        ),
      ),
    );
  }

 /* Widget _buildInvitesList() {
    if (_isInvitesLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_activeInvites.isEmpty) {
      return const Center(child: Text('Nenhum usuário convidado ainda.'));
    }

    return ListView.builder(
      itemCount: _activeInvites.length,
      itemBuilder: (context, index) {
        final invite = _activeInvites[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.person),
            title: Text(
              invite.email,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              tooltip: 'Remover acesso',
              onPressed: _isLoading 
                  ? null 
                  : () => _deleteInvite(invite.userId, invite.email),
            ),
          ),
        );
      },
    );
  }*/
}
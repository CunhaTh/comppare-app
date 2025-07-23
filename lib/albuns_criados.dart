// lib/albuns_criados.dart

import 'package:flutter/material.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/models/folder_model.dart'; // Importa o modelo Folder
import 'package:application_progress/models/image_model.dart'; // Importa o modelo ImageModel

class AlbunsCriadosPage extends StatefulWidget {
  final String initialFolderName; // Nome da pasta principal (do PrincipalPage)
  final int initialFolderId; // ID da pasta selecionada
  final String folderApiPath; // Caminho da pasta (não será mais usado diretamente para buscar imagens)

  const AlbunsCriadosPage({
    super.key,
    required this.initialFolderName,
    required this.initialFolderId,
    required this.folderApiPath,
  });

  @override
  _AlbunsCriadosPageState createState() => _AlbunsCriadosPageState();
}

class _AlbunsCriadosPageState extends State<AlbunsCriadosPage> {
  final ApiService _apiService = ApiService();
  Folder? _currentFolderDetails; // Para armazenar os detalhes completos da pasta
  bool _isLoadingDetails = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchFolderDetails();
  }

  Future<void> _fetchFolderDetails() async {
    setState(() {
      _isLoadingDetails = true;
      _errorMessage = '';
    });

    try {
      // Usa o ApiService para buscar os detalhes da pasta específica pelo ID
      final Folder fetchedFolder = await _apiService.getFolderDetails(widget.initialFolderId);
      if (mounted) {
        setState(() {
          _currentFolderDetails = fetchedFolder;
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar detalhes da pasta: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Não foi possível carregar o conteúdo da pasta. Tente novamente.';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDetails = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Usa o nome da subpasta para o título da AppBar
        title: Text(
          _currentFolderDetails?.principalPageDisplayName ?? widget.initialFolderName,
          style: const TextStyle(color: Colors.black),
        ),
        backgroundColor: const Color(0xFFaed513),
        iconTheme: const IconThemeData(color: Colors.black), // Cor do ícone de voltar
      ),
      backgroundColor: Colors.black, // Fundo preto
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFaed513)))
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                )
              : _currentFolderDetails == null || _currentFolderDetails!.imagens!.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhuma imagem encontrada nesta pasta "${_currentFolderDetails?.principalPageDisplayName ?? ''}".',
                        style: const TextStyle(color: Colors.white54, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 imagens por linha
                        crossAxisSpacing: 8.0, // Espaçamento horizontal
                        mainAxisSpacing: 8.0, // Espaçamento vertical
                      ),
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _currentFolderDetails!.imagens!.length,
                      itemBuilder: (context, index) {
                        final image = _currentFolderDetails!.imagens![index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12.0), // Cantos arredondados
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(
                                image.path,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: const Color(0xFFaed513),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: const Icon(Icons.broken_image, color: Colors.white54, size: 50),
                                  );
                                },
                              ),
                              // Opcional: Adicionar um overlay com o nome da imagem ou data
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                  color: Colors.black54,
                                  child: Text(
                                    'ID: ${image.id} - ${image.takenAt!.split('/')[0]}', // Exemplo: ID e data
                                    style: const TextStyle(color: Colors.white, fontSize: 12),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

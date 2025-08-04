import 'package:application_progress/login.dart';
import 'package:application_progress/models/folder_model.dart';
import 'package:flutter/material.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'dart:developer' as devtools;

class AlbumState extends ChangeNotifier {
  List<Folder> _imageGroups = [];
  bool _isLoading = true;
  final ApiService _apiService;

  AlbumState({required ApiService apiService}) : _apiService = apiService;

  List<Folder> get imageGroups => _imageGroups;
  bool get isLoading => _isLoading;

  Future<void> fetchSubfolders(int folderId, BuildContext context) async {
    _isLoading = true;
    notifyListeners(); // Notifica a UI que o estado de carregamento mudou

    final int userId = TokenHelper().userId;

    if (!TokenHelper().hasToken() || userId == 0) {
      _handleAuthError(context);
      return;
    }

    try {
      final fetchedGroups = await _apiService.fetchSubfolders(folderId);
      _imageGroups = fetchedGroups;
      devtools.log('Subálbuns carregados: ${_imageGroups.map((g) => g.nome).join(', ')}');
    } on ApiException catch (e) {
      devtools.log('Erro na API ao carregar subálbuns: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar subálbuns: ${e.message}')),
      );
      if (e.statusCode == 401) {
        _handleAuthError(context);
      }
    } catch (e) {
      devtools.log('Erro inesperado ao carregar subálbuns: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado ao carregar subálbuns: ${e.toString()}')),
      );
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifica a UI que o carregamento terminou
    }
  }

  Future<void> createSubalbum({
    required String folderName,
    required List<String> tags,
    required int parentFolderId,
    required String parentPath,
    required BuildContext context,
  }) async {
    final int userId = TokenHelper().userId;
    if (!TokenHelper().hasToken() || userId == 0) {
      _handleAuthError(context);
      return;
    }

    try {
      final parentPathWithoutUser = parentPath.split('/').skip(1).join('/');
      final fullFolderNameForApi = "$parentPathWithoutUser/$folderName";
      devtools.log('Tentando criar subálbum com nome: $fullFolderNameForApi');

      final newFolderId = await _apiService.createSubFolder(
        folderName: fullFolderNameForApi,
        tags: tags,
        parentFolderId: parentFolderId, 
        idUsuario: userId, parentFolderPath: parentPath,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subálbum criado com sucesso!')),
      );

      // Recarrega os subálbuns para incluir o novo
      await fetchSubfolders(parentFolderId, context);
    } on ApiException catch (e) {
      devtools.log('Erro ao criar subálbum: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao criar subálbum: ${e.message}')),
      );
      if (e.statusCode == 401) {
        _handleAuthError(context);
      }
    } catch (e) {
      devtools.log('Erro inesperado ao criar subálbum: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado ao criar subálbum: ${e.toString()}')),
      );
    }
  }

  void _handleAuthError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Erro: Usuário não logado. Redirecionando...')),
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
}
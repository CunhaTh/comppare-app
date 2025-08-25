import 'dart:collection';
import 'dart:convert';
import 'package:application_progress/infra/api_endponts.dart';
import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/models/tag_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as foundation;
import 'package:http/http.dart' as _httpClient;
import 'package:shared_preferences/shared_preferences.dart';

class CreateTagsPage extends StatefulWidget {
  const CreateTagsPage({super.key});

  @override
  State<CreateTagsPage> createState() => _CreateTagsPageState();
}

class _CreateTagsPageState extends State<CreateTagsPage> {
  final _tagsController = TextEditingController();
  bool _isLoading = false;
  List<TagModel> _tags = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  
  Future<void> _loadTags() async {
    final user = UserHelper().user;
    if (user == null || user.id == null) {
      _navigateToLogin();
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // getTags agora deve retornar uma List<TagModel>
      final tagsFromApi = await _apiService.getTags(user.id!);
      
      // Armazena a lista de TagModel no estado
      if (mounted) {
        setState(() {
          _tags = tagsFromApi.cast<TagModel>();
          debugPrint('Tags carregadas do servidor: ${_tags.map((t) => t.nomeTag).toList()}');
        });
      }
      
      // Salva a lista de objetos TagModel, convertendo para JSON antes de salvar.
      final tagsJsonList = tagsFromApi.map((tag) => jsonEncode({'id': tag, 'nomeTag': tag})).toList();
      await _saveTagsLocally('user_${user.id}_tags', tagsJsonList);
      await _saveGlobalTags(tagsJsonList);
      await UserHelper().setUserTags(tagsFromApi.map((t) => t).cast<String>().toList());

    } catch (e) {
      debugPrint('Erro ao carregar tags: $e');
      // Tentativa de carregar do cache local em caso de falha na API
      final prefs = await SharedPreferences.getInstance();
      final tagsKey = 'user_${user.id}_tags';
      final tagsString = prefs.getString(tagsKey);
      if (tagsString != null && mounted) {
        try {
          final localTags = (jsonDecode(tagsString) as List<dynamic>).map((e) => TagModel.fromJson(jsonDecode(e))).toList();
          setState(() {
            _tags = localTags;
            debugPrint('Tags carregadas do cache local (fallback): ${_tags.map((t) => t.nomeTag).toList()}');
          });
        } catch (e) {
           debugPrint('Erro ao parsear tags do cache local: $e');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveTagsLocally(String key, List<String> tagsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(tagsJson));
    debugPrint('Tags salvas localmente para chave $key: ${tagsJson.join(",")}');
  }
  
  Future<void> _saveGlobalTags(List<String> tagsJson) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('global_tags', jsonEncode(tagsJson));
    debugPrint('Tags globais salvas: ${tagsJson.join(",")}');
  }

  Future<void> _createTagsOnApi(String nomeTag) async {
    final user = UserHelper().user;
    if (user == null || user.id == null) {
      _navigateToLogin();
      return;
    }
    try {
      await _apiService.refreshTokenIfNeeded();
      final response = await _apiService.saveTags(
        nomeTag: nomeTag,
        usuario: user.id!,
      );
      debugPrint('Tags sincronizadas com a API: ${response['message']}');
      if (response['codRetorno'] == 201) {
        await _loadTags(); // Recarrega após sucesso
      }
    } catch (e) {
      debugPrint('Erro ao sincronizar tags com a API: $e');
      if (e is ApiException && e.statusCode == 401) {
        _navigateToLogin();
      } else if (mounted) {
        _showErrorDialog('Falha ao salvar tags no servidor: $e');
      }
    }
  }



  Future<void> _createTags() async {
    final tagsString = _tagsController.text.trim();
    if (tagsString.isEmpty) {
      _showErrorDialog('As tags não podem estar vazias.');
      return;
    }

    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final tags = tagsString.split(',').map((tag) => tag.trim()).where((tag) {
        if (tag.isEmpty) return false;
        if (tag.length > 20) {
          _showErrorDialog('As tags devem ter no máximo 20 caracteres.');
          return false;
        }
        if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(tag)) {
          _showErrorDialog('As tags só podem conter letras, números e underline (_).');
          return false;
        }
        return true;
      }).toList();

      if (tags.isEmpty) {
        _showErrorDialog('Nenhuma tag válida foi fornecida.');
        return;
      }

      final uniqueTags = tags.join(',');
      await _createTagsOnApi(uniqueTags);

      if (mounted) {
        setState(() {
          _tagsController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Categorias criadas com sucesso: $uniqueTags')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao criar Categoria: $e');
      if (mounted) {
        _showErrorDialog('Falha ao criar categoria: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

    Future<void> _handleDeleteTag(TagModel tag) async {
    try {
      // Chama a função da classe ApiService, passando o ID da tag.
      await _apiService.deleteTag(tag.id, tag.nomeTag);
      
      // Se a chamada for bem-sucedida, você pode recarregar a lista de tags
      // ou remover a tag da lista local.
      // Por exemplo:
      setState(() {
        // Remove a tag da lista local
        _tags.removeWhere((t) => t.id == tag.id);
      });

      // Exibe uma mensagem de sucesso
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tag "${tag.nomeTag}" excluída com sucesso!'))
      );

    } catch (e) {
      // Exibe uma mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao excluir tag: $e'))
      );
    }
  }


  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 520 && MediaQuery.of(context).size.height > 889;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Categoria'),
        backgroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Insira as Categorias',
              style: TextStyle(fontSize: 16 * MediaQuery.of(context).textScaleFactor),
            ),
            SizedBox(height: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                hintText: 'Ex.: treino, dieta, progresso',
                border: const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028,
                  vertical: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022,
                ),
              ),
              enabled: !_isLoading,
            ),
            SizedBox(height: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createTags,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFaed513),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.044,
                    vertical: isLargeScreen ? screenWidth * 0.025 : screenWidth * 0.033,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Criar Categoria',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            SizedBox(height: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
            Expanded(
              child: ListView.builder(
                itemCount: _tags.length,
                itemBuilder: (context, index) {
                  final tag = _tags[index];
                  return ListTile(
                    title: Text(
                      tag.nomeTag,
                      style: TextStyle(
                        // ignore: deprecated_member_use
                        fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        // Passando o ID e o nome da tag para a nova função
                        await _handleDeleteTag(tag);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
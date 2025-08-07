import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateTagsPage extends StatefulWidget {
  const CreateTagsPage({super.key});

  @override
  State<CreateTagsPage> createState() => _CreateTagsPageState();
}

class _CreateTagsPageState extends State<CreateTagsPage> {
  final _tagsController = TextEditingController();
  bool _isLoading = false;
  List<String> _tags = [];

  @override
  void initState() {
    super.initState();
    _loadTags();
  }

  Future<void> _loadTags() async {
    final prefs = await SharedPreferences.getInstance();
    final tagsString = prefs.getString('global_tags');
    if (tagsString != null) {
      setState(() {
        _tags = (jsonDecode(tagsString) as List<dynamic>).map((e) => e.toString()).toList();
      });
    }
  }

  Future<void> _saveTags(String key, List<String> tags) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(tags));
    debugPrint('Tags salvas localmente para chave $key: ${tags.join(",")}');
  }

  Future<void> _createTags() async {
    final tagsString = _tagsController.text.trim();
    if (tagsString.isEmpty) {
      _showErrorDialog('As tags não podem estar vazias.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final tags = tagsString.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
      if (tags.isEmpty) {
        _showErrorDialog('Nenhuma tag válida foi fornecida.');
        return;
      }

      // Remover duplicatas mantendo a ordem
      // ignore: prefer_collection_literals
      final uniqueTags = LinkedHashSet<String>.from([..._tags, ...tags]).toList();
      await _saveTags('global_tags', uniqueTags);

      if (mounted) {
        setState(() {
          _tags = uniqueTags;
          _tagsController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tags criadas com sucesso: ${uniqueTags.join(",")}')),
        );
      }
    } catch (e) {
      debugPrint('Erro ao criar tags: $e');
      if (mounted) {
        _showErrorDialog('Falha ao criar tags: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    // Lógica de navegação para login, se necessário
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
                      tag,
                      style: TextStyle(
                        fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                        color: Colors.black87,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _tags.removeAt(index);
                          _saveTags('global_tags', _tags);
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Tag "$tag" removida com sucesso')),
                        );
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
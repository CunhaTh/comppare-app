import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/models/image_model.dart';
import 'package:application_progress/principal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as devtools;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:html' as html; // Para web, se aplicável
import 'package:application_progress/main.dart' as main_app;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImagemDetalhesPage extends StatefulWidget {
  final List<ImageModel> images;
  final List<String> categorias;
  final String subAlbumName;

  const ImagemDetalhesPage({
    super.key,
    required this.images,
    required this.categorias,
    required this.subAlbumName,
  });

  @override
  State<ImagemDetalhesPage> createState() => _ImagemDetalhesPageState();
}

class _ImagemDetalhesPageState extends State<ImagemDetalhesPage>
    with TickerProviderStateMixin {
  late Future<List<ImageModel>> _imageItemsFuture;
  late List<String> categorias;
  final ScrollController _scrollController = ScrollController();
  int? _selectedIndex;
  List<ImageModel> allSelectedImages = [];
  List<ImageModel>? _imageItems;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final ApiService _apiService = ApiService(httpClient: http.Client());

  // Função para deletar imagens selecionadas
  Future<void> deleteImageList() async {
    final selectedImages =
        _imageItems?.where((image) => image.isSelected).toList() ?? [];
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Selecione pelo menos uma imagem para deletar.')),
      );
      return;
    }

    // Confirmação
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text(
              'Tem certeza que deseja excluir as imagens selecionadas? Esta ação não poderá ser desfeita.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      _isLoading =
          true; // Adicione _isLoading como variável de estado se não existir
    });

    try {
      // Deletar cada imagem na API
      for (final image in selectedImages) {
        await _apiService.deleteImage(image.id,
            selectedImages.first as int); // Substitua pelo método real da API
      }

      // Atualizar a lista local removendo as imagens deletadas
      if (_imageItems != null) {
        _imageItems!.removeWhere((image) => selectedImages.contains(image));
      }

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Imagens deletadas com sucesso!')),
      );
    } catch (e) {
      debugPrint('Erro ao deletar imagens: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Erro ao deletar imagens. Tente novamente.')),
      );
    } finally {
      setState(() {
        _isLoading =
            false; // Adicione _isLoading como variável de estado se não existir
      });
    }
  }

  Future<Uint8List?> _loadImageBytesFromUrl(String url) async {
    try {
      debugPrint('Tentando carregar imagem da URL: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null &&
            (contentType.startsWith('image/') ||
                contentType == 'application/octet-stream')) {
          if (response.bodyBytes.isNotEmpty) {
            debugPrint(
                'Imagem carregada com sucesso da URL: $url. Tamanho: ${response.bodyBytes.length} bytes.');
            return response.bodyBytes;
          }
        }
        debugPrint(
            'Falha ao carregar imagem da URL: $url. Content-Type inesperado ou corpo vazio.');
        return null;
      }
      debugPrint(
          'Falha ao carregar imagem da URL: $url com status ${response.statusCode}.');
      return null;
    } catch (e) {
      debugPrint('Erro ao carregar imagem da URL $url: $e');
      return null;
    }
  }

  Future<List<ImageModel>> _prepareImageItems() async {
    List<ImageModel> items = [];
    for (int i = 0; i < widget.images.length; i++) {
      final ImageModel myImage = widget.images[i];
      Uint8List? imageData;

      devtools.debugPrint(
          'Processando MyImage ID: ${myImage.id}, Path: ${myImage.url}');

      imageData = await _loadImageBytesFromUrl(myImage.url);
      if (imageData != null && imageData.isNotEmpty) {
        devtools.debugPrint(
            'Bytes carregados da URL para ID: ${myImage.id}. Tamanho: ${imageData.length} bytes.');
      } else {
        devtools.debugPrint(
            'ATENÇÃO: Não foi possível obter dados válidos para a imagem ID: ${myImage.id}, Path: ${myImage.url}. Usando placeholder.');
        imageData = Uint8List(0);
      }

      items.add(ImageModel.fromMyImage(myImage, imageData: imageData));
      debugPrint(
          'Preparando imagem com URL: ${myImage.url}, imageData: ${myImage.imageData != null}');
    }
    _imageItems = items.cast<ImageModel>();
    return items;
  }

  Uint8List? _placeholderBytes;

  @override
  void initState() {
    super.initState();
    categorias = widget.categorias;
    _imageItemsFuture = _prepareImageItems();

    // Inicializar animações
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - (MediaQuery.of(context).size.width * 0.33),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + (MediaQuery.of(context).size.width * 0.33),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Widget _buildImageCard(ImageModel imageItem, int index, bool isLargeScreen,
      double screenWidth, double screenHeight) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.all(isLargeScreen ? 8.0 : 6.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        imageItem.isSelected = !imageItem.isSelected;
                      });
                      _scaleController.forward().then((_) {
                        _scaleController.reverse();
                      });
                    },
                    child: AnimatedBuilder(
                      animation: _scaleAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: imageItem.isSelected
                              ? _scaleAnimation.value
                              : 1.0,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: imageItem.isSelected
                                    ? const Color(0xFFaed513)
                                    : Colors.grey.withOpacity(0.3),
                                width: imageItem.isSelected ? 3.0 : 1.0,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15.0),
                              child: Stack(
                                children: [
                                  Image.memory(
                                    imageItem.imageData!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint(
                                          'Erro ao renderizar imagem do GridView: $error');
                                      return Container(
                                        color: Colors.grey[200],
                                        child: const Center(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error,
                                                  color: Colors.red, size: 40),
                                              SizedBox(height: 8),
                                              Text('Erro de imagem',
                                                  style: TextStyle(
                                                      color: Colors.red)),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  if (imageItem.isSelected)
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFaed513),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check,
                                          color: Colors.black,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 12.0 : 8.0,
                    vertical: isLargeScreen ? 8.0 : 6.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _showEditDialog(context, imageItem, index),
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeScreen ? 12.0 : 8.0,
                              vertical: isLargeScreen ? 8.0 : 6.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: Colors.black,
                                  size: isLargeScreen ? 16.0 : 14.0,
                                ),
                                SizedBox(width: isLargeScreen ? 6.0 : 4.0),
                                Text(
                                  'Editar',
                                  style: TextStyle(
                                    fontSize: isLargeScreen ? 14.0 : 12.0,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildComppareButton(bool isLargeScreen, double screenWidth,
      double screenHeight, List<ImageModel> loadedImageItems) {
    final selectedCount =
        loadedImageItems.where((item) => item.isSelected).length;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.all(isLargeScreen ? 16.0 : 12.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFaed513).withOpacity(0.3),
                    blurRadius: 12.0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _showComparisonDialog(context, loadedImageItems,
                      categorias, widget.subAlbumName),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? 24.0 : 20.0,
                      vertical: isLargeScreen ? 16.0 : 14.0,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFaed513), Color(0xFF9bc412)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.compare,
                          color: Colors.black,
                          size: isLargeScreen ? 24.0 : 20.0,
                        ),
                        SizedBox(width: isLargeScreen ? 12.0 : 8.0),
                        Text(
                          'Comppare',
                          style: TextStyle(
                            fontSize: isLargeScreen ? 18.0 : 16.0,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (selectedCount > 0) ...[
                          SizedBox(width: isLargeScreen ? 12.0 : 8.0),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeScreen ? 8.0 : 6.0,
                              vertical: isLargeScreen ? 4.0 : 3.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              '$selectedCount',
                              style: TextStyle(
                                fontSize: isLargeScreen ? 14.0 : 12.0,
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.black),
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const PrincipalPage()),
              (Route<dynamic> route) => false,
            );
          },
        ),
        title: Center(
          child: Image.asset(
            "assets/logo_cortada.png",
            width: isLargeScreen ? screenWidth * 0.25 : screenWidth * 0.35,
            height: isLargeScreen ? screenHeight * 0.04 : screenHeight * 0.06,
            fit: BoxFit.contain,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: isLargeScreen ? 16.0 : 12.0),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.exit_to_app, color: Colors.black),
              ),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const main_app.MyHomePage(title: ''),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<ImageModel>>(
        future: _imageItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFaed513).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFaed513)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando imagens...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erro ao carregar imagens',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.grey,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhuma imagem encontrada',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Adicione imagens para começar a comparar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            );
          } else {
            final List<ImageModel> loadedImageItems =
                snapshot.data!.cast<ImageModel>();
            return Stack(
              children: [
                Container(
                  padding: EdgeInsets.only(
                    left: isLargeScreen ? 16.0 : 12.0,
                    right: isLargeScreen ? 16.0 : 12.0,
                    top: isLargeScreen ? 16.0 : 12.0,
                    bottom: isLargeScreen ? 100.0 : 80.0, // Espaço para o botão
                  ),
                  child: GridView.builder(
                    controller: _scrollController,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount:
                          (screenWidth / (isLargeScreen ? 220 : 180))
                              .floor()
                              .clamp(1, 3),
                      childAspectRatio: 0.85,
                      crossAxisSpacing: isLargeScreen ? 16.0 : 12.0,
                      mainAxisSpacing: isLargeScreen ? 16.0 : 12.0,
                    ),
                    itemCount: loadedImageItems.length,
                    itemBuilder: (context, index) {
                      final imageItem = loadedImageItems[index];
                      return _buildImageCard(imageItem, index, isLargeScreen,
                          screenWidth, screenHeight);
                    },
                  ),
                ),
                // Botão Comppare no rodapé
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildComppareButton(isLargeScreen, screenWidth,
                      screenHeight, loadedImageItems),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFaed513).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFFaed513),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sucesso',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFFaed513),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Erro',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Color(0xFFaed513),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, ImageModel imageItem, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;

    final Map<String, TextEditingController> controllers = {
      for (var categoria in categorias)
        categoria: TextEditingController(
          text: categoria == 'Data'
              ? imageItem.date ?? ''
              : categoria == 'Peso'
                  ? imageItem.weight ?? ''
                  : categoria == 'Série'
                      ? imageItem.waist ?? ''
                      : categoria == 'Obs'
                          ? imageItem.observation ?? ''
                          : imageItem.customCategorias[categoria] ?? '',
        ),
    };

    Future<void> saveChanges(ImageModel updatedItem) async {
      final prefs = await SharedPreferences.getInstance();
      final categoriaKey = 'image_tags_${updatedItem.id}';
      final existingCategorias =
          jsonDecode(prefs.getString(categoriaKey) ?? '{}')
                  as Map<String, dynamic>? ??
              {};
      final updatedCategorias = {
        'Data': controllers['Data']?.text ?? updatedItem.date ?? '',
        'Peso': controllers['Peso']?.text ?? updatedItem.weight ?? '',
        'Série': controllers['Série']?.text ?? updatedItem.waist ?? '',
        'Obs': controllers['Obs']?.text ?? updatedItem.observation ?? '',
        for (var categoria in categorias)
          if (categoria != 'Data' &&
              categoria != 'Peso' &&
              categoria != 'Série' &&
              categoria != 'Obs')
            categoria: controllers[categoria]!.text,
      };
      await prefs.setString(categoriaKey, jsonEncode(updatedCategorias));

      setState(() {
        if (_imageItems != null && index >= 0 && index < _imageItems!.length) {
          _imageItems![index] = ImageModel(
            id: updatedItem.id,
            url: updatedItem.url,
            imageData: updatedItem.imageData,
            date: updatedCategorias['Data'],
            weight: updatedCategorias['Peso'],
            waist: updatedCategorias['Série'],
            observation: updatedCategorias['Obs'],
            customCategorias: {
              for (var categoria in categorias)
                if (categoria != 'Data' &&
                    categoria != 'Peso' &&
                    categoria != 'Série' &&
                    categoria != 'Obs')
                  categoria: updatedCategorias[categoria]!,
            },
            takenAt: updatedItem.toString(),
            isSelected: updatedItem.isSelected,
          );
        }
      });
      Navigator.of(context).pop(updatedItem);
    }

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              width: isLargeScreen ? screenWidth * 0.8 : screenWidth * 0.95,
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.8,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFaed513),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Editar Imagem',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 20.0 : 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: isLargeScreen
                                ? screenHeight * 0.3
                                : screenHeight * 0.25,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8.0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: imageItem.imageData!.isNotEmpty
                                  ? Image.memory(
                                      imageItem.imageData!,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.image_not_supported,
                                                color: Colors.grey, size: 48),
                                            SizedBox(height: 8),
                                            Text('Imagem não disponível',
                                                style: TextStyle(
                                                    color: Colors.grey)),
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          SizedBox(height: isLargeScreen ? 24.0 : 20.0),
                          if (categorias.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: categorias.map((categoria) {
                                return Container(
                                  margin: EdgeInsets.only(
                                      bottom: isLargeScreen ? 16.0 : 12.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        categoria,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: isLargeScreen ? 16.0 : 14.0,
                                          color: Colors.black,
                                        ),
                                      ),
                                      SizedBox(height: 8.0),
                                      TextField(
                                        controller: controllers[categoria],
                                        decoration: InputDecoration(
                                          hintText:
                                              'Insira o valor para $categoria',
                                          filled: true,
                                          fillColor: Colors.grey[50],
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            borderSide: BorderSide(
                                                color: Colors.grey[300]!),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            borderSide: BorderSide(
                                                color: Colors.grey[300]!),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            borderSide: const BorderSide(
                                                color: Color(0xFFaed513),
                                                width: 2),
                                          ),
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                            vertical: 12.0,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            Container(
                              padding:
                                  EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline,
                                      color: Colors.grey, size: 20),
                                  SizedBox(width: 12),
                                  Text(
                                    'Sem categorias disponíveis no momento.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: isLargeScreen ? 14.0 : 12.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: isLargeScreen ? 16.0 : 14.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel,
                                      size: isLargeScreen ? 18.0 : 16.0),
                                  SizedBox(width: 8.0),
                                  Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isLargeScreen ? 16.0 : 14.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFaed513),
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: isLargeScreen ? 16.0 : 14.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 2,
                              ),
                              onPressed: () {
                                final updatedItem = ImageModel(
                                  id: imageItem.id,
                                  url: imageItem.url,
                                  imageData: imageItem.imageData,
                                  date: controllers['Data']?.text ??
                                      imageItem.date,
                                  weight: controllers['Peso']?.text ??
                                      imageItem.weight,
                                  waist: controllers['Série']?.text ??
                                      imageItem.waist,
                                  observation: controllers['Obs']?.text ??
                                      imageItem.observation,
                                  customCategorias: {
                                    ...imageItem.customCategorias,
                                    for (var categoria in categorias)
                                      if (categoria != 'Data' &&
                                          categoria != 'Peso' &&
                                          categoria != 'Série' &&
                                          categoria != 'Obs')
                                        categoria: controllers[categoria]!.text,
                                  },
                                  takenAt: '',
                                );
                                saveChanges(updatedItem);
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save,
                                      size: isLargeScreen ? 18.0 : 16.0),
                                  SizedBox(width: 8.0),
                                  Text(
                                    'Salvar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isLargeScreen ? 16.0 : 14.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }).then((updatedItem) {
      // Feedback opcional
    });
  }

// Substitua o método _showComparisonDialog em lib/views/comppareimg.dart
  void _showComparisonDialog(
      BuildContext context,
      List<ImageModel> imagesToCompare,
      List<String> categorias,
      String subAlbumName) async {
    final GlobalKey repaintKey = GlobalKey();
    final GlobalKey shareRepaintKey = GlobalKey();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;

    final List<ImageModel> selectedImages =
        imagesToCompare.where((item) => item.isSelected).toList();
    if (selectedImages.length < 2) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Atenção',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: const Text(
              'Selecione pelo menos 2 imagens para comparar.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Color(0xFFaed513),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    List<ImageModel> displayedImages = [
      selectedImages[0],
      selectedImages[1],
    ];
    final List<ImageModel> allSelectedImages = List.from(
        selectedImages); // Todas as imagens selecionadas para miniaturas

    final Map<String, List<TextEditingController>> controllers = {
      for (var categoria in categorias)
        categoria: displayedImages.asMap().entries.map((entry) {
          final ImageModel item = entry.value;
          switch (categoria) {
            case 'Data':
              return TextEditingController(text: item.date ?? '');
            case 'Peso':
              return TextEditingController(text: item.weight ?? '');
            case 'Cintura':
              return TextEditingController(text: item.waist ?? '');
            case 'Obs':
              return TextEditingController(text: item.observation ?? '');
            default:
              return TextEditingController(
                  text: item.customCategorias[categoria] ?? '');
          }
        }).toList(),
    };

    Future<Uint8List?> captureCard(GlobalKey key) async {
      try {
        RenderRepaintBoundary boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData =
            await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      } catch (e) {
        devtools.debugPrint("Erro ao capturar o card: $e");
        return null;
      }
    }

    Future<void> shareImages() async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Container(
              width: isLargeScreen ? screenWidth * 0.9 : screenWidth * 0.95,
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.85,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20.0),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
                    decoration: const BoxDecoration(
                      color: Color(0xFFaed513),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(20.0),
                        topRight: Radius.circular(20.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.share,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Compartilhar Comparação',
                              style: TextStyle(
                                fontSize: isLargeScreen ? 18.0 : 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.black,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isLargeScreen ? 8.0 : 6.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Preview da imagem
                          Container(
                            margin: EdgeInsets.only(
                                bottom: isLargeScreen ? 8.0 : 6.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8.0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16.0),
                              child: RepaintBoundary(
                                key: shareRepaintKey,
                                child: Container(
                                  color: Colors.white,
                                  padding:
                                      EdgeInsets.all(isLargeScreen ? 8.0 : 6.0)
                                          .copyWith(right: 0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      // Container principal das imagens
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        height: isLargeScreen ? 300.0 : 250.0,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children:
                                              displayedImages.map((imageItem) {
                                            return Container(
                                              color: Colors.red,
                                              child: Image.memory(
                                                imageItem.imageData!,
                                                fit: BoxFit.contain,
                                                //  width: double.infinity,
                                                height: double.infinity,
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                      SizedBox(
                                          height: isLargeScreen ? 16.0 : 12.0),
                                      // Logo do Comppare
                                      Image.asset(
                                        "assets/logo_cortada.png",
                                        width: isLargeScreen ? 80.0 : 60.0,
                                        height: isLargeScreen ? 40.0 : 30.0,
                                        fit: BoxFit.contain,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Informações do compartilhamento
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: const Color(0xFFaed513),
                                  size: isLargeScreen ? 20.0 : 18.0,
                                ),
                                SizedBox(width: 12.0),
                                Expanded(
                                  child: Text(
                                    'Esta imagem será compartilhada com a logo do Comppare e as informações das imagens selecionadas.',
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 14.0 : 12.0,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(20.0),
                        bottomRight: Radius.circular(20.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: isLargeScreen ? 16.0 : 14.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.cancel,
                                      size: isLargeScreen ? 18.0 : 16.0),
                                  SizedBox(width: 8.0),
                                  Text(
                                    'Cancelar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: isLargeScreen ? 16.0 : 14.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 8.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFaed513),
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: isLargeScreen ? 16.0 : 14.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                elevation: 2,
                              ),
                              onPressed: () async {
                                Navigator.of(context).pop();

                                // Mostrar loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) {
                                    return Dialog(
                                      backgroundColor: Colors.transparent,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const CircularProgressIndicator(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                      Color(0xFFaed513)),
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              'Preparando compartilhamento...',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                );

                                final Uint8List? imageBytes =
                                    await captureCard(shareRepaintKey);

                                // Fechar loading
                                Navigator.of(context).pop();

                                if (imageBytes == null) {
                                  _showErrorDialog(
                                      'Erro ao capturar a imagem para compartilhamento.');
                                  return;
                                }

                                try {
                                  if (kIsWeb) {
                                    final blob =
                                        html.Blob([imageBytes], 'image/png');
                                    final url =
                                        html.Url.createObjectUrlFromBlob(blob);
                                    final anchor = html.AnchorElement(href: url)
                                      ..setAttribute('download',
                                          'comppare_comparison_${DateTime.now().millisecondsSinceEpoch}.png')
                                      ..click();
                                    html.Url.revokeObjectUrl(url);
                                    _showSuccessDialog(
                                        'Imagem baixada com sucesso! Compartilhe manualmente.');
                                  } else {
                                    final tempDir =
                                        await getTemporaryDirectory();
                                    final file = await File(
                                            '${tempDir.path}/comppare_comparison_${DateTime.now().millisecondsSinceEpoch}.png')
                                        .writeAsBytes(imageBytes);
                                    final xFile = XFile(file.path);
                                    await Share.shareXFiles(
                                      [xFile],
                                      text:
                                          'Confira minha comparação de progresso no Comppare! 💪',
                                      subject:
                                          'Comparação de Progresso - Comppare',
                                    );
                                    _showSuccessDialog(
                                        'Compartilhamento iniciado com sucesso!');
                                  }
                                } catch (e) {
                                  _showErrorDialog('Erro ao compartilhar: $e');
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.share,
                                      size: isLargeScreen ? 18.0 : 16.0),
                                  SizedBox(width: 8.0),
                                  Text(
                                    'Compartilhar',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: isLargeScreen ? 16.0 : 14.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    Future<void> saveCard() async {
      final Uint8List? imageBytes = await captureCard(repaintKey);
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Erro ao capturar o card para salvamento.')),
        );
        return;
      }

      if (kIsWeb) {
        final blob = html.Blob([imageBytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download',
              'comparison_card_${DateTime.now().millisecondsSinceEpoch}.png')
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem baixada com sucesso!')),
        );
      } else {
        final result = await ImageGallerySaver.saveImage(
          imageBytes,
          quality: 100,
          name: "comparison_card_${DateTime.now().millisecondsSinceEpoch}",
        );
        if (result['isSuccess']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Card salvo na galeria com sucesso!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Erro ao salvar o card na galeria.')),
          );
        }
      }
    }

    final ScrollController localScrollController =
        ScrollController(); // Usar um controller local para o diálogo

    // Funções de scroll para as miniaturas
    void scrollLeft() {
      localScrollController.animateTo(
        localScrollController.offset -
            (screenWidth *
                0.25), // Ajuste o valor de scroll conforme necessário
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    void scrollRight() {
      localScrollController.animateTo(
        localScrollController.offset +
            (screenWidth *
                0.25), // Ajuste o valor de scroll conforme necessário
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(isLargeScreen ? 16.0 : 8.0),
          child: Container(
            width: screenWidth * 0.98,
            height: screenHeight * 0.95,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20.0),
              color: Colors.white,
            ),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                // Inicializa _selectedIndex com a primeira imagem exibida
                int? selectedIndex;
                // Encontra o índice da primeira imagem exibida na lista original 'allSelectedImages'
                selectedIndex = allSelectedImages.indexOf(displayedImages[0]);
                if (selectedIndex == -1 && allSelectedImages.isNotEmpty) {
                  selectedIndex =
                      0; // fallback se não encontrar, seleciona o primeiro
                }

                void onThumbnailTap(
                    ImageModel tappedImage, int tappedIndexInAllSelected) {
                  setState(() {
                    // A lógica aqui deve ser: a imagem clicada se torna a primeira (esquerda)
                    // e a que estava na primeira posição vai para a segunda (direita).
                    final ImageModel currentFirstImage = displayedImages[0];
                    final ImageModel currentSecondImage = displayedImages[1];

                    if (tappedImage == currentFirstImage) {
                      // Clicou na imagem da esquerda, não faz nada
                      return;
                    } else if (tappedImage == currentSecondImage) {
                      // Clicou na imagem da direita, troca com a esquerda
                      displayedImages[0] = tappedImage;
                      displayedImages[1] = currentFirstImage;
                    } else {
                      // Clicou em uma imagem da miniatura que não está em exibição
                      // A nova imagem clicada vai para a posição 0 (esquerda)
                      displayedImages[0] = tappedImage;
                      // E a imagem que estava na posição 0 vai para a posição 1 (direita)
                      // Mas apenas se ela não for a imagem que acabou de ser substituída.
                      if (tappedImage != currentFirstImage) {
                        displayedImages[1] = currentFirstImage;
                      }
                    }

                    // Atualiza o _selectedIndex para refletir a imagem que está agora à esquerda
                    selectedIndex =
                        allSelectedImages.indexOf(displayedImages[0]);

                    // Atualiza os controladores de texto com os dados das novas imagens exibidas
                    controllers.forEach((categoria, controllerList) {
                      // Atualiza a primeira posição (esquerda)
                      switch (categoria) {
                        case 'Data':
                          controllerList[0].text =
                              displayedImages[0].date ?? '';
                          break;
                        case 'Peso':
                          controllerList[0].text =
                              displayedImages[0].weight ?? '';
                          break;
                        case 'Cintura':
                          controllerList[0].text =
                              displayedImages[0].waist ?? '';
                          break;
                        case 'Obs':
                          controllerList[0].text =
                              displayedImages[0].observation ?? '';
                          break;
                        default:
                          controllerList[0].text =
                              displayedImages[0].customCategorias[categoria] ??
                                  '';
                          break;
                      }
                      // Atualiza a segunda posição (direita)
                      if (controllerList.length > 1) {
                        // Garante que há controlador para a segunda imagem
                        switch (categoria) {
                          case 'Data':
                            controllerList[1].text =
                                displayedImages[1].date ?? '';
                            break;
                          case 'Peso':
                            controllerList[1].text =
                                displayedImages[1].weight ?? '';
                            break;
                          case 'Cintura':
                            controllerList[1].text =
                                displayedImages[1].waist ?? '';
                            break;
                          case 'Obs':
                            controllerList[1].text =
                                displayedImages[1].observation ?? '';
                            break;
                          default:
                            controllerList[1].text = displayedImages[1]
                                    .customCategorias[categoria] ??
                                '';
                            break;
                        }
                      }
                    });
                  });
                }

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Título do diálogo
                    Container(
                      padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
                      decoration: const BoxDecoration(
                        color: Color(0xFFaed513),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(20.0),
                          topRight: Radius.circular(20.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              subAlbumName,
                              style: TextStyle(
                                fontSize: isLargeScreen ? 20.0 : 18.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.black,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Imagens exibidas em um Row centralizado
                    Expanded(
                      child: RepaintBoundary(
                        key: repaintKey,
                        child: Column(
                          children: [
                            // Imagens exibidas em um Row centralizado
                            Expanded(
                              child: Container(
                                margin:
                                    EdgeInsets.all(isLargeScreen ? 16.0 : 12.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16.0),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8.0,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: displayedImages.map((imageItem) {
                                      return Expanded(
                                        child: Container(
                                          height: double.infinity,
                                          child: Image.memory(
                                            imageItem.imageData!,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              devtools.debugPrint(
                                                  'Erro ao carregar imagem em displayedImages: $error');
                                              return Container(
                                                color: Colors.grey[200],
                                                child: const Center(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(Icons.error,
                                                          color: Colors.red,
                                                          size: 40),
                                                      SizedBox(height: 8),
                                                      Text('Erro de imagem',
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(
                                height: isLargeScreen
                                    ? screenWidth * 0.02
                                    : screenWidth * 0.01),
                            // Tags e TextFields (rolável)
                            Flexible(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.zero,
                                child: categorias.isNotEmpty
                                    ? Container(
                                        padding: EdgeInsets.all(
                                            isLargeScreen ? 16.0 : 12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: categorias.map((categoria) {
                                            return Container(
                                              margin: EdgeInsets.only(
                                                  bottom: isLargeScreen
                                                      ? 12.0
                                                      : 8.0),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Container(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                      horizontal: 12.0,
                                                      vertical: 6.0,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFaed513),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8.0),
                                                    ),
                                                    child: Text(
                                                      categoria,
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: isLargeScreen
                                                            ? 14.0
                                                            : 12.0,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(height: 8.0),
                                                  Row(
                                                    children: displayedImages
                                                        .asMap()
                                                        .entries
                                                        .map((imageEntry) {
                                                      final int imageIndex =
                                                          imageEntry.key;
                                                      return Expanded(
                                                        child: Container(
                                                          margin: EdgeInsets.only(
                                                              right: imageIndex <
                                                                      displayedImages
                                                                              .length -
                                                                          1
                                                                  ? 8.0
                                                                  : 0),
                                                          child: TextField(
                                                            controller: controllers[
                                                                    categoria]![
                                                                imageIndex],
                                                            style: TextStyle(
                                                              fontSize:
                                                                  isLargeScreen
                                                                      ? 14.0
                                                                      : 12.0,
                                                            ),
                                                            textAlign: TextAlign
                                                                .center,
                                                            decoration:
                                                                InputDecoration(
                                                              hintText: 'Valor',
                                                              filled: true,
                                                              fillColor: Colors
                                                                  .grey[50],
                                                              border:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.0),
                                                                borderSide: BorderSide(
                                                                    color: Colors
                                                                            .grey[
                                                                        300]!),
                                                              ),
                                                              enabledBorder:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.0),
                                                                borderSide: BorderSide(
                                                                    color: Colors
                                                                            .grey[
                                                                        300]!),
                                                              ),
                                                              focusedBorder:
                                                                  OutlineInputBorder(
                                                                borderRadius:
                                                                    BorderRadius
                                                                        .circular(
                                                                            8.0),
                                                                borderSide: const BorderSide(
                                                                    color: Color(
                                                                        0xFFaed513),
                                                                    width: 2),
                                                              ),
                                                              contentPadding:
                                                                  EdgeInsets
                                                                      .symmetric(
                                                                horizontal:
                                                                    12.0,
                                                                vertical: 8.0,
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      )
                                    : Container(
                                        margin: EdgeInsets.all(
                                            isLargeScreen ? 16.0 : 12.0),
                                        padding: EdgeInsets.all(
                                            isLargeScreen ? 20.0 : 16.0),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(12.0),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(Icons.info_outline,
                                                color: Colors.grey, size: 20),
                                            SizedBox(width: 12),
                                            Text(
                                              'Nenhuma categoria disponível.',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize:
                                                    isLargeScreen ? 14.0 : 12.0,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botões de compartilhar e baixar
                    Container(
                      padding: EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(20.0),
                          bottomRight: Radius.circular(20.0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(right: 8.0),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFaed513),
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                    vertical: isLargeScreen ? 16.0 : 14.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: shareImages,
                                icon: Icon(
                                  Icons.share,
                                  size: isLargeScreen ? 18.0 : 16.0,
                                ),
                                label: Text(
                                  'Compartilhar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isLargeScreen ? 14.0 : 12.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(left: 8.0),
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFaed513),
                                  foregroundColor: Colors.black,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.0,
                                    vertical: isLargeScreen ? 16.0 : 14.0,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  elevation: 2,
                                ),
                                onPressed: saveCard,
                                icon: Icon(
                                  Icons.download,
                                  size: isLargeScreen ? 18.0 : 16.0,
                                ),
                                label: Text(
                                  'Baixar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isLargeScreen ? 14.0 : 12.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Miniaturas das imagens selecionadas
                    Container(
                      height: isLargeScreen ? 120.0 : 100.0,
                      margin: EdgeInsets.all(isLargeScreen ? 16.0 : 12.0),
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            controller: localScrollController,
                            padding: EdgeInsets.symmetric(
                                horizontal: isLargeScreen ? 40.0 : 32.0),
                            child: Row(
                              children: allSelectedImages
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final int index = entry.key;
                                final ImageModel imageItem = entry.value;
                                return GestureDetector(
                                  onTap: () {
                                    onThumbnailTap(imageItem, index);
                                  },
                                  child: Container(
                                    width: isLargeScreen ? 80.0 : 70.0,
                                    height: isLargeScreen ? 80.0 : 70.0,
                                    margin:
                                        EdgeInsets.symmetric(horizontal: 8.0),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12.0),
                                      border: Border.all(
                                        color: selectedIndex == index
                                            ? const Color(0xFFaed513)
                                            : Colors.grey.withOpacity(0.3),
                                        width: selectedIndex == index ? 3 : 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: selectedIndex == index
                                              ? const Color(0xFFaed513)
                                                  .withOpacity(0.3)
                                              : Colors.black.withOpacity(0.1),
                                          blurRadius: 4.0,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(11.0),
                                      child: Image.memory(
                                        imageItem.imageData!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          devtools.debugPrint(
                                              'Erro ao carregar imagem da miniatura: $error');
                                          return Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.error,
                                                      color: Colors.red,
                                                      size: 16),
                                                  Text('Erro',
                                                      style: TextStyle(
                                                          color: Colors.red,
                                                          fontSize: 8)),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white,
                                    Colors.white.withOpacity(0.0)
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFaed513),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios,
                                    color: Colors.black,
                                    size: 16,
                                  ),
                                ),
                                onPressed: scrollLeft,
                                tooltip: 'Rolar para a esquerda',
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    Colors.white
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFaed513),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.black,
                                    size: 16,
                                  ),
                                ),
                                onPressed: scrollRight,
                                tooltip: 'Rolar para a direita',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

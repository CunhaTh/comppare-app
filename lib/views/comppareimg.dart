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
  final List<String> tags;
  final String subAlbumName;

  const ImagemDetalhesPage({
    super.key,
    required this.images,
    required this.tags,
    required this.subAlbumName, 
   // required this.idSubfolder,
  });

  @override
  State<ImagemDetalhesPage> createState() => _ImagemDetalhesPageState();
}

class _ImagemDetalhesPageState extends State<ImagemDetalhesPage> {
  late Future<List<ImageModel>> _imageItemsFuture;
  late List<String> tags;
  final ScrollController _scrollController = ScrollController();
  int? _selectedIndex;
  List<ImageModel> allSelectedImages = [];
  List<ImageModel>? _imageItems;
  bool _isLoading = true;

  final ApiService _apiService = ApiService(httpClient: http.Client());
  
  // Função para deletar imagens selecionadas
  Future<void> deleteImageList() async {
    final selectedImages = _imageItems?.where((image) => image.isSelected).toList() ?? [];
    if (selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos uma imagem para deletar.')),
      );
      return;
    }

    // Confirmação
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir as imagens selecionadas? Esta ação não poderá ser desfeita.'),
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
      _isLoading = true; // Adicione _isLoading como variável de estado se não existir
    });

    try {
      // Deletar cada imagem na API
      for (final image in selectedImages) {
        await _apiService.deleteImage(image.id, selectedImages.first as int); // Substitua pelo método real da API
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
        const SnackBar(content: Text('Erro ao deletar imagens. Tente novamente.')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Adicione _isLoading como variável de estado se não existir
      });
    }
  }

  Future<Uint8List?> _loadImageBytesFromUrl(String url) async {
    try {
      debugPrint('Tentando carregar imagem da URL: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        if (contentType != null && (contentType.startsWith('image/') || contentType == 'application/octet-stream')) {
          if (response.bodyBytes.isNotEmpty) {
            debugPrint('Imagem carregada com sucesso da URL: $url. Tamanho: ${response.bodyBytes.length} bytes.');
            return response.bodyBytes;
          }
        }
        debugPrint('Falha ao carregar imagem da URL: $url. Content-Type inesperado ou corpo vazio.');
        return null;
      }
      debugPrint('Falha ao carregar imagem da URL: $url com status ${response.statusCode}.');
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

    devtools.debugPrint('Processando MyImage ID: ${myImage.id}, Path: ${myImage.url}');

    // Sempre tenta carregar da URL
    imageData = await _loadImageBytesFromUrl(myImage.url);
    if (imageData != null && imageData.isNotEmpty) {
      devtools.debugPrint('Bytes carregados da URL para ID: ${myImage.id}. Tamanho: ${imageData.length} bytes.');
    } else {
      devtools.debugPrint('ATENÇÃO: Não foi possível obter dados válidos para a imagem ID: ${myImage.id}, Path: ${myImage.url}. Usando placeholder.');
      imageData = Uint8List(0); // Placeholder
    }

    // Cria o ImageItem com o ID explícito de MyImage
    items.add(ImageModel.fromMyImage(myImage, imageData: imageData));
    debugPrint('Preparando imagem com URL: ${myImage.url}, imageData: ${myImage.imageData != null}');
  }
  _imageItems = items.cast<ImageModel>(); // Atualiza a lista no estado
  return items;
}

  Uint8List? _placeholderBytes;

  @override
  void initState() {
    super.initState();
    tags = widget.tags;
    _imageItemsFuture = _prepareImageItems(); // Inicia o carregamento assíncrono
    
  }

  @override
  void dispose() {
    _scrollController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;

    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const PrincipalPage()),
              (Route<dynamic> route) => false,
            );
          },
          child: Center(
            child: Image.asset(
              "assets/logo_cortada.png",
              width: isLargeScreen ? screenWidth * 0.3 : screenWidth * 0.4,
              height: isLargeScreen ? screenHeight * 0.05 : screenHeight * 0.07,
              fit: BoxFit.contain,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.05),
            child: GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const PrincipalPage()),
                  (Route<dynamic> route) => false,
                );
              },
              child: Icon(Icons.home, size: isLargeScreen ? screenWidth * 0.05 : screenWidth * 0.067),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<ImageModel>>(
        future: _imageItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar imagens: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma imagem encontrada.'));
          } else {
            final List<ImageModel> loadedImageItems = snapshot.data!.cast<ImageModel>();
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                  child: GridView.builder(
                    padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (screenWidth / (isLargeScreen ? 200 : 150)).floor().clamp(1, 3),
                      childAspectRatio: 1,
                      crossAxisSpacing: isLargeScreen ? screenWidth * 0.06 : screenWidth * 0.083,
                      mainAxisSpacing: isLargeScreen ? screenWidth * 0.06 : screenWidth * 0.083,
                    ),
                    itemCount: loadedImageItems.length,
                    itemBuilder: (context, index) {
                      final imageItem = loadedImageItems[index];
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  imageItem.isSelected = !imageItem.isSelected;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: imageItem.isSelected ? Colors.green : Colors.grey,
                                    width: 2.0,
                                  ),
                                ),
                                child: Image.memory(
                                  imageItem.imageData!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('Erro ao renderizar imagem do GridView: $error');
                                    return const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.error, color: Colors.red, size: 40),
                                          Text('Erro de imagem', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          if (imageItem.isSelected)
                            Padding(
                              padding: EdgeInsets.only(top: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014),
                              child: Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: isLargeScreen ? screenWidth * 0.05 : screenWidth * 0.067,
                              ),
                            ),
                          GestureDetector(
                            onTap: () => _showEditDialog(context, imageItem, index),
                            child: Padding(
                              padding: EdgeInsets.only(top: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'edit',
                                    style: TextStyle(fontSize: 17 * MediaQuery.of(context).textScaleFactor),
                                  ),
                                  SizedBox(width: isLargeScreen ? screenWidth * 0.012 : screenWidth * 0.017),
                                  Icon(
                                    Icons.edit,
                                    color: Colors.black,
                                    size: isLargeScreen ? screenWidth * 0.035 : screenWidth * 0.047,
                                  ),
                                ],
                              ),
                            ),
                          ),
                         /* GestureDetector(
                            onTap: () => deleteImageList(),
                            child: Padding(
                              padding: EdgeInsets.only(top: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'delete',
                                    style: TextStyle(fontSize: 17 * MediaQuery.of(context).textScaleFactor),
                                  ),
                                  SizedBox(width: isLargeScreen ? screenWidth * 0.012 : screenWidth * 0.017),
                                  Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: isLargeScreen ? screenWidth * 0.035 : screenWidth * 0.047,
                                  ),
                                ],
                              ),
                            ),
                          ),*/
                        ],
                      );
                    },
                  ),
                ),
                Positioned(
                  left: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.042,
                  right: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.042,
                  bottom: isLargeScreen ? screenHeight * 0.08 : screenHeight * 0.1,
                  child: GestureDetector(
                    onTap: () => _showComparisonDialog(context, loadedImageItems, tags, widget.subAlbumName),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028,
                        vertical: isLargeScreen ? screenHeight * 0.015 : screenHeight * 0.022,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFaed513),
                        borderRadius: BorderRadius.circular(isLargeScreen ? screenWidth * 0.06 : screenWidth * 0.083),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'Comppare',
                            style: TextStyle(
                              fontSize: 18 * MediaQuery.of(context).textScaleFactor,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, ImageModel imageItem, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 520 && MediaQuery.of(context).size.height > 889;
    final Map<String, TextEditingController> controllers = {
      for (var tag in tags)
        tag: TextEditingController(
          text: tag == 'Data'
              ? imageItem.date ?? ''
              : tag == 'Peso'
                  ? imageItem.weight ?? ''
                  : tag == 'Série'
                      ? imageItem.waist ?? ''
                      : tag == 'Obs'
                          ? imageItem.observation ?? ''
                          : imageItem.customTags[tag] ?? '',
        ),
    };

Future<void> saveChanges(ImageModel updatedItem) async {
    final prefs = await SharedPreferences.getInstance();
    final tagKey = 'image_tags_${updatedItem.id}';
    final existingTags = jsonDecode(prefs.getString(tagKey) ?? '{}') as Map<String, dynamic>? ?? {};
    final updatedTags = {
    'Data': controllers['Data']?.text ?? updatedItem.date ?? '',
    'Peso': controllers['Peso']?.text ?? updatedItem.weight ?? '',
    'Série': controllers['Série']?.text ?? updatedItem.waist ?? '',
    'Obs': controllers['Obs']?.text ?? updatedItem.observation ?? '',
    for (var tag in tags)
      if (tag != 'Data' && tag != 'Peso' && tag != 'Série' && tag != 'Obs')
        tag: controllers[tag]!.text,
  };
  await prefs.setString(tagKey, jsonEncode(updatedTags));

  setState(() {
    if (_imageItems != null && index >= 0 && index < _imageItems!.length) {
      _imageItems![index] = ImageModel(
        id: updatedItem.id,
        url: updatedItem.url,
        imageData: updatedItem.imageData,
        date: updatedTags['Data'],
        weight: updatedTags['Peso'],
        waist: updatedTags['Série'],
        observation: updatedTags['Obs'],
        customTags: {
          for (var tag in tags)
            if (tag != 'Data' && tag != 'Peso' && tag != 'Série' && tag != 'Obs')
              tag: updatedTags[tag]!,
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
      builder: (context) {
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Edit Image',
                  style: TextStyle(
                    fontSize: 18 * MediaQuery.of(context).textScaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: CircleAvatar(
                  backgroundColor: Colors.black,
                  radius: isLargeScreen ? screenWidth * 0.025 : screenWidth * 0.033,
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: isLargeScreen ? screenWidth * 0.033 : screenWidth * 0.044,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: isLargeScreen ? screenWidth * 0.6 : screenWidth * 0.8,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                  ),
                  // Verifica se imageData não está vazia para evitar erro com Image.memory
                  child: imageItem.imageData!.isEmpty
                      ? Image.memory(
                          imageItem.imageData!,
                          fit: BoxFit.cover,
                        )
                      : const Center(child: Text('Imagem não disponível')), // Placeholder para imagem vazia
                ),
                SizedBox(height: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.044),
                if (tags.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: tags.map((tag) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                        child: Row(
                          children: [
                            SizedBox(
                              width: isLargeScreen ? screenWidth * 0.2 : screenWidth * 0.28,
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16 * MediaQuery.of(context).textScaleFactor,
                                ),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: controllers[tag],
                                decoration: InputDecoration(
                                  hintText: 'Insira o valor $tag',
                                  border: const OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028,
                                    vertical: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  )
                else
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                    child: Text(
                      'Sem Tags no momento.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFaed513),
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(
                      horizontal: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.044,
                      vertical: isLargeScreen ? screenWidth * 0.025 : screenWidth * 0.033,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                    ),
                  ),
                  onPressed: () {
                    final updatedItem = ImageModel(
                      id: imageItem.id,
                      url: imageItem.url,
                      imageData: imageItem.imageData,
                      date: controllers['Data']?.text ?? imageItem.date,
                      weight: controllers['Peso']?.text ?? imageItem.weight,
                      waist: controllers['Série']?.text ?? imageItem.waist,
                      observation: controllers['Obs']?.text ?? imageItem.observation,
                      customTags: {
                        ...imageItem.customTags,
                        for (var tag in tags)
                          if (tag != 'Data' && tag != 'Peso' && tag != 'Série' && tag != 'Obs')
                            tag: controllers[tag]!.text,
                      },
                      takenAt: '',
                    );
                    saveChanges(updatedItem);
                  },
                  icon: Icon(Icons.save, size: isLargeScreen ? screenWidth * 0.04 : screenWidth * 0.056),
                  label: Text(
                    'Salvar',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }
    ).then((updatedItem) {
      // Feedback opcional
    });
  }
// Substitua o método _showComparisonDialog em lib/views/comppareimg.dart
void _showComparisonDialog(BuildContext context, List<ImageModel> imagesToCompare, List<String> tags, String subAlbumName) async {
  final GlobalKey repaintKey = GlobalKey();
  final GlobalKey shareRepaintKey = GlobalKey();
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final isLargeScreen = screenWidth > 520 && screenHeight > 889;

  final List<ImageModel> selectedImages = imagesToCompare.where((item) => item.isSelected).toList();
  if (selectedImages.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecione pelo menos 2 imagens para comparar.'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  List<ImageModel> displayedImages = [
    selectedImages[0],
    selectedImages[1],
  ];
  final List<ImageModel> allSelectedImages = List.from(selectedImages); // Todas as imagens selecionadas para miniaturas

  final Map<String, List<TextEditingController>> controllers = {
    for (var tag in tags)
      tag: displayedImages.asMap().entries.map((entry) {
        final ImageModel item = entry.value;
        switch (tag) {
          case 'Data':
            return TextEditingController(text: item.date ?? '');
          case 'Peso':
            return TextEditingController(text: item.weight ?? '');
          case 'Cintura':
            return TextEditingController(text: item.waist ?? '');
          case 'Obs':
            return TextEditingController(text: item.observation ?? '');
          default:
            return TextEditingController(text: item.customTags[tag] ?? '');
        }
      }).toList(),
  };

  Future<Uint8List?> captureCard(GlobalKey key) async {
    try {
      RenderRepaintBoundary boundary = key.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      devtools.debugPrint("Erro ao capturar o card: $e");
      return null;
    }
  }

  Future<void> shareImages() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Compartilhamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: shareRepaintKey,
                child: Container(
                  color: Colors.white,
                  padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: displayedImages.map((imageItem) {
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  SizedBox(
                                    height: isLargeScreen ? screenWidth * 0.5 : screenWidth * 0.6,
                                    child: Image.memory(
                                      imageItem.imageData!,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  SizedBox(height: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014),
                                  Text(
                                    imageItem.date ?? '',
                                    style: TextStyle(
                                      fontSize: 12 * MediaQuery.of(context).textScaleFactor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
                      Image.asset(
                        "assets/logo_cortada.png",
                        width: isLargeScreen ? screenWidth * 0.2 : screenWidth * 0.3,
                        height: isLargeScreen ? screenWidth * 0.1 : screenWidth * 0.15,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),
              ),
              const Text('Quer compartilhar essa imagem?'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final Uint8List? imageBytes = await captureCard(shareRepaintKey);
                if (imageBytes == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erro ao capturar a imagem para compartilhamento.')),
                  );
                  return;
                }

                if (kIsWeb) {
                  final blob = html.Blob([imageBytes], 'image/png');
                  final url = html.Url.createObjectUrlFromBlob(blob);
                  final anchor = html.AnchorElement(href: url)
                    ..setAttribute('download', 'comparison_share.png')
                    ..click();
                  html.Url.revokeObjectUrl(url);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Imagem baixada. Compartilhe manualmente.')),
                  );
                } else {
                  final tempDir = await getTemporaryDirectory();
                  final file = await File('${tempDir.path}/comparison_share.png').writeAsBytes(imageBytes);
                  final xFile = XFile(file.path);
                  await Share.shareXFiles(
                    [xFile],
                    text: 'Confira minha comparação de progresso!',
                    subject: 'Comparação de Imagens',
                  );
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveCard() async {
    final Uint8List? imageBytes = await captureCard(repaintKey);
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao capturar o card para salvamento.')),
      );
      return;
    }

    if (kIsWeb) {
      final blob = html.Blob([imageBytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'comparison_card_${DateTime.now().millisecondsSinceEpoch}.png')
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

  final ScrollController localScrollController = ScrollController(); // Usar um controller local para o diálogo

  // Funções de scroll para as miniaturas
  void scrollLeft() {
    localScrollController.animateTo(
      localScrollController.offset - (screenWidth * 0.25), // Ajuste o valor de scroll conforme necessário
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void scrollRight() {
    localScrollController.animateTo(
      localScrollController.offset + (screenWidth * 0.25), // Ajuste o valor de scroll conforme necessário
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.all(8.0),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        content: Container(
          width: screenWidth * 0.98,
          height: screenHeight * 0.90,
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.zero,
          ),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              // Inicializa _selectedIndex com a primeira imagem exibida
              int? selectedIndex;
              // Encontra o índice da primeira imagem exibida na lista original 'allSelectedImages'
              selectedIndex = allSelectedImages.indexOf(displayedImages[0]);
              if (selectedIndex == -1 && allSelectedImages.isNotEmpty) {
                selectedIndex = 0; // fallback se não encontrar, seleciona o primeiro
              }
            
              void onThumbnailTap(ImageModel tappedImage, int tappedIndexInAllSelected) {
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
                  selectedIndex = allSelectedImages.indexOf(displayedImages[0]);

                  // Atualiza os controladores de texto com os dados das novas imagens exibidas
                  controllers.forEach((tag, controllerList) {
                    // Atualiza a primeira posição (esquerda)
                    switch (tag) {
                      case 'Data':
                        controllerList[0].text = displayedImages[0].date ?? '';
                        break;
                      case 'Peso':
                        controllerList[0].text = displayedImages[0].weight ?? '';
                        break;
                      case 'Cintura':
                        controllerList[0].text = displayedImages[0].waist ?? '';
                        break;
                      case 'Obs':
                        controllerList[0].text = displayedImages[0].observation ?? '';
                        break;
                      default:
                        controllerList[0].text = displayedImages[0].customTags[tag] ?? '';
                        break;
                    }
                    // Atualiza a segunda posição (direita)
                    if (controllerList.length > 1) { // Garante que há controlador para a segunda imagem
                      switch (tag) {
                        case 'Data':
                          controllerList[1].text = displayedImages[1].date ?? '';
                          break;
                        case 'Peso':
                          controllerList[1].text = displayedImages[1].weight ?? '';
                          break;
                        case 'Cintura':
                          controllerList[1].text = displayedImages[1].waist ?? '';
                          break;
                        case 'Obs':
                          controllerList[1].text = displayedImages[1].observation ?? '';
                          break;
                        default:
                          controllerList[1].text = displayedImages[1].customTags[tag] ?? '';
                          break;
                      }
                    }
                  });
                });
              }

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
                    color: Colors.white,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            subAlbumName,
                            style: TextStyle(
                              fontSize: 18 * MediaQuery.of(context).textScaleFactor,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: CircleAvatar(
                            backgroundColor: Colors.black,
                            radius: isLargeScreen ? screenWidth * 0.025 : screenWidth * 0.033,
                            child: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: isLargeScreen ? screenWidth * 0.033 : screenWidth * 0.044,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: RepaintBoundary(
                      key: repaintKey,
                      child: Column(
                        children: [
                          // Imagens exibidas em um Row centralizado
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: displayedImages.map((imageItem) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.zero,
                                    child: Container(
                                      height: double.infinity,
                                      decoration: const BoxDecoration(
                                        borderRadius: BorderRadius.zero,
                                      ),
                                      child: Image.memory(
                                        imageItem.imageData!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          devtools.debugPrint('Erro ao carregar imagem em displayedImages: $error');
                                          return const Center(
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(Icons.error, color: Colors.red, size: 40),
                                                Text('Erro de imagem', style: TextStyle(color: Colors.red)),
                                              ],
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
                          SizedBox(height: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.01),
                          // Tags e TextFields
                          if (tags.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.02),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: tags.map((tag) {
                                  return Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      // Tag à esquerda
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014,
                                          vertical: isLargeScreen ? screenWidth * 0.005 : screenWidth * 0.007,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFaed513),
                                          borderRadius: BorderRadius.zero,
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15 * MediaQuery.of(context).textScaleFactor,
                                          ),
                                        ),
                                      ),
                                      // TextFields centralizados em relação às imagens
                                      ...displayedImages.asMap().entries.map((imageEntry) {
                                        final int imageIndex = imageEntry.key;
                                        return Expanded(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isLargeScreen ? screenWidth * 0.04 : screenWidth * 0.04,
                                            ),
                                            child: SizedBox(
                                              width: isLargeScreen ? screenWidth * 0.2 : screenWidth * 0.2,
                                              child: TextField(
                                                controller: controllers[tag]![imageIndex],
                                                style: TextStyle(
                                                  fontSize: 12 * MediaQuery.of(context).textScaleFactor,
                                                ),
                                                textAlign: TextAlign.center,
                                                decoration: const InputDecoration(
                                                  contentPadding: EdgeInsets.zero,
                                                  isDense: true,
                                                  border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.zero,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      }),
                                    ],
                                  );
                                }).toList(),
                              ),
                            )
                          else
                            Padding(
                              padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                              child: Text(
                                'Nenhuma tag disponível.',
                                style: TextStyle(
                                  fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFaed513),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.022,
                              vertical: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.015,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                            ),
                          ),
                          onPressed: shareImages,
                          icon: Icon(Icons.share, size: isLargeScreen ? screenWidth * 0.04 : screenWidth * 0.030),
                          label: Text(
                            'Compartilhar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11 * MediaQuery.of(context).textScaleFactor,
                            ),
                          ),
                        ),
                        SizedBox(width: isLargeScreen ? screenWidth * 0.04 : screenWidth * 0.056),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFaed513),
                            foregroundColor: Colors.black,
                            padding: EdgeInsets.symmetric(
                              horizontal: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.022,
                              vertical: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.015,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                            ),
                          ),
                          onPressed: saveCard,
                          icon: Icon(Icons.download, size: isLargeScreen ? screenWidth * 0.04 : screenWidth * 0.030),
                          label: Text(
                            'Salvar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11 * MediaQuery.of(context).textScaleFactor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          controller: localScrollController,
                          child: Row(
                            children: allSelectedImages.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final ImageModel imageItem = entry.value;
                              return GestureDetector(
                                onTap: () {
                                  onThumbnailTap(imageItem, index);
                                },
                                child: Container(
                                  width: isLargeScreen ? screenWidth * 0.2 : screenWidth * 0.20,
                                  height: isLargeScreen ? screenWidth * 0.2 : screenWidth * 0.20,
                                  margin: EdgeInsets.symmetric(horizontal: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: selectedIndex == index ? Colors.blue : Colors.grey,
                                      width: selectedIndex == index ? 3 : 1,
                                    ),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Image.memory(
                                    imageItem.imageData!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      devtools.debugPrint('Erro ao carregar imagem da miniatura: $error');
                                      return const Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.error, color: Colors.red, size: 20),
                                            Text('Erro', style: TextStyle(color: Colors.red, fontSize: 10)),
                                          ],
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
                      Positioned(
                        left: 1,
                        top: isLargeScreen ? screenWidth * 0.08 : screenWidth * 0.11,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: const Color(0xFFaed513),
                            size: isLargeScreen ? screenWidth * 0.04 : screenWidth * 0.056,
                          ),
                          onPressed: scrollLeft,
                          tooltip: 'Rolar para a esquerda',
                        ),
                      ),
                      Positioned(
                        right: 1,
                        top: isLargeScreen ? screenWidth * 0.08 : screenWidth * 0.11,
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: const Color(0xFFaed513),
                            size: isLargeScreen ? screenWidth * 0.04 : screenWidth * 0.056,
                          ),
                          onPressed: scrollRight,
                          tooltip: 'Rolar para a direita',
                        ),
                      ),
                    ],
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
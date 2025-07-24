// lib/views/comppareimg.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:application_progress/models/image_model.dart'; // Importa MyImage
import 'package:application_progress/infra/api_services.dart'; // Para o ApiService
import 'package:application_progress/infra/token_helper.dart'; // Para TokenHelper
import 'package:application_progress/login.dart'; // Para LoginScreen
import 'package:flutter/foundation.dart'; // Para kIsWeb
import 'package:flutter/material.dart' as devtools;
import 'dart:typed_data'; // Para Uint8List
import 'dart:ui' as ui; // Para ui.Image
import 'package:flutter/rendering.dart'; // Para RenderRepaintBoundary
import 'package:http/http.dart' as http; // Para carregar imagens de URL
import 'dart:developer' as devtools; // Para devtools.debugPrint

// Dependências para compartilhamento e salvamento (adicione ao pubspec.yaml se necessário)
// import 'package:image_gallery_saver/image_gallery_saver.dart';
// import 'package:share_plus/share_plus.dart';
// import 'package:path_provider/path_provider.dart';
// import 'dart:io'; // Para File
// import 'dart:html' as html; // Para html.Blob no web

// Classe auxiliar para seleção de arquivos (mantida do seu código antigo)
class FilePickerHelper {
  static Future<List<PlatformFile>?> pickImages(bool allowMultiple) async {
    // Note: FilePicker.platform.pickFiles não está disponível diretamente aqui,
    // mas a lógica é mantida para referência de como era usada.
    // Você precisará garantir que 'file_picker' esteja importado e configurado onde este helper é chamado.
    return null; // Retorna nulo para evitar erro, já que a funcionalidade de pickImages não é o foco desta tela.
  }
}

// Reintroduzindo a classe ImageItem para gerenciar dados da UI
class ImageItem {
  final int id; // ID da imagem na API
  final String path; // URL da imagem
  Uint8List imageData; // Dados da imagem em bytes (para Image.memory)
  bool isSelected; // Para seleção na UI
  String? date;
  String? weight;
  String? waist;
  String? observation;
  Map<String, String> customTags;

  ImageItem({
    required this.id,
    required this.path,
    required this.imageData,
    this.isSelected = false,
    this.date,
    this.weight,
    this.waist,
    this.observation,
    this.customTags = const {},
  });

  // Construtor para criar ImageItem a partir de MyImage
  factory ImageItem.fromMyImage(MyImage myImage, Uint8List imageData) {
    return ImageItem(
      id: myImage.id,
      path: myImage.path,
      imageData: imageData,
      date: myImage.takenAt.split(' ')[0], // Usando takenAt como data inicial
      // Outros campos podem ser inicializados com valores padrão ou nulos
      weight: 'N/A',
      waist: 'N/A',
      observation: 'N/A',
      customTags: {},
    );
  }
}

class ImagemDetalhesPage extends StatefulWidget {
  final List<MyImage> images; // Lista de MyImage (vindos da AlbunsCriadosPage)
  final List<String> tags; // Tags da pasta (não da imagem individual, se for o caso)
  final String subAlbumName;

  const ImagemDetalhesPage({
    super.key,
    required this.images,
    required this.tags,
    required this.subAlbumName,
  });

  @override
  State<ImagemDetalhesPage> createState() => _ImagemDetalhesPageState();
}

class _ImagemDetalhesPageState extends State<ImagemDetalhesPage> {
  late Future<List<ImageItem>> _imageItemsFuture;
  List<ImageItem>? _imageItems; // A lista real de ImageItems que será populada
  final ScrollController _scrollController = ScrollController(); // Para o GridView
  final ApiService _apiService = ApiService(); // Instância do ApiService

  @override
  void initState() {
    super.initState();
    _imageItemsFuture = _prepareImageItems(); // Inicia o carregamento assíncrono
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Função para carregar os bytes de uma URL
  Future<Uint8List?> _loadImageBytesFromUrl(String url) async {
    try {
      devtools.debugPrint('Tentando carregar imagem da URL: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final contentType = response.headers['content-type'];
        devtools.debugPrint('Content-Type da URL $url: $contentType');

        if (contentType != null && (contentType.startsWith('image/') || contentType == 'application/octet-stream')) {
          if (response.bodyBytes.isNotEmpty) {
            devtools.debugPrint('Imagem carregada com sucesso da URL: $url. Tamanho: ${response.bodyBytes.length} bytes.');
            return response.bodyBytes;
          } else {
            devtools.debugPrint('Falha ao carregar imagem da URL: $url. Corpo vazio.');
            return null;
          }
        } else {
          devtools.debugPrint('Falha ao carregar imagem da URL: $url. Content-Type inesperado: $contentType. Corpo da resposta: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
          return null;
        }
      } else {
        devtools.debugPrint('Falha ao carregar imagem da URL: $url com status ${response.statusCode}. Corpo da resposta: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return null;
      }
    } catch (e) {
      devtools.debugPrint('Erro catastrófico ao carregar imagem da URL $url: $e');
      return null;
    }
  }

  // Função assíncrona para preparar a lista de ImageItem
  Future<List<ImageItem>> _prepareImageItems() async {
    List<ImageItem> items = [];
    for (int i = 0; i < widget.images.length; i++) {
      final MyImage myImage = widget.images[i];
      Uint8List? imageData;

      devtools.debugPrint('Processando MyImage ID: ${myImage.id}, Path: ${myImage.path}');

      // Sempre tenta carregar da URL, pois MyImage não tem bytes diretamente
      imageData = await _loadImageBytesFromUrl(myImage.path);
      if (imageData != null && imageData.isNotEmpty) {
        devtools.debugPrint('Bytes carregados da URL para ID: ${myImage.id}. Tamanho: ${imageData.length} bytes.');
      }

      // Se imageData ainda for nulo ou vazio após tentar carregar, use um placeholder
      if (imageData == null || imageData.isEmpty) {
        devtools.debugPrint('ATENÇÃO: Não foi possível obter dados VÁLIDOS para a imagem ID: ${myImage.id}, Path: ${myImage.path}. Usando placeholder.');
        // Cria um Uint8List vazio para evitar erros de renderização, ou um placeholder visual
        imageData = Uint8List(0); // Garante que é um Uint8List vazio
      }

      // Cria um ImageItem a partir de MyImage e os bytes carregados
      items.add(ImageItem.fromMyImage(myImage, imageData));
    }
    _imageItems = items; // Salva a lista carregada no estado
    return items;
  }

  // Função para excluir uma imagem
  Future<void> _deleteImage(ImageItem imageToDelete) async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text('Tem certeza que deseja excluir esta imagem?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final userId = TokenHelper().userId;
        if (!TokenHelper().hasToken() || userId == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Erro: Usuário não logado. Redirecionando...')),
            );
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
          return;
        }

        await _apiService.deleteImage(userId, imageToDelete.id); // Chama o ApiService com o ID da imagem

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagem excluída com sucesso!')),
          );
          // Remove a imagem da lista local e atualiza a UI
          setState(() {
            _imageItems?.remove(imageToDelete);
            // Se a lista ficar vazia, pode ser útil voltar para a tela anterior
            if (_imageItems?.isEmpty ?? true) {
              Navigator.pop(context);
            }
          });
        }
      } catch (e) {
        devtools.debugPrint('Erro ao excluir imagem: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir imagem: ${e.toString()}')),
          );
          if (e.toString().contains('Não autorizado') || e.toString().contains('Token inválido') || e.toString().contains('401')) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      }
    }
  }

  // Diálogo para editar os metadados da imagem
  void _showEditDialog(BuildContext context, ImageItem imageItem, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 520 && MediaQuery.of(context).size.height > 889;
    final Map<String, TextEditingController> controllers = {
      // Inicializa controladores com os valores atuais do ImageItem
      'Data': TextEditingController(text: imageItem.date ?? ''),
      'Peso': TextEditingController(text: imageItem.weight ?? ''),
      'Cintura': TextEditingController(text: imageItem.waist ?? ''),
      'Obs': TextEditingController(text: imageItem.observation ?? ''),
      // Para tags personalizadas
      for (var entry in imageItem.customTags.entries) entry.key: TextEditingController(text: entry.value),
    };

    void saveChanges(ImageItem updatedItem) {
      setState(() {
        if (_imageItems != null && index >= 0 && index < _imageItems!.length) {
          _imageItems![index] = updatedItem;
        }
        // TODO: Adicionar lógica para persistir as mudanças na API, se aplicável
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
                  'Editar Imagem',
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
                  child: imageItem.imageData.isNotEmpty
                      ? Image.memory(
                          imageItem.imageData,
                          fit: BoxFit.cover,
                        )
                      : const Center(child: Text('Imagem não disponível')),
                ),
                SizedBox(height: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.044),
                // Campos de edição para Data, Peso, Cintura, Obs
                _buildTextFieldRow('Data', controllers['Data']!, isLargeScreen, screenWidth),
                _buildTextFieldRow('Peso', controllers['Peso']!, isLargeScreen, screenWidth),
                _buildTextFieldRow('Cintura', controllers['Cintura']!, isLargeScreen, screenWidth),
                _buildTextFieldRow('Obs', controllers['Obs']!, isLargeScreen, screenWidth),
                // Campos para tags personalizadas
                ...imageItem.customTags.keys.map((tagKey) {
                  return _buildTextFieldRow(tagKey, controllers[tagKey]!, isLargeScreen, screenWidth);
                }).toList(),
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
                    final updatedItem = ImageItem(
                      id: imageItem.id,
                      path: imageItem.path,
                      imageData: imageItem.imageData,
                      isSelected: imageItem.isSelected,
                      date: controllers['Data']?.text,
                      weight: controllers['Peso']?.text,
                      waist: controllers['Cintura']?.text,
                      observation: controllers['Obs']?.text,
                      customTags: {
                        // Atualiza tags personalizadas
                        ...imageItem.customTags,
                        for (var tagKey in imageItem.customTags.keys)
                          tagKey: controllers[tagKey]!.text,
                      },
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
      },
    );
  }

  // Helper para construir os campos de texto no diálogo de edição
  Widget _buildTextFieldRow(String label, TextEditingController controller, bool isLargeScreen, double screenWidth) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
      child: Row(
        children: [
          SizedBox(
            width: isLargeScreen ? screenWidth * 0.2 : screenWidth * 0.28,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16 * MediaQuery.of(context).textScaleFactor,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Insira o valor $label',
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
  }

  // Diálogo para comparação de imagens
  void _showComparisonDialog(BuildContext context, List<ImageItem> imagesToCompare, List<String> tags, String subAlbumName) async {
    final GlobalKey repaintKey = GlobalKey();
    final GlobalKey shareRepaintKey = GlobalKey();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;

    final List<ImageItem> selectedImages = imagesToCompare.where((item) => item.isSelected).toList();

    if (selectedImages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos 2 imagens para comparar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    List<ImageItem> displayedImages = [
      selectedImages[0],
      selectedImages[1],
    ];

    final Map<String, List<TextEditingController>> controllers = {
      for (var tag in tags)
        tag: displayedImages.asMap().entries.map((entry) {
          final ImageItem item = entry.value;
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
                                        imageItem.imageData,
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

                  // Lógica de compartilhamento (requer dependências: share_plus, path_provider, dart:html)
                  // if (kIsWeb) {
                  //   final blob = html.Blob([imageBytes], 'image/png');
                  //   final url = html.Url.createObjectUrlFromBlob(blob);
                  //   final anchor = html.AnchorElement(href: url)
                  //     ..setAttribute('download', 'comparison_share.png')
                  //     ..click();
                  //   html.Url.revokeObjectUrl(url);
                  //   ScaffoldMessenger.of(context).showSnackBar(
                  //     const SnackBar(content: Text('Imagem baixada. Compartilhe manualmente.')),
                  //   );
                  // } else {
                  //   final tempDir = await getTemporaryDirectory();
                  //   final file = await File('${tempDir.path}/comparison_share.png').writeAsBytes(imageBytes);
                  //   final xFile = XFile(file.path);
                  //   await Share.shareXFiles(
                  //     [xFile],
                  //     text: 'Confira minha comparação de progresso!',
                  //     subject: 'Comparação de Imagens',
                  //   );
                  // }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Funcionalidade de compartilhamento desativada. Adicione as dependências e descomente o código.')),
                  );
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


      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Funcionalidade de salvamento desativada. Adicione as dependências e descomente o código.')),
      );
    }

    final ScrollController _localScrollController = ScrollController(); // Usar um controller local para o diálogo

    // Funções de scroll para as miniaturas (não usadas diretamente no diálogo de comparação, mas mantidas para referência)
    void _scrollLeft() {
      _localScrollController.animateTo(
        _localScrollController.offset - (screenWidth * 0.25),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }

    void _scrollRight() {
      _localScrollController.animateTo(
        _localScrollController.offset + (screenWidth * 0.25),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
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
                  'Comparar Imagens',
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
              children: [
                RepaintBoundary(
                  key: repaintKey,
                  child: Container(
                    color: Colors.white, // Fundo branco para a imagem capturada
                    padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: displayedImages.map((imageItem) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014),
                                child: Column(
                                  children: [
                                    Container(
                                      height: isLargeScreen ? screenWidth * 0.5 : screenWidth * 0.6,
                                      // Usa Image.memory com imageData
                                      child: imageItem.imageData.isNotEmpty
                                          ? Image.memory(
                                              imageItem.imageData,
                                              fit: BoxFit.cover,
                                            )
                                          : Center(child: Text('Imagem não disponível')),
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
                        // Exibe os campos de metadados para cada imagem
                        ...tags.map((tag) {
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: isLargeScreen ? screenWidth * 0.2 : screenWidth * 0.28,
                                  child: Text(
                                    tag,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                      color: Colors.black, // Cor do texto para o fundo branco
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Row(
                                    children: displayedImages.asMap().entries.map((entry) {
                                      final ImageItem item = entry.value;
                                      String value = '';
                                      switch (tag) {
                                        case 'Data':
                                          value = item.date ?? '';
                                          break;
                                        case 'Peso':
                                          value = item.weight ?? '';
                                          break;
                                        case 'Cintura':
                                          value = item.waist ?? '';
                                          break;
                                        case 'Obs':
                                          value = item.observation ?? '';
                                          break;
                                        default:
                                          value = item.customTags[tag] ?? '';
                                      }
                                      return Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(horizontal: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014),
                                          child: Text(
                                            value,
                                            style: TextStyle(
                                              fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                                              color: Colors.black, // Cor do texto para o fundo branco
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
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
              ],
            ),
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  onPressed: shareImages,
                  icon: const Icon(Icons.share, color: Colors.black),
                  label: const Text('Compartilhar', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFaed513),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: saveCard,
                  icon: const Icon(Icons.download, color: Colors.black),
                  label: const Text('Salvar', style: TextStyle(color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFaed513),
                  ),
                ),
              ],
            ),
          ],
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
      appBar: AppBar(
        title: Text(widget.subAlbumName, style: const TextStyle(color: Colors.black)),
        backgroundColor: const Color(0xFFaed513),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      backgroundColor: Colors.black,
      body: FutureBuilder<List<ImageItem>>(
        future: _imageItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFaed513)));
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Erro ao carregar imagens: ${snapshot.error}',
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma imagem encontrada para este álbum.',
                style: TextStyle(color: Colors.white54, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          } else {
            // Se os dados foram carregados com sucesso, use-os
            _imageItems = snapshot.data; // Atualiza a lista no estado
            return Stack(
              children: [
                Padding(
                  padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                  child: GridView.builder(
                    controller: _scrollController, // Adiciona o controller
                    padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.028),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: (screenWidth / (isLargeScreen ? 200 : 150)).floor().clamp(1, 3),
                      childAspectRatio: 1,
                      crossAxisSpacing: isLargeScreen ? screenWidth * 0.06 : screenWidth * 0.083,
                      mainAxisSpacing: isLargeScreen ? screenWidth * 0.06 : screenWidth * 0.083,
                    ),
                    itemCount: _imageItems!.length,
                    itemBuilder: (context, index) {
                      final imageItem = _imageItems![index];
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
                                child: imageItem.imageData.isNotEmpty
                                    ? Image.memory(
                                        imageItem.imageData,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          devtools.debugPrint('Erro ao renderizar imagem do GridView: $error');
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
                                      )
                                    : const Center(child: Text('Imagem não disponível')), // Placeholder para imagem vazia
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
                                    'editar',
                                    style: TextStyle(fontSize: 17 * MediaQuery.of(context).textScaleFactor, color: Colors.white),
                                  ),
                                  SizedBox(width: isLargeScreen ? screenWidth * 0.012 : screenWidth * 0.017),
                                  Icon(
                                    Icons.edit,
                                    color: Colors.white,
                                    size: isLargeScreen ? screenWidth * 0.035 : screenWidth * 0.047,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Botão de exclusão para cada imagem
                          GestureDetector(
                            onTap: () => _deleteImage(imageItem),
                            child: Padding(
                              padding: EdgeInsets.only(top: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'excluir',
                                    style: TextStyle(fontSize: 17 * MediaQuery.of(context).textScaleFactor, color: Colors.red),
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
                          ),
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
                    onTap: () => _showComparisonDialog(context, _imageItems!, widget.tags, widget.subAlbumName),
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
}

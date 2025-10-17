import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:application_progress/albuns_criados.dart';
import 'package:application_progress/infra/api_exception.dart';
import 'package:application_progress/infra/api_services.dart';
import 'package:application_progress/infra/repositories/ranking_repository.dart';
import 'package:application_progress/infra/token_helper.dart';
import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/login.dart';
import 'package:application_progress/models/comppare_model.dart';
import 'package:application_progress/models/folder_model.dart';
import 'package:application_progress/models/image_model.dart';
import 'package:application_progress/models/tag_model.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/shareableframe_withzoom.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as devtools;
import 'package:flutter/material.dart' as foundation;
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as _httpClient;
import 'package:http_parser/http_parser.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';

import 'dart:html' as html; // Para web, se aplicável
import 'package:application_progress/main.dart' as main_app;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:application_progress/helpers/date_picker_widget.dart';

import '../controllers/controller.dart';
import '../infra/api_endponts.dart';

class ImagemDetalhesPage extends StatefulWidget {
  final List<ImageModel> images;
  final List<String> categorias;
  final String subAlbumName;
  final bool isOwner;

  const ImagemDetalhesPage({
    super.key,
    required this.images,
    required this.categorias,
    required this.subAlbumName,
    required this.isOwner,
  });

  @override
  State<ImagemDetalhesPage> createState() => _ImagemDetalhesPageState();
}

class _ImagemDetalhesPageState extends State<ImagemDetalhesPage>
    with TickerProviderStateMixin {
  final GlobalKey shareRepaintKey = GlobalKey();
  late Future<List<ImageModel>> _imageItemsFuture;
  List<ImageModel>?
      _imageItems; // Agora esta é nossa única fonte da verdade após o load
  final List<Folder> idPastaPai = [];
  final Map<String, String> _savedValues = {};
  final Map<String, TextEditingController> _controllers = {};
  late List<String> categorias;
  final ScrollController _scrollController = ScrollController();
  int? _selectedIndex;
  List<ImageModel> allSelectedImages = [];
  late ValueNotifier<List<ImageModel>> _imageItemsListenable;
  bool _isLoading = true;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final ApiService _apiService = ApiService(httpClient: http.Client());
  Map<int, String> _tagIdToNameMap = {};

  late final bool canEdit = widget.isOwner;

  bool _showInstruction = true;

  @override
  void initState() {
    super.initState();
    categorias = widget.categorias;

    // MUDANÇA 1: Simplificamos a inicialização do Future.
    // O Future agora é responsável apenas pela carga inicial. A lista de estado
    // `_imageItems` será preenchida pelo FutureBuilder.
    _imageItemsFuture = _prepareImageItems();

    // O resto do seu initState continua igual.
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
    _imageItemsListenable.dispose();
    _controllers.values.forEach((controller) => controller.dispose());
    _scrollController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

// Função principal que gerencia o fluxo de exclusão
  void _deleteImage(ImageModel imageItem, int index) async {
    // Mostra um dialog de confirmação e aguarda a resposta do usuário
    final bool? confirmed = await _showDeleteConfirmationDialog(context);

    // Apenas continua se o usuário explicitamente confirmar a exclusão
    if (confirmed == true) {
      try {
        // Mostra um indicador de loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        final User? user = UserHelper().user;
        if (user == null || user.id == null) {
          throw Exception('Usuário não autenticado.');
        }

        // Chama o método da sua API para deletar a imagem no backend
        await ApiService().deleteImage(user.id!, imageItem.id);
        
        RankingRepository.instance.removePhotoWithTagPoints();

        Navigator.of(context).pop(); // Fecha o loading

        

        // Remove o item da lista local
        setState(() {
          _imageItems?.removeAt(index); // Apenas remove da lista.
        });

        // Mostra uma mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Imagem excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        Navigator.of(context).pop(); // Fecha o loading em caso de erro
        // Mostra uma mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao excluir a imagem: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

// Dialog de confirmação para evitar exclusões acidentais
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: const Text(
              'Você tem certeza que deseja excluir esta imagem? Esta ação não pode ser desfeita.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context)
                    .pop(false); // Retorna false se o usuário cancelar
              },
            ),
            TextButton(
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context)
                    .pop(true); // Retorna true se o usuário confirmar
              },
            ),
          ],
        );
      },
    );
  }

  // Method to capture card image
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone de exclusão com animação
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.delete_forever_rounded,
                    color: Colors.red,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),

                // Título com tipografia melhorada
                const Text(
                  'Confirmar Exclusão',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Mensagem com melhor legibilidade
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: const Text(
                    'Tem certeza que deseja excluir as imagens selecionadas? Esta ação não poderá ser desfeita.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),

                // Botões com design aprimorado
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[50],
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: Colors.grey[300]!,
                                width: 1.5,
                              ),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Cancelar',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 3,
                            shadowColor: Colors.red.withOpacity(0.4),
                          ),
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(true),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.delete_forever_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Excluir',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
    // Passo 1: Busca as tags do usuário (isso continua igual e está correto).
    final User? user = UserHelper().user;
    if (user?.id != null) {
      try {
        final List<TagModel> userTags = await ApiService().getTags(user!.id!);
        // Preenche a variável de estado da classe
        _tagIdToNameMap = {for (var tag in userTags) tag.id: tag.nomeTag};
      } catch (e) {
        devtools.debugPrint("Erro ao buscar tags do usuário: $e");
      }
    }

    // MELHORIA (PERFORMANCE): Processar todas as imagens em paralelo.
    // Criamos uma lista de "tarefas" (Futures) a serem executadas.
    final List<Future<ImageModel?>> processingTasks = [];

    for (final myImage in widget.images) {
      // Para cada imagem, adicionamos uma tarefa assíncrona à lista.
      processingTasks.add(_loadAndEnrichImage(myImage));
    }

    // Executa todas as tarefas da lista em paralelo e espera a conclusão de todas.
    final List<ImageModel?> processedResults =
        await Future.wait(processingTasks);

    // Filtra qualquer resultado nulo que possa ter ocorrido por erro no carregamento.
    final List<ImageModel> finalItems =
        processedResults.whereType<ImageModel>().toList();

    _imageItems = finalItems;
    return finalItems;
  }
  

Future<ImageModel?> _loadAndEnrichImage(ImageModel myImage) async {
  try {
    // Passo 1: Carrega os bytes da imagem. (Nenhuma alteração aqui, está OK)
    final Uint8List? imageData = await _loadImageBytesFromUrl(myImage.url);

    if (imageData == null || imageData.isEmpty) {
      devtools.debugPrint(
          'ATENÇÃO: Não foi possível obter dados para a imagem ID: ${myImage.id}.');
      return null; // Descarta a imagem se não for possível carregar o arquivo.
    }

    final finalItem = ImageModel.fromMyImage(myImage, imageData: imageData);

    // Passo 2: Tenta carregar a comparação. (Nenhuma alteração aqui, está OK)
    ComparacaoModel? comparacao;
    if (myImage.id != null && myImage.id != 0) {
      try {
        comparacao = await ApiService().getComparacaoSave(myImage.id!);
      } on ApiException catch (e) {
        // Ignora o erro APENAS se for um 404 (Not Found).
        if (e.statusCode != 404) {
          devtools.debugPrint(
              'Erro inesperado ao buscar comparação para imagem ID ${myImage.id}: $e');
        } else {
          devtools.debugPrint(
              'Nenhuma comparação encontrada para a imagem ID ${myImage.id} (esperado).');
        }
      }
    }

    // Passo 3: Preenche os dados se a comparação foi encontrada. (Correção aplicada aqui)
    if (comparacao != null) {
      if (comparacao.dataComparacao != null &&
          comparacao.dataComparacao!.isNotEmpty) {
        finalItem.date = comparacao.dataComparacao;
      }

      // CORREÇÃO: Itera sobre as tags e usa o 'nome' e 'valor' diretamente do JSON.
      // Isso elimina a dependência de '_tagIdToNameMap', que estava falhando.
      for (var tagData in comparacao.tags) {
        // Garantindo que 'tagData' é um mapa, para acesso seguro.
        if (tagData is Map<String, dynamic>) {
          final categoryName = tagData['nome']?.toString(); // O nome da tag já vem no JSON
          final valor = tagData['valor']?.toString() ?? '';

          if (categoryName?.isNotEmpty == true) {
            // A chave do metadado é o nome da categoria.
            finalItem.metadata[categoryName!] = valor; 
          } else {
            // Fallback (Mantido para segurança): Tenta usar o mapa de IDs se o nome falhar
            final tagId = tagData['id_tag'] as int?;
            if (tagId != null) {
              final categoryNameFromMap = _tagIdToNameMap[tagId];
              if (categoryNameFromMap != null) {
                finalItem.metadata[categoryNameFromMap] = valor;
              }
            }
          }
        }
      }
    }

    devtools.debugPrint('RESULTADO FINAL: Date=${finalItem.date}, Metadata Keys=${finalItem.metadata.keys.toList()}');
    return finalItem;
  } catch (e) {
    devtools
        .debugPrint('Erro GERAL ao processar a imagem ID ${myImage.id}: $e');
    return null;
  }
}

  Uint8List? _placeholderBytes;

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

  Future<void> _editDateForImage(
      BuildContext context, ImageModel imageItem, int index) async {
    // Tenta usar a data existente da imagem como data inicial
    DateTime initialPickerDate;
    try {
      initialPickerDate = DateFormat('dd/MM/yyyy').parse(imageItem.date ?? '');
    } catch (e) {
      initialPickerDate = DateTime.now();
    }

    // 1. Abre o seletor de data
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialPickerDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      locale: const Locale('pt', 'BR'),
    );

    if (pickedDate == null || !mounted) return;

    // 2. Prepara o novo objeto ImageModel com a data atualizada
    final String newDateString = DateFormat('dd/MM/yyyy').format(pickedDate);
    // Usamos o método copyWith para criar uma nova instância imutável
    final ImageModel itemAtualizado = imageItem.copyWith(date: newDateString);

    // 3. ATUALIZA A UI INSTANTANEAMENTE
    setState(() {
      _imageItems![index] = itemAtualizado;
    });

    // 4. Salva na API em segundo plano
    try {
      await ApiService().saveOrUpdateComparacao(itemAtualizado);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Data salva na nuvem!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Erro ao salvar a data: $e'),
              backgroundColor: Colors.red),
        );
        // Reverte a mudança na UI se a API falhar
        setState(() {
          _imageItems![index] = imageItem;
        });
      }
    }
  }

// MUDANÇA 3: A adição da Key no _buildImageCard
  Widget _buildImageCard({
    Key? key, // Parâmetro Key adicionado
    required ImageModel imageItem,
    required int index,
    required bool isLargeScreen,
    required double screenWidth,
    required double screenHeight,
  }) {
    
// Definição das funções de ação
// A ação SÓ é executada se 'canEdit' for true.
final VoidCallback? editOnTap = canEdit
    ? () => _showEditDialog(context, imageItem, index)
    : null; // Se for false, a função é null, travando o botão.

final VoidCallback? deleteOnTap = canEdit
    ? () => _deleteImage(imageItem, index)
    : null; // Se for false, a função é null, travando o botão.

// Definição das cores para sinalização visual
// As cores ATIVAS (black, red) SÓ são usadas se 'canEdit' for true.
final Color editColor = canEdit ? Colors.black : Colors.grey.shade600;
final Color deleteColor = canEdit ? Colors.red : Colors.grey.shade600;
final Color containerColor = canEdit ? Colors.black.withOpacity(0.05) : Colors.grey.shade100;
final Color deleteContainerColor = canEdit ? Colors.red.withOpacity(0.1) : Colors.grey.shade100; // Nova cor para o container de delete


    final String dataAtualFormatada =
        DateFormat('dd/MM/yyyy').format(DateTime.now());
    final String dateText =
        (imageItem.date != null && imageItem.date!.isNotEmpty)
            ? imageItem.date!
            : dataAtualFormatada;

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return FadeTransition(
          key: key, // Key aplicada ao widget raiz
          opacity: _fadeAnimation,
          child: Container(
            margin: EdgeInsets.all(isLargeScreen ? 8.0 : 6.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              color: Colors.white, // Adicionado para melhor visualização
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
                // Widget que exibe a data
                DatePickerWidget(
                  currentDate: dateText,
                  onDateChanged: (newDate) {
                    setState(() {
                      // Atualiza a data da imagem
                      imageItem.date = newDate;
                      final controller =
                          ImageDataController(apiService: ApiService());

                      controller.saveImageData(
                        idPhoto: imageItem.id,
                        dataComparacao: newDate,
                      );
                    });
                  },
                  padding: const EdgeInsets.only(
                    left: 16.0,
                    top: 16.0,
                    right: 16.0,
                    bottom: 8.0,
                  ),
                  textStyle: TextStyle(
                    fontSize: isLargeScreen ? 14.0 : 12.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
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
                // --- FIM DA PARTE DA IMAGEM ---

                // --- INÍCIO DA MUDANÇA: BARRA DE AÇÕES ---

Container(
    padding: EdgeInsets.symmetric(
        horizontal: isLargeScreen ? 8.0 : 4.0,
        vertical: isLargeScreen ? 8.0 : 6.0,
    ),
    child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
            // Botão Editar (envolvido por Expanded)
                      Expanded(
                          child: GestureDetector(
                              // TRAVA: onTap é null se canEdit for false (usuário não dono)
                              onTap: editOnTap, 
                              child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: isLargeScreen ? 12.0 : 8.0,
                                      vertical: isLargeScreen ? 8.0 : 6.0,
                                  ),
                                  decoration: BoxDecoration(
                                      // Cor do Container muda se estiver inativo
                                      color: containerColor, 
                                      borderRadius: BorderRadius.circular(8.0),
                                  ),
                                  child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                          Icon(
                                              Icons.edit,
                                              // Cor do Ícone muda
                                              color: editColor, 
                                              size: isLargeScreen ? 16.0 : 14.0,
                                          ),
                                          SizedBox(width: isLargeScreen ? 6.0 : 4.0),
                                          Text(
                                              'Editar',
                                              style: TextStyle(
                                                  fontSize: isLargeScreen ? 14.0 : 12.0,
                                                  fontWeight: FontWeight.w500,
                                                  // Cor do Texto muda
                                                  color: editColor, 
                                              ),
                                          ),
                                      ],
                                  ),
                              ),
                          ),
                      ),

                      SizedBox(width: isLargeScreen ? 8.0 : 4.0),

                      // Botão Deletar (apenas o ícone)
                      GestureDetector(
                          // TRAVA: onTap é null se canEdit for false (usuário não dono)
                          onTap: deleteOnTap, 
                          child: Container(
                              padding: EdgeInsets.all(isLargeScreen ? 8.0 : 6.0),
                              decoration: BoxDecoration(
                                  // Cor do Container de Delete muda se estiver inativo
                                  color: deleteContainerColor, 
                                  borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Icon(
                                  Icons.delete_outline,
                                  // Cor do Ícone muda
                                  color: deleteColor, 
                                  size: isLargeScreen ? 20.0 : 18.0,
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

  // Uma verificação para desabilitar o botão se nenhuma foto for selecionada
  final bool isButtonEnabled = selectedCount > 0;

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
              // Adiciona uma sombra mais sutil se o botão estiver desabilitado
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFaed513).withOpacity(isButtonEnabled ? 0.3 : 0.1),
                  blurRadius: 12.0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                // LÓGICA PRINCIPAL AQUI
                onTap: () {
                  // Se o botão não estiver habilitado, não faz nada.
                  if (!isButtonEnabled) return;

                  RankingRepository.instance.addPhotoWithTagPoints();

                  // 2. Continua com a ação original de abrir o diálogo.
                  _showComparisonDialog(
                    context,
                    loadedImageItems,
                    categorias,
                    widget.subAlbumName,
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLargeScreen ? 24.0 : 20.0,
                    vertical: isLargeScreen ? 16.0 : 14.0,
                  ),
                  decoration: BoxDecoration(
                    // Deixa o botão um pouco mais "apagado" se estiver desabilitado
                    gradient: LinearGradient(
                      colors: isButtonEnabled
                          ? [const Color(0xFFaed513), const Color(0xFF9bc412)]
                          : [Colors.grey.shade400, Colors.grey.shade500],
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
  /// Cria o widget da moldura de comparação para ser salvo ou compartilhado.
Widget _buildShareableFrame({
  required GlobalKey key,
  required List<ImageModel> displayedImages,
  required bool isLargeScreen,
}) {
  // Dimensões: 300x533 (proporção 9:16) para Story do Instagram
  const double frameWidth = 300.0;
  const double frameHeight = 400.0;
  const double logoHeight = 30.0; 

  return RepaintBoundary(
    key: key,
    child: Container(
      width: frameWidth,
      height: frameHeight,
      color: Colors.transparent, // Fundo branco
      
      child: Stack(
        children: [


          // CONTAINER PRINCIPAL DAS IMAGENS (AGORA COLADO NAS BORDAS VERTICAIS)
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [

              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: displayedImages.map((imageItem) {
                    return Expanded(
                      child: InteractiveViewer( // <--- NOVO WIDGET AQUI!
                        clipBehavior: Clip.antiAlias, // Permite que a imagem se arraste para fora dos limites se desejar
                        boundaryMargin: EdgeInsets.all(double.minPositive), //const EdgeInsets.all(double.infinity), // Permite arrastar sem limites
                        minScale: 1.0, // Escala mínima (sem diminuir abaixo do tamanho original)
                        maxScale: 4.0, // Escala máxima (4x de zoom)
                        child: Image.memory(
                          imageItem.imageData!,
                          // MUDANÇA: Voltamos para BoxFit.cover (ou BoxFit.fill), pois o zoom manual
                          // agora controla o enquadramento, permitindo que o usuário ajuste o corte.
                          // Usar 'contain' com zoom manual geralmente não é a melhor UX.
                          fit: BoxFit.contain, 
                          height: double.infinity,
                          width: double.infinity,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
                                        Padding(
                            padding: const EdgeInsets.only(top: 15, left: 40, right: 30),
                            child: Column(children: [
                                Icon(
                                        Icons.pinch_rounded,
                                        size: 24, // Ajuste o tamanho conforme necessário
                                        color: Colors.black,
                                      ),
                                      Text('Arraste, para redimencionar as imagens', style: TextStyle(color: Colors.black, fontSize: 10))
                            ],)),
            ],
          ),

          Positioned(
            left: 0,
            right: 0,
            // Ajustamos o 'bottom' para a posição que você desejava (em torno do meio superior)
            // Calculado: (533 / 2) - 160 = ~106.5 (Posicionamento mais alto, fora da zona de recorte da imagem do seu print)
            bottom: frameHeight / 2 - 75, 
            child: Center(
              child: Image.asset(
                  "assets/logo_all_green.png",
                  width: 80.0, 
                  height: logoHeight,
                  fit: BoxFit.contain,
                ),
              
            ),
          ),

                     
        ],
      ),
    ),
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
              Navigator.pop(context);
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
                  child: const Icon(Icons.home, color: Colors.black),
                ),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const PrincipalPage()),
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
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text('Erro: ${snapshot.error}'));
            }

            // MUDANÇA 4: A NOVA LÓGICA DE GERENCIAMENTO DE ESTADO
            // Sincroniza a lista de estado `_imageItems` com os dados da API apenas na primeira vez.
            if (_imageItems == null) {
              _imageItems = snapshot.data ?? [];
            }

            // A partir daqui, a UI depende apenas de `_imageItems`, que é a nossa "fonte da verdade".
            if (_imageItems!.isEmpty) {
              print("FutureBuilder: Erro - ${snapshot.error}");
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
            }
            if (_imageItems == null) {
              _imageItems = snapshot.data ?? [];
            }

            // 2. VERIFICAÇÃO: Agora, verificamos a nossa lista de estado `_imageItems`.
            //    Se ela estiver vazia, mostramos a mensagem.
            if (_imageItems!.isEmpty) {
              print("FutureBuilder: A lista _imageItems está vazia.");
              // Sua UI para "nenhuma imagem" continua a mesma, está ótima.
              print("FutureBuilder: Sem dados ou lista vazia");
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
              _imageItems =
                  loadedImageItems; // Sincroniza _imageItems com loadedImageItems
              print(
                  "loadedImageItems metadata: ${loadedImageItems.map((item) => item.metadata).toList()}");
              return Stack(
                children: [
                  Container(
                    padding: EdgeInsets.only(
                      left: isLargeScreen ? 16.0 : 12.0,
                      right: isLargeScreen ? 16.0 : 12.0,
                      top: isLargeScreen ? 16.0 : 12.0,
                      bottom: isLargeScreen ? 100.0 : 80.0,
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
                        return _buildImageCard(
                          key: ValueKey(imageItem.id),
                          imageItem: imageItem,
                          index: index,
                          isLargeScreen: isLargeScreen,
                          screenWidth: screenWidth,
                          screenHeight: screenHeight,
                        );
                      },
                    ),
                  ),
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
        ));
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone de sucesso com design aprimorado
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFaed513).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFaed513).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFFaed513),
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),

                // Título com tipografia melhorada
                const Text(
                  'Sucesso!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),

                // Mensagem com melhor legibilidade
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),

                // Botão OK com design aprimorado
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFaed513),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      shadowColor: const Color(0xFFaed513).withOpacity(0.4),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'OK',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showErrorDialog(BuildContext context, String message) async {
    await showDialog(
      context: context,
      barrierDismissible: true, // Permite fechar tocando fora, opcional
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.green.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.verified_rounded,
                    color: Colors.green,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Show, Deu tudo certo !',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    message,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black54,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 3,
                      shadowColor: Colors.green.withOpacity(0.4),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.thumb_up_rounded,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'ok, vlw',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

// A sua função de API para recuperar as tags
  Future<List<TagModel>> getTags(int usuario) async {
    final User? user = UserHelper().user;
    if (user == null || user.id == null) {
      throw ApiException('Usuário não autenticado.', statusCode: 401);
    }

    final url = Uri.parse(ApiEndpoints.listarTags);
    final body = {
      'usuario': user.id,
    };
    final responseBody = await ApiService().sendRequest(
      () => http.post(
        url,
        headers: ApiService().getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Tags carregadas com sucesso.',
      errorMessage: 'Falha ao carregar tags.',
    );

    if (responseBody.containsKey('data') && responseBody['data'] is List) {
      final List<dynamic> tagsJson = responseBody['data'] as List<dynamic>;
      foundation.debugPrint(
          'Tags do usuário: ${tagsJson.map((e) => e['nomeTag']?.toString() ?? '').toList()}');
      return tagsJson
          .map((json) => TagModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      foundation.debugPrint('Nenhuma tag encontrada para o usuário.');
      return [];
    }
  }

  Map<String, String> getHeaders({bool includeContentType = true}) {
    final String? authToken = TokenHelper().token;
    foundation.debugPrint(
        'ApiService: Token sendo acessado em getHeaders: $authToken');
    final Map<String, String> headers = {
      'Accept': 'application/json',
    };

    if (includeContentType) {
      headers['Content-Type'] = 'application/json';
    }

    if (authToken != null && authToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $authToken';
    } else {
      foundation.debugPrint(
          'Aviso: Token de autenticação não disponível no TokenHelper.');
    }
    return headers;
  }

  Future<void> onEditButtonPressed(
      BuildContext context, ImageModel imageItem, int index) async {
    // 1. Abre o diálogo e espera pelo resultado (o item atualizado)
    final ImageModel? itemAtualizado =
        await _showEditDialog(context, imageItem, index);

    // 2. Se o usuário salvou (resultado não é nulo)
    if (itemAtualizado != null && mounted) {
      // 3. ATUALIZA A UI INSTANTANEAMENTE
      //    Apenas modificamos nossa lista de estado `_imageItems` dentro de um setState.
      setState(() {
        _imageItems![index] = itemAtualizado;
      });

      // 4. Salva na API em segundo plano (atualização otimista)
      try {
        await ApiService().saveOrUpdateComparacao(itemAtualizado);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Alterações salvas na nuvem!'),
                backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao salvar na API: $e'),
                backgroundColor: Colors.red),
          );
          // Opcional: Reverter a mudança na UI se a API falhar
          setState(() {
            _imageItems![index] = imageItem; // Volta ao estado original
          });
        }
      }
    }
  }

  Future<ImageModel?> _showEditDialog(
      BuildContext context, ImageModel imageItem, int index) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    Map<String, int> tagIds = {};
    ComparacaoModel? comparacao;
    Map<String, String> apiValues = {};
    List<String> categoriasDinamicas = [];

    try {
      final List<TagModel> tags =
          await ApiService().getTags(UserHelper().user!.id!);
      tagIds = {for (var tag in tags) tag.nomeTag: tag.id};
      print("Tags do usuário (tagIds): $tagIds");

      if (imageItem.id == null) {
        Navigator.of(context).pop();
        if (context.mounted) {
          await _showErrorDialog(context, 'ID da imagem não encontrado.');
        }
        return null;
      }

      comparacao = await ApiService().getComparacaoSave(imageItem.id!);
      print("Comparação recuperada: $comparacao");

      if (comparacao != null && comparacao.tags.isNotEmpty) {
        for (var tag in comparacao.tags) {
          final tagId = tag['id_tag'] as int?;
          final valor = tag['valor']?.toString() ?? '';
          if (tagId != null) {
            final category = tagIds.entries
                .firstWhere(
                  (entry) => entry.value == tagId,
                  orElse: () => null!,
                )
                ?.key;
            if (category != null) {
              apiValues[category] = valor;
            }
          }
        }
        print("Valores da API mapeados: $apiValues");
      }
      Navigator.of(context).pop();
    } catch (e) {
      Navigator.of(context).pop();
      print("Erro ao carregar comparação: $e");
      // Não exibe erro para o usuário se não houver comparação, apenas prossegue
    }

    // Define categorias dinâmicas independentemente de comparação
    categoriasDinamicas = ['Data']..addAll(widget.categorias.isNotEmpty
        ? widget.categorias.where((cat) {
            print("Abimael Categoria: $cat");
            return tagIds.containsKey(cat);
          })
        : tagIds.keys.where((cat) => tagIds.containsKey(cat)));
    print("Categorias dinâmicas: $categoriasDinamicas");

    // Inicializa controllers com valores da API ou vazios
    final Map<String, TextEditingController> controllers = {};
    for (var categoria in categoriasDinamicas) {
      String textValue = apiValues[categoria] ?? '';
      if (textValue.isEmpty) {
        textValue = categoria == 'Data'
            ? (imageItem.date ?? _savedValues[categoria] ?? '')
            : imageItem.metadata[categoria] ?? _savedValues[categoria] ?? '';
      }
      print("Valor para $categoria: $textValue");
      controllers[categoria] = TextEditingController(text: textValue);
    }

// DENTRO DE: _showEditDialog
    // 1. Abre o diálogo e aguarda o resultado.
    //    Ele só retornará um `ImageModel` se a API salvar com sucesso.
    //    Caso contrário (cancelamento ou erro), retornará `null`.

    ///(ABIMAEL): Removendo o campo Data para não exibir dentro do EDITAR IMAGEM
    ///List<String> filtradas = categorias.where((item) => item.toLowerCase() != 'data').toList();

    final ImageModel? itemConfirmadoPelaAPI = await _openEditDialog(context,
        imageItem, index, tagIds, apiValues, controllers, categoriasDinamicas);

    // 2. Se o resultado NÃO for nulo, significa que a API confirmou o salvamento.
    //    Agora sim, é seguro atualizar o estado da tela principal.
    if (itemConfirmadoPelaAPI != null) {
      if (_imageItems != null && index >= 0 && index < _imageItems!.length) {
        // 3. Chama o setState para reconstruir a UI com o dado já confirmado.
        setState(() {
          // Atualiza a lista local
          _imageItems![index] = itemConfirmadoPelaAPI;

          // Recria o Future para que o FutureBuilder reconstrua a grade de imagens.
          _imageItemsFuture = Future.value(List.from(_imageItems!));
        });

        // Opcional: Mostrar uma mensagem de sucesso na tela principal
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Dados atualizados com sucesso!'),
                backgroundColor: Colors.green),
          );
        }
      }
    }
    // Se `itemConfirmadoPelaAPI` for nulo, não fazemos nada, pois o usuário cancelou ou a API falhou.
  }

  Future<ImageModel?> _openEditDialog(
    BuildContext context,
    ImageModel imageItem,
    int index,
    Map<String, int> tagIds,
    Map<String, String> apiValues,
    Map<String, TextEditingController> controllers,
    List<String> categoriasDinamicas,
  ) async {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 520 && screenHeight > 889;

    ///(ABIMAEL): Removendo o campo Data para não exibir dentro do EDITAR IMAGEM(A pedido do Andrew)
    List<String> categoriasDinamicasFiltradas = widget.categorias
        .where((item) => item.toLowerCase() != 'data')
        .toList();

    final updatedItem = await showDialog<ImageModel>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            bool isProcessing = false;

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
                child: Stack(
                  children: [
                    Column(
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
                                onTap: () => Navigator.of(dialogContext).pop(),
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
                            padding:
                                EdgeInsets.all(isLargeScreen ? 20.0 : 16.0),
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
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16.0),
                                    child: imageItem.imageData != null &&
                                            imageItem.imageData!.isNotEmpty
                                        ? Image.memory(
                                            imageItem.imageData!,
                                            fit: BoxFit.fitHeight,
                                          )
                                        : Container(
                                            color: Colors.grey[200],
                                            child: const Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                      Icons.image_not_supported,
                                                      color: Colors.grey,
                                                      size: 48),
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
                                if (categoriasDinamicasFiltradas.isNotEmpty)
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: categoriasDinamicasFiltradas
                                        .map((categoria) {
                                      return Container(
                                        margin: EdgeInsets.only(
                                            bottom:
                                                isLargeScreen ? 16.0 : 12.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              categoria,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    isLargeScreen ? 16.0 : 14.0,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(height: 8.0),
                                            TextField(
                                              controller:
                                                  controllers[categoria],
                                              decoration: InputDecoration(
                                                hintText:
                                                    'Insira o valor para $categoria',
                                                filled: true,
                                                fillColor: Colors.grey[50],
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey[300]!),
                                                ),
                                                enabledBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  borderSide: BorderSide(
                                                      color: Colors.grey[300]!),
                                                ),
                                                focusedBorder:
                                                    OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12.0),
                                                  borderSide: const BorderSide(
                                                      color: Color(0xFFaed513),
                                                      width: 2),
                                                ),
                                                contentPadding:
                                                    EdgeInsets.symmetric(
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
                                    padding: EdgeInsets.all(
                                        isLargeScreen ? 20.0 : 16.0),
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
                                            fontSize:
                                                isLargeScreen ? 14.0 : 12.0,
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
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      elevation: 0,
                                    ),
                                    onPressed: isProcessing
                                        ? null
                                        : () =>
                                            Navigator.of(dialogContext).pop(),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.cancel,
                                            size: isLargeScreen ? 18.0 : 16.0),
                                        SizedBox(width: 8.0),
                                        Expanded(
                                          child: Text(
                                            'Cancelar',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize:
                                                  isLargeScreen ? 16.0 : 14.0,
                                            ),
                                            overflow: TextOverflow.ellipsis,
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
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      elevation: 2,
                                    ),
                                    onPressed: isProcessing
                                        ? null // Botão desabilitado enquanto estiver processando
                                        : () async {
                                            // 1. Inicia o estado de carregamento DENTRO do diálogo
                                            //    (O `setState` aqui é do StatefulBuilder do seu diálogo)
                                            setState(() {
                                              isProcessing = true;
                                            });

                                            try {
                                              // Prepara os dados para a API (seu código original, que está correto)
                                              final Map<String, String>
                                                  updatedMetadata =
                                                  Map.from(imageItem.metadata);
                                              controllers
                                                  .forEach((key, controller) {
                                                updatedMetadata[key] =
                                                    controller.text.trim();
                                              });

                                              final tagsParaAPI = updatedMetadata
                                                  .entries
                                                  .map((entry) {
                                                    final tagId =
                                                        tagIds[entry.key];
                                                    if (tagId != null) {
                                                      return {
                                                        'id_tag': tagId,
                                                        'valor': entry.value
                                                      };
                                                    }
                                                    return null;
                                                  })
                                                  .whereType<
                                                      Map<String, dynamic>>()
                                                  .toList();

                                              // 2. Tenta salvar os dados na API
                                              final result =
                                                  await _saveChangesAndReturnItem(
                                                imageItem,
                                                updatedMetadata,
                                                tagsParaAPI,
                                              );

                                              final ImageModel? itemConfirmado =
                                                  result['newItem']
                                                      as ImageModel?;

                                              // 3. SUCESSO: Fecha o diálogo e retorna o item ATUALIZADO pela API.
                                              //    Este valor será capturado pelo `await _openEditDialog(...)` na sua função principal.
                                              if (dialogContext.mounted &&
                                                  itemConfirmado != null) {
                                                Navigator.of(dialogContext)
                                                    .pop(itemConfirmado);
                                                    await RankingRepository.instance.addPhotoWithTagPoints();
                                              }
                                            } catch (e) {
                                              // 4. FALHA: Mostra um erro para o usuário e NÃO fecha o diálogo.
                                              print(
                                                  "Erro ao salvar alterações: $e");
                                              if (dialogContext.mounted) {
                                                ScaffoldMessenger.of(
                                                        dialogContext)
                                                    .showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                        'Erro ao salvar: $e'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                              // IMPORTANTE: Não chamamos Navigator.pop() aqui em caso de erro.
                                            } finally {
                                              // 5. Garante que o indicador de carregamento seja desativado no final,
                                              //    seja em caso de sucesso ou falha.
                                              if (dialogContext.mounted) {
                                                setState(() {
                                                  isProcessing = false;
                                                });
                                              }
                                            }
                                          },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.save,
                                            size: isLargeScreen ? 18.0 : 16.0),
                                        SizedBox(width: 8.0),
                                        Expanded(
                                          child: Text(
                                            'Salvar',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize:
                                                  isLargeScreen ? 16.0 : 14.0,
                                              overflow: TextOverflow.ellipsis,
                                            ),
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
                    if (isProcessing)
                      const Positioned.fill(
                        child: Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFFaed513)),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    return updatedItem;
  }

// Crie esta nova função na sua classe
  Future<ImageModel?> _uploadNewImageWithData(
    ImageModel newItem,
    Map<String, String> metadata,
    List<Map<String, dynamic>> tags,
  ) async {
    final User? user = UserHelper().user;
    if (user == null) throw Exception('Usuário não autenticado.');
    if (newItem.imageData == null)
      throw Exception('Dados da imagem não encontrados.');

    // Crie um endpoint novo na sua API para isso, ex: /api/fotos/criarComDados
    var request =
        http.MultipartRequest('POST', Uri.parse(ApiEndpoints.salvaComparacao));

    // Adiciona os campos de texto
    request.fields['id_usuario'] = user.id.toString();
    request.fields['data_comparacao'] =
        metadata['Data'] ?? DateFormat('dd/MM/yyyy').format(DateTime.now());
    request.fields['tags'] =
        jsonEncode(tags); // Envia as tags como uma string JSON

    // Adiciona o arquivo da imagem
    request.files.add(http.MultipartFile.fromBytes(
      'photo', // O nome do campo que sua API espera para o arquivo
      newItem.imageData!,
      filename: 'upload.jpg', // Um nome de arquivo padrão
      contentType: MediaType('image', 'jpeg'),
    ));

    // Adiciona os headers de autenticação
    request.headers.addAll(ApiService().getHeaders(includeContentType: false));

    // Envia a requisição
    final response = await request.send();
    final responseBody = await response.stream.bytesToString();
    final decodedBody = jsonDecode(responseBody);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Assumindo que sua API retorna o objeto da foto criada com o novo ID
      // Você precisará ajustar o `ImageModel.fromMap` se necessário
      return ImageModel.fromMap(decodedBody['data']);
    } else {
      throw Exception(
          'Falha ao fazer upload da nova imagem: ${decodedBody["message"]}');
    }
  }

// Função corrigida - substitua a sua por esta
  Future<Map<String, dynamic>> _saveChangesAndReturnItem(
    ImageModel originalItem,
    Map<String, String> updatedMetadata,
    List<Map<String, dynamic>> tagsParaAPI,
  ) async {
    final User? user = UserHelper().user;
    if (user == null || user.id == null) {
      // A verificação de token não é necessária aqui
      throw Exception('Usuário não autenticado.');
    }

    // Salvar localmente (esta parte está correta)
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        'image_tags_${originalItem.id}', jsonEncode(updatedMetadata));
    print("Metadados salvos localmente: $updatedMetadata");

    // Preparar o corpo da requisição (esta parte está correta)
    String dataComparacao = DateFormat('dd/MM/yyyy').format(DateTime.now());
    if (updatedMetadata['Data']?.isNotEmpty == true) {
      try {
        dataComparacao = DateFormat('dd/MM/yyyy')
            .format(DateFormat('dd/MM/yyyy').parse(updatedMetadata['Data']!));
      } catch (e) {
        print("Erro ao formatar data: $e, usando data atual: $dataComparacao");
      }
    }

    final body = {
      'id_usuario': user.id,
      'id_photo': originalItem.id,
      'data_comparacao': dataComparacao,
      'tags': tagsParaAPI,
    };

    print("Corpo enviado à API: $body");

    // --- INÍCIO DA CORREÇÃO ---

    // 1. sendRequest já retorna o Map<String, dynamic> do body em caso de sucesso.
    //    Vamos chamar a variável de 'responseBody' para ficar mais claro.
    final responseBody = await ApiService().sendRequest(
      () => http.post(
        Uri.parse(ApiEndpoints.salvaComparacao),
        headers: ApiService().getHeaders(includeContentType: true),
        body: jsonEncode(body),
      ),
      successMessage: 'Alterações salvas com sucesso.',
      errorMessage: 'Falha ao salvar as alterações.',
    );

    print("Resposta da API (corpo JSON): $responseBody");

    // 2. Não precisamos mais verificar 'statusCode' ou 'body', pois sendRequest já fez isso.
    //    Agora trabalhamos diretamente com a resposta decodificada.
    final Map<String, String> syncedMetadata = Map.from(updatedMetadata);

    // A lógica abaixo para sincronizar com a resposta da API é opcional,
    // mas é uma boa prática para garantir que o estado do app reflita 100% o que está no servidor.
    try {
      if (responseBody['data'] != null &&
          responseBody['data'] is List &&
          responseBody['data'].isNotEmpty) {
        final tagsFromApi =
            responseBody['data'][0]['tags'] as List<dynamic>? ?? [];
        final List<TagModel> tags = await ApiService().getTags(user.id!);
        for (var tag in tagsFromApi) {
          final tagId = tag['id_tag'] as int?;
          final valor = tag['valor']?.toString() ?? '';
          if (tagId != null) {
            final category = tags
                .firstWhere((t) => t.id == tagId, orElse: () => null!)
                ?.nomeTag;
            if (category != null) {
              syncedMetadata[category] = valor;
            }
          }
        }
      }
    } catch (e) {
      print("Erro ao processar metadados da API: $e, usando updatedMetadata");
    }

    // --- FIM DA CORREÇÃO ---

    final newItem = ImageModel(
      id: originalItem.id,
      url: originalItem.url,
      imageData: originalItem.imageData,
      isSelected: originalItem.isSelected,
      metadata: syncedMetadata,
    );

    print("newItem metadata retornado: ${newItem.metadata}");

    // Mantemos a estrutura de retorno para não quebrar as outras funções
    return {'newItem': newItem, 'response': responseBody};
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

    String? _getValueForCategory(ImageModel item, String categoria) {
      // 1. Prioridade máxima: o valor no metadata.
      String? metadataValue = item.metadata[categoria];
      if (metadataValue != null && metadataValue.isNotEmpty) {
        return metadataValue;
      }
    }

    final List<ImageModel> selectedImages =
        imagesToCompare.where((item) => item.isSelected).toList();
    if (selectedImages.length < 2) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícone de atenção com design aprimorado
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Color(0xFFaed513),
                        width: 2,
                      ),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFaed513),
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Título com tipografia melhorada
                  const Text(
                    'Atenção',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),

                  // Mensagem com melhor legibilidade
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Text(
                      'Selecione pelo menos 2 imagens para comparar.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        height: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Botão com design aprimorado
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFaed513),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.lightbulb_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Entendi',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        categoria: displayedImages.map((item) {
          final textValue = _getValueForCategory(item, categoria);
          return TextEditingController(text: textValue);
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

    Future<void> shareSaveImages() async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: isLargeScreen ? screenWidth * 0.9 : screenWidth * 0.95,
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.85,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header do dialog
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24.0 : 20.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFaed513), Color(0xFF9bc412)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24.0),
                        topRight: Radius.circular(24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFaed513).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Compartilhar Comparação',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 20.0 : 18.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: -0.5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Conteúdo com a pré-visualização
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isLargeScreen ? 12.0 : 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Usando a nova função reutilizável para criar a moldura
                          ShareableFrameWithZoom(
                            shareRepaintKey: shareRepaintKey,
                            displayedImages: displayedImages,
                            isLargeScreen: isLargeScreen,
                          ),
                          const SizedBox(height: 8),
                          // Texto informativo
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFaed513)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: const Color(0xFFaed513),
                                    size: isLargeScreen ? 22.0 : 20.0,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Esta imagem será compartilhada com a logo do Comppare e as informações das imagens selecionadas.',
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 15.0 : 13.0,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Botões de ação
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24.0 : 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.black87,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: isLargeScreen ? 18.0 : 16.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                                side: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              elevation: 0,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFaed513),
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                horizontal: 24.0,
                                vertical: isLargeScreen ? 18.0 : 16.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                            ),
                            onPressed: () async {
                              await RankingRepository.instance.addPhotoCompartilhar();
                              // Lógica de captura e compartilhamento
                              final Uint8List? imageBytes =
                                  await captureCard(shareRepaintKey);
                              Navigator.of(context)
                                  .pop(); // Fecha o dialog de preview
                                
                              if (imageBytes == null) {
                                _showErrorDialog(context,
                                    'Erro ao capturar a imagem para compartilhamento.');
                                return;
                              }
                              

                              await shareImage(imageBytes);
                              
                              
                            },
                            child: const Text('Compartilhar'),
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

    Future<void> shareImages() async {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: isLargeScreen ? screenWidth * 0.9 : screenWidth * 0.95,
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.85,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header aprimorado
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24.0 : 20.0),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFaed513), Color(0xFF9bc412)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24.0),
                        topRight: Radius.circular(24.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFaed513).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Compartilhar Comparação',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 20.0 : 18.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                              letterSpacing: -0.5,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.black.withOpacity(0.2),
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.black,
                              size: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildShareableFrame(
                    key: shareRepaintKey, // A chave que você já usava
                    displayedImages: displayedImages,
                    isLargeScreen: isLargeScreen,
                  ),
                  // Content com design aprimorado
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(isLargeScreen ? 12.0 : 10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Preview da imagem com design aprimorado
                          RepaintBoundary(
                            key: shareRepaintKey,
                            child: Container(
                              color: Colors.white,
                              // padding:
                              //     EdgeInsets.all(isLargeScreen ? 12.0 : 10.0)
                              //         .copyWith(right: 0),
                              child: Stack(
                                children: [
                                  // Container principal das imagens
                                    Container(
                                      // Mantemos a altura fixa para o Row de miniaturas
                                      height: 150, 
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: displayedImages.map((imageItem) {
                                          return Expanded(
                                            child: Padding( // Adicione um padding opcional para separar as miniaturas
                                              padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                              child: InteractiveViewer( // <--- NOVO WIDGET AQUI!
                                                // Configurações de Recorte (Clipping) e Margem Interativa
                                                clipBehavior: Clip.antiAlias, 
                                                boundaryMargin: EdgeInsets.all(double.minPositive),
                                                minScale: 1.0, 
                                                maxScale: 4.0, 
                                                
                                                // O Image agora é o filho do InteractiveViewer
                                                child: Image.memory(
                                                  imageItem.imageData!,
                                                  // Usamos BoxFit.cover/fill para garantir que a área inicial seja preenchida
                                                  // (ou BoxFit.contain se você quiser ver a imagem inteira na miniatura)
                                                  fit: BoxFit.cover, 
                                                  height: double.infinity,
                                                  width: double.infinity,
                                                ),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ),

                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    bottom: 10,
                                    child: Image.asset(
                                      "assets/logo_all_green.png",
                                      width: isLargeScreen ? 50.0 : 50.0,
                                      height: isLargeScreen ? 35.0 : 25.0,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Informações do compartilhamento com design aprimorado
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey[50],
                              borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFaed513)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.info_outline_rounded,
                                    color: const Color(0xFFaed513),
                                    size: isLargeScreen ? 22.0 : 20.0,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'Esta imagem será compartilhada com a logo do Comppare e as informações das imagens selecionadas.',
                                    style: TextStyle(
                                      fontSize: isLargeScreen ? 15.0 : 13.0,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                      height: 1.4,
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Actions com design aprimorado
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24.0 : 20.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(24.0),
                        bottomRight: Radius.circular(24.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(right: 10.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[100],
                                foregroundColor: Colors.black87,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: isLargeScreen ? 18.0 : 16.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                  side: BorderSide(
                                    color: Colors.grey[300]!,
                                    width: 1.5,
                                  ),
                                ),
                                elevation: 0,
                                shadowColor: Colors.transparent,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.cancel_rounded,
                                    size: isLargeScreen ? 20.0 : 18.0,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      'Cancelar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: isLargeScreen ? 16.0 : 14.0,
                                        color: Colors.grey[700],
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 10.0),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFaed513),
                                foregroundColor: Colors.black,
                                padding: EdgeInsets.symmetric(
                                  horizontal: 24.0,
                                  vertical: isLargeScreen ? 18.0 : 16.0,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                elevation: 3,
                                shadowColor:
                                    const Color(0xFFaed513).withOpacity(0.4),
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
                                        padding: const EdgeInsets.all(36),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(28),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.15),
                                              blurRadius: 25,
                                              offset: const Offset(0, 12),
                                              spreadRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Container do loading com fundo aprimorado
                                            Container(
                                              padding: const EdgeInsets.all(24),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFaed513)
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(24),
                                                border: Border.all(
                                                  color: const Color(0xFFaed513)
                                                      .withOpacity(0.2),
                                                  width: 2,
                                                ),
                                              ),
                                              child:
                                                  const CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                            Color>(
                                                        Color(0xFFaed513)),
                                                strokeWidth: 4,
                                              ),
                                            ),
                                            const SizedBox(height: 28),

                                            // Título com tipografia melhorada
                                            const Text(
                                              'Preparando...',
                                              style: TextStyle(
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black87,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                            const SizedBox(height: 16),

                                            // Mensagem com melhor legibilidade
                                            const Text(
                                              'Preparando imagem para compartilhamento',
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black54,
                                                height: 1.5,
                                                fontWeight: FontWeight.w400,
                                              ),
                                              textAlign: TextAlign.center,
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
                                  _showErrorDialog(context,
                                      'Erro ao capturar a imagem para compartilhamento.');
                                  return;
                                }

                                // // Usar o novo método melhorado para compartilhamento
                                // await shareToSocialMedia(imageBytes);
                                // Chamar o novo método de compartilhamento
                                await shareImage(imageBytes);
                                await RankingRepository.instance.addPhotoCompartilhar();
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.share_rounded,
                                    size: isLargeScreen ? 20.0 : 18.0,
                                  ),
                                  SizedBox(width: 8.0),
                                  Expanded(
                                    child: Text(
                                      'Compartilhar',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: isLargeScreen ? 16.0 : 14.0,
                                        overflow: TextOverflow.ellipsis,
                                      ),
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
      // Cria uma chave local para a RepaintBoundary deste dialog específico
      final GlobalKey savePreviewKey = GlobalKey();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Container(
              width: isLargeScreen ? screenWidth * 0.9 : screenWidth * 0.95,
              constraints: BoxConstraints(
                maxHeight: screenHeight * 0.85,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header (similar ao de compartilhar, mas com texto diferente)
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24.0 : 20.0),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFaed513), Color(0xFF9bc412)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24.0),
                        topRight: Radius.circular(24.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Salvar Pré-visualização',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 20.0 : 18.0,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.close_rounded,
                                color: Colors.black, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Conteúdo com a pré-visualização da moldura
                    Expanded(
                      // ⭐️ Remova o SingleChildScrollView!
                      // Seu frame agora estará diretamente visível e pronto para receber toques.
                      child: Padding( // Mantenha o padding se for necessário
                        padding: EdgeInsets.all(isLargeScreen ? 12.0 : 10.0),
                        child: _buildShareableFrame(
                          key: savePreviewKey,
                          displayedImages: displayedImages,
                          isLargeScreen: isLargeScreen,
                        ),
                      ),
                    ),
                  // Botões de ação "Cancelar" e "Salvar"
                  Container(
                    padding: EdgeInsets.all(isLargeScreen ? 24.0 : 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              padding: EdgeInsets.symmetric(
                                  vertical: isLargeScreen ? 18.0 : 16.0),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancelar',
                                style: TextStyle(color: Colors.black87)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFaed513),
                              padding: EdgeInsets.symmetric(
                                  vertical: isLargeScreen ? 18.0 : 16.0),
                            ),
                            onPressed: () async {
                              // Lógica para capturar e salvar a imagem
                              final Uint8List? imageBytes =
                                  await captureCard(savePreviewKey);
                              Navigator.of(context)
                                  .pop(); // Fecha o dialog de preview

                              if (imageBytes == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Erro ao capturar o card para salvamento.')),
                                );
                                return;
                              }

                              // Lógica de salvamento que você já tinha
                              if (kIsWeb) {
                                final blob =
                                    html.Blob([imageBytes], 'image/png');
                                final url =
                                    html.Url.createObjectUrlFromBlob(blob);
                                final anchor = html.AnchorElement(href: url)
                                  ..setAttribute('download',
                                      'comparison_card_${DateTime.now().millisecondsSinceEpoch}.png')
                                  ..click();
                                html.Url.revokeObjectUrl(url);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Imagem baixada com sucesso!')),
                                );
                                await RankingRepository.instance.addPhotoPoints();
                              } else {
                                final result =
                                    await ImageGallerySaver.saveImage(
                                  imageBytes,
                                  quality: 100,
                                  name:
                                      "comparison_card_${DateTime.now().millisecondsSinceEpoch}",
                                );
                                if (result['isSuccess']) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Card salvo na galeria com sucesso!')),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text(
                                            'Erro ao salvar o card na galeria.')),
                                  );
                                }
                              }
                            },
                            child: const Text('Salvar na Galeria',
                                style: TextStyle(color: Colors.black)),
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
                      controllerList[0].text =
                          _getValueForCategory(displayedImages[0], categoria)!;
                      // Atualiza a segunda posição (direita)
                      // Atualiza a segunda posição (direita)
                      if (controllerList.length > 1) {
                        controllerList[1].text = _getValueForCategory(
                            displayedImages[1], categoria)!;
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
                            // Imagens exibidas em um Row centralizado (altura fixa)
                            Expanded(
                              child: SizedBox(
                                height: isLargeScreen ? 360.0 : 280.0,
                                child: Container(
                                  margin: EdgeInsets.all(
                                      isLargeScreen ? 16.0 : 12.0),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16.0),
                                    border: Border.all(
                                      color: Colors.grey[300]!,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children:
                                          displayedImages.map((imageItem) {
                                        int index =
                                            displayedImages.indexOf(imageItem);

                                        return Expanded(
                                          child: Align(
                                            alignment: index == 0
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
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
                                                                color: Colors
                                                                    .red)),
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
                            ),
                            SizedBox(
                                height: isLargeScreen
                                    ? screenWidth * 0.02
                                    : screenWidth * 0.01),
                            // Conteúdo rolável: categorias + ações + miniaturas
                            Expanded(
                              child: SingleChildScrollView(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.fromLTRB(
                                        isLargeScreen ? 16.0 : 12.0,
                                        8.0,
                                        isLargeScreen ? 16.0 : 12.0,
                                        8.0,
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 12.0,
                                                vertical: 6.0),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFaed513)
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(8.0),
                                            ),
                                            child: Text(
                                              'Data',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold,
                                                fontSize:
                                                    isLargeScreen ? 14.0 : 12.0,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 12.0),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  // Lê a data diretamente da propriedade .date
                                                  displayedImages[0].date ??
                                                      'N/A',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: isLargeScreen
                                                        ? 16.0
                                                        : 14.0,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Text(
                                                  // Lê a data diretamente da propriedade .date
                                                  displayedImages[1].date ??
                                                      'N/A',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    fontSize: isLargeScreen
                                                        ? 16.0
                                                        : 14.0,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const Divider(
                                              height: 24, thickness: 1),
                                        ],
                                      ),
                                    ),

                                    // Medidas/Categorias
                                    categorias.isNotEmpty
                                        ? Container(
                                            padding: EdgeInsets.all(
                                                isLargeScreen ? 16.0 : 12.0),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children:
                                                  categorias.map((categoria) {
                                                return Container(
                                                  margin: EdgeInsets.only(
                                                      bottom: isLargeScreen
                                                          ? 12.0
                                                          : 8.0),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal: 12.0,
                                                          vertical: 6.0,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: const Color(
                                                              0xFFaed513),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      8.0),
                                                        ),
                                                        child: Text(
                                                          categoria,
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize:
                                                                isLargeScreen
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
                                                                          displayedImages.length -
                                                                              1
                                                                      ? 8.0
                                                                      : 0),
                                                              child: TextField(
                                                                controller: controllers[
                                                                        categoria]![
                                                                    imageIndex],
                                                                style:
                                                                    TextStyle(
                                                                  fontSize:
                                                                      isLargeScreen
                                                                          ? 14.0
                                                                          : 12.0,
                                                                ),
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                decoration:
                                                                    InputDecoration(
                                                                  hintText:
                                                                      'Valor',
                                                                  filled: true,
                                                                  fillColor:
                                                                      Colors.grey[
                                                                          50],
                                                                  border:
                                                                      OutlineInputBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                    borderSide:
                                                                        BorderSide(
                                                                            color:
                                                                                Colors.grey[300]!),
                                                                  ),
                                                                  enabledBorder:
                                                                      OutlineInputBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                    borderSide:
                                                                        BorderSide(
                                                                            color:
                                                                                Colors.grey[300]!),
                                                                  ),
                                                                  focusedBorder:
                                                                      OutlineInputBorder(
                                                                    borderRadius:
                                                                        BorderRadius.circular(
                                                                            8.0),
                                                                    borderSide: const BorderSide(
                                                                        color: Color(
                                                                            0xFFaed513),
                                                                        width:
                                                                            2),
                                                                  ),
                                                                  contentPadding:
                                                                      EdgeInsets
                                                                          .symmetric(
                                                                    horizontal:
                                                                        12.0,
                                                                    vertical:
                                                                        8.0,
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
                                                    color: Colors.grey,
                                                    size: 20),
                                                SizedBox(width: 12),
                                                Text(
                                                  'Nenhuma categoria disponível.',
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: isLargeScreen
                                                        ? 14.0
                                                        : 12.0,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                    // Miniaturas (dentro da área rolável)
                                    Container(
                                      height: isLargeScreen ? 120.0 : 100.0,
                                      margin: EdgeInsets.all(
                                          isLargeScreen ? 16.0 : 12.0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
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
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFaed513),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
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
                                          Expanded(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              controller: localScrollController,
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: isLargeScreen
                                                      ? 40.0
                                                      : 32.0),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: allSelectedImages
                                                    .asMap()
                                                    .entries
                                                    .map((entry) {
                                                  final int index = entry.key;
                                                  final ImageModel imageItem =
                                                      entry.value;
                                                  return GestureDetector(
                                                    onTap: () {
                                                      onThumbnailTap(
                                                          imageItem, index);
                                                    },
                                                    child: Container(
                                                      width: isLargeScreen
                                                          ? 80.0
                                                          : 70.0,
                                                      height: isLargeScreen
                                                          ? 80.0
                                                          : 70.0,
                                                      margin:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 8.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12.0),
                                                        border: Border.all(
                                                          color: selectedIndex ==
                                                                  index
                                                              ? const Color(
                                                                  0xFFaed513)
                                                              : Colors.grey
                                                                  .withOpacity(
                                                                      0.3),
                                                          width:
                                                              selectedIndex ==
                                                                      index
                                                                  ? 3
                                                                  : 1,
                                                        ),
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color: selectedIndex ==
                                                                    index
                                                                ? const Color(
                                                                        0xFFaed513)
                                                                    .withOpacity(
                                                                        0.3)
                                                                : Colors.black
                                                                    .withOpacity(
                                                                        0.1),
                                                            blurRadius: 4.0,
                                                            offset:
                                                                const Offset(
                                                                    0, 2),
                                                          ),
                                                        ],
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(11.0),
                                                        child: Image.memory(
                                                          imageItem.imageData!,
                                                          fit: BoxFit.cover,
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            devtools.debugPrint(
                                                                'Erro ao carregar imagem da miniatura: $error');
                                                            return Container(
                                                              color: Colors
                                                                  .grey[200],
                                                              child:
                                                                  const Center(
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .center,
                                                                  children: [
                                                                    Icon(
                                                                        Icons
                                                                            .error,
                                                                        color: Colors
                                                                            .red,
                                                                        size:
                                                                            16),
                                                                    Text('Erro',
                                                                        style: TextStyle(
                                                                            color:
                                                                                Colors.red,
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
                                          ),
                                          Container(
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
                                                padding:
                                                    const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color:
                                                      const Color(0xFFaed513),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
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
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Botões de compartilhar e baixar no rodapé do diálogo
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
                                    overflow: TextOverflow.ellipsis,
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
                                  'Salvar',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isLargeScreen ? 14.0 : 12.0,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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

  Future<void> shareImage(Uint8List imageBytes) async {
    if (kIsWeb) {
      // Para web, usar Web Share API
      try {
        final blob = html.Blob([imageBytes], 'image/png');
        final file =
            html.File([blob], 'comppare_comparison.png', {'type': 'image/png'});

        final shareData = <String, dynamic>{
          'title': 'Minha Comparação - Comppare',
          'text': 'Confira minha comparação de progresso no Comppare! 😊',
          'files': [file],
        };

        await (html.window.navigator as dynamic).share(shareData);
        //_showSuccessDialog('Compartilhamento iniciado com sucesso!');
      } catch (e) {
        print('Web Share API falhou: $e');
        // Fallback: mostrar opções de compartilhamento
        //_showSocialShareOptionsWeb(imageBytes);
      }
    } else {
      // Para mobile (Android/iOS)
      try {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/comppare_comparison_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);
        final xFile = XFile(imagePath);

        await Share.shareXFiles(
          [xFile],
          text: 'Confira minha comparação de progresso no Comppare! 😊',
          subject: 'Comparação de Progresso - Comppare',
        );
        _showSuccessDialog('Compartilhamento realizado com sucesso!');
      } catch (e) {
        print('Erro ao compartilhar no mobile: $e');
        _showErrorDialog(context, 'Erro ao compartilhar a imagem: $e');
      }
    }
  }

  // Método para mostrar opções de compartilhamento na web com redes sociais
  void _showSocialShareOptionsWeb(Uint8List imageBytes) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header com ícone
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFaed513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.share,
                    color: Color(0xFFaed513),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Título
                const Text(
                  'Compartilhar nas Redes Sociais',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtítulo
                const Text(
                  'Escolha onde deseja compartilhar sua comparação:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Botões de redes sociais
                Column(
                  children: [
                    // Download da imagem primeiro
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFaed513),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _downloadImageWeb(imageBytes);
                        },
                        icon: const Icon(Icons.download, size: 20),
                        label: const Text(
                          'Baixar Imagem',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // WhatsApp
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          // _shareToWhatsAppWeb(imageBytes);
                          final shareData = <String, dynamic>{
                            'title': 'Minha Comparação - Comppare',
                            'text':
                                'Confira minha comparação de progresso no Comppare! 😊',
                            'url': '${ApiEndpoints.baseUrl}',
                          };

                          await (html.window.navigator as dynamic)
                              .share(shareData);
                          // _showSuccessDialog(
                          //     'Compartilhamento iniciado com sucesso!');
                        },
                        icon: const Icon(Icons.chat, size: 20),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Botão cancelar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Métodos específicos para compartilhamento na web
  void _downloadImageWeb(Uint8List imageBytes) {
    final blob = html.Blob([imageBytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download',
          'comppare_comparison_${DateTime.now().millisecondsSinceEpoch}.png')
      ..click();
    html.Url.revokeObjectUrl(url);
    _showSuccessDialog('Imagem baixada com sucesso!');
  }

  void _shareToWhatsAppWeb(Uint8List imageBytes) async {
    try {
      // Tentar usar a Web Share API nativa com arquivo
      final blob = html.Blob([imageBytes], 'image/png');
      final file =
          html.File([blob], 'comppare_comparison.png', {'type': 'image/png'});

      final shareData = <String, dynamic>{
        'title': 'Minha Comparação - Comppare',
        'text':
            'Confira minha comparação de progresso no Comppare! 😊 ${ApiEndpoints.baseUrl}',
        'files': [file],
      };

      // Tentar compartilhar usando Web Share API
      await (html.window.navigator as dynamic).share(shareData);
      _showSuccessDialog('Compartilhamento iniciado com sucesso!');
    } catch (e) {
      print('Web Share API falhou: $e');
      
      await RankingRepository.instance.addPhotoPoints();
      // Fallback: baixar imagem e redirecionar para WhatsApp Web
      _downloadImageWeb(imageBytes);

      final text = Uri.encodeComponent(
          'Confira minha comparação de progresso no Comppare! 😊 ${ApiEndpoints.baseUrl}');
      final url = 'https://wa.me/?text=$text';
      html.window.open(url, '_blank');
      _showSuccessDialog('Imagem baixada! Redirecionando para o WhatsApp...');
    }
  }

  void _shareToFacebookWeb() async {
    try {
      // Tentar usar a Web Share API nativa
      final shareData = <String, dynamic>{
        'title': 'Minha Comparação - Comppare',
        'text': 'Confira minha comparação de progresso no Comppare! 😊',
        'url': '${ApiEndpoints.baseUrl}',
      };

      await (html.window.navigator as dynamic).share(shareData);
      _showSuccessDialog('Compartilhamento iniciado com sucesso!');
    } catch (e) {
      print('Web Share API falhou: $e');

      // Fallback: redirecionar para Facebook
      final text = Uri.encodeComponent(
          'Confira minha comparação de progresso no Comppare! 😊');
      final url =
          'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('${ApiEndpoints.baseUrl}')}&quote=$text';
      html.window.open(url, '_blank');
      _showSuccessDialog('Redirecionando para o Facebook...');
    }
  }

  void _shareToInstagramWeb(Uint8List imageBytes) {
    // Instagram Web não suporta compartilhamento direto, então baixa a imagem
    _downloadImageWeb(imageBytes);
    _showSuccessDialog(
        'Para compartilhar no Instagram, baixe a imagem e use o app!');
  }

  void _shareToTwitterWeb() {
    final text = Uri.encodeComponent(
        'Confira minha comparação de progresso no Comppare! 😊');
    final url =
        'https://twitter.com/intent/tweet?text=$text&url=${Uri.encodeComponent('${ApiEndpoints.baseUrl}')}';
    html.window.open(url, '_blank');
    _showSuccessDialog('Redirecionando para o Twitter...');
  }

  void _shareToEmailWeb() {
    final subject = Uri.encodeComponent('Comparação de Progresso - Comppare');
    final body = Uri.encodeComponent(
        'Confira minha comparação de progresso no Comppare! 😊\n\n${ApiEndpoints.baseUrl}');
    final url = 'mailto:?subject=$subject&body=$body';
    html.window.open(url, '_blank');
    _showSuccessDialog('Redirecionando para o email...');
  }

  // Método melhorado para compartilhamento social
  Future<void> shareToSocialMedia(Uint8List imageBytes) async {
    try {
      if (kIsWeb) {
        // Para web, criar um blob e tentar diferentes estratégias de compartilhamento
        final blob = html.Blob([imageBytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);

        // Estratégia 1: Tentar Web Share API (funciona em alguns navegadores)
        if (html.window.navigator.share != null) {
          try {
            await html.window.navigator.share({
              'title': 'Comparação de Progresso - Comppare',
              'text': 'Confira minha comparação de progresso no Comppare! 💪',
              'url': url,
            });
            _showSuccessDialog('Compartilhamento social iniciado com sucesso!');

            // Limpar a URL após um tempo
            Future.delayed(const Duration(seconds: 10), () {
              html.Url.revokeObjectUrl(url);
            });
            return;
          } catch (shareError) {
            devtools.debugPrint('Web Share API falhou: $shareError');
          }
        }

        // Estratégia 2: Mostrar opções de compartilhamento com download da imagem
        _showSocialShareOptionsWithDownload(imageBytes, url);
      } else {
        // Para mobile (Android/iOS)
        final tempDir = await getTemporaryDirectory();
        final fileName =
            'comppare_comparison_${DateTime.now().millisecondsSinceEpoch}.png';
        final file =
            await File('${tempDir.path}/$fileName').writeAsBytes(imageBytes);
        final xFile = XFile(file.path);

        await Share.shareXFiles(
          [xFile],
          text: 'Confira minha comparação de progresso no Comppare! 💪',
          subject: 'Comparação de Progresso - Comppare',
        );
        _showSuccessDialog('Compartilhamento social iniciado com sucesso!');
      }
    } catch (e) {
      devtools.debugPrint('Erro no compartilhamento: $e');
      _showErrorDialog(context, 'Erro ao compartilhar: $e');
    }
  }

  // Método para mostrar opções de compartilhamento com download na web
  void _showSocialShareOptionsWithDownload(
      Uint8List imageBytes, String blobUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header com ícone
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFaed513).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.share,
                    color: Color(0xFFaed513),
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),

                // Título
                const Text(
                  'Compartilhar nas Redes Sociais',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                // Subtítulo
                const Text(
                  'Escolha onde deseja compartilhar sua comparação:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Botões de redes sociais
                Column(
                  children: [
                    // Download da imagem primeiro
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFaed513),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _downloadImage(imageBytes);
                        },
                        icon: const Icon(Icons.download, size: 20),
                        label: const Text(
                          'Baixar Imagem',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // Facebook
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _shareToFacebookWithText();
                        },
                        icon: const Icon(Icons.facebook, size: 20),
                        label: const Text(
                          'Facebook',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // Twitter/X
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _shareToTwitterWithText();
                        },
                        icon: const Icon(Icons.flutter_dash, size: 20),
                        label: const Text(
                          'Twitter/X',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // WhatsApp
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _shareToWhatsAppWithText();
                        },
                        icon: const Icon(Icons.chat, size: 20),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),

                    // Email
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _shareToEmailWithText();
                        },
                        icon: const Icon(Icons.email, size: 20),
                        label: const Text(
                          'Email',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Botão cancelar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Método para download da imagem na web
  void _downloadImage(Uint8List imageBytes) {
    final blob = html.Blob([imageBytes], 'image/png');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download',
          'comppare_comparison_${DateTime.now().millisecondsSinceEpoch}.png')
      ..click();
    html.Url.revokeObjectUrl(url);
    _showSuccessDialog('Imagem baixada com sucesso!');
  }

  // Métodos para compartilhamento específico em cada rede social (apenas texto)
  void _shareToFacebookWithText() {
    final text = Uri.encodeComponent(
        'Confira minha comparação de progresso no Comppare! 💪');
    final url =
        'https://www.facebook.com/sharer/sharer.php?u=${Uri.encodeComponent('${ApiEndpoints.baseUrl}')}&quote=$text';
    html.window.open(url, '_blank');
    _showSuccessDialog('Redirecionando para o Facebook...');
  }

  void _shareToTwitterWithText() {
    final text = Uri.encodeComponent(
        'Confira minha comparação de progresso no Comppare! 💪');
    final url =
        'https://twitter.com/intent/tweet?text=$text&url=${Uri.encodeComponent('${ApiEndpoints.baseUrl}')}';
    html.window.open(url, '_blank');
    _showSuccessDialog('Redirecionando para o Twitter...');
  }

  void _shareToWhatsAppWithText() {
    final text = Uri.encodeComponent(
        'Confira minha comparação de progresso no Comppare! 💪 ${ApiEndpoints.baseUrl}');
    final url = 'https://wa.me/?text=$text';
    html.window.open(url, '_blank');
    _showSuccessDialog('Redirecionando para o WhatsApp...');
  }

  void _shareToEmailWithText() {
    final subject = Uri.encodeComponent('Comparação de Progresso - Comppare');
    final body = Uri.encodeComponent(
        'Confira minha comparação de progresso no Comppare! 💪\n\n${ApiEndpoints.baseUrl}');
    final url = 'mailto:?subject=$subject&body=$body';
    html.window.open(url, '_blank');
    _showSuccessDialog('Redirecionando para o email...');
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.of(context).pushReplacementNamed(
        '/login'); // Ajuste a rota '/login' conforme necessário
  }
}

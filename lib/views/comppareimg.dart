import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:application_progress/models/image_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html; // Para web, se aplicável
import 'package:application_progress/main.dart' as main_app;
import 'package:http/http.dart' as http; // Adicione este import para fazer requisições HTTP
import 'package:flutter/foundation.dart';

class ImageItem {
  final Uint8List imageData;
  String date;
  String weight;
  String waist;
  String observation;
  bool isSelected;
  Map<String, String> customTags;

  ImageItem({
    required this.imageData,
    required this.date,
    required this.weight,
    required this.waist,
    required this.observation,
    this.isSelected = false,
    this.customTags = const {},
  });
}

class ImagemDetalhesPage extends StatefulWidget {
  final List<ImageModel> images;
  final List<String> tags;
  final String subAlbumName;
  final int idSubfolder;

  const ImagemDetalhesPage({
    Key? key,
    required this.images,
    required this.tags,
    required this.subAlbumName, required this.idSubfolder,
  }) : super(key: key);

  @override
  State<ImagemDetalhesPage> createState() => _ImagemDetalhesPageState();
}

class _ImagemDetalhesPageState extends State<ImagemDetalhesPage> {
  // Alterado para um Future para carregar as imagens
  late Future<List<ImageItem>> _imageItemsFuture;
  late List<String> tags;
  final ScrollController _scrollController = ScrollController();
  int? _selectedIndex;
  List<ImageItem> allSelectedImages = [];

  // A lista real de ImageItems que será populada após a resolução do Future.
  // Será usada pelo ListView.builder e no _showEditDialog.
  List<ImageItem>? _imageItems;

  // Função para carregar os bytes de uma URL
  Future<Uint8List?> _loadImageBytesFromUrl(String url,) async {
    try {
      debugPrint('Tentando carregar imagem da URL: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
      final contentType = response.headers['content-type'];
        debugPrint('Content-Type da URL $url: $contentType');

        if (contentType != null && (contentType.startsWith('image/') || contentType == 'application/octet-stream')) {
          if (response.bodyBytes.isNotEmpty) {
            debugPrint('Imagem carregada com sucesso da URL: $url. Tamanho: ${response.bodyBytes.length} bytes.');
            return response.bodyBytes;
          } else {
            debugPrint('Falha ao carregar imagem da URL: $url. Corpo vazio.');
            return null;
          }
        } else {
          debugPrint('Falha ao carregar imagem da URL: $url. Content-Type inesperado: $contentType. Corpo da resposta: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
          return null;
        }
      } else {
        debugPrint('Falha ao carregar imagem da URL: $url com status ${response.statusCode}. Corpo da resposta: ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}');
        return null;
      }
    } catch (e) {
      debugPrint('Erro catastrófico ao carregar imagem da URL $url: $e');
      return null;
    } 
  }

  // Função assíncrona para preparar a lista de ImageItem
  Future<List<ImageItem>> _prepareImageItems() async {
    List<ImageItem> items = [];
    for (int i = 0; i < widget.images.length; i++) {
      final ImageModel myImage = widget.images[i];
      Uint8List? imageData;

      debugPrint('Processando MyImage ID: ${myImage.id}, Path: ${myImage.path}'); // Debug 5
      
      if (myImage.bytes != null && myImage.bytes!.isNotEmpty) {
        imageData = myImage.bytes;
        debugPrint('Usando bytes existentes para ID: ${myImage.id}. Tamanho: ${imageData!.length} bytes.'); // Debug 6
      } else {
        imageData = await _loadImageBytesFromUrl(myImage.path);
      if (imageData != null && imageData.isNotEmpty) {
        debugPrint('Bytes carregados da URL para ID: ${myImage.id}. Tamanho: ${imageData.length} bytes.'); // Debug 7
        }
      }

      // Se imageData ainda for nulo ou vazio após tentar carregar, use um placeholder
    if (imageData == null || imageData.isEmpty) {
      debugPrint('ATENÇÃO: Não foi possível obter dados VÁLIDOS para a imagem ID: ${myImage.id}, Path: ${myImage.path}. Usando placeholder.'); // Debug 8
      imageData = Uint8List(0); // Garante que é um Uint8List vazio
    } else {
       // Opcional: Para ter certeza que a imagem tem um cabeçalho válido
       // Você pode tentar verificar se os primeiros bytes correspondem a assinaturas de imagem (ex: JPEG, PNG)
       // Isso é avançado e pode não ser necessário se as URLs forem confiáveis.
    }

       items.add(ImageItem(
        imageData: imageData,
        date: myImage.date ?? '0${i + 1}/01/2025',
        weight: myImage.weight ?? '${50 + i}kg',
        waist: myImage.waist ?? '${60 + i}cm',
        observation: myImage.observation ?? (i % 2 == 0 ? 'Dieta' : 'Novo'),
        customTags: myImage.customTags ?? const {},
      ));
    }
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
              MaterialPageRoute(builder: (context) => const main_app.MyHomePage(title: '')),
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
                  MaterialPageRoute(builder: (context) => const main_app.MyHomePage(title: '')),
                  (Route<dynamic> route) => false,
                );
              },
              child: Icon(Icons.arrow_back, size: isLargeScreen ? screenWidth * 0.05 : screenWidth * 0.067),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<ImageItem>>( // Use FutureBuilder para lidar com o carregamento assíncrono
        future: _imageItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator()); // Mostra um loader enquanto carrega
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar imagens: ${snapshot.error}')); // Mostra erro
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nenhuma imagem encontrada.')); // Sem dados
          } else {
            // Se os dados foram carregados, exiba o GridView
            final List<ImageItem> loadedImageItems = snapshot.data!;
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
                                  imageItem.imageData,
                                  fit: BoxFit.cover,
                                  // Adicione um placeholder ou tratamento de erro visual para 'Image.memory'
                                  errorBuilder: (context, error, stackTrace) {
                                    debugPrint('Erro ao renderizar imagem do GridView: $error');
                                    return Center(
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
                            onTap: () => _showEditDialog(context, imageItem, index), // Lembre-se de ajustar _showEditDialog para usar loadedImageItems[index]
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
                    onTap: () => _showComparisonDialog(context, loadedImageItems, tags, widget.subAlbumName), // Lembre-se de ajustar _showComparisonDialog
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
        }
      ),
    );
  }  

  // **MÉTODO _showEditDialog AJUSTADO**
  // Ele recebe o ImageItem e o index diretamente
  void _showEditDialog(BuildContext context, ImageItem imageItem, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 520 && MediaQuery.of(context).size.height > 889;
    final Map<String, TextEditingController> controllers = {
      for (var tag in tags)
        tag: TextEditingController(
          text: tag == 'Data'
              ? imageItem.date
              : tag == 'Peso'
                  ? imageItem.weight
                  : tag == 'Série'
                      ? imageItem.waist
                      : tag == 'Obs'
                          ? imageItem.observation
                          : imageItem.customTags[tag] ?? '',
        ),
    };

    void saveChanges(ImageItem updatedItem) {
      setState(() {
        // Atualiza o item específico na lista _imageItems
        // Verificação de nulidade e limites para segurança
        if (_imageItems != null && index >= 0 && index < _imageItems!.length) {
          _imageItems![index] = updatedItem;
        }
        // Aqui você pode adicionar lógica para persistir as mudanças
        // Ex: salvar em um banco de dados, SharedPreferences, etc.
      });
      Navigator.of(context).pop(updatedItem); // Fecha o diálogo e retorna o item atualizado
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
                  child: imageItem.imageData.isNotEmpty
                      ? Image.memory(
                          imageItem.imageData,
                          fit: BoxFit.cover,
                        )
                      : Center(child: Text('Imagem não disponível')), // Placeholder para imagem vazia
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
                    final updatedItem = ImageItem(
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
    ).then((updatedItem) {
      // Este bloco .then é chamado quando o showDialog é fechado.
      // Se saveChanges já atualizou _imageItems e chamou setState,
      // esta parte pode não precisar fazer nada,
      // ou pode ser usada para feedback (ex: SnackBar).
      // Se você está usando um gerenciamento de estado mais complexo (Provider, Bloc, Riverpod),
      // este é o lugar para notificar o gerenciador de estado sobre a atualização.
    });
  }

void _showComparisonDialog(BuildContext context, List<ImageItem> imagesToCompare, List<String> tags, String subAlbumName) async {
  final GlobalKey repaintKey = GlobalKey();
  final GlobalKey shareRepaintKey = GlobalKey();
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final isLargeScreen = screenWidth > 520 && screenHeight > 889;

  // Use a lista 'imagesToCompare' que já é passada como parâmetro
  // Ela já contém as imagens selecionadas da tela anterior
  final List<ImageItem> selectedImages = imagesToCompare.where((item) => item.isSelected).toList();

  if (selectedImages.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecione pelo menos 2 imagens para comparar.'),
        backgroundColor: Colors.orange, // Adicionado cor para melhor feedback
      ),
    );
    return;
  }

  // Se você precisa ordenar as imagens selecionadas por um índice original,
  // precisaria que ImageItem tivesse uma propriedade 'originalIndex' ou
  // você teria que passar os pares (imageItem, originalIndex) da tela anterior.
  // Por enquanto, vou assumir que 'imagesToCompare' já vem na ordem desejada
  // ou que a ordem de seleção já é suficiente.
  // Se 'selectedImages' já veio filtrada da tela anterior, não há um 'index' associado a ela aqui.
  // Se 'index' se refere à ordem original da lista 'imagesToCompare', então precisa ser mantido.

  // Removendo a parte de ordenação por 'index' se não for necessário,
  // pois 'selectedImages' já é uma List<ImageItem>.
  // Se você realmente precisa do índice original para a comparação,
  // teríamos que ajustar como 'imagesToCompare' é populada.
  // Por enquanto, vamos assumir que selectedImages já está na ordem que você quer exibir.

  List<ImageItem> displayedImages = [
    selectedImages[0], // Pega a primeira imagem selecionada
    selectedImages[1], // Pega a segunda imagem selecionada
  ];
  // Não precisamos de 'updatedIndices' aqui se estamos trabalhando com a lista de ImageItem diretamente.
  // final List<int> updatedIndices = [selectedImages[0]['index'] as int, selectedImages[1]['index'] as int];
  final List<ImageItem> allSelectedImages = selectedImages; // allSelectedImages já é selectedImages

  final Map<String, List<TextEditingController>> controllers = {
    for (var tag in tags)
      tag: displayedImages.asMap().entries.map((entry) {
        final ImageItem item = entry.value;
        switch (tag) {
          case 'Data':
            return TextEditingController(text: item.date ?? '');
          case 'Peso':
            return TextEditingController(text: item.weight ?? '');
          case 'Cintura': // Alterado de 'Série' para 'Cintura' conforme o modelo ImageItem
            return TextEditingController(text: item.waist ?? '');
          case 'Obs':
            return TextEditingController(text: item.observation ?? '');
          default:
            return TextEditingController(text: item.customTags[tag] ?? '');
        }
      }).toList(),
  };

  Future<Uint8List?> captureCard() async {
    try {
      RenderRepaintBoundary boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Erro ao capturar o card: $e"); // Use debugPrint para logs de depuração
      return null;
    }
  }

  Future<Uint8List?> captureShareImage() async {
    try {
      RenderRepaintBoundary boundary = shareRepaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint("Erro ao capturar a imagem para compartilhamento: $e");
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
                                  Container(
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
                final Uint8List? imageBytes = await captureShareImage();
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
    final Uint8List? imageBytes = await captureCard();
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

  // Esta função saveChanges só faz sentido se você tiver acesso ao setState do ImagemDetalhesPage
  // e se você pretende persistir essas alterações nos ImageItems.
  // Se for apenas para o contexto do diálogo de comparação, não é necessário modificar a lista original.
  void saveChanges() {
    // Para persistir as alterações, você precisaria de um mecanismo para atualizar a lista
    // de imageItems na ImagemDetalhesPage (e potencialmente salvar no backend).
    // O código abaixo assume que 'imageItems' é uma variável acessível do State pai,
    // o que não é o caso dentro desta função isolada se ela não estiver dentro do State.
    // Se o objetivo é apenas exibir, não há necessidade de salvar.
    // Se for para salvar, o 'imageItems' deve ser passado como referência ou atualizado via callback.

    // Exemplo de como seria se 'imageItems' fosse acessível e 'setState' pudesse ser chamado:
    // setState(() {
    //   // Note que 'displayedImages' pode ter sido reordenado,
    //   // então, o ideal é atualizar os itens originais na lista 'imagesToCompare'
    //   // com base em algum ID único ou no próprio objeto.
    //   // Aqui, estou usando os itens de 'displayedImages' que foram modificados.
    //
    //   // Atualize as propriedades dos ImageItems originais na lista 'imagesToCompare'
    //   // (ou na lista _imageItemsFuture na ImagemDetalhesPage)
    //   // Por exemplo, você pode passar um callback para _showComparisonDialog
    //   // que atualiza a lista principal.
    //   // Ou, se 'displayedImages' são referências aos objetos de 'imagesToCompare':
    //
    //   displayedImages[0].date = controllers['Data']?[0].text ?? '';
    //   displayedImages[0].weight = controllers['Peso']?[0].text ?? '';
    //   displayedImages[0].waist = controllers['Cintura']?[0].text ?? ''; // Corrigido para 'Cintura'
    //   displayedImages[0].observation = controllers['Obs']?[0].text ?? '';
    //   tags.forEach((tag) {
    //     if (tag != 'Data' && tag != 'Peso' && tag != 'Cintura' && tag != 'Obs') { // Corrigido
    //       displayedImages[0].customTags[tag] = controllers[tag]![0].text;
    //     }
    //   });
    //
    //   displayedImages[1].date = controllers['Data']?[1].text ?? '';
    //   displayedImages[1].weight = controllers['Peso']?[1].text ?? '';
    //   displayedImages[1].waist = controllers['Cintura']?[1].text ?? ''; // Corrigido
    //   displayedImages[1].observation = controllers['Obs']?[1].text ?? '';
    //   tags.forEach((tag) {
    //     if (tag != 'Data' && tag != 'Peso' && tag != 'Cintura' && tag != 'Obs') { // Corrigido
    //       displayedImages[1].customTags[tag] = controllers[tag]![1].text;
    //     }
    //   });
    // });
    // Navigator.of(context).pop(); // Fechar o diálogo após salvar
  }


  // Certifique-se de que _scrollController está definido no State onde _showComparisonDialog é chamado
  // Se _scrollController não estiver acessível aqui, passe-o como parâmetro ou defina-o localmente.
  // Como ele é usado para o scroll das miniaturas, ele precisaria ser um ScrollController
  // do State pai ou ser inicializado aqui dentro.
  // Para fins de demonstração, vou assumir que ele pode ser um novo ScrollController se necessário
  // apenas para este diálogo, ou que o ImagemDetalhesPage tem um controller que pode ser usado.
  // Se for o mesmo controller usado na tela principal, você precisaria passá-lo para cá.
  final ScrollController _localScrollController = ScrollController(); // Usar um controller local para o diálogo

  // Funções de scroll para as miniaturas
  void _scrollLeft() {
    _localScrollController.animateTo(
      _localScrollController.offset - (screenWidth * 0.25), // Ajuste o valor de scroll conforme necessário
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _scrollRight() {
    _localScrollController.animateTo(
      _localScrollController.offset + (screenWidth * 0.25), // Ajuste o valor de scroll conforme necessário
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  // Variável para controlar qual miniatura está selecionada para exibição principal
  int? _selectedIndex; // Movido para dentro do escopo do diálogo para ser gerido pelo StatefulBuilder

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
              if (_selectedIndex == null) {
                // Encontra o índice da primeira imagem exibida na lista original 'allSelectedImages'
                _selectedIndex = allSelectedImages.indexOf(displayedImages[0]);
                if (_selectedIndex == -1 && allSelectedImages.isNotEmpty) {
                  _selectedIndex = 0; // fallback se não encontrar, seleciona o primeiro
                }
              }

              void onThumbnailTap(ImageItem tappedImage, int tappedIndexInAllSelected) {
                setState(() {
                  // A lógica aqui deve ser: a imagem clicada se torna a primeira (esquerda)
                  // e a que estava na primeira posição vai para a segunda (direita).
                  final ImageItem currentFirstImage = displayedImages[0];
                  final ImageItem currentSecondImage = displayedImages[1];

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
                    // Se a imagem clicada já for a mesma que estava na posição 0,
                    // a imagem da posição 1 permanece inalterada,
                    // ou você pode definir uma lógica para qual imagem deve ir para a direita.
                    // Para simplicidade, vou fazer a imagem atual da esquerda ir para a direita
                    // se a imagem clicada não for a mesma da esquerda.
                    if (tappedImage != currentFirstImage) {
                       displayedImages[1] = currentFirstImage;
                    }
                  }

                  // Atualiza o _selectedIndex para refletir a imagem que está agora à esquerda
                  _selectedIndex = allSelectedImages.indexOf(displayedImages[0]);

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
                      case 'Cintura': // Corrigido
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
                        case 'Cintura': // Corrigido
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
                                        imageItem.imageData,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          debugPrint('Erro ao carregar imagem em displayedImages: $error');
                                          return Center(
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
                                      }).toList(),
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
                            'Baixar',
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
                          controller: _localScrollController, // Usando o controller local
                          child: Row(
                            children: allSelectedImages.asMap().entries.map((entry) {
                              final int index = entry.key;
                              final ImageItem imageItem = entry.value;
                              return GestureDetector(
                                onTap: () {
                                  // Atualiza o estado da UI para refletir a nova seleção
                                  onThumbnailTap(imageItem, index); // Chama a função local para o tap
                                },
                                child: Container(
                                  width: isLargeScreen ? screenWidth * 0.2 : screenWidth * 0.20,
                                  height: isLargeScreen ? screenWidth * 0.2 : screenWidth * 0.20,
                                  margin: EdgeInsets.symmetric(horizontal: isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: _selectedIndex == index ? Colors.blue : Colors.grey,
                                      width: _selectedIndex == index ? 3 : 1,
                                    ),
                                    borderRadius: BorderRadius.zero,
                                  ),
                                  child: Image.memory(
                                    imageItem.imageData,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      debugPrint('Erro ao carregar imagem da miniatura: $error');
                                      return Center(
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
                          onPressed: _scrollLeft,
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
                          onPressed: _scrollRight,
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
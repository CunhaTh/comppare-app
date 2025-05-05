import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';

class ImageItem {
  final Uint8List imageData;
  late final String date;
  late final String weight;
  late final String waist;
  late final String observation;
  bool isSelected;

  ImageItem({
    required this.imageData,
    required this.date,
    required this.weight,
    required this.waist,
    required this.observation,
    this.isSelected = false,
  });
}

class ImagemDetalhesPage extends StatefulWidget {
  final List<Uint8List> images;

  const ImagemDetalhesPage({Key? key, required this.images}) : super(key: key);

  @override
  State<ImagemDetalhesPage> createState() => _ImagemDetalhesPageState();
}

class _ImagemDetalhesPageState extends State<ImagemDetalhesPage> {
  late List<ImageItem> imageItems;

  @override
  void initState() {
    super.initState();
    imageItems = widget.images.asMap().entries.map((entry) {
      final int index = entry.key;
      final Uint8List imageData = entry.value;
      return ImageItem(
        imageData: imageData,
        date: '0${index + 1}/01/2025',
        weight: '${50 + index}kg',
        waist: '${60 + index}cm',
        observation: index % 2 == 0 ? 'Dieta' : 'Novo',
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: Image.asset(
                "assets/logo_cortada.png",
                width: 150,
                height: 50,
              ),
            )
          ],
        ),
        backgroundColor: Colors.white,
        actions: [
          Builder(
            builder: (BuildContext context) {
              return Padding(
                padding: const EdgeInsets.only(right: 20),
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: const Icon(Icons.logout),
                ),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 30,
                mainAxisSpacing: 30,
              ),
              itemCount: imageItems.length,
              itemBuilder: (context, index) {
                final imageItem = imageItems[index];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      imageItem.isSelected = !imageItem.isSelected;
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: imageItem.isSelected ? Colors.green : Colors.grey,
                            width: 2.0,
                          ),
                        ),
                        child: Image.memory(
                          imageItem.imageData,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        ),
                      ),
                      if (imageItem.isSelected)
                        const Positioned(
                          top: 5,
                          right: 5,
                          child: Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 24,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Positioned(
            left: 15,
            right: 15,
            bottom: 40,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15.0),
              decoration: BoxDecoration(
                color: const Color(0xFFaed513),
                borderRadius: BorderRadius.circular(30.0),
              ),
              child: GestureDetector(
                onTap: () {
                  _showComparisonDialog(context);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Comppare',
                      style: TextStyle(fontSize: 18,color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

      void _showComparisonDialog(BuildContext context) {
  // Chave para capturar o widget como imagem
  final GlobalKey _repaintKey = GlobalKey();

  // Filtra as imagens selecionadas e cria uma lista de mapas tipados
  final List<Map<String, dynamic>> selectedImages = imageItems
      .asMap()
      .entries
      .where((entry) => entry.value.isSelected)
      .map((entry) => {
            'index': entry.key,
            'imageItem': entry.value,
          })
      .toList();

  if (selectedImages.length < 3) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Selecione pelo menos 3 imagens para comparar.'),
      ),
    );
    return;
  }

  // Ordena as imagens selecionadas pelo índice
  selectedImages.sort((a, b) {
    final int indexA = a['index'] as int;
    final int indexB = b['index'] as int;
    return indexA.compareTo(indexB);
  });

  // Pega as três imagens selecionadas
  final ImageItem firstImageItem = selectedImages[0]['imageItem'] as ImageItem;
  final ImageItem middleImageItem = selectedImages[1]['imageItem'] as ImageItem;
  final ImageItem lastImageItem = selectedImages[2]['imageItem'] as ImageItem;

  // Nome do subálbum (você precisará passar isso de alguma forma)
  String subAlbumName = "Abdomên"; // Substitua por uma variável real, se disponível

  // Controladores para os campos editáveis
  final TextEditingController firstDateController = TextEditingController(text: firstImageItem.date);
  final TextEditingController firstWeightController = TextEditingController(text: firstImageItem.weight);
  final TextEditingController firstSeriesController = TextEditingController(text: firstImageItem.waist); // Ou "series"
  final TextEditingController firstObsController = TextEditingController(text: firstImageItem.observation);

  final TextEditingController middleDateController = TextEditingController(text: middleImageItem.date);
  final TextEditingController middleWeightController = TextEditingController(text: middleImageItem.weight);
  final TextEditingController middleSeriesController = TextEditingController(text: middleImageItem.waist);
  final TextEditingController middleObsController = TextEditingController(text: middleImageItem.observation);

  final TextEditingController lastDateController = TextEditingController(text: lastImageItem.date);
  final TextEditingController lastWeightController = TextEditingController(text: lastImageItem.weight);
  final TextEditingController lastSeriesController = TextEditingController(text: lastImageItem.waist);
  final TextEditingController lastObsController = TextEditingController(text: lastImageItem.observation);

  // Função para capturar o card como imagem
  Future<Uint8List?> _captureCard() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      print("Erro ao capturar o card: $e");
      return null;
    }
  }

  // Função para compartilhar no Instagram
  Future<void> _shareToInstagram() async {
    final Uint8List? imageBytes = await _captureCard();
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao capturar o card para compartilhamento.')),
      );
      return;
    }

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/card.png').writeAsBytes(imageBytes);

    await Share.shareFiles(
      [file.path],
      text: 'Confira minha comparação!',
      mimeTypes: ['image/png'],
    );
  }

  // Função para salvar o card na galeria
  Future<void> _saveCard() async {
    final Uint8List? imageBytes = await _captureCard();
    if (imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao capturar o card para salvamento.')),
      );
      return;
    }

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

  // Função para salvar as alterações nos ImageItems
  void _saveChanges() {
    setState(() {
      firstImageItem.date = firstDateController.text;
      firstImageItem.weight = firstWeightController.text;
      firstImageItem.waist = firstSeriesController.text; // Ou "series"
      firstImageItem.observation = firstObsController.text;

      middleImageItem.date = middleDateController.text;
      middleImageItem.weight = middleWeightController.text;
      middleImageItem.waist = middleSeriesController.text;
      middleImageItem.observation = middleObsController.text;

      lastImageItem.date = lastDateController.text;
      lastImageItem.weight = lastWeightController.text;
      lastImageItem.waist = lastSeriesController.text;
      lastImageItem.observation = lastObsController.text;
    });
    Navigator.of(context).pop(); // Fecha o diálogo após salvar
  }

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                subAlbumName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const CircleAvatar(
                backgroundColor: Colors.black,
                radius: 12,
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        content: RepaintBoundary(
          key: _repaintKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Imagens lado a lado
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Image.memory(
                      firstImageItem.imageData,
                      height: 450,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Image.memory(
                      middleImageItem.imageData,
                      height: 450,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Expanded(
                    child: Image.memory(
                      lastImageItem.imageData,
                      height: 450,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Tabela com campos editáveis
              Table(
                border: TableBorder.all(color: Colors.black54, width: 2),
                columnWidths: const {
                  0: FlexColumnWidth(1),
                  1: FlexColumnWidth(1),
                  2: FlexColumnWidth(1),
                },
                children: [
                  // Linha "Data"
                  TableRow(
                    decoration: BoxDecoration(color: Colors.grey[300]),
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Data',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: firstDateController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: middleDateController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: lastDateController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Linha "Peso"
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Peso',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: firstWeightController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: middleWeightController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: lastWeightController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Linha "Série"
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Série',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: firstSeriesController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: middleSeriesController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: lastSeriesController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  // Linha "Obs"
                  TableRow(
                    children: [
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Obs',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.left,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: firstObsController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: middleObsController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: lastObsController,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ],
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                onPressed: _shareToInstagram,
                icon: const Icon(Icons.share, size: 20),
                label: const Text(
                  'Compartilhar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFaed513),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                onPressed: _saveChanges, // Salva as alterações ao clicar em "Salvar"
                icon: const Icon(Icons.save, size: 20),
                label: const Text(
                  'Salvar',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      );
    },
  );
}
}
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

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
  final List<Uint8List> images;
  final List<String> tags;
  final String subAlbumName;

  const ImagemDetalhesPage({
    Key? key,
    required this.images,
    required this.tags,
    required this.subAlbumName,
  }) : super(key: key);

  @override
  State<ImagemDetalhesPage> createState() => _ImagemDetalhesPageState();
}

class _ImagemDetalhesPageState extends State<ImagemDetalhesPage> {
  late List<ImageItem> imageItems;
  late List<String> tags;
  final ScrollController _scrollController = ScrollController();
  
  int? _selectedIndex;

  List<ImageItem> allSelectedImages = [];

  void _onThumbnailTap(ImageItem imageItem, int index) {
    setState(() {
      _selectedIndex = index; // Update selected index
    });
  }

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
    tags = widget.tags;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    _scrollController.animateTo(
      _scrollController.offset - (MediaQuery.of(context).size.width * 0.33), // ~120px proporcional
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _scrollRight() {
    _scrollController.animateTo(
      _scrollController.offset + (MediaQuery.of(context).size.width * 0.33), // ~120px proporcional
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Center(
            child: Image.asset(
              "assets/logo_cortada.png",
              width: screenWidth * 0.4, // 40% da largura
              height: screenHeight * 0.07, // 7% da altura
              fit: BoxFit.contain,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.05), // 5% da largura
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.logout, size: screenWidth * 0.067), // ~24px
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(screenWidth * 0.022), // ~8px
            child: GridView.builder(
              padding: EdgeInsets.all(screenWidth * 0.028), // ~10px
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: (screenWidth / 150).floor().clamp(1, 3), // Ajusta colunas dinamicamente
                childAspectRatio: 1,
                crossAxisSpacing: screenWidth * 0.083, // ~30px
                mainAxisSpacing: screenWidth * 0.083, // ~30px
              ),
              itemCount: imageItems.length,
              itemBuilder: (context, index) {
                final imageItem = imageItems[index];
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
                          ),
                        ),
                      ),
                    ),
                    if (imageItem.isSelected)
                      Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.014), // ~5px
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: screenWidth * 0.067, // ~24px
                        ),
                      ),
                    GestureDetector(
                      onTap: () => _showEditDialog(context, index),
                      child: Padding(
                        padding: EdgeInsets.only(top: screenWidth * 0.014), // ~5px
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'edit',
                              style: TextStyle(fontSize: 17 * MediaQuery.of(context).textScaleFactor),
                            ),
                            SizedBox(width: screenWidth * 0.017), // ~6px
                            Icon(
                              Icons.edit,
                              color: Colors.black,
                              size: screenWidth * 0.047, // ~17px
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
            left: screenWidth * 0.042, // ~15px
            right: screenWidth * 0.042, // ~15px
            bottom: screenHeight * 0.1, // ~10% da altura
            child: GestureDetector(
              onTap: () => _showComparisonDialog(context, imageItems, tags, widget.subAlbumName),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.028, // ~10px
                  vertical: screenHeight * 0.022, // ~15px
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFaed513),
                  borderRadius: BorderRadius.circular(screenWidth * 0.083), // ~30px
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
      ),
    );
  }

  void _showEditDialog(BuildContext context, int index) {
    final imageItem = imageItems[index];
    final screenWidth = MediaQuery.of(context).size.width;
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

    void _saveChanges(ImageItem updatedItem) {
      setState(() {
        imageItems[index] = updatedItem;
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
                  radius: screenWidth * 0.033, // ~12px
                  child: Icon(
                    Icons.close,
                    color: Colors.white,
                    size: screenWidth * 0.044, // ~16px
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
                  height: screenWidth * 0.8, // 80% da largura
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(screenWidth * 0.022), // ~8px
                  ),
                  child: Image.memory(
                    imageItem.imageData,
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(height: screenWidth * 0.044), // ~16px
                if (tags.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: tags.map((tag) {
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: screenWidth * 0.022), // ~8px
                        child: Row(
                          children: [
                            SizedBox(
                              width: screenWidth * 0.28, // ~100px
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
                                    horizontal: screenWidth * 0.028, // ~10px
                                    vertical: screenWidth * 0.022, // ~8px
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
                    padding: EdgeInsets.symmetric(vertical: screenWidth * 0.022), // ~8px
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
                      horizontal: screenWidth * 0.044, // ~16px
                      vertical: screenWidth * 0.033, // ~12px
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(screenWidth * 0.022), // ~8px
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
                    _saveChanges(updatedItem);
                  },
                  icon: Icon(Icons.save, size: screenWidth * 0.056), // ~20px
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
      if (updatedItem != null && updatedItem is ImageItem) {
        setState(() {
          imageItems[index] = updatedItem;
        });
      }
    });
  }

  void _showComparisonDialog(BuildContext context, List<ImageItem> imageItems, List<String> tags, String subAlbumName) {
    final GlobalKey _repaintKey = GlobalKey();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final List<Map<String, dynamic>> selectedImages = imageItems
        .asMap()
        .entries
        .where((entry) => entry.value.isSelected)
        .map((entry) => {
              'index': entry.key,
              'imageItem': entry.value,
            })
        .toList();

    if (selectedImages.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos 2 imagens para comparar.'),
        ),
      );
      return;
    }

    selectedImages.sort((a, b) {
      final int indexA = a['index'] as int;
      final int indexB = b['index'] as int;
      return indexA.compareTo(indexB);
    });

    List<ImageItem> displayedImages = [
      selectedImages[0]['imageItem'] as ImageItem,
      selectedImages[1]['imageItem'] as ImageItem,
    ];
    final List<int> updatedIndices = [selectedImages[0]['index'] as int, selectedImages[1]['index'] as int];
    final List<ImageItem> allSelectedImages = selectedImages.map((entry) => entry['imageItem'] as ImageItem).toList();

    final Map<String, List<TextEditingController>> controllers = {
      for (var tag in tags)
        tag: displayedImages.asMap().entries.map((entry) {
          final int index = entry.key;
          final ImageItem item = entry.value;
          switch (tag) {
            case 'Data':
              return TextEditingController(text: item.date ?? '');
            case 'Peso':
              return TextEditingController(text: item.weight ?? '');
            case 'Série':
              return TextEditingController(text: item.waist ?? '');
            case 'Obs':
              return TextEditingController(text: item.observation ?? '');
            default:
              return TextEditingController(text: (item.customTags ?? {})[tag] ?? '');
          }
        }).toList(),
    };

    Future<Uint8List?> _captureCard() async {
      try {
        RenderRepaintBoundary boundary = _repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        return byteData?.buffer.asUint8List();
      } catch (e) {
        print("Erro ao capturar o card: $e");
        return null;
      }
    }

    Future<void> _shareToInstagram() async {
      final Uint8List? imageBytes = await _captureCard();
      if (imageBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao capturar o card para compartilhamento.')),
        );
        return;
      }

      if (kIsWeb) {
        final blob = html.Blob([imageBytes], 'image/png');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', 'card.png')
          ..click();
        html.Url.revokeObjectUrl(url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Imagem baixada. Compartilhe manualmente.')),
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = await File('${tempDir.path}/card.png').writeAsBytes(imageBytes);
        await Share.shareFiles(
          [file.path],
          text: 'Confira minha comparação!',
          mimeTypes: ['image/png'],
        );
      }
    }

    Future<void> _saveCard() async {
      final Uint8List? imageBytes = await _captureCard();
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

    void _saveChanges() {
      final List<ImageItem> updatedItems = [
        ImageItem(
          imageData: displayedImages[0].imageData,
          date: controllers['Data']?[0].text ?? '',
          weight: controllers['Peso']?[0].text ?? '',
          waist: controllers['Série']?[0].text ?? '',
          observation: controllers['Obs']?[0].text ?? '',
          customTags: {
            for (var tag in tags)
              if (tag != 'Data' && tag != 'Peso' && tag != 'Série' && tag != 'Obs')
                tag: controllers[tag]![0].text,
          },
        ),
        ImageItem(
          imageData: displayedImages[1].imageData,
          date: controllers['Data']?[1].text ?? '',
          weight: controllers['Peso']?[1].text ?? '',
          waist: controllers['Série']?[1].text ?? '',
          observation: controllers['Obs']?[1].text ?? '',
          customTags: {
            for (var tag in tags)
              if (tag != 'Data' && tag != 'Peso' && tag != 'Série' && tag != 'Obs')
                tag: controllers[tag]![1].text,
          },
        ),
      ];
      setState(() {
        imageItems[updatedIndices[0]] = updatedItems[0];
        imageItems[updatedIndices[1]] = updatedItems[1];
      });
      Navigator.of(context).pop();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            void _onThumbnailTap(ImageItem tappedImage, int index) {
              setState(() {
                final ImageItem currentFirstImage = displayedImages[0];
                displayedImages[0] = tappedImage;
                displayedImages[1] = currentFirstImage;
                controllers.forEach((tag, controllerList) {
                  controllerList[0].text = displayedImages[0].customTags?[tag] ?? '';
                  controllerList[1].text = displayedImages[1].customTags?[tag] ?? '';
                  switch (tag) {
                    case 'Data':
                      controllerList[0].text = displayedImages[0].date ?? '';
                      controllerList[1].text = displayedImages[1].date ?? '';
                      break;
                    case 'Peso':
                      controllerList[0].text = displayedImages[0].weight ?? '';
                      controllerList[1].text = displayedImages[1].weight ?? '';
                      break;
                    case 'Série':
                      controllerList[0].text = displayedImages[0].waist ?? '';
                      controllerList[1].text = displayedImages[1].waist ?? '';
                      break;
                    case 'Obs':
                      controllerList[0].text = displayedImages[0].observation ?? '';
                      controllerList[1].text = displayedImages[1].observation ?? '';
                      break;
                  }
                });
              });
            }

            return AlertDialog(
              title: Row(
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
                      radius: screenWidth * 0.033, // ~12px
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: screenWidth * 0.044, // ~16px
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
                      key: _repaintKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: displayedImages.map((imageItem) {
                              return Expanded(
                                child: Container(
                                  height: screenWidth * 0.9, // 90% da largura
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.grey, width: 1),
                                    borderRadius: BorderRadius.circular(screenWidth * 0.022), // ~8px
                                  ),
                                  child: Image.memory(
                                    imageItem.imageData,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: screenWidth * 0.028), // ~10px
                          if (tags.isNotEmpty)
                            Table(
                              border: TableBorder.all(color: Colors.black54, width: 1),
                              columnWidths: {
                                0: const FlexColumnWidth(1),
                                for (int i = 0; i < displayedImages.length; i++)
                                  (i + 1): const FlexColumnWidth(1),
                              },
                              children: tags.asMap().entries.map((entry) {
                                final int tagIndex = entry.key;
                                final String tag = entry.value;
                                return TableRow(
                                  decoration: tagIndex == 0 ? BoxDecoration(color: Colors.grey[300]) : null,
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.only(
                                        top: screenWidth * 0.014, // ~5px
                                        left: screenWidth * 0.028, // ~10px
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12 * MediaQuery.of(context).textScaleFactor,
                                        ),
                                      ),
                                    ),
                                    ...displayedImages.asMap().entries.map((imageEntry) {
                                      final int imageIndex = imageEntry.key;
                                      return Padding(
                                        padding: EdgeInsets.all(screenWidth * 0.0056), // ~2px
                                        child: TextField(
                                          controller: controllers[tag]![imageIndex],
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          style: TextStyle(
                                            fontSize: 12 * MediaQuery.of(context).textScaleFactor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }),
                                  ],
                                );
                              }).toList(),
                            )
                          else
                            Padding(
                              padding: EdgeInsets.all(screenWidth * 0.022), // ~8px
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
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: screenWidth * 0.028), // ~10px
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFaed513),
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.044, // ~16px
                                vertical: screenWidth * 0.033, // ~12px
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.022), // ~8px
                              ),
                            ),
                            onPressed: _shareToInstagram,
                            icon: Icon(Icons.share, size: screenWidth * 0.056), // ~20px
                            label: Text(
                              'Compartilhar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                              ),
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.056), // ~20px
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFaed513),
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.044, // ~16px
                                vertical: screenWidth * 0.033, // ~12px
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(screenWidth * 0.022), // ~8px
                              ),
                            ),
                            onPressed: _saveCard,
                            icon: Icon(Icons.download, size: screenWidth * 0.056), // ~20px
                            label: Text(
                              'Baixar',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                   Stack(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        controller: _scrollController,
                        child: Row(
                          children: allSelectedImages.asMap().entries.map((entry) {
                            final int index = entry.key;
                            final ImageItem imageItem = entry.value;
                            return GestureDetector(
                              onTap: () => _onThumbnailTap(imageItem, index),
                              child: Container(
                                width: screenWidth * 0.28, // ~100px
                                height: screenWidth * 0.28, // ~100px
                                margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.022), // ~8px
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: _selectedIndex == index ? Colors.blue : Colors.grey, // Highlight selected image
                                    width: _selectedIndex == index ? 3 : 1, // Thicker border for selected
                                  ),
                                  borderRadius: BorderRadius.circular(screenWidth * 0.022), // ~8px
                                ),
                                child: Image.memory(
                                  imageItem.imageData,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Positioned(
                        left: 0,
                        top: screenWidth * 0.11, // Centraliza verticalmente
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.black,
                            size: screenWidth * 0.056, // ~20px
                          ),
                          onPressed: _scrollLeft,
                          tooltip: 'Rolar para a esquerda',
                        ),
                      ),
                      Positioned(
                        right: 0,
                        top: screenWidth * 0.11, // Centraliza verticalmente
                        child: IconButton(
                          icon: Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.black,
                            size: screenWidth * 0.056, // ~20px
                          ),
                          onPressed: _scrollRight,
                          tooltip: 'Rolar para a direita',
                        ),
                      ),
                    ],
                  )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
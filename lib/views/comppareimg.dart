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
    super.key,
    required this.images,
    required this.tags,
    required this.subAlbumName,
  });

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
      _selectedIndex = index;
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
          onTap: () => Navigator.of(context).pop(),
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
              onTap: () => Navigator.of(context).pop(),
              child: Icon(Icons.logout, size: isLargeScreen ? screenWidth * 0.05 : screenWidth * 0.067),
            ),
          ),
        ],
      ),
      body: Stack(
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
                        padding: EdgeInsets.only(top: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: isLargeScreen ? screenWidth * 0.05 : screenWidth * 0.067,
                        ),
                      ),
                    GestureDetector(
                      onTap: () => _showEditDialog(context, index),
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
              onTap: () => _showComparisonDialog(context, imageItems, tags, widget.subAlbumName),
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
      ),
    );
  }

  void _showEditDialog(BuildContext context, int index) {
    final imageItem = imageItems[index];
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
                  child: Image.memory(
                    imageItem.imageData,
                    fit: BoxFit.cover,
                  ),
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
      if (updatedItem != null && updatedItem is ImageItem) {
        setState(() {
          imageItems[index] = updatedItem;
        });
      }
    });
  }

void _showComparisonDialog(BuildContext context, List<ImageItem> imageItems, List<String> tags, String subAlbumName) {
  final GlobalKey repaintKey = GlobalKey();
  final GlobalKey shareRepaintKey = GlobalKey();
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  final isLargeScreen = screenWidth > 520 && screenHeight > 889;

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
      print("Erro ao capturar o card: $e");
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
      print("Erro ao capturar a imagem para compartilhamento: $e");
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

  void saveChanges() {
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
      return AlertDialog(
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.all(8.0),
        content: Container(
          width: screenWidth * 0.98,
          height: screenHeight * 0.90,
          decoration: BoxDecoration(),
          child: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              void onThumbnailTap(ImageItem tappedImage, int index) {
                setState(() {
                  final ImageItem currentFirstImage = displayedImages[0];
                  displayedImages[0] = tappedImage;
                  displayedImages[1] = currentFirstImage;
                  controllers.forEach((tag, controllerList) {
                    if (controllerList.length > 1) {
                      controllerList[0].text = displayedImages[0].customTags[tag] ?? '';
                      controllerList[1].text = displayedImages[1].customTags[tag] ?? '';
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
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: displayedImages.map((imageItem) {
                                return Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.zero,
                                    child: Container(
                                      height: double.infinity,
                                      child: Image.memory(
                                        imageItem.imageData,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          SizedBox(height: isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.010),
                          if (tags.isNotEmpty)
                            Container(
                              padding: EdgeInsets.all(isLargeScreen ? screenWidth * 0.02 : screenWidth * 0.02),
                              child: Wrap(
                                spacing: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014,
                                runSpacing: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014,
                                children: tags.asMap().entries.map((entry) {
                                  final int tagIndex = entry.key;
                                  final String tag = entry.value;
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014,
                                          vertical: isLargeScreen ? screenWidth * 0.005 : screenWidth * 0.007,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: Text(
                                          tag,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15 * MediaQuery.of(context).textScaleFactor,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 20,),
                                    //  SizedBox(width: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014),
                                      ...displayedImages.asMap().entries.map((imageEntry) {
                                        final int imageIndex = imageEntry.key;
                                        return SizedBox(
                                          width: isLargeScreen ? screenWidth * 0.15 : screenWidth * 0.2,
                                          child: TextField(
                                            controller: controllers[tag]![imageIndex],
                                            /*decoration: InputDecoration(
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(5),
                                              ),
                                              contentPadding: EdgeInsets.symmetric(
                                                horizontal: isLargeScreen ? screenWidth * 0.01 : screenWidth * 0.014,
                                                vertical: isLargeScreen ? screenWidth * 0.005 : screenWidth * 0.007,
                                              ),
                                            ),*/
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
                              horizontal: isLargeScreen ? screenWidth * 0.03 : screenWidth * 0.044,
                              vertical: isLargeScreen ? screenWidth * 0.025 : screenWidth * 0.033,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
                            ),
                          ),
                          onPressed: shareImages,
                          icon: Icon(Icons.share, size: isLargeScreen ? screenWidth * 0.04 : screenWidth * 0.056),
                          label: Text(
                            'Compartilhar',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14 * MediaQuery.of(context).textScaleFactor,
                            ),
                          ),
                        ),
                        SizedBox(width: isLargeScreen ? screenWidth * 0.04 : screenWidth * 0.056),
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
                          onPressed: saveCard,
                          icon: Icon(Icons.download, size: isLargeScreen ? screenWidth * 0.04 : screenWidth * 0.056),
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
                              onTap: () {
                                setState(() {
                                  _selectedIndex = index;
                                });
                                onThumbnailTap(imageItem, index);
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
                                  borderRadius: BorderRadius.circular(isLargeScreen ? screenWidth * 0.015 : screenWidth * 0.022),
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
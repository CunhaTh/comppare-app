import 'dart:typed_data';

import 'package:application_progress/models/image_model.dart';
import 'package:flutter/material.dart';


// Ele deve ser um StatefulWidget para gerenciar o estado de zoom e pan.
class ShareableFrameWithZoom extends StatefulWidget {
  final GlobalKey shareRepaintKey;
  final List<ImageModel> displayedImages;
  final bool isLargeScreen;

  const ShareableFrameWithZoom({
    super.key,
    required this.shareRepaintKey,
    required this.displayedImages,
    required this.isLargeScreen,
  });

  @override
  State<ShareableFrameWithZoom> createState() => ShareableFrameWithZoomState();
}

class ShareableFrameWithZoomState extends State<ShareableFrameWithZoom> {
  Matrix4 _matrix1 = Matrix4.identity();
  Matrix4 _matrix2 = Matrix4.identity();

  // Dimensões Padrão para cada imagem na moldura de compartilhamento
  // Se o usuário usa o editor de zoom, essas dimensões definem o tamanho do ClipRect.
  final double _imageWidth = 150.0;
  final double _imageHeight = 250.0;
  final double _spacing = 8.0;

  Future<void> _openZoomEditor(int index) async {
    final ImageModel imageItem = widget.displayedImages[index];
    final Matrix4 currentMatrix = (index == 0) ? _matrix1 : _matrix2;

    final Matrix4? resultMatrix = await showModalBottomSheet<Matrix4>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return ZoomEditorModal(
          imageItem: imageItem,
          initialMatrix: currentMatrix,
        );
      },
    );

    if (resultMatrix != null) {
      setState(() {
        if (index == 0) {
          _matrix1 = resultMatrix;
        } else {
          _matrix2 = resultMatrix;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ O RepaintBoundary é a moldura de captura.
    return RepaintBoundary(
      key: widget.shareRepaintKey,
      // ⭐️ PASSO 1: O Container define a cor de fundo (essencial contra o preto).
      // Sem width/height fixos, ele se adapta ao filho.
      child: Container(
        color: Colors.white,
        // ⭐️ PASSO 2: Usar Column/Row com MainAxisSize.min para "abraçar" o conteúdo.
        child: Column(
          mainAxisSize: MainAxisSize.min, // Chave para remover a sobra vertical
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // O conteúdo principal é o Row das imagens
            Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 12.0, right: 12.0),
              child: Row(
                mainAxisSize: MainAxisSize.min, // Chave para remover a sobra horizontal
                mainAxisAlignment: MainAxisAlignment.center,
                // Não usamos Expanded aqui dentro, pois o Expanded força o preenchimento total.
                children: widget.displayedImages.map((imageItem) {
                  final index = widget.displayedImages.indexOf(imageItem);
                  final currentMatrix = (index == 0) ? _matrix1 : _matrix2;

                  return Padding(
                    padding: index == 0 ? EdgeInsets.zero : EdgeInsets.only(left: _spacing),
                    // Definimos o tamanho exato de CADA imagem.
                    child: SizedBox(
                      width: _imageWidth,
                      height: _imageHeight,
                      child: GestureDetector(
                        onTap: () => _openZoomEditor(index),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRect(
                              child: Transform(
                                transform: currentMatrix,
                                alignment: Alignment.center,
                                child: Image.memory(
                                  // Assumindo que imageData não é nulo.
                                  imageItem.imageData ?? Uint8List(0), 
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),

                            // ÍCONE DE EDIÇÃO
                            Align(
                              alignment: Alignment.topRight,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  padding: const EdgeInsets.all(4.0),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.zoom_in_map,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // POSICIONAMENTO DA LOGO (Fixado ao fundo da área de captura)
            Padding(
              padding: const EdgeInsets.only(bottom: 12.0, top: 40.0), // Aumentei o espaçamento superior
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min, // Crucial para o Container da logo
                    children: [
                      // Usando Asset de Exemplo (Assumindo que o logo_all_green.png exista)
                      Image.asset(
                        "assets/logo_all_green.png", 
                        width: 25.0,
                        height: 25.0,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'comppare',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFaed513),
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
    );
  }
}

// Este é o widget de edição que será mostrado em um showDialog/showModalBottomSheet.
// Mantido o mesmo, pois o foco era apenas na visualização de compartilhamento.
class ZoomEditorModal extends StatelessWidget {
  final ImageModel imageItem;
  final Matrix4 initialMatrix; // Matriz salva do estado anterior

  const ZoomEditorModal({
    super.key,
    required this.imageItem,
    required this.initialMatrix,
  });

  @override
  Widget build(BuildContext context) {
    final transformationController = TransformationController(initialMatrix);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar Zoom'),
        backgroundColor: const Color(0xFF9bc412),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, transformationController.value);
            },
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: transformationController,
          panEnabled: true,
          scaleEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.memory(
            imageItem.imageData ?? Uint8List(0),
            fit: BoxFit.contain, // BoxFit.contain é mais adequado para o modal de edição
          ),
        ),
      ),
    );
  }
}
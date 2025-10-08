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
const double frameWidth = 300.0;
const double frameHeight = 533.0;

return RepaintBoundary(
 key: widget.shareRepaintKey,
 child: Container(
width: frameWidth,
height: frameHeight,
color: Colors.white,

child: Stack(
 children: [
 Positioned.fill(
child: Column(
 crossAxisAlignment: CrossAxisAlignment.stretch,
 children: [
Expanded(
 child: Row(
mainAxisAlignment: MainAxisAlignment.center,
crossAxisAlignment: CrossAxisAlignment.stretch,
children: widget.displayedImages.map((imageItem) {
 final index = widget.displayedImages.indexOf(imageItem);
 final currentMatrix = (index == 0) ? _matrix1 : _matrix2;

 return Expanded(
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
imageItem.imageData!,
fit: BoxFit.cover,
 ),
),
 ),
 
 // ÍCONE DE EDIÇÃO - CORRIGIDO PARA VISIBILIDADE
 Align(
alignment: Alignment.topRight,
                child: Padding(
                   padding: const EdgeInsets.all(8.0),
                   child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                     color: Colors.black.withOpacity(0.4), // Fundo escuro
                     shape: BoxShape.circle,
                    ),
                    child: const Icon(
                     Icons.zoom_in_map,
                     color: Colors.white, // Ícone claro
                     size: 20,
                    ),
                   ),
                  ),
                 ),
                ],
               ),
              ),
             );
            }).toList(),
           ),
          ),
         ],
        ),
       ),
// POSICIONAMENTO DA LOGO (Flutuante sobre as Imagens - CÓDIGO FINALIZADO)
Positioned(
left: 0,
right: 0,
bottom: 30.0,
child: Center(
child: Container(
 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
 decoration: BoxDecoration(
   color: Colors.white.withOpacity(0.85),
   borderRadius: BorderRadius.circular(15),
 ),
 child: Row(
   mainAxisSize: MainAxisSize.min,
   children: [
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
class ZoomEditorModal extends StatelessWidget {
  final ImageModel imageItem;
  final Matrix4 initialMatrix; // Matriz salva do estado anterior

  const ZoomEditorModal({
    required this.imageItem,
    required this.initialMatrix,
  });

  @override
  Widget build(BuildContext context) {
    // A GlobalKey é usada para obter a Matriz de Transformação FINAL
    final transformationController = TransformationController(initialMatrix);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustar Zoom'),
        backgroundColor: const Color(0xFF9bc412),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            // Ao salvar, retorna a matriz final
            onPressed: () {
              Navigator.pop(context, transformationController.value);
            },
          ),
        ],
      ),
body: 
    Center(
        child: InteractiveViewer(
        transformationController: transformationController,
        panEnabled: true,
        scaleEnabled: true,
        minScale: 1.0,
        maxScale: 4.0,
        // ⭐️ REMOVIDO: AspectRatio(aspectRatio: 1.0)
        child: Image.memory(
          imageItem.imageData!,
          fit: BoxFit.cover, // Use .contain ou .fitWidth/Height para melhor visualização no modal
          // Você pode querer usar BoxFit.contain ou BoxFit.fitHeight aqui, 
          // dependendo de como você quer que a imagem preencha a tela do modal.
        ),
        ),
      ),
    );
  }
}
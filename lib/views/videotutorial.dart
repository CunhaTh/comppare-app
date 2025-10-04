import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

// O widget que contém a lógica do player de vídeo
class VideoPlayerDialogContent extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerDialogContent({super.key, required this.videoUrl});

  @override
  State<VideoPlayerDialogContent> createState() => _VideoPlayerDialogContentState();
}

class _VideoPlayerDialogContentState extends State<VideoPlayerDialogContent> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    _initializeVideoPlayerFuture = _controller.initialize().then((_) {
      setState(() {}); 
      _controller.setLooping(true);
      _controller.play(); // Inicia a reprodução automaticamente ao abrir o diálogo
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          // Usa AspectRatio para manter a proporção do vídeo
          return AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: Stack(
              alignment: Alignment.center, // Centraliza os controles
              children: <Widget>[
                VideoPlayer(_controller),
                // Botão de Play/Pause transparente
                InkWell(
                  onTap: () {
                    setState(() {
                      _controller.value.isPlaying ? _controller.pause() : _controller.play();
                    });
                  },
                  child: AnimatedOpacity(
                    opacity: _controller.value.isPlaying ? 0.0 : 1.0, // Fica visível apenas quando pausado
                    duration: const Duration(milliseconds: 300),
                    child: Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                        size: 50.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Tela de carregamento
          return const SizedBox(
            height: 200, // Altura mínima enquanto carrega
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
      },
    );
  }
}
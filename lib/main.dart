import 'package:application_progress/cadastro.dart';
import 'package:flutter/material.dart';
/*import 'package:video_player/video_player.dart';*/

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AppProgress',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Meu Progresso'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});


  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
   /* late VideoPlayerController _videoPlayerController;
   @override
  void initState() {
    super.initState();
    _videoPlayerController = VideoPlayerController.asset("assets/video_god2.mp4")..initialize().then((context){
      _videoPlayerController.play();
      _videoPlayerController.setLooping(true);
      setState(() {});
    });
    }
  @override
  void dispose(){
    super.dispose();
    _videoPlayerController.dispose();
  }*/

  @override
  Widget build(BuildContext context) {
       return Scaffold(body: Stack(children: [
         SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            child: Image.asset("assets/tela_principal.png")
          ),
        ),
      ),
        
     /* SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            height: _videoPlayerController?.value?.size?.height ?? 0,
            width: _videoPlayerController?.value?.size?.width  ?? 0,
            child: VideoPlayer(_videoPlayerController),
          ),
        ),
      ),*/
      FloatingActionButton(onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroScreen()));
        },   tooltip: 'Click' , // Texto que aparece ao passar/parar o cursos em cima do botão
        child:  Container(
          child: const Text('Assinar'),),
      ),
    ],),);
  } 
   /* return Scaffold(
      appBar: AppBar(
  
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        
        title: Text(widget.title),
      ),
      body: const Center(
       
        child: Column(
        
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Meu App de Progresso',
            ),
  
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => CadastroScreen()));
        },
        tooltip: 'Click' , // Texto que aparece ao passar/parar o cursos em cima do botão
        child:  Container(
          child: const Text('Assinar'),),
      ),
    );*/
  }


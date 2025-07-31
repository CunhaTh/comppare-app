import 'package:application_progress/main.dart';
import 'package:application_progress/principal.dart';
import 'package:application_progress/views/pagemconstrucao.dart';
import 'package:flutter/material.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADM',
      theme: ThemeData(
        primaryColor: const Color(0xFF637700), // Cor primária
        scaffoldBackgroundColor: const Color.fromARGB(255, 212, 213, 206), // Cor de fundo
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black),
        ),
        colorScheme: ColorScheme.fromSwatch().copyWith(secondary: const Color(0xFFaed513)),
      ),
      home: //const AdmPage(),
            const PrincipalPage()
    );
  }
}

class AdmPage extends StatefulWidget {
  const AdmPage({super.key});

  @override
  _AdmPageState createState() => _AdmPageState();
}

class _AdmPageState extends State<AdmPage> {
  // Para armazenar o índice do ListTile selecionado
  int? selectedTileIndex;
  int? selectedQuestionIndex;

  // Lista de FAQs
  final List<Map<String, String>> faqs = [
    {
      "question": "Como faço para assinar um plano?",
      "answer": "Para assinar um plano, escolha um dos planos disponíveis e clique no botão 'Assinar'."
    },
    {
      "question": "Quais são os métodos de pagamento aceitos?",
      "answer": "Aceitamos cartões de crédito, débito e PayPal."
    },
    {
      "question": "Posso cancelar minha assinatura?",
      "answer": "Sim, você pode cancelar sua assinatura a qualquer momento através da sua conta."
    },
    {
      "question": "Como posso mudar meu plano?",
      "answer": "Para mudar seu plano, entre em contato com o suporte ao cliente."
    },
  ];
  
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Padding(
          padding: const EdgeInsets.only(left: 100),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ),
              Row(
                children: [
                  Builder(
                    builder: (BuildContext context) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Pagemconstrucao() //const MyHomePage(title: '',),
                              ),
                            );
                          },
                          child: const Icon(Icons.logout)
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              'Aqui você pode customizar / Configurar "TODO" o APP',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF637700),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: const Text(
                  'BOTÂO',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Configurações',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('Permissões'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Lógica para abrir a tela de permissões
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Tags'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Lógica para abrir a tela de tags
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Notificações'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Lógica para abrir a tela de notificações
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('Sobre'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // Lógica para abrir a tela 'Sobre'
                    },
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('FAQs'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      setState(() {
                        selectedTileIndex = selectedTileIndex == 0 ? null : 0; // Alterna a visibilidade do ListView
                      });
                    },
                  ),
                  if (selectedTileIndex == 0) ...[
                    SizedBox(
                      height: 200, // Definindo uma altura fixa para o ListView
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: faqs.length,
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedQuestionIndex = selectedQuestionIndex == index ? null : index;
                              });
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    faqs[index]["question"]!,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (selectedQuestionIndex == index) ...[
                                    const SizedBox(height: 5),
                                    Text(faqs[index]["answer"]!)
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

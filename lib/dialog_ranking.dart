import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Para usar firstWhereOrNull (opcional)

import 'app_colors.dart';
import 'infra/repositories/ranking_repository.dart';
import 'infra/user_helper.dart';
// Importar o modelo centralizado

class DialogRanking extends StatefulWidget {
  const DialogRanking({super.key});

  @override
  State<DialogRanking> createState() => _DialogRankingState();
}

class _DialogRankingState extends State<DialogRanking> {
  bool _isLoading = true; // Única variável de controle de carregamento

  List<RankingItemModel> items = [];

  // Método para obter a posição do usuário atual
  RankingItemModel? get positionCurrentUser {
    final userName = UserHelper.instance.user?.nome ?? '';
    return items.firstWhereOrNull(
      (i) => i.nome == userName && (i.position ?? 0) > 5,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadRankingData();
  }

  // Método para carregar e atribuir posições aos dados do ranking
  Future<void> _loadRankingData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      items = await RankingRepository.getDataRanking() ?? [];
      items = getPositions(items);
    } catch (e) {
      // Log ou tratamento de erro, se necessário
      print('Erro ao carregar ranking: $e');
      items = []; // Define uma lista vazia em caso de erro
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para atribuir posições aos itens
  List<RankingItemModel> getPositions(List<RankingItemModel> items) {
    for (int i = 0; i < items.length; i++) {
      items[i] = RankingItemModel(
        position: i + 1,
        nome: items[i].nome,
        pontos: items[i].pontos,
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Image.asset('assets/ranking.png', width: 50),
                ),
                const Text(
                  'Ranking',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(width: 30),
            const Tooltip(
              message: 'Você acumula pontos à medida em que usa os serviços do nosso app',
              child: Icon(Icons.info_outline, size: 20),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.height * 0.4,
          child: Builder(
            builder: (context) {
              if (_isLoading) {
                return const Center(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: CircularProgressIndicator.adaptive(
                      strokeWidth: 2,
                      backgroundColor: AppColors.primaryColor,
                    ),
                  ),
                );
              }
              if (items.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum ponto foi registrado ainda.\n'
                    'Seja o primeiro a acumular pontos e se destacar!',
                    textAlign: TextAlign.center,
                  ),
                );
              }
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...items.take(5).map((i) {
                      return PositionCard(
                        position: i.position ?? 0,
                        name: i.nome ?? 'Desconhecido',
                        points: i.pontos ?? '0',
                      );
                    }),
                    if (positionCurrentUser != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.more_horiz, size: 40),
                          PositionCard(
                            position: positionCurrentUser!.position ?? 0,
                            name: positionCurrentUser!.nome ?? 'Você',
                            points: positionCurrentUser!.pontos ?? '0',
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Fechar',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PositionCard extends StatelessWidget {
  const PositionCard({
    super.key,
    required this.position,
    required this.name,
    required this.points,
  });

  final int position;
  final String? name; // Tornar name opcional para lidar com null
  final String? points; // Tornar points opcional para lidar com null

  Color get positionColor {
    switch (position) {
      case 1:
        return const Color(0xFFFFB800);
      case 2:
        return const Color(0xFFAAAAAA);
      case 3:
        return const Color(0xFFE46E00);
      default:
        return Colors.black.withOpacity(0.7);
    }
  }

  TextStyle get textStyle {
    return TextStyle(
      color: positionColor,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text('$positionº', style: textStyle),
                const SizedBox(width: 10),
                Text(
                  name == (UserHelper.instance.user?.nome ?? '')
                      ? 'Você'
                      : name ?? 'Desconhecido',
                  style: textStyle,
                ),
              ],
            ),
            Text('${points ?? '0'} pts', style: textStyle),
          ],
        ),
      ),
    );
  }
}
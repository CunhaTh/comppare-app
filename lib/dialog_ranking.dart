import 'package:flutter/material.dart';
import 'package:collection/collection.dart'; // Para usar firstWhereOrNull (opcional)

import 'infra/repositories/ranking_repository.dart';
import 'infra/user_helper.dart';
import 'models/ranking_item_model.dart'; // Importar o modelo centralizado

class DialogRanking extends StatefulWidget {
  const DialogRanking({super.key});

  @override
  State<DialogRanking> createState() => _DialogRankingState();
}

class _DialogRankingState extends State<DialogRanking> {
  List<RankingItemModel> items = [];
  bool _isLoading = true; // Para controlar o estado de carregamento

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

  Future<void> _loadRankingData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      items = await RankingRepository.getDataRanking();
      items = getPositions(items);
    } catch (e) {
      // Exibir mensagem de erro, se necessário
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar ranking: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Método para calcular as posições com base nos pontos
  List<RankingItemModel> getPositions(List<RankingItemModel> items) {
    // Ordenar os itens por pontos (assumindo que pontos é uma String numérica)
    items.sort((a, b) {
      final pontosA = int.tryParse(a.pontos ?? '0') ?? 0;
      final pontosB = int.tryParse(b.pontos ?? '0') ?? 0;
      return pontosB.compareTo(pontosA); // Ordem decrescente
    });

    // Atribuir posições
    for (int i = 0; i < items.length; i++) {
      items[i].position = i + 1;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      height: MediaQuery.of(context).size.height * 0.7,
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
                  'Ranking Comppare',
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
        content: SingleChildScrollView(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...items.take(5).map((i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: PositionCard(
                          position: i.position ?? 0,
                          name: i.nome ?? 'Usuário Desconhecido',
                          points: i.pontos ?? '0',
                        ),
                      );
                    }).toList(),
                    if (positionCurrentUser != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.more_horiz, size: 40),
                          PositionCard(
                            position: positionCurrentUser!.position ?? 0,
                            name: positionCurrentUser!.nome ?? 'Usuário Desconhecido',
                            points: positionCurrentUser!.pontos ?? '0',
                          ),
                        ],
                      ),
                  ],
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
  final String name;
  final String points;

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
                Text(name, style: textStyle),
              ],
            ),
            Text('$points pts', style: textStyle),
          ],
        ),
      ),
    );
  }
}
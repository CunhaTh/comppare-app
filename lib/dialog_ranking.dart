import 'package:flutter/material.dart';

import 'infra/repositories/ranking_repository.dart';

class DialogRanking extends StatefulWidget {
  const DialogRanking({super.key});

  @override
  State<DialogRanking> createState() => _DialogRankingState();
}

class _DialogRankingState extends State<DialogRanking> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      RankingRepository.getDataRanking();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.5,
      height: MediaQuery.of(context).size.height * 0.7,
      child: AlertDialog(
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Nosso ranking',
              style: TextStyle(
                fontSize: 18,
              ),
            ),
            Icon(Icons.info_outline),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PositionCard(name: 'João', position: 1, points: 10),
            SizedBox(height: 8),
            PositionCard(name: 'Maria', position: 2, points: 8),
            SizedBox(height: 8),
            PositionCard(name: 'Luis', position: 3, points: 6),
            SizedBox(height: 8),
            PositionCard(name: 'Andrew', position: 4, points: 5),
            SizedBox(height: 8),
            PositionCard(name: 'Thiago', position: 5, points: 3),
            Icon(Icons.more_horiz, size: 40),
            PositionCard(name: 'Você', position: 10, points: 1),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              child: const Text(
                'Fechar',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () => Navigator.of(context).pop(),
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
  final int points;

  Color get positionColor {
    switch (position) {
      case 1:
        return const Color(0xFFFFB800);
      case 2:
        return const Color(0xFFAAAAAA);
      case 3:
        return const Color(0xFFE46E00);
      default:
        return Colors.black.withValues(alpha: 0.7);
    }
  }

  TextStyle get textStyle {
    return TextStyle(
        color: positionColor, fontSize: 16, fontWeight: FontWeight.w700);
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
            Text(points.toString(), style: textStyle),
          ],
        ),
      ),
    );
  }
}

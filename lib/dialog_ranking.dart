import 'package:application_progress/models/plan_model.dart';
import 'package:application_progress/views/plans_page.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'app_colors.dart';
import 'infra/repositories/ranking_repository.dart';
import 'infra/user_helper.dart';

class RankingModel {
  final int? userPlanId;
  final List<RankingItemModel> items;
  final PlanModel currentPlan;
  final List<PlanModel> allPlans;

  RankingModel({
    required this.userPlanId,
    required this.items,
    required this.currentPlan,
    required this.allPlans,
  });
}


class DialogRanking extends StatelessWidget {
  final RankingModel data;

  const DialogRanking({super.key, required this.data});

@override
Widget build(BuildContext context) {
  // IDs dos planos que não podem ver o ranking.
  const ID_PLANO_GRATUITO = 1;
  // A constante do plano de afiliado foi removida, pois não é mais necessária aqui.

  // --- LÓGICA DE BLOQUEIO AJUSTADA ---
  // Agora, a verificação checa APENAS se o plano do usuário é o gratuito.
  final bool isBlocked = (data.userPlanId == ID_PLANO_GRATUITO || data.userPlanId == null);

  return AlertDialog(
    title: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        if (!isBlocked)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Image.asset('assets/ranking.png', width: 40)),
              const Tooltip(
                  message:
                      'Você acumula pontos à medida em que usa os serviços do nosso app',
                  child: Icon(Icons.info_outline, size: 20)),
            ],
          ),
        Text(
          isBlocked ? 'Recurso Avançado' : 'Ranking',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
      ],
    ),
    content: _buildContent(context, isBlocked),
    actions: [
      Center(
        child: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.w500)),
        ),
      ),
    ],
  );
}

  Widget _buildContent(BuildContext context, bool isBlocked) {
    if (isBlocked) {
      return _buildAccessBlockedMessage(context);
    }

    if (data.items.isEmpty) {
      return const Center(
          child: Text(
              'Nenhum ponto foi registrado ainda.\nSeja o primeiro a se destacar!',
              textAlign: TextAlign.center));
    }

    final userName = UserHelper().user?.nome ?? '';
    final currentUser = data.items.firstWhereOrNull(
        (i) => i.nome == userName && (i.position ?? 0) > 10);

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...data.items.map((item) => PositionCard(
              position: item.position ?? 0,
              name: item.nome,
              points: item.pontos)),
          if (currentUser != null)
            Column(
              children: [
                const Icon(Icons.more_horiz, size: 40),
                PositionCard(
                    position: currentUser.position ?? 0,
                    name: currentUser.nome,
                    points: currentUser.pontos),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildAccessBlockedMessage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 50, color: Colors.amber[700]),
          const SizedBox(height: 16),
          const Text('Função para Planos Avançados',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              'Sua vez de entrar no game! Assine um de nossos planos para se unir aos outros usuários e buscar o lugar mais alto do pódio.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFaed513),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            onPressed: () {
              // Navegação agora usa os dados corretos recebidos no modelo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SubscriptionPage(
                    initialPlan: data.currentPlan,
                    availablePlans: data.allPlans,
                  ),
                ),
              );
            },
            child: const Text('Conheça nossos Planos',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
        return Colors.black.withValues(alpha: 0.7);
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
                  name == (UserHelper().user?.nome ?? '')
                      ? 'Você'
                      : name,
                  style: textStyle,
                ),
              ],
            ),
            Text('$points pts', style: textStyle),
          ],
        ),
      ),
    );
  }
}

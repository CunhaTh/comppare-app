import 'package:application_progress/infra/user_helper.dart';
import 'package:application_progress/main.dart';
import 'package:application_progress/views/awaiting_payment.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPage extends StatefulWidget {
  final Plano initialPlan;
  final List<Plano>? availablePlans; // Lista opcional de planos para escolha

  const SubscriptionPage(
      {super.key, required this.initialPlan, this.availablePlans});

  @override
  State<SubscriptionPage> createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  bool loading = false;
  late Plano selectedPlan; // Plano selecionado pelo usuário

  @override
  void initState() {
    super.initState();
    // Inicializa com o plano passado ou o primeiro da lista, se disponível
    selectedPlan = widget.availablePlans?.isNotEmpty == true
        ? widget.availablePlans!.first
        : widget.initialPlan;
  }

  Future<void> _subscribe() async {
    setState(() => loading = true);
    final userId = UserHelper().user?.id;
    if (userId != null) {
      final url = Uri.parse(
          'https://dev.comppare.com.br/payment.php?pid=${selectedPlan.id}&uid=$userId');
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AwaitingPayment()),
          );
        }
      } else {
        if (mounted) {
          _showErrorDialog('Não foi possível iniciar o pagamento.');
        }
      }
    } else {
      if (mounted) {
        _showErrorDialog('Usuário não autenticado.');
      }
    }
    setState(() => loading = false);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Assinar Plano',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: const Color(0xFFaed513),
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Dropdown ou ListView para escolher o plano
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<Plano>(
                value: selectedPlan,
                icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                iconSize: 24,
                elevation: 16,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                underline: const SizedBox(),
                onChanged: (Plano? newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedPlan = newValue;
                    });
                  }
                },
                items: (widget.availablePlans ?? [widget.initialPlan])
                    .map<DropdownMenuItem<Plano>>((Plano value) {
                  return DropdownMenuItem<Plano>(
                    value: value,
                    child: Text(value.nome),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            PlanWidget(plan: selectedPlan),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: loading ? null : _subscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFaed513),
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.black87,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Confirmar Assinatura'),
            ),
          ],
        ),
      ),
    );
  }
}

class PlanWidget extends StatelessWidget {
  final Plano plan;

  const PlanWidget({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.grey[300]!, width: 2),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            plan.nome,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            plan.descricao,
            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'R\$ ${plan.valor.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Tags: ${plan.quantidadeTags} | Fotos: ${plan.quantidadeFotos}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          Text(
            'Convites: ${plan.quantidadeConvites} | Pastas: ${plan.quantidadePastas}',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

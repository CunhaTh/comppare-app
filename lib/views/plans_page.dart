import 'dart:convert';

import 'package:application_progress/infra/user_helper.dart';
import 'package:flutter/material.dart';
import 'package:get/utils.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import '../infra/api_endponts.dart';
import '../infra/token_helper.dart';
import '../planos.dart';
import 'awaiting_payment.dart';

class PlansPage extends StatefulWidget {
  const PlansPage({super.key});

  @override
  State<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends State<PlansPage> {
  List<Plano> plans = [];

  void getPlans() async {
    final response = await http.get(
      Uri.parse('https://api.comppare.com.br/api/planos/listar'),
      headers: {
        'Authorization': 'Bearer ${TokenHelper.instance.token}',
      },
    );

    final data = json.decode(response.body);
    final List<dynamic> planosJson = data['data'];
    plans = planosJson.map((json) => Plano.fromJson(json)).toList();
    setState(() {});
  }

  Future<bool> getCheckUpdatePlan(int newPlanId) async {
    final response = await http.post(
      Uri.parse(ApiEndpoints.checkUpdatePlan),
      body: {
        "cpf": UserHelper.instance.user?.cpf,
        "plano": newPlanId.toString(),
      },
      headers: {
        'Authorization': 'Bearer ${TokenHelper.instance.token}',
      },
    );

    final data = json.decode(response.body);
    debugPrint('DATA: $data');
    return data['changePlan'] ?? false;
  }

  Plano? get currentUSerPlan {
    return plans.firstWhereOrNull(
      (p) => p.id == UserHelper.instance.user?.idPlano,
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(getPlans);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Planos',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (currentUSerPlan != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        const Text(
                          'Seu plano atual',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        PlanWidget(plan: currentUSerPlan!),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () async {
                            bool error = false;
                            final navigator = Navigator.of(context);

                            await showDialog(
                              context: context,
                              builder: (contextDialog) => DialogChangePlan(
                                pressContinue: (planId) async {
                                  final navigatorDialog =
                                      Navigator.of(contextDialog);

                                  bool canUpdatePlan =
                                      await getCheckUpdatePlan(planId);
                                  var userId = UserHelper.instance.user?.id;

                                  if (canUpdatePlan && userId != null) {
                                    final redirected = await launchUrl(
                                      Uri.parse(
                                        'https://dev.comppare.com.br/payment.php?pid=${planId.toString()}&uid=${userId.toString()}',
                                      ),
                                    );
                                    if (redirected && mounted) {
                                      navigatorDialog.pushNamed(
                                        AwaitingPayment.route,
                                      );
                                    }
                                  } else {
                                    navigatorDialog.pop();
                                    error = true;
                                  }
                                },
                                plans: plans
                                    .where((p) => p.id != currentUSerPlan?.id)
                                    .toList(),
                              ),
                            );

                            if (error && mounted) {
                              showDialog(
                                context: navigator.context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Erro'),
                                  content: const Text(
                                      'Não foi possível fazer a mudança de plano'),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(ctx).pop();
                                      },
                                      child: const Text('Fechar'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFaed513),
                          ),
                          child: const Text(
                            'Quero mudar o meu plano',
                            style: TextStyle(
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            const Text(
              'Todos os planos disponíveis',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Center(
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: plans.map((p) {
                  return PlanWidget(plan: p);
                }).toList(),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class PlanWidget extends StatelessWidget {
  const PlanWidget({super.key, required this.plan});

  final Plano plan;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      margin: const EdgeInsets.symmetric(vertical: 1),
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
        border: Border.all(
          color: Colors.grey[300]!,
          width: 2,
        ),
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
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[700],
            ),
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
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class DialogChangePlan extends StatefulWidget {
  const DialogChangePlan({
    super.key,
    required this.plans,
    required this.pressContinue,
  });

  final List<Plano> plans;
  final Future<void> Function(int planId) pressContinue;

  @override
  State<DialogChangePlan> createState() => _DialogChangePlanState();
}

class _DialogChangePlanState extends State<DialogChangePlan> {
  Plano? selectedPlan;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            children: [
              const Text(
                'Selecione abaixo o plano que deseja adquirir:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              ...widget.plans.map((p) {
                return CheckboxListTile(
                  title: Text(
                    p.nome,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  value: selectedPlan == p,
                  activeColor: const Color(0xFFaed513),
                  checkColor: Colors.black,
                  onChanged: (value) {
                    selectedPlan = p;
                    setState(() {});
                  },
                );
              }),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selectedPlan == null
                          ? () {}
                          : () async {
                              setState(() => loading = true);

                              await widget.pressContinue(selectedPlan!.id);

                              setState(() => loading = false);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedPlan == null
                            ? Colors.grey
                            : const Color(0xFFaed513),
                      ),
                      child: loading
                          ? const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Center(
                                child: SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: CircularProgressIndicator.adaptive(
                                    strokeWidth: 2,
                                    backgroundColor: Colors.black87,
                                  ),
                                ),
                              ),
                            )
                          : const Text(
                              'Continuar',
                              style: TextStyle(
                                color: Colors.black87,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Tooltip(
                    message: 'Ao clicar em "Continuar", sua '
                        'solicitação será enviada e, caso seja '
                        'aprovada, você será redirecionado para '
                        'inserir os dados que serão usados no '
                        'pagamento do novo plano',
                    child: Icon(
                      Icons.info_outline,
                      size: 30,
                      color: Colors.black,
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

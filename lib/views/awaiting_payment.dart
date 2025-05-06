import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../login.dart';

class AwaitingPayment extends StatefulWidget {
  const AwaitingPayment({super.key});

  static const route = '/aguardando-pagamento';

  @override
  State<AwaitingPayment> createState() => _AwaitingPaymentState();
}

class _AwaitingPaymentState extends State<AwaitingPayment> {
  bool? success;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      String? querySuccess = Uri.base.queryParameters['success'];

      if (querySuccess == 'true') success = true;
      if (querySuccess == 'false') success = false;
      loading = false;
      setState(() {});

      if (success == true && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
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
            )
          ],
        ),
        backgroundColor: Colors.white,
      ),
      body: Builder(
        builder: (context) {
          if (loading) {
            return const Padding(
              padding: EdgeInsets.only(top: 50),
              child: Center(
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator.adaptive(
                    strokeWidth: 3,
                    backgroundColor: AppColors.primaryColor,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Builder(
                builder: (context) {
                  if (success == null) {
                    return Column(
                      children: [
                        Image.asset(
                          'assets/awaiting.png',
                          width: MediaQuery.of(context).size.width * 0.5,
                        ),
                        const Text(
                          'Estamos aguardando a confirmação do pagamento para que '
                          'você possa ter acesso aos nossos serviços...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ],
                    );
                  }

                  if (success == false) {
                    return Column(
                      children: [
                        const Icon(
                          Icons.sentiment_dissatisfied_rounded,
                          size: 70,
                        ),
                        const Text(
                          'Que pena...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                          ),
                        ),
                        const Text(
                          'Parece que o seu pagamento não foi processado.\n'
                          'Entre em contato com o suporte para avaliarmos a sua '
                          'situação em nosso sistema.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 30),
                        IconButton.filled(
                          onPressed: () {},
                          icon: const Text(
                            'Fala com o suporte',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                          ),
                          color: AppColors.primaryColor,
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all(
                              AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

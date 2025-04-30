import 'package:flutter/material.dart';

class ChatButton extends StatelessWidget {
  const ChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showGeneralDialog(
          context: context,
          barrierDismissible: true,
          barrierLabel: 'Canto inferior direito',
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
          transitionBuilder: (context, anim1, anim2, _) {
            final width = MediaQuery.of(context).size.width;
            final height = MediaQuery.of(context).size.height;
            final dialogWidth = width * 0.5;
            final dialogHeight = height * 0.5;

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(
                    1.0, 1.0), // começa fora da tela, canto inferior direito
                end: Offset.zero, // chegar no ponto final
              ).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
              child: Align(
                alignment: Alignment.bottomRight,
                child: Material(
                  elevation: 10,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: dialogWidth,
                    height: dialogHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/chat_background.png',
                          width: dialogWidth,
                          height: dialogHeight,
                        ),
                        Container(
                          width: dialogWidth,
                          height: dialogHeight,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      child: Text('CHAT'),
    );
  }
}

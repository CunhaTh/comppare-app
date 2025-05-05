import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

import 'app_colors.dart';
import 'infra/repositories/chat_repository.dart';

class ChatButton extends StatefulWidget {
  const ChatButton({super.key});

  @override
  State<ChatButton> createState() => _ChatButtonState();
}

class _ChatButtonState extends State<ChatButton> {
  List<ChatQuestionModel> questions = [];
  ChatQuestionModel? selectedQuestion;

  final questionController = TextEditingController();

  OutlineInputBorder get fieldBorder {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(
        color: Colors.transparent,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      questions = await ChatRepository.getChatQuestions();
      setState(() {});
    });
  }

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
          transitionBuilder: (context, anim1, anim2, child) {
            final width = MediaQuery.of(context).size.width;
            final height = MediaQuery.of(context).size.height;
            final dialogWidth = width * 0.6;
            final dialogHeight = height * 0.6;

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1.0, 1.0),
                    end: Offset.zero,
                  ).animate(
                      CurvedAnimation(parent: anim1, curve: Curves.easeOut)),
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
                            Padding(
                              padding: const EdgeInsets.only(top: 30),
                              child: Image.asset(
                                'assets/chat_background.png',
                                width: double.maxFinite,
                              ),
                            ),
                            Container(
                              width: dialogWidth,
                              height: dialogHeight,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            Column(
                              children: [
                                TypeAheadField<ChatQuestionModel>(
                                  suggestionsCallback: (query) {
                                    var result = questions
                                        .where((a) => (a.question)
                                            .toLowerCase()
                                            .contains(query.toLowerCase()))
                                        .toList();
                                    return result.toList();
                                  },
                                  itemBuilder: (context, question) {
                                    return Container(
                                      color: Colors.white,
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                        child: Text(
                                          question.question,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  emptyBuilder: (context) => const SizedBox(),
                                  onSelected: (question) {
                                    setDialogState(() {
                                      selectedQuestion = question;
                                      questionController.text =
                                          question.question;
                                    });
                                  },
                                  builder: (context, control, fn) {
                                    return Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: TextField(
                                        controller: questionController,
                                        focusNode: fn,
                                        onChanged: (t) => control.text = t,
                                        decoration: InputDecoration(
                                          hintText: 'Digite aqui',
                                          fillColor: Colors.white,
                                          border: fieldBorder,
                                          enabledBorder: fieldBorder,
                                          focusedBorder: fieldBorder,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.bottomRight,
                                    child: AnimatedScale(
                                      scale: 1,
                                      duration:
                                          const Duration(milliseconds: 300),
                                      curve: Curves.easeOutBack,
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: ChatBalloon(
                                          message: selectedQuestion?.answer ??
                                              'Olá, bem vindo ao Comppare App! Digite no campo acima e selecione a sua dúvida',
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      backgroundColor: AppColors.primaryColor,
      child: const Icon(Icons.smart_toy, color: Colors.white),
    );
  }
}

class ChatBalloon extends StatelessWidget {
  final String message;

  const ChatBalloon({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: BalloonPainter(),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
            )
          ],
        ),
        child: SingleChildScrollView(child: Text(message)),
      ),
    );
  }
}

class BalloonPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final path = Path();
    path.moveTo(size.width - 10, size.height);
    path.lineTo(size.width - 2, size.height + 10);
    path.lineTo(size.width - 20, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

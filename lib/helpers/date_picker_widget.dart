import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Widget reutilizável para seleção de data
///
/// Este componente permite ao usuário selecionar uma data através de um DatePicker
/// nativo do Flutter. Quando clicado, abre o seletor de data e retorna a data selecionada.
class DatePickerWidget extends StatelessWidget {
  /// Data atual selecionada
  final String? currentDate;

  /// Callback chamado quando a data é alterada
  final Function(String) onDateChanged;

  /// Estilo do texto da data
  final TextStyle? textStyle;

  /// Padding ao redor do widget
  final EdgeInsetsGeometry? padding;

  /// Formato da data para exibição
  final String dateFormat;

  /// Data mínima permitida
  final DateTime? firstDate;

  /// Data máxima permitida
  final DateTime? lastDate;

  const DatePickerWidget({
    Key? key,
    this.currentDate,
    required this.onDateChanged,
    this.textStyle,
    this.padding,
    this.dateFormat = 'dd/MM/yyyy',
    this.firstDate,
    this.lastDate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Se não há data atual, usa a data de hoje
    final String displayDate =
        currentDate ?? DateFormat(dateFormat).format(DateTime.now());

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: GestureDetector(
        onTap: () => _selectDate(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, color: Colors.black54),
            const SizedBox(width: 4),
            Text(
              displayDate,
              style: textStyle ??
                  const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Abre o DatePicker nativo do Flutter
  Future<void> _selectDate(BuildContext context) async {
    DateTime? selectedDate;

    // Se há uma data atual, tenta parseá-la
    if (currentDate != null && currentDate!.isNotEmpty) {
      try {
        selectedDate = DateFormat(dateFormat).parse(currentDate!);
      } catch (e) {
        // Se não conseguir fazer o parse, usa a data atual
        selectedDate = DateTime.now();
      }
    } else {
      selectedDate = DateTime.now();
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: firstDate ?? DateTime(1900),
      lastDate: lastDate ?? DateTime(2100),
      locale: const Locale('pt', 'BR'), // Português brasileiro
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Colors.green, // Cor primária do app
                  onPrimary: Colors.white,
                  surface: Colors.white,
                  onSurface: Colors.black,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final String formattedDate = DateFormat(dateFormat).format(picked);
      onDateChanged(formattedDate);
    }
  }
}

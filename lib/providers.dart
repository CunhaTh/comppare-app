import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'form_model.dart';

final formProvider = ChangeNotifierProvider<FormModel>((ref) {
  return FormModel();
});

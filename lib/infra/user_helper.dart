import 'package:get_storage/get_storage.dart';

class UserHelper {
  UserHelper._();

  static UserHelper instance = UserHelper._();

  int? get userId {
    final data = GetStorage().read('userId');

    return data;
  }

  Future<void> setUserId(int userId) async {
    await GetStorage().write('userId', userId);
  }
}

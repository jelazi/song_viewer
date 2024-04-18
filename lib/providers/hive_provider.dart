import 'package:default_project/model/user.dart';
import 'package:hive/hive.dart';

class HiveProvider {
  dynamic settingsBox;
  dynamic transposeBox;
  Future<void> initHiveBox() async {
    settingsBox = await Hive.openBox('settingsBox');
    transposeBox = await Hive.openBox('transposeBox');
  }

  dynamic getSettingsValue(String name) {
    return settingsBox.get(name);
  }

  void setSettingsValue(String key, dynamic value) {
    settingsBox.put(key, value);
  }

  void setNewTransposeForSong(String songId, int transpose) {
    transposeBox.put(songId, transpose);
  }

  int getTransposeForSong(String songId) {
    return transposeBox.get(songId) ?? 0;
  }

  void setCurrentUser(User? user) {
    settingsBox.put('currentUser', user);
  }

  User? getCurrentUser() {
    return settingsBox.get('currentUser');
  }
}

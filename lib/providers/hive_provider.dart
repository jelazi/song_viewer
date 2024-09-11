import 'package:default_project/model/user.dart';
import 'package:default_project/model/web_song.dart';
import 'package:hive/hive.dart';

class HiveProvider {
  dynamic settingsBox;
  dynamic transposeBox;
  dynamic webSongBox;
  Future<void> initHiveBox() async {
    settingsBox = await Hive.openBox('settingsBox');
    transposeBox = await Hive.openBox('transposeBox');
    webSongBox = await Hive.openBox('webSongBox');
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

  void setWebSong(String key, WebSong value) {
    webSongBox.put(key, value);
  }

  WebSong? getWebSong(String key) {
    // key is song.server + song.ref
    return webSongBox.get(key);
  }
}

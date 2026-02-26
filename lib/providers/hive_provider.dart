import 'dart:io';

import 'package:default_project/model/update_songlist_data.dart';
import 'package:default_project/model/user.dart';
import 'package:default_project/model/web_interpret.dart';
import 'package:default_project/model/web_song.dart';
import 'package:hive/hive.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

class HiveProvider {
  late Box settingsBox;
  late Box transposeBox;
  late Box webSongBox;
  late Box interpretWebBox;
  Future<void> initHiveBox() async {
    settingsBox = await _openBoxSafe('settingsBox');
    transposeBox = await _openBoxSafe('transposeBox');
    webSongBox = await _openBoxSafe('webSongBox');
    interpretWebBox = await _openBoxSafe('interpretWebBox');
  }

  /// Opens a Hive box, removing stale lock files on failure and retrying once.
  Future<Box> _openBoxSafe(String name) async {
    try {
      return await Hive.openBox(name);
    } on PathAccessException catch (e) {
      logger.w('Hive box "$name" locked, removing stale lock and retrying: $e');
      final dir = await path_provider.getApplicationDocumentsDirectory();
      final lockFile = File('${dir.path}/$name.lock');
      if (await lockFile.exists()) {
        try {
          await lockFile.delete();
        } catch (_) {}
      }
      return await Hive.openBox(name);
    }
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

  void setUpdateSongListData(String key, UpdateSongListData value) {
    webSongBox.put(key, value);
  }

  UpdateSongListData? getUpdateSongListData(String key) {
    return webSongBox.get(key);
  }

  WebSong? getWebSong(String key) {
    // key is song.server + song.ref
    return webSongBox.get(key);
  }

  void setHistoryInterpretToWebBox(String nameWeb, WebInterpret interpret) {
    interpretWebBox.get(nameWeb);
    final webInterprets = interpretWebBox.get(nameWeb);

    if (webInterprets != null && webInterprets is List) {
      if (webInterprets.length > 10) {
        webInterprets.removeRange(0, webInterprets.length - 10);
      }
    }
    if (webInterprets != null && webInterprets is List && webInterprets.isNotEmpty) {
      if (!webInterprets.any((element) => interpret.ref == element.ref)) {
        webInterprets.add(interpret);
        interpretWebBox.put(nameWeb, webInterprets);
      }
    } else {
      interpretWebBox.put(nameWeb, [interpret]);
    }
  }

  WebInterpret? getInterpretFromWebBox(String nameWeb, String ref) {
    final webInterprets = interpretWebBox.get(nameWeb);
    if (webInterprets != null && webInterprets is Map) {
      return webInterprets[ref];
    }
    return null;
  }

  List<WebInterpret> getInterpretsFromWebBox(String nameWeb) {
    final webInterprets = interpretWebBox.get(nameWeb);
    if (webInterprets != null && webInterprets is List) {
      return List<WebInterpret>.from(webInterprets);
    }
    return [];
  }
}

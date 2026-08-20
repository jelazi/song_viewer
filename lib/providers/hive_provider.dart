import 'dart:io';

import 'package:default_project/model/update_playlist_data.dart';
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
  late Box songsCacheBox;
  late Box searchHistoryBox;
  Future<void> initHiveBox() async {
    settingsBox = await _openBoxSafe('settingsBox');
    transposeBox = await _openBoxSafe('transposeBox');
    webSongBox = await _openBoxSafe('webSongBox', isCache: true);
    interpretWebBox = await _openBoxSafe('interpretWebBox', isCache: true);
    songsCacheBox = await _openBoxSafe('songsCacheBox', isCache: true);
    searchHistoryBox = await _openBoxSafe('searchHistoryBox');
  }

  /// Opens a Hive box, removing stale lock files on failure and retrying once.
  ///
  /// [isCache] marks boxes whose content can be downloaded again. If such a box
  /// cannot be decoded — typically because it holds records written by an older
  /// app version whose adapter has since changed — it is deleted and recreated
  /// instead of blocking the app start. Boxes holding user data are never
  /// dropped; those errors are rethrown.
  Future<Box> _openBoxSafe(String name, {bool isCache = false}) async {
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
    } catch (e) {
      if (!isCache) rethrow;
      logger.w('Hive cache box "$name" could not be read, recreating it: $e');
      await Hive.deleteBoxFromDisk(name);
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

  void setUpdatePlaylistData(String key, UpdatePlaylistData value) {
    webSongBox.put(key, value);
  }

  UpdatePlaylistData? getUpdatePlaylistData(String key) {
    final data = webSongBox.get(key);
    if (data is UpdatePlaylistData) return data;
    // Migration: old data was stored as UpdateSongListData
    if (data is UpdateSongListData) {
      final migrated = UpdatePlaylistData(data.lastUpdate, Map<String, DateTime>.from(data.mapIdSongs));
      webSongBox.put(key, migrated);
      return migrated;
    }
    return null;
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

  // ---------------------------------------------------------------------------
  // Songs cache (Hive-based offline storage)
  // ---------------------------------------------------------------------------

  void saveSongsCache(List<Map<String, dynamic>> songsJson, String syncTimestamp) {
    songsCacheBox.put('songs', songsJson);
    songsCacheBox.put('lastSyncTimestamp', syncTimestamp);
  }

  List<Map<String, dynamic>>? loadSongsCache() {
    final data = songsCacheBox.get('songs');
    if (data is List) {
      return data.map((e) => _deepCastMap(e as Map)).toList();
    }
    return null;
  }

  /// Recursively casts Hive's `_Map<dynamic, dynamic>` to `Map<String, dynamic>`.
  Map<String, dynamic> _deepCastMap(Map map) {
    return map.map((key, value) {
      if (value is Map) {
        return MapEntry(key.toString(), _deepCastMap(value));
      } else if (value is List) {
        return MapEntry(key.toString(), _deepCastList(value));
      }
      return MapEntry(key.toString(), value);
    });
  }

  List<dynamic> _deepCastList(List list) {
    return list.map((e) {
      if (e is Map) return _deepCastMap(e);
      if (e is List) return _deepCastList(e);
      return e;
    }).toList();
  }

  String? getLastSyncTimestamp() {
    return songsCacheBox.get('lastSyncTimestamp') as String?;
  }

  void savePlaylistsCache(List<Map<String, dynamic>> playlistsJson) {
    songsCacheBox.put('playlists', playlistsJson);
  }

  List<Map<String, dynamic>>? loadPlaylistsCache() {
    final data = songsCacheBox.get('playlists');
    if (data is List) {
      return data.map((e) => _deepCastMap(e as Map)).toList();
    }
    return null;
  }

  void saveGroupsCache(List<String> groups) {
    songsCacheBox.put('groups', groups);
  }

  List<String>? loadGroupsCache() {
    final data = songsCacheBox.get('groups');
    if (data is List) {
      return data.map((e) => e.toString()).toList();
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Chord diagrams cache
  // ---------------------------------------------------------------------------

  void saveChordDiagramsCache(Map<String, List<String>> diagrams, String syncTimestamp) {
    // Convert Map<String, List<String>> to a JSON-safe format for Hive
    final data = diagrams.map((key, value) => MapEntry(key, List<String>.from(value)));
    songsCacheBox.put('chordDiagrams', data);
    songsCacheBox.put('chordDiagramsSyncTimestamp', syncTimestamp);
  }

  Map<String, List<String>>? loadChordDiagramsCache() {
    final data = songsCacheBox.get('chordDiagrams');
    if (data is Map) {
      return data.map((key, value) {
        final positions = (value is List) ? value.map((e) => e.toString()).toList() : <String>[];
        return MapEntry(key.toString(), positions);
      });
    }
    return null;
  }

  String? getChordDiagramsSyncTimestamp() {
    return songsCacheBox.get('chordDiagramsSyncTimestamp') as String?;
  }

  bool isChordsSeedDone() {
    return songsCacheBox.get('chordsSeedDone') == true;
  }

  void setChordsSeedDone() {
    songsCacheBox.put('chordsSeedDone', true);
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

  // ---------------------------------------------------------------------------
  // Web search-query history (persisted, per server + combined across servers)
  // ---------------------------------------------------------------------------

  static const int _maxSearchHistory = 20;
  static const String _allHistoryKey = '__all__';

  /// Record a search query for [server]. Stored most-recent-first, de-duplicated
  /// case-insensitively, and also mirrored into a combined cross-server list.
  void addSearchHistory(String server, String query) {
    final q = query.trim();
    if (q.isEmpty) return;
    _pushHistory(server, q);
    _pushHistory(_allHistoryKey, q);
  }

  void _pushHistory(String key, String q) {
    final raw = searchHistoryBox.get(key);
    List<String> list = raw is List ? List<String>.from(raw.map((e) => e.toString())) : <String>[];
    list.removeWhere((e) => e.toLowerCase() == q.toLowerCase());
    list.insert(0, q);
    if (list.length > _maxSearchHistory) {
      list = list.sublist(0, _maxSearchHistory);
    }
    searchHistoryBox.put(key, list);
  }

  /// Search-query history for a single server (most recent first).
  List<String> getSearchHistory(String server) => _readHistory(server);

  /// Combined search-query history across all servers (most recent first).
  List<String> getAllSearchHistory() => _readHistory(_allHistoryKey);

  List<String> _readHistory(String key) {
    final raw = searchHistoryBox.get(key);
    return raw is List ? List<String>.from(raw.map((e) => e.toString())) : <String>[];
  }

  /// Clear history for one server and rebuild the combined list from the rest.
  void clearSearchHistory(String server) {
    searchHistoryBox.delete(server);
    final List<String> merged = [];
    final seen = <String>{};
    for (final key in searchHistoryBox.keys) {
      if (key == _allHistoryKey) continue;
      final raw = searchHistoryBox.get(key);
      if (raw is List) {
        for (final e in raw) {
          final s = e.toString();
          if (seen.add(s.toLowerCase())) merged.add(s);
        }
      }
    }
    searchHistoryBox.put(_allHistoryKey, merged.take(_maxSearchHistory).toList());
  }
}

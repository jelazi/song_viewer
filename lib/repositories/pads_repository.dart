import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:path_provider/path_provider.dart';

import '../model/pad_set.dart';
import '../providers/hive_provider.dart';
import '../providers/pocketbase_provider.dart';
import '../services/pad_audio_engine.dart';

/// Pad sets from the server, the pad files cached on the device and the
/// pad preferences.
class PadsRepository {
  static const _setsCacheKey = 'padSetsCache';
  static const _songPreferencesCacheKey = 'padSongPreferencesCache';
  static const _windowOpenKey = 'padWindowOpen';
  static const _windowMinimizedKey = 'padWindowMinimized';
  static const _selectedSetKey = 'padSelectedSet';
  static const _volumeKey = 'padVolume';
  static const _fadeInKey = 'padFadeInSeconds';
  static const _fadeOutKey = 'padFadeOutSeconds';
  static const _fadeCurveKey = 'padFadeCurve';

  final PocketBaseProvider _pocketBaseProvider;
  final HiveProvider _hiveProvider;
  final Dio _dio;

  PadsRepository({required PocketBaseProvider pocketBaseProvider, required HiveProvider hiveProvider, Dio? dio})
      : _pocketBaseProvider = pocketBaseProvider,
        _hiveProvider = hiveProvider,
        _dio = dio ?? Dio();

  /// Pad sets from the server, or the last copy seen when it is unreachable.
  Future<List<PadSet>> loadSets() async {
    if (_pocketBaseProvider.isConnected) {
      try {
        final sets = await _pocketBaseProvider.getPadSets();
        _hiveProvider.setSettingsValue(_setsCacheKey, jsonEncode(sets.map((set) => set.toJson()).toList()));
        return sets;
      } catch (e) {
        logger.w('Pad sets could not be loaded from the server: $e');
      }
    }
    final cached = _hiveProvider.getSettingsValue(_setsCacheKey);
    if (cached is! String) return [];
    return (jsonDecode(cached) as List).map((json) => PadSet.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Pads saved for songs, from the server or the last copy seen.
  Future<Map<String, SongPadPreference>> loadSongPreferences() async {
    if (_pocketBaseProvider.isConnected) {
      try {
        final preferences = await _pocketBaseProvider.getSongPadPreferences();
        _cacheSongPreferences(preferences);
        return preferences;
      } catch (e) {
        logger.w('Song pads could not be loaded from the server: $e');
      }
    }
    return _cachedSongPreferences();
  }

  /// Saves the pad for [songId], or removes it when [preference] is null, and
  /// returns all saved pads. The server copy is read again first, so a pad
  /// saved meanwhile on another device is kept. Without a server the change
  /// stays on this device only.
  Future<Map<String, SongPadPreference>> saveSongPreference(String songId, SongPadPreference? preference) async {
    var preferences = _cachedSongPreferences();
    final online = _pocketBaseProvider.isConnected;
    if (online) {
      try {
        preferences = await _pocketBaseProvider.getSongPadPreferences();
      } catch (e) {
        logger.w('Song pads could not be re-read before saving: $e');
      }
    }
    preferences = {...preferences};
    if (preference == null) {
      preferences.remove(songId);
    } else {
      preferences[songId] = preference;
    }
    _cacheSongPreferences(preferences);
    if (online) {
      try {
        await _pocketBaseProvider.saveSongPadPreferences(preferences);
      } catch (e) {
        logger.w('Song pad saved on this device only: $e');
      }
    }
    return preferences;
  }

  Map<String, SongPadPreference> _cachedSongPreferences() {
    final cached = _hiveProvider.getSettingsValue(_songPreferencesCacheKey);
    if (cached is! String) return {};
    return (jsonDecode(cached) as Map<String, dynamic>).map((songId, json) => MapEntry(songId, SongPadPreference.fromJson(json as Map<String, dynamic>)));
  }

  void _cacheSongPreferences(Map<String, SongPadPreference> preferences) {
    _hiveProvider.setSettingsValue(_songPreferencesCacheKey, jsonEncode(preferences.map((songId, preference) => MapEntry(songId, preference.toJson()))));
  }

  /// Keys of [set] whose current file is already on the device.
  Future<Set<int>> downloadedKeys(PadSet set) async {
    final keys = <int>{};
    for (final entry in set.fileUrls.entries) {
      if (await File(await _localPath(set, entry.key)).exists()) keys.add(entry.key);
    }
    return keys;
  }

  /// Local path of the pad for [semitone], downloading it first if needed.
  Future<String> ensureFile(PadSet set, int semitone) async {
    final path = await _localPath(set, semitone);
    final file = File(path);
    if (await file.exists()) return path;

    await file.parent.create(recursive: true);
    final partial = '$path.part';
    await _dio.download(set.fileUrls[semitone]!, partial);
    await File(partial).rename(path);
    await _removeOtherVersions(file, semitone);
    return path;
  }

  /// The file name carries the server's file name, so a re-uploaded pad gets
  /// a new local file instead of silently playing the old one.
  Future<String> _localPath(PadSet set, int semitone) async {
    final support = await getApplicationSupportDirectory();
    final serverName = Uri.parse(set.fileUrls[semitone]!).pathSegments.last;
    return '${support.path}/pads/${set.id}/${semitone}_$serverName';
  }

  Future<void> _removeOtherVersions(File current, int semitone) async {
    await for (final entity in current.parent.list()) {
      final name = entity.uri.pathSegments.last;
      if (entity is File && entity.path != current.path && name.startsWith('${semitone}_')) {
        await entity.delete();
      }
    }
  }

  bool get isWindowOpen => _hiveProvider.getSettingsValue(_windowOpenKey) == true;
  set isWindowOpen(bool value) => _hiveProvider.setSettingsValue(_windowOpenKey, value);

  bool get isWindowMinimized => _hiveProvider.getSettingsValue(_windowMinimizedKey) == true;
  set isWindowMinimized(bool value) => _hiveProvider.setSettingsValue(_windowMinimizedKey, value);

  String? get selectedSetId => _hiveProvider.getSettingsValue(_selectedSetKey) as String?;
  set selectedSetId(String? value) => _hiveProvider.setSettingsValue(_selectedSetKey, value);

  double get volume => (_hiveProvider.getSettingsValue(_volumeKey) as num?)?.toDouble() ?? 0.8;
  set volume(double value) => _hiveProvider.setSettingsValue(_volumeKey, value);

  int get fadeInSeconds => _hiveProvider.getSettingsValue(_fadeInKey) as int? ?? 4;
  set fadeInSeconds(int value) => _hiveProvider.setSettingsValue(_fadeInKey, value);

  int get fadeOutSeconds => _hiveProvider.getSettingsValue(_fadeOutKey) as int? ?? 4;
  set fadeOutSeconds(int value) => _hiveProvider.setSettingsValue(_fadeOutKey, value);

  PadFadeCurve get fadeCurve =>
      PadFadeCurve.values.firstWhere((curve) => curve.name == _hiveProvider.getSettingsValue(_fadeCurveKey), orElse: () => PadFadeCurve.smooth);
  set fadeCurve(PadFadeCurve value) => _hiveProvider.setSettingsValue(_fadeCurveKey, value.name);
}

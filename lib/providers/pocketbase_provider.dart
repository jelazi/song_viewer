import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:logger_pkg/logger_pkg.dart';
import 'package:pocketbase/pocketbase.dart';

import '../model/note.dart';
import '../model/playlist.dart';
import '../model/qr_link.dart';
import '../model/song/song.dart';
import '../model/user.dart';
import '../model/youtube_video.dart';
import '../services/enums.dart';

/// Represents a granular realtime change event from PocketBase.
class RealtimeChangeEvent<T> {
  /// The action: 'create', 'update', or 'delete'
  final String action;

  /// The parsed record (null for delete events if record not available)
  final T? record;

  /// The record ID (useful for delete events)
  final String recordId;

  /// Server timestamp of the change (PocketBase 'updated' field)
  final String serverUpdated;

  const RealtimeChangeEvent({
    required this.action,
    this.record,
    required this.recordId,
    this.serverUpdated = '',
  });

  bool get isCreate => action == 'create';
  bool get isUpdate => action == 'update';
  bool get isDelete => action == 'delete';
}

class PocketBaseConfig {
  String pocketbaseUrl;
  String email;
  String password;

  PocketBaseConfig({
    required this.pocketbaseUrl,
    required this.email,
    required this.password,
  });

  factory PocketBaseConfig.fromJson(Map<String, dynamic> json) => PocketBaseConfig(
        pocketbaseUrl: json['pocketbaseUrl'] as String? ?? 'http://127.0.0.1:8090',
        email: json['email'] as String? ?? '',
        password: json['password'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'pocketbaseUrl': pocketbaseUrl,
        'email': email,
        'password': password,
      };

  bool get isValid => pocketbaseUrl.isNotEmpty && email.isNotEmpty && password.isNotEmpty;
}

class PocketBaseProvider {
  late PocketBase _pb;
  PocketBaseConfig? _config;
  bool _isConnected = false;

  // Platform-agnostic realtime streams
  final _selectedSongController = StreamController<Map<String, dynamic>?>.broadcast();
  Stream<Map<String, dynamic>?> get selectedSongStream => _selectedSongController.stream;

  final _songChangeController = StreamController<RealtimeChangeEvent<Song>>.broadcast();
  Stream<RealtimeChangeEvent<Song>> get songChangeStream => _songChangeController.stream;

  final _playlistChangeController = StreamController<RealtimeChangeEvent<Playlist>>.broadcast();
  Stream<RealtimeChangeEvent<Playlist>> get playlistChangeStream => _playlistChangeController.stream;

  final _userChangeController = StreamController<RealtimeChangeEvent<User>>.broadcast();
  Stream<RealtimeChangeEvent<User>> get userChangeStream => _userChangeController.stream;

  final _groupChangeController = StreamController<RealtimeChangeEvent<String>>.broadcast();
  Stream<RealtimeChangeEvent<String>> get groupChangeStream => _groupChangeController.stream;

  final _qrLinksController = StreamController<List<QrLink>>.broadcast();
  Stream<List<QrLink>> get qrLinksStream => _qrLinksController.stream;

  // Local timestamp maps for realtime_state-based change detection
  Map<String, String> _songTimestamps = {};
  Map<String, String> _playlistTimestamps = {};
  Map<String, String> _groupTimestamps = {};
  Map<String, String> _userTimestamps = {};

  // Global update trigger — only when this changes do we diff the timestamp maps
  String _lastUpdatedTimestamp = '';

  bool get isConnected => _isConnected;
  PocketBaseConfig? get config => _config;

  PocketBaseProvider();

  /// Loads config from pocketbase_config.json file in app documents directory.
  /// Falls back to bundled asset config if file doesn't exist.
  Future<PocketBaseConfig?> loadConfig() async {
    try {
      // Try loading from app documents directory first
      final dir = await _getConfigDir();
      final file = File('$dir/pocketbase_config.json');
      if (await file.exists()) {
        final content = await file.readAsString();
        _config = PocketBaseConfig.fromJson(jsonDecode(content));
        return _config;
      }
    } catch (e) {
      logger.w('Could not load config from documents: $e');
    }

    // Try loading from bundled asset
    try {
      final content = await rootBundle.loadString('pocketbase_config.json');
      _config = PocketBaseConfig.fromJson(jsonDecode(content));
      return _config;
    } catch (e) {
      logger.w('No pocketbase_config.json found: $e');
    }

    return null;
  }

  /// Saves config to app documents directory.
  Future<void> saveConfig(PocketBaseConfig config) async {
    _config = config;
    try {
      final dir = await _getConfigDir();
      final file = File('$dir/pocketbase_config.json');
      await file.writeAsString(jsonEncode(config.toJson()));
    } catch (e) {
      logger.e('Error saving config: $e');
    }
  }

  Future<String> _getConfigDir() async {
    // Use platform-specific documents directory
    final dir = Directory.systemTemp.parent; // fallback
    try {
      // path_provider is imported by caller; we use a simple approach here
      final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
      final configDir = '$home/.songviewer';
      await Directory(configDir).create(recursive: true);
      return configDir;
    } catch (_) {
      return dir.path;
    }
  }

  /// Authenticates with PocketBase using email/password from config.
  Future<bool> authenticate() async {
    if (_config == null || !_config!.isValid) {
      logger.w('PocketBase config is not valid');
      return false;
    }

    try {
      _pb = PocketBase(_config!.pocketbaseUrl);
      await _pb.collection('users').authWithPassword(_config!.email, _config!.password);
      _isConnected = true;
      logger.i('PocketBase authenticated successfully');
      await _initializeTimestampMaps();
      _subscribeToRealtime();
      return true;
    } catch (e) {
      logger.e('PocketBase authentication failed: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Reconnect with new config (used when changing settings).
  Future<bool> reconnect(PocketBaseConfig newConfig) async {
    _isConnected = false;
    _config = newConfig;
    await saveConfig(newConfig);
    _pb = PocketBase(newConfig.pocketbaseUrl);
    return authenticate();
  }

  /// Test connection to PocketBase without saving.
  Future<bool> testConnection(PocketBaseConfig testConfig) async {
    try {
      final testPb = PocketBase(testConfig.pocketbaseUrl);
      await testPb.collection('users').authWithPassword(testConfig.email, testConfig.password);
      return true;
    } catch (e) {
      logger.e('PocketBase test connection failed: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Realtime subscriptions (replaces Firebase RTDB)
  // ---------------------------------------------------------------------------

  void _subscribeToRealtime() {
    // Single subscription to realtime_state — handles ALL change detection
    _pb.collection('realtime_state').subscribe('*', (e) {
      if (e.action == 'update' || e.action == 'create') {
        final key = e.record?.getStringValue('key');
        final data = e.record?.get<dynamic>('data');
        switch (key) {
          case 'currentSong':
            if (data is Map) {
              _selectedSongController.add(Map<String, dynamic>.from(data));
            }
            break;
          case 'qrLinks':
            if (data is List) {
              final links = data.whereType<Map>().map((e) => QrLink.fromJson(Map<String, dynamic>.from(e))).toList();
              _qrLinksController.add(links);
            }
            break;
          case 'updated':
            // Global trigger — when this timestamp changes, diff all maps
            final newTs = (data is String) ? data : data?.toString() ?? '';
            if (newTs.isNotEmpty && newTs != _lastUpdatedTimestamp) {
              logger.i('Realtime: global updated changed from $_lastUpdatedTimestamp to $newTs');
              _lastUpdatedTimestamp = newTs;
              _triggerUpdateCheck();
            }
            break;
        }
      }
    });
  }

  /// Triggered when the global 'updated' timestamp changes.
  /// Loads all timestamp maps from server and diffs against local state.
  Future<void> _triggerUpdateCheck() async {
    try {
      final songTs = await _loadTimestampMap('songs_updated');
      if (songTs.toString() != _songTimestamps.toString()) {
        await _handleSongTimestampChange(songTs);
      }

      final playlistTs = await _loadTimestampMap('playlists_updated');
      if (playlistTs.toString() != _playlistTimestamps.toString()) {
        await _handlePlaylistTimestampChange(playlistTs);
      }

      final groupTs = await _loadTimestampMap('groups_updated');
      if (groupTs.toString() != _groupTimestamps.toString()) {
        _handleGroupTimestampChange(groupTs);
      }

      final userTs = await _loadTimestampMap('users_updated');
      if (userTs.toString() != _userTimestamps.toString()) {
        await _handleUserTimestampChange(userTs);
      }
    } catch (e) {
      logger.e('Error during update check: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Timestamp map initialization & change detection
  // ---------------------------------------------------------------------------

  Future<void> _initializeTimestampMaps() async {
    _songTimestamps = await _loadTimestampMap('songs_updated');
    _playlistTimestamps = await _loadTimestampMap('playlists_updated');
    _groupTimestamps = await _loadTimestampMap('groups_updated');
    _userTimestamps = await _loadTimestampMap('users_updated');

    // Load the global updated timestamp
    final updatedData = await _getRealtimeState('updated');
    _lastUpdatedTimestamp = (updatedData is String) ? updatedData : updatedData?.toString() ?? '';

    // If maps are empty, build initial maps from existing server data
    if (_songTimestamps.isEmpty) await _buildInitialTimestamps('songs', 'songUuid', 'songs_updated', (m) => _songTimestamps = m);
    if (_playlistTimestamps.isEmpty) await _buildInitialTimestamps('playlists', 'playlistUuid', 'playlists_updated', (m) => _playlistTimestamps = m);
    if (_groupTimestamps.isEmpty) await _buildInitialGroupTimestamps();
    if (_userTimestamps.isEmpty) await _buildInitialUserTimestamps();

    // Initialize global updated if it doesn't exist yet
    if (_lastUpdatedTimestamp.isEmpty) {
      _lastUpdatedTimestamp = DateTime.now().toUtc().toIso8601String();
      await _setRealtimeState('updated', _lastUpdatedTimestamp);
    }
  }

  Future<Map<String, String>> _loadTimestampMap(String key) async {
    final data = await _getRealtimeState(key);
    if (data is Map && data.isNotEmpty) {
      return Map<String, String>.from(data.map((k, v) => MapEntry(k.toString(), v.toString())));
    }
    return {};
  }

  Future<void> _buildInitialTimestamps(String collection, String uuidField, String stateKey, void Function(Map<String, String>) setter) async {
    try {
      final records = await _pb.collection(collection).getFullList();
      final now = DateTime.now().toUtc().toIso8601String();
      final map = <String, String>{for (final r in records) r.getStringValue(uuidField): now};
      setter(map);
      if (map.isNotEmpty) await _setRealtimeState(stateKey, map);
    } catch (e) {
      logger.e('Error building initial timestamps for $collection: $e');
    }
  }

  Future<void> _buildInitialGroupTimestamps() async {
    try {
      final records = await _pb.collection('groups').getFullList();
      final now = DateTime.now().toUtc().toIso8601String();
      _groupTimestamps = {for (final r in records) r.getStringValue('name'): now};
      if (_groupTimestamps.isNotEmpty) await _setRealtimeState('groups_updated', _groupTimestamps);
    } catch (e) {
      logger.e('Error building initial group timestamps: $e');
    }
  }

  Future<void> _buildInitialUserTimestamps() async {
    try {
      final records = await _pb.collection('app_users').getFullList();
      final now = DateTime.now().toUtc().toIso8601String();
      _userTimestamps = {for (final r in records) r.getStringValue('name'): now};
      if (_userTimestamps.isNotEmpty) await _setRealtimeState('users_updated', _userTimestamps);
    } catch (e) {
      logger.e('Error building initial user timestamps: $e');
    }
  }

  // --- Timestamp diff handlers ---

  Future<void> _handleSongTimestampChange(Map<String, String> newTimestamps) async {
    // Detect updated or new songs
    for (final entry in newTimestamps.entries) {
      final id = entry.key;
      final ts = entry.value;
      if (!_songTimestamps.containsKey(id) || _songTimestamps[id] != ts) {
        final song = await getSongByUuid(id);
        if (song != null) {
          final action = _songTimestamps.containsKey(id) ? 'update' : 'create';
          logger.i('Realtime songs: action=$action, id=$id, updated=$ts');
          _songChangeController.add(RealtimeChangeEvent<Song>(
            action: action,
            record: song,
            recordId: id,
            serverUpdated: ts,
          ));
        }
      }
    }
    // Detect deleted songs
    for (final id in _songTimestamps.keys) {
      if (!newTimestamps.containsKey(id)) {
        logger.i('Realtime songs: action=delete, id=$id');
        _songChangeController.add(RealtimeChangeEvent<Song>(
          action: 'delete',
          recordId: id,
        ));
      }
    }
    _songTimestamps = Map.from(newTimestamps);
  }

  Future<void> _handlePlaylistTimestampChange(Map<String, String> newTimestamps) async {
    for (final entry in newTimestamps.entries) {
      final id = entry.key;
      final ts = entry.value;
      if (!_playlistTimestamps.containsKey(id) || _playlistTimestamps[id] != ts) {
        final playlist = await getPlaylist(id);
        if (playlist != null) {
          final action = _playlistTimestamps.containsKey(id) ? 'update' : 'create';
          logger.i('Realtime playlists: action=$action, id=$id, updated=$ts');
          _playlistChangeController.add(RealtimeChangeEvent<Playlist>(
            action: action,
            record: playlist,
            recordId: id,
            serverUpdated: ts,
          ));
        }
      }
    }
    for (final id in _playlistTimestamps.keys) {
      if (!newTimestamps.containsKey(id)) {
        logger.i('Realtime playlists: action=delete, id=$id');
        _playlistChangeController.add(RealtimeChangeEvent<Playlist>(
          action: 'delete',
          recordId: id,
        ));
      }
    }
    _playlistTimestamps = Map.from(newTimestamps);
  }

  void _handleGroupTimestampChange(Map<String, String> newTimestamps) {
    for (final entry in newTimestamps.entries) {
      final name = entry.key;
      final ts = entry.value;
      if (!_groupTimestamps.containsKey(name) || _groupTimestamps[name] != ts) {
        final action = _groupTimestamps.containsKey(name) ? 'update' : 'create';
        logger.i('Realtime groups: action=$action, name=$name, updated=$ts');
        _groupChangeController.add(RealtimeChangeEvent<String>(
          action: action,
          record: name,
          recordId: name,
          serverUpdated: ts,
        ));
      }
    }
    for (final name in _groupTimestamps.keys) {
      if (!newTimestamps.containsKey(name)) {
        logger.i('Realtime groups: action=delete, name=$name');
        _groupChangeController.add(RealtimeChangeEvent<String>(
          action: 'delete',
          recordId: name,
        ));
      }
    }
    _groupTimestamps = Map.from(newTimestamps);
  }

  Future<void> _handleUserTimestampChange(Map<String, String> newTimestamps) async {
    for (final entry in newTimestamps.entries) {
      final name = entry.key;
      final ts = entry.value;
      if (!_userTimestamps.containsKey(name) || _userTimestamps[name] != ts) {
        final user = await getUserByName(name);
        if (user != null) {
          final action = _userTimestamps.containsKey(name) ? 'update' : 'create';
          logger.i('Realtime app_users: action=$action, name=$name, updated=$ts');
          _userChangeController.add(RealtimeChangeEvent<User>(
            action: action,
            record: user,
            recordId: name,
            serverUpdated: ts,
          ));
        }
      }
    }
    for (final name in _userTimestamps.keys) {
      if (!newTimestamps.containsKey(name)) {
        logger.i('Realtime app_users: action=delete, name=$name');
        _userChangeController.add(RealtimeChangeEvent<User>(
          action: 'delete',
          recordId: name,
        ));
      }
    }
    _userTimestamps = Map.from(newTimestamps);
  }

  // --- Timestamp update helpers (called after CRUD) ---

  /// Bumps the global 'updated' timestamp — this is what the listener watches.
  Future<void> _bumpUpdatedTimestamp() async {
    _lastUpdatedTimestamp = DateTime.now().toUtc().toIso8601String();
    await _setRealtimeState('updated', _lastUpdatedTimestamp);
  }

  Future<void> _updateSongTimestamp(String songUuid) async {
    _songTimestamps[songUuid] = DateTime.now().toUtc().toIso8601String();
    await _setRealtimeState('songs_updated', _songTimestamps);
    await _bumpUpdatedTimestamp();
  }

  Future<void> _removeSongTimestamp(String songUuid) async {
    _songTimestamps.remove(songUuid);
    await _setRealtimeState('songs_updated', _songTimestamps);
    await _bumpUpdatedTimestamp();
  }

  Future<void> _updatePlaylistTimestamp(String playlistUuid) async {
    _playlistTimestamps[playlistUuid] = DateTime.now().toUtc().toIso8601String();
    await _setRealtimeState('playlists_updated', _playlistTimestamps);
    await _bumpUpdatedTimestamp();
  }

  Future<void> _removePlaylistTimestamp(String playlistUuid) async {
    _playlistTimestamps.remove(playlistUuid);
    await _setRealtimeState('playlists_updated', _playlistTimestamps);
    await _bumpUpdatedTimestamp();
  }

  Future<void> _updateGroupTimestamp(String groupName) async {
    _groupTimestamps[groupName] = DateTime.now().toUtc().toIso8601String();
    await _setRealtimeState('groups_updated', _groupTimestamps);
    await _bumpUpdatedTimestamp();
  }

  Future<void> _removeGroupTimestamp(String groupName) async {
    _groupTimestamps.remove(groupName);
    await _setRealtimeState('groups_updated', _groupTimestamps);
    await _bumpUpdatedTimestamp();
  }

  Future<void> _updateUserTimestamp(String userName) async {
    _userTimestamps[userName] = DateTime.now().toUtc().toIso8601String();
    await _setRealtimeState('users_updated', _userTimestamps);
    await _bumpUpdatedTimestamp();
  }

  Future<void> _removeUserTimestamp(String userName) async {
    _userTimestamps.remove(userName);
    await _setRealtimeState('users_updated', _userTimestamps);
    await _bumpUpdatedTimestamp();
  }

  // ---------------------------------------------------------------------------
  // Realtime state (currentSong, qrLinks) — replaces Firebase RTDB
  // ---------------------------------------------------------------------------

  Future<void> _setRealtimeState(String key, dynamic data) async {
    try {
      // Try to find existing record
      final results = await _pb.collection('realtime_state').getFullList(filter: 'key = "$key"');
      if (results.isNotEmpty) {
        await _pb.collection('realtime_state').update(results.first.id, body: {'data': data});
      } else {
        await _pb.collection('realtime_state').create(body: {'key': key, 'data': data});
      }
    } catch (e) {
      logger.e('Error setting realtime state "$key": $e');
    }
  }

  Future<dynamic> _getRealtimeState(String key) async {
    try {
      final results = await _pb.collection('realtime_state').getFullList(filter: 'key = "$key"');
      if (results.isNotEmpty) {
        return results.first.get<dynamic>('data');
      }
    } catch (e) {
      logger.e('Error getting realtime state "$key": $e');
    }
    return null;
  }

  void saveNewSelectedSong(String id, String title, String interpret, String lyricsWithoutChords, String lyricsWithChords) {
    final data = {'song': id, 'title': title, 'interpret': interpret, 'lyricsWithoutChords': lyricsWithoutChords, 'lyricsWithChords': lyricsWithChords};
    _setRealtimeState('currentSong', data);
  }

  void removeSelectedSong() {
    final data = {'song': '', 'title': '', 'interpret': '', 'lyricsWithoutChords': '', 'lyricsWithChords': ''};
    _setRealtimeState('currentSong', data);
  }

  Future<void> setQrLinks(List<QrLink> links) async {
    final data = links.map((e) => e.toJson()).toList();
    await _setRealtimeState('qrLinks', data);
  }

  Future<List<QrLink>?> getQrLinks() async {
    final data = await _getRealtimeState('qrLinks');
    if (data is List) {
      return data.whereType<Map>().map((e) => QrLink.fromJson(Map<String, dynamic>.from(e))).toList();
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Single-record fetch helpers (used by timestamp diff handlers)
  // ---------------------------------------------------------------------------

  Future<Song?> getSongByUuid(String uuid) async {
    try {
      final results = await _pb.collection('songs').getFullList(filter: 'songUuid = "${_escapeFilter(uuid)}"');
      if (results.isNotEmpty) {
        return _recordToSong(results.first);
      }
    } catch (e) {
      logger.e('Error getting song by UUID: $e');
    }
    return null;
  }

  Future<User?> getUserByName(String name) async {
    try {
      final results = await _pb.collection('app_users').getFullList(filter: 'name = "${_escapeFilter(name)}"');
      if (results.isNotEmpty) {
        return _recordToUser(results.first);
      }
    } catch (e) {
      logger.e('Error getting user by name: $e');
    }
    return null;
  }

  // ---------------------------------------------------------------------------
  // Songs CRUD
  // ---------------------------------------------------------------------------

  Future<List<Song>> getListSongs() async {
    try {
      final records = await _pb.collection('songs').getFullList(sort: 'title');
      return records.map((r) => _recordToSong(r)).toList();
    } catch (e) {
      logger.e('Error getting songs: $e');
      return [];
    }
  }

  Future<bool> addOrUpdateSong(Song song) async {
    try {
      // Find by songUuid
      final existing = await _pb.collection('songs').getFullList(filter: 'songUuid = "${_escapeFilter(song.id)}"');
      final body = _songToBody(song);
      if (existing.isNotEmpty) {
        await _pb.collection('songs').update(existing.first.id, body: body);
      } else {
        await _pb.collection('songs').create(body: body);
      }
      await _updateSongTimestamp(song.id);
      return true;
    } catch (e) {
      logger.e('Error saving song: $e');
      return false;
    }
  }

  Future<bool> deleteSong(String songUuid) async {
    try {
      final existing = await _pb.collection('songs').getFullList(filter: 'songUuid = "${_escapeFilter(songUuid)}"');
      if (existing.isNotEmpty) {
        await _pb.collection('songs').delete(existing.first.id);
        await _removeSongTimestamp(songUuid);
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Error deleting song: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Playlists CRUD
  // ---------------------------------------------------------------------------

  Future<List<Playlist>> getListPlaylists() async {
    try {
      final records = await _pb.collection('playlists').getFullList(sort: 'name');
      return records.map((r) => _recordToPlaylist(r)).toList();
    } catch (e) {
      logger.e('Error getting playlists: $e');
      return [];
    }
  }

  Future<Playlist?> getPlaylist(String playlistUuid) async {
    try {
      final results = await _pb.collection('playlists').getFullList(filter: 'playlistUuid = "${_escapeFilter(playlistUuid)}"');
      if (results.isNotEmpty) {
        return _recordToPlaylist(results.first);
      }
    } catch (e) {
      logger.e('Error getting playlist: $e');
    }
    return null;
  }

  Future<bool> addOrUpdatePlaylist(Playlist playlist) async {
    try {
      final existing = await _pb.collection('playlists').getFullList(filter: 'playlistUuid = "${_escapeFilter(playlist.id ?? '')}"');
      final body = _playlistToBody(playlist);
      if (existing.isNotEmpty) {
        await _pb.collection('playlists').update(existing.first.id, body: body);
      } else {
        await _pb.collection('playlists').create(body: body);
      }
      await _updatePlaylistTimestamp(playlist.id ?? '');
      return true;
    } catch (e) {
      logger.e('Error saving playlist: $e');
      return false;
    }
  }

  Future<bool> deletePlaylist(Playlist playlist) async {
    try {
      final existing = await _pb.collection('playlists').getFullList(filter: 'playlistUuid = "${_escapeFilter(playlist.id ?? '')}"');
      if (existing.isNotEmpty) {
        await _pb.collection('playlists').delete(existing.first.id);
        await _removePlaylistTimestamp(playlist.id ?? '');
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Error deleting playlist: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // App Users CRUD
  // ---------------------------------------------------------------------------

  Future<List<User>> getListAppUsers() async {
    try {
      final records = await _pb.collection('app_users').getFullList(sort: 'name');
      return records.map((r) => _recordToUser(r)).toList();
    } catch (e) {
      logger.e('Error getting app users: $e');
      return [];
    }
  }

  Future<bool> addOrUpdateAppUser(User user) async {
    try {
      final existing = await _pb.collection('app_users').getFullList(filter: 'name = "${_escapeFilter(user.name)}"');
      final body = _userToBody(user);
      if (existing.isNotEmpty) {
        await _pb.collection('app_users').update(existing.first.id, body: body);
      } else {
        await _pb.collection('app_users').create(body: body);
      }
      await _updateUserTimestamp(user.name);
      return true;
    } catch (e) {
      logger.e('Error saving app user: $e');
      return false;
    }
  }

  Future<bool> deleteAppUser(User user) async {
    try {
      final existing = await _pb.collection('app_users').getFullList(filter: 'name = "${_escapeFilter(user.name)}"');
      if (existing.isNotEmpty) {
        await _pb.collection('app_users').delete(existing.first.id);
        await _removeUserTimestamp(user.name);
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Error deleting app user: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Groups CRUD
  // ---------------------------------------------------------------------------

  Future<List<String>> getListGroups() async {
    try {
      final records = await _pb.collection('groups').getFullList(sort: 'name');
      return records.map((r) => r.getStringValue('name')).toList();
    } catch (e) {
      logger.e('Error getting groups: $e');
      return [];
    }
  }

  Future<bool> createGroup(String groupName) async {
    try {
      final existing = await _pb.collection('groups').getFullList(filter: 'name = "${_escapeFilter(groupName)}"');
      if (existing.isNotEmpty) return false;
      await _pb.collection('groups').create(body: {'name': groupName});
      await _updateGroupTimestamp(groupName);
      return true;
    } catch (e) {
      logger.e('Error creating group: $e');
      return false;
    }
  }

  Future<bool> deleteGroup(String groupName) async {
    try {
      final existing = await _pb.collection('groups').getFullList(filter: 'name = "${_escapeFilter(groupName)}"');
      if (existing.isNotEmpty) {
        await _pb.collection('groups').delete(existing.first.id);
        await _removeGroupTimestamp(groupName);
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Error deleting group: $e');
      return false;
    }
  }

  Future<bool> updateGroup(String oldName, String newName) async {
    try {
      final existing = await _pb.collection('groups').getFullList(filter: 'name = "${_escapeFilter(oldName)}"');
      if (existing.isNotEmpty) {
        await _pb.collection('groups').update(existing.first.id, body: {'name': newName});
        _groupTimestamps.remove(oldName);
        _groupTimestamps[newName] = DateTime.now().toUtc().toIso8601String();
        await _setRealtimeState('groups_updated', _groupTimestamps);
        await _bumpUpdatedTimestamp();
        return true;
      }
      return false;
    } catch (e) {
      logger.e('Error updating group: $e');
      return false;
    }
  }

  Future<bool> addGroupsList(List<String> groups) async {
    try {
      final existingRecords = await _pb.collection('groups').getFullList();
      final existingNames = existingRecords.map((r) => r.getStringValue('name')).toSet();
      final now = DateTime.now().toUtc().toIso8601String();
      var added = false;
      for (final group in groups) {
        if (!existingNames.contains(group)) {
          await _pb.collection('groups').create(body: {'name': group});
          _groupTimestamps[group] = now;
          added = true;
        }
      }
      if (added) {
        await _setRealtimeState('groups_updated', _groupTimestamps);
        await _bumpUpdatedTimestamp();
      }
      return true;
    } catch (e) {
      logger.e('Error adding groups list: $e');
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // File upload (replaces Firebase Storage)
  // ---------------------------------------------------------------------------

  /// Uploads a file and returns its public URL.
  /// Files are stored in an 'uploads' collection with a file field.
  Future<String?> uploadFile(String fileName, List<int> fileBytes, {String? contentType}) async {
    try {
      final file = http.MultipartFile.fromBytes(
        'file',
        fileBytes,
        filename: fileName,
      );
      final record = await _pb.collection('uploads').create(
        body: {'name': fileName},
        files: [file],
      );
      // Build public URL: <baseUrl>/api/files/<collectionId>/<recordId>/<filename>
      final uploadedFileName = (record.get<dynamic>('file') as String?) ?? fileName;
      return '${_config!.pocketbaseUrl}/api/files/${record.collectionId}/${record.id}/$uploadedFileName';
    } catch (e) {
      logger.e('Error uploading file: $e');
      return null;
    }
  }

  /// Returns the PocketBase instance for advanced usage (e.g., file URLs).
  PocketBase get pb => _pb;

  // ---------------------------------------------------------------------------
  // Sync helpers — get record counts for smart sync
  // ---------------------------------------------------------------------------

  Future<int> getServerSongCount() async {
    try {
      final result = await _pb.collection('songs').getList(page: 1, perPage: 1);
      return result.totalItems;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getServerPlaylistCount() async {
    try {
      final result = await _pb.collection('playlists').getList(page: 1, perPage: 1);
      return result.totalItems;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getServerUserCount() async {
    try {
      final result = await _pb.collection('app_users').getList(page: 1, perPage: 1);
      return result.totalItems;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getServerGroupCount() async {
    try {
      final result = await _pb.collection('groups').getList(page: 1, perPage: 1);
      return result.totalItems;
    } catch (e) {
      return 0;
    }
  }

  /// Upload all local songs to server (for initial push).
  Future<int> uploadAllSongs(List<Song> songs) async {
    int count = 0;
    for (final song in songs) {
      // addOrUpdateSong already updates timestamps individually
      final result = await addOrUpdateSong(song);
      if (result) count++;
    }
    return count;
  }

  /// Upload all local playlists to server (for initial push).
  Future<int> uploadAllPlaylists(List<Playlist> playlists) async {
    int count = 0;
    for (final playlist in playlists) {
      final result = await addOrUpdatePlaylist(playlist);
      if (result) count++;
    }
    return count;
  }

  /// Upload all local users to server (for initial push).
  Future<int> uploadAllUsers(List<User> users) async {
    int count = 0;
    for (final user in users) {
      final result = await addOrUpdateAppUser(user);
      if (result) count++;
    }
    return count;
  }

  /// Upload all local groups to server (for initial push).
  Future<int> uploadAllGroups(List<String> groups) async {
    return (await addGroupsList(groups)) ? groups.length : 0;
  }

  // ---------------------------------------------------------------------------
  // Data conversion helpers
  // ---------------------------------------------------------------------------

  String _escapeFilter(String value) {
    return value.replaceAll('"', '\\"');
  }

  Song _recordToSong(RecordModel r) {
    final song = Song(
      id: r.getStringValue('songUuid'),
      title: r.getStringValue('title'),
      lyrics: r.getStringValue('lyrics'),
      originalLyrics: r.getStringValue('originalLyrics'),
      indexSongBook: r.get<int?>('indexSongBook'),
      interpret: r.getStringValue('interpret'),
      songBar: r.get<int?>('songBar'),
      bmp: r.get<int?>('bmp'),
    );

    // typeTranspose
    final tt = r.getStringValue('typeTranspose');
    if (tt == 'german') {
      song.typeTranspose = TypeTranspose.german;
    } else {
      song.typeTranspose = TypeTranspose.czech;
    }

    // JSON array fields
    final sheetsData = r.get<dynamic>('sheets');
    if (sheetsData is List) {
      song.sheets = sheetsData.map((e) => e.toString()).toList();
    }

    final groupsData = r.get<dynamic>('groups');
    if (groupsData is List) {
      song.groups = groupsData.map((e) => e.toString()).toList();
    }

    final tagsData = r.get<dynamic>('tags');
    if (tagsData is List) {
      song.tags = tagsData.map((e) => e.toString()).toList();
    }

    final notesData = r.get<dynamic>('notes');
    if (notesData is List) {
      song.notes = notesData.whereType<Map>().map((e) => Note.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    final ytData = r.get<dynamic>('youtubeVideos');
    if (ytData is List) {
      song.youtubeVideos = ytData.whereType<Map>().map((e) => YoutubeVideo.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    return song;
  }

  Map<String, dynamic> _songToBody(Song song) {
    return {
      'songUuid': song.id,
      'title': song.title,
      'lyrics': song.lyrics,
      'originalLyrics': song.originalLyrics ?? '',
      'indexSongBook': song.indexSongBook,
      'interpret': song.interpret ?? '',
      'typeTranspose': song.typeTranspose == TypeTranspose.german ? 'german' : 'czech',
      'songBar': song.songBar,
      'bmp': song.bmp,
      'sheets': song.sheets ?? [],
      'groups': song.groups ?? [],
      'tags': song.tags ?? [],
      'notes': song.notes?.map((e) => e.toJson()).toList() ?? [],
      'youtubeVideos': song.youtubeVideos?.map((e) => e.toJson()).toList() ?? [],
    };
  }

  Playlist _recordToPlaylist(RecordModel r) {
    final playlist = Playlist(
      id: r.getStringValue('playlistUuid'),
      name: r.getStringValue('name'),
    );
    final songIdsData = r.get<dynamic>('listSongIds');
    if (songIdsData is List) {
      playlist.listSongIds = songIdsData.map((e) => e.toString()).toList();
    }
    return playlist;
  }

  Map<String, dynamic> _playlistToBody(Playlist playlist) {
    return {
      'playlistUuid': playlist.id ?? '',
      'name': playlist.name,
      'listSongIds': playlist.listSongIds,
    };
  }

  User _recordToUser(RecordModel r) {
    final user = User(r.getStringValue('name'), r.getStringValue('appPassword'));
    final typeStr = r.getStringValue('typeUser');
    user.typeUser = TypeUser.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => TypeUser.none,
    );
    final groupData = r.get<dynamic>('allowedGroup');
    if (groupData is List) {
      user.allowedGroup = groupData.map((e) => e.toString()).toList();
    }
    return user;
  }

  Map<String, dynamic> _userToBody(User user) {
    return {
      'name': user.name,
      'appPassword': user.password,
      'typeUser': user.typeUser.name,
      'allowedGroup': user.allowedGroup,
    };
  }

  /// Clean up subscriptions.
  void dispose() {
    _pb.collection('realtime_state').unsubscribe();
    _selectedSongController.close();
    _songChangeController.close();
    _playlistChangeController.close();
    _userChangeController.close();
    _groupChangeController.close();
    _qrLinksController.close();
  }
}

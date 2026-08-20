import 'dart:async';

import 'package:collection/collection.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../model/playlist.dart';
import '../providers/hive_provider.dart';
import '../providers/pocketbase_provider.dart';

class PlaylistRepository {
  final PocketBaseProvider _pocketBaseProvider;
  final HiveProvider _hiveProvider;

  var _playlists = <Playlist>[];

  final isChangedPlaylistController = StreamController<int>.broadcast();
  Stream<int> get isChangedPlaylist => isChangedPlaylistController.stream.asBroadcastStream();
  int _isChangedPlaylistValue = 0;

  PlaylistRepository({
    required HiveProvider hiveProvider,
    required PocketBaseProvider pocketBaseProvider,
  })  : _hiveProvider = hiveProvider,
        _pocketBaseProvider = pocketBaseProvider {
    _init();
  }

  List<Playlist> get playlists {
    return List<Playlist>.from(_playlists);
  }

  void _init() async {
    // Cache first: the app must show the user's playlists with no server and no
    // network. The server, when there is one, replaces the list afterwards.
    _loadFromCache();

    if (_pocketBaseProvider.isConnected) {
      _playlists = await _pocketBaseProvider.getListPlaylists();
      await _saveToCache();
      isChangedPlaylistController.sink.add(_isChangedPlaylistValue++);
    }

    // Listen to granular playlist change events via PocketBase realtime
    _pocketBaseProvider.playlistChangeStream.listen((event) {
      _handlePlaylistRealtimeEvent(event);
    });
  }

  void _loadFromCache() {
    final cached = _hiveProvider.loadPlaylistsCache();
    if (cached == null) return;
    _playlists = [];
    for (final json in cached) {
      try {
        _playlists.add(Playlist.fromJson(json));
      } catch (e) {
        logger.w('Error parsing cached playlist: $e');
      }
    }
    logger.i('Loaded ${_playlists.length} playlists from Hive cache');
  }

  Future<void> _saveToCache() async {
    try {
      _hiveProvider.savePlaylistsCache(_playlists.map((p) => p.toJson()).toList());
    } catch (e) {
      logger.e('Error saving playlists to cache: $e');
    }
  }

  void _handlePlaylistRealtimeEvent(RealtimeChangeEvent<Playlist> event) {
    if (event.isDelete) {
      _playlists.removeWhere((p) => p.id == event.recordId);
      logger.i('Realtime: playlist deleted id=${event.recordId}');
    } else if (event.isCreate && event.record != null) {
      final existing = _playlists.firstWhereOrNull((p) => p.id == event.record!.id);
      if (existing == null) {
        _playlists.add(event.record!);
        logger.i('Realtime: playlist created id=${event.record!.id} updated=${event.serverUpdated}');
      }
    } else if (event.isUpdate && event.record != null) {
      final index = _playlists.indexWhere((p) => p.id == event.record!.id);
      if (index >= 0) {
        _playlists[index] = event.record!;
        logger.i('Realtime: playlist updated id=${event.record!.id} updated=${event.serverUpdated}');
      } else {
        _playlists.add(event.record!);
        logger.i('Realtime: playlist updated (new) id=${event.record!.id} updated=${event.serverUpdated}');
      }
    }
    _saveToCache();
    isChangedPlaylistController.sink.add(_isChangedPlaylistValue++);
  }

  /// Writes locally first, then to the server when there is one.
  ///
  /// The local write is what decides the return value: a build with no server
  /// must still be able to create and edit playlists. When a server *is*
  /// connected and rejects the write, the local copy is kept anyway and the
  /// failure is logged — dropping the user's edit would be worse.
  Future<bool> savePlaylist(Playlist playlist) async {
    playlist.updatedAt = DateTime.now().toUtc();

    _playlists.removeWhere((element) => element.id == playlist.id);
    _playlists.add(playlist);
    await _saveToCache();

    if (_pocketBaseProvider.isConnected) {
      final result = await _pocketBaseProvider.addOrUpdatePlaylist(playlist);
      if (!result) logger.w('Playlist saved locally but not pushed to server: ${playlist.name}');
    }
    return true;
  }

  /// Restores playlists from a backup, upserting every one.
  ///
  /// Goes through the local list rather than straight to the server, so a
  /// backup restores into a build that has no server at all.
  Future<int> restorePlaylists(List<Playlist> restored) async {
    if (restored.isEmpty) return 0;

    final now = DateTime.now().toUtc();
    for (final playlist in restored) {
      playlist.updatedAt = now;
      _playlists.removeWhere((p) => p.id == playlist.id);
      _playlists.add(playlist);
    }
    await _saveToCache();

    if (_pocketBaseProvider.isConnected) {
      for (final playlist in restored) {
        final ok = await _pocketBaseProvider.addOrUpdatePlaylist(playlist);
        if (!ok) logger.w('Restored playlist not pushed to server: ${playlist.name}');
      }
    }

    isChangedPlaylistController.sink.add(_isChangedPlaylistValue++);
    return restored.length;
  }

  Future<bool> deletePlaylist(Playlist playlist) async {
    if (_pocketBaseProvider.isConnected) {
      final result = await _pocketBaseProvider.deletePlaylist(playlist);
      // With a server present it stays the source of truth: a refused delete
      // must not leave the two sides disagreeing.
      if (!result) return false;
    }

    _playlists.removeWhere((element) => element.id == playlist.id);
    await _saveToCache();
    return true;
  }
}

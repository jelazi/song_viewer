import 'dart:async';

import 'package:collection/collection.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../model/playlist.dart';
import '../providers/hive_provider.dart';
import '../providers/pocketbase_provider.dart';

class PlaylistRepository {
  final HiveProvider _hiveProvider;
  final PocketBaseProvider _pocketBaseProvider;

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
    _playlists = await _pocketBaseProvider.getListPlaylists();

    // Listen to granular playlist change events via PocketBase realtime
    _pocketBaseProvider.playlistChangeStream.listen((event) {
      _handlePlaylistRealtimeEvent(event);
    });
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
    isChangedPlaylistController.sink.add(_isChangedPlaylistValue++);
  }

  Future<bool> savePlaylist(Playlist playlist) async {
    final result = await _pocketBaseProvider.addOrUpdatePlaylist(playlist);
    if (result == false) {
      return false;
    }
    if (_playlists.any((element) => element.id == playlist.id)) {
      _playlists.removeWhere((element) => element.id == playlist.id);
    }
    _playlists.add(playlist);
    return true;
  }

  Future<bool> deletePlaylist(Playlist playlist) async {
    final result = await _pocketBaseProvider.deletePlaylist(playlist);
    if (result == false) {
      return false;
    }
    _playlists.removeWhere((element) => element.id == playlist.id);
    return true;
  }
}

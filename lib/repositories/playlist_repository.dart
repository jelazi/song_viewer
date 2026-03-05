import 'dart:async';

import 'package:logger_pkg/logger_pkg.dart';

import '../model/playlist.dart';
import '../model/update_playlist_data.dart';
import '../providers/firebase_provider.dart';
import '../providers/hive_provider.dart';

Map<String, dynamic> _deepCastMap(Map data) {
  return data.map((key, value) {
    if (value is Map) {
      return MapEntry(key.toString(), _deepCastMap(value));
    }
    return MapEntry(key.toString(), value);
  });
}

class PlaylistRepository {
  final HiveProvider _hiveProvider;
  final FirebaseProvider _firebaseProvider;

  var _playlists = <Playlist>[];

  late UpdatePlaylistData updatePlaylistData;

  final isChangedPlaylistController = StreamController<int>.broadcast();
  Stream<int> get isChangedPlaylist => isChangedPlaylistController.stream.asBroadcastStream();
  int _isChangedPlaylistValue = 0;

  PlaylistRepository({
    required HiveProvider hiveProvider,
    required FirebaseProvider firebaseProvider,
  })  : _hiveProvider = hiveProvider,
        _firebaseProvider = firebaseProvider {
    _init();
  }

  List<Playlist> get playlists {
    return List<Playlist>.from(_playlists);
  }

  void _init() async {
    updatePlaylistData = _hiveProvider.getUpdatePlaylistData('updatePlaylistData') ?? UpdatePlaylistData(DateTime(1900), {});

    _playlists = await _firebaseProvider.getListPlaylistsFromFirestore();

    // Listen to playlist update notifications from RTDB
    _firebaseProvider.updatePlaylistStream.listen((data) {
      if (data != null) {
        try {
          final castedData = _deepCastMap(data);
          final newUpdatePlaylistData = UpdatePlaylistData.fromJson(castedData);
          if (newUpdatePlaylistData.lastUpdate.isAfter(updatePlaylistData.lastUpdate)) {
            _updatePlaylistsFromFirebase(newUpdatePlaylistData);
          }
        } catch (e) {
          logger.e('Error update playlist from firebase: $e');
        }
      }
    });
  }

  void _updatePlaylistsFromFirebase(UpdatePlaylistData newUpdatePlaylistData) async {
    // Find playlist IDs that are new or updated compared to what we already know
    final changedIds = <String>[];
    for (final entry in newUpdatePlaylistData.mapIdPlaylists.entries) {
      final oldTimestamp = updatePlaylistData.mapIdPlaylists[entry.key];
      if (oldTimestamp == null || entry.value.isAfter(oldTimestamp)) {
        changedIds.add(entry.key);
      }
    }

    updatePlaylistData = newUpdatePlaylistData;
    _hiveProvider.setUpdatePlaylistData('updatePlaylistData', updatePlaylistData);

    // Fetch only the changed playlists individually
    for (final id in changedIds) {
      final playlist = await _firebaseProvider.getPlaylistFromFirestore(id);
      if (playlist != null) {
        // Update or add
        _playlists.removeWhere((p) => p.id == id);
        _playlists.add(playlist);
      } else {
        // Playlist was deleted
        _playlists.removeWhere((p) => p.id == id);
      }
    }

    isChangedPlaylistController.sink.add(_isChangedPlaylistValue++);
  }

  Future<void> _notifyPlaylistUpdate(String playlistId) async {
    updatePlaylistData.lastUpdate = DateTime.now();
    updatePlaylistData.mapIdPlaylists[playlistId] = DateTime.now();
    updatePlaylistData = removeUpdateDataOlderThanThreeDays(updatePlaylistData);
    _hiveProvider.setUpdatePlaylistData('updatePlaylistData', updatePlaylistData);
    await _firebaseProvider.setUpdatePlaylist(updatePlaylistData);
  }

  UpdatePlaylistData removeUpdateDataOlderThanThreeDays(UpdatePlaylistData data) {
    final newMap = <String, DateTime>{};
    data.mapIdPlaylists.forEach((key, value) {
      if (value.isAfter(DateTime.now().subtract(const Duration(days: 3)))) {
        newMap[key] = value;
      }
    });
    return UpdatePlaylistData(data.lastUpdate, newMap);
  }

  Future<bool> savePlaylist(Playlist playlist) async {
    final result = await _firebaseProvider.addPlaylistToFirebase(playlist);
    if (result == false) {
      return false;
    }
    if (_playlists.any((element) => element.id == playlist.id)) {
      _playlists.removeWhere((element) => element.id == playlist.id);
    }
    _playlists.add(playlist);
    await _notifyPlaylistUpdate(playlist.id ?? '');
    return true;
  }

  Future<bool> deletePlaylist(Playlist playlist) async {
    final result = await _firebaseProvider.deletePlaylist(playlist);
    if (result == false) {
      return false;
    }
    _playlists.removeWhere((element) => element.id == playlist.id);
    await _notifyPlaylistUpdate(playlist.id ?? '');
    return true;
  }
}

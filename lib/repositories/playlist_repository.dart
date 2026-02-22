import '../model/playlist.dart';
import '../providers/firebase_provider.dart';
import '../providers/hive_provider.dart';

class PlaylistRepository {
  // ignore: unused_field
  final HiveProvider _hiveProvider;
  final FirebaseProvider _firebaseProvider;

  var _playlists = <Playlist>[];

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
    _playlists = await _firebaseProvider.getListPlaylistsFromFirestore();
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

    return true;
  }

  Future<bool> deletePlaylist(Playlist playlist) async {
    final result = await _firebaseProvider.deletePlaylist(playlist);
    if (result == false) {
      return false;
    }
    _playlists.removeWhere((element) => element.id == playlist.id);
    return true;
  }
}

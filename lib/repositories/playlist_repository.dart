import '../model/playlist.dart';
import '../providers/firebase_provider.dart';
import '../providers/hive_provider.dart';

class PlaylistRepository {
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
    _firebaseProvider.addPlaylistToFirebase(playlist);
    _playlists = await _firebaseProvider.getListPlaylistsFromFirestore();
    return true;
  }

  Future<bool> deletePlaylist(Playlist playlist) async {
    await _firebaseProvider.deletePlaylist(playlist);
    _playlists = await _firebaseProvider.getListPlaylistsFromFirestore();
    return true;
  }
}

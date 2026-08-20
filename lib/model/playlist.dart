import 'package:json_annotation/json_annotation.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:uuid/uuid.dart';

import 'song/song.dart';

part 'playlist.g.dart';

@JsonSerializable(explicitToJson: true)
class Playlist {
  String name;
  String? id;
  List<String> listSongIds = [];

  /// UTC time of the last local write, set by [PlaylistRepository] on every
  /// save. Basis for per-record last-write-wins. **Not stored on the PocketBase
  /// server** — the `playlists` collection has no such field, so a playlist
  /// that round-trips through the server comes back with this null.
  DateTime? updatedAt;

  Playlist({required this.id, required this.name, this.updatedAt}) {
    _generateId();
  }

  void _generateId() {
    if (id != null) return;
    var uuidGener = const Uuid();
    id = uuidGener.v1();
  }

  String addSong(Song song) {
    if (listSongIds.contains(song.id)) {
      logger.w('this song is in playlist');
      return 'isInPlaylist';
    }
    listSongIds.add(song.id);
    return '';
  }

  factory Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$PlaylistToJson(this);
}

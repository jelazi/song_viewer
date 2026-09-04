import '../../model/playlist.dart';
import '../../model/song/song.dart';

/// JSON shapes served to the browser by [LocalWebServer].
///
/// The field names deliberately match what the hudebni-web (zizkovi.online)
/// client already expects, so the two front-ends stay interchangeable.
class LocalWebPayload {
  const LocalWebPayload._();

  /// Lyrics as the browser renders them: chords stay as `[Am]` markers, the
  /// app's `{...}` line notes are dropped.
  ///
  /// The note markers are stripped rather than rendered because they are an
  /// editing aid tied to the desktop's own line layout — there is nothing on
  /// the page to anchor them to.
  static String content(Song song) => song.lyrics.replaceAll(RegExp(r'\{[^}]*\}'), '');

  /// The short form used in list and playlist views.
  static Map<String, dynamic> songSummary(Song song) => {
        'id': song.id,
        'title': song.title,
        'interpret': song.interpret ?? '',
        'indexSongBook': song.indexSongBook,
        'groups': song.groups ?? const <String>[],
        'tags': song.tags ?? const <String>[],
        'hasSheets': song.sheets?.isNotEmpty ?? false,
        'hasVideos': song.youtubeVideos?.isNotEmpty ?? false,
        'lyricsPlain': song.lyricsWithoutChordsWithLines,
      };

  static Map<String, dynamic> songDetail(Song song) => {
        'id': song.id,
        'title': song.title,
        'interpret': song.interpret ?? '',
        'indexSongBook': song.indexSongBook,
        'typeTranspose': song.typeTranspose.name,
        'content': content(song),
        'groups': song.groups ?? const <String>[],
        'tags': song.tags ?? const <String>[],
        'sheets': song.sheets ?? const <String>[],
        'youtubeVideos': (song.youtubeVideos ?? const []).map((v) => {'name': v.name, 'path': v.path}).toList(),
        'performanceNotes': (song.notes ?? const []).where((n) => n.isNotEmpty).map((n) => {'index': n.index, 'noteText': n.noteText}).toList(),
        'chordOverrides': song.chordOverrides ?? const <String, List<String>>{},
      };

  static Map<String, dynamic> playlistSummary(Playlist playlist) => {
        'id': playlist.id ?? '',
        'name': playlist.name,
        'songCount': playlist.listSongIds.length,
      };

  static Map<String, dynamic> playlistDetail(Playlist playlist, List<Song> songs) => {
        'id': playlist.id ?? '',
        'name': playlist.name,
        'songs': songs.map(songSummary).toList(),
      };

  static Map<String, dynamic> currentSong(String songId) => {'songId': songId};

  /// The whole diagram library, keyed by chord name.
  ///
  /// It has to be the whole library rather than just the chords a song uses:
  /// the reader can transpose, and a transposed chord is a different grip, not
  /// the original one under a new name. The map is a few kilobytes, so sending
  /// it once per page load is cheaper than getting this wrong.
  static Map<String, List<String>> chordLibrary(
    Iterable<String> names,
    List<String> Function(String chordName, {Song? song}) resolve,
  ) {
    final map = <String, List<String>>{};
    for (final name in names) {
      final positions = resolve(name);
      if (positions.isNotEmpty) map[name] = positions;
    }
    return map;
  }
}

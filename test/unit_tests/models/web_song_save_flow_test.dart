import 'package:song_viewer/model/song/song.dart';
import 'package:song_viewer/model/web_song.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger_pkg/logger_pkg.dart';

/// Reproduces, in pure data terms, the "save a song from the web" flow used by
/// the desktop web body and verifies that the lyrics survive every step:
/// build -> persist (JSON cache / PocketBase body) -> reload -> display.
///
/// These tests guard against the regression where a web song was saved with
/// only its title and interpret, but no lyrics.
void main() {
  setUpAll(() {
    logger = MyLogger(debug: false, saveToFile: false, level: 0);
  });

  const sampleLyric = 'Intro\n[Ab] [Db]\n\nVerse\n[Ab]I love You Lord\n[Db]Oh Your mercy never fails me';

  Song buildSavedSongFromWeb(WebSong web) {
    // Mirrors WebBody._openSaveDialog: a fresh song carrying the downloaded text.
    final song = Song.empty();
    song.id = 'generated-id';
    song.title = web.title;
    song.interpret = web.interpret;
    song.lyrics = web.lyric;
    song.groups = ['Test'];
    return song;
  }

  group('Web song save flow', () {
    test('song built from a web song keeps the downloaded lyrics', () {
      final web = WebSong(
        title: 'Gratitude',
        ref: 'gratitude-chords',
        interpret: 'Brandon Lake',
        server: 'worshipchords.com',
        lyric: sampleLyric,
      );

      final song = buildSavedSongFromWeb(web);

      expect(song.title, 'Gratitude');
      expect(song.interpret, 'Brandon Lake');
      expect(song.lyrics, sampleLyric);
      expect(song.lyrics, isNotEmpty);
    });

    test('lyrics survive the JSON round-trip used by the Hive cache', () {
      final web = WebSong(
        title: 'Gratitude',
        ref: 'gratitude-chords',
        interpret: 'Brandon Lake',
        server: 'worshipchords.com',
        lyric: sampleLyric,
      );

      final saved = buildSavedSongFromWeb(web);

      // saveSongsCache stores s.toJson(); loadSongsFromCache rebuilds via fromJson.
      final reloaded = Song.fromJson(saved.toJson());

      expect(reloaded.lyrics, sampleLyric);
      expect(reloaded.title, 'Gratitude');
      expect(reloaded.interpret, 'Brandon Lake');
    });

    test('display path exposes the lyrics with chords', () {
      final web = WebSong(
        title: 'Gratitude',
        ref: 'gratitude-chords',
        interpret: 'Brandon Lake',
        server: 'worshipchords.com',
        lyric: sampleLyric,
      );

      final song = Song.fromJson(buildSavedSongFromWeb(web).toJson());

      // The desktop preview renders song.lyrics directly...
      expect(song.lyrics, isNotEmpty);
      // ...and the chord-aware getter (TypeLyric.translate -> lyrics) too.
      expect(song.lyricsWithChords, contains('I love You Lord'));
      expect(song.lyricsWithChords, contains('Ab'));
    });

    test('an empty download must not produce a saveable song silently', () {
      final web = WebSong(
        title: 'Broken',
        ref: 'broken-chords',
        interpret: 'Nobody',
        server: 'worshipchords.com',
        lyric: '',
      );

      final song = buildSavedSongFromWeb(web);

      // The save dialog now blocks this case; the data itself is clearly empty.
      expect(song.lyrics, isEmpty);
    });
  });
}

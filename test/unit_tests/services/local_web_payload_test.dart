import 'package:song_viewer/model/note.dart';
import 'package:song_viewer/model/playlist.dart';
import 'package:song_viewer/model/song/song.dart';
import 'package:song_viewer/model/youtube_video.dart';
import 'package:song_viewer/services/enums.dart';
import 'package:song_viewer/services/local_web/local_web_payload.dart';
import 'package:flutter_test/flutter_test.dart';

Song _song({
  String id = 'song-1',
  String lyrics = '[C]Svatý, [G]svatý',
  List<Note>? notes,
}) {
  return Song(
    id: id,
    title: 'Svatý',
    lyrics: lyrics,
    interpret: 'Hillsong',
    indexSongBook: 12,
    groups: ['chvály', 'web'],
    tags: ['adorace'],
    sheets: ['https://example.com/noty.pdf'],
    notes: notes,
    youtubeVideos: [YoutubeVideo(name: 'Live', path: 'https://youtu.be/abc')],
  );
}

void main() {
  group('content', () {
    test('keeps chord markers — the page positions chords from them', () {
      expect(LocalWebPayload.content(_song()), '[C]Svatý, [G]svatý');
    });

    test('drops the app-only {} line notes', () {
      final song = _song(lyrics: '[C]Svatý{pomalu}, [G]svatý');

      expect(LocalWebPayload.content(song), '[C]Svatý, [G]svatý');
    });
  });

  group('songSummary', () {
    test('reports attachments as flags rather than shipping them', () {
      final summary = LocalWebPayload.songSummary(_song());

      expect(summary['hasSheets'], isTrue);
      expect(summary['hasVideos'], isTrue);
      expect(summary['id'], 'song-1');
      expect(summary['indexSongBook'], 12);
    });

    test('a song with no interpret serializes an empty string, not null', () {
      final song = Song(id: 'x', title: 'T', lyrics: '');

      expect(LocalWebPayload.songSummary(song)['interpret'], '');
      expect(LocalWebPayload.songSummary(song)['hasSheets'], isFalse);
    });
  });

  group('songDetail', () {
    test('maps the app notes onto the performance notes the page renders', () {
      final song = _song(notes: [
        const Note(index: 3, noteText: 'zpomalit'),
        const Note(index: 0, noteText: '   '),
      ]);

      final detail = LocalWebPayload.songDetail(song);

      expect(detail['performanceNotes'], [
        {'index': 3, 'noteText': 'zpomalit'},
      ]);
    });

    test('carries the song overrides and the notation flavour', () {
      final song = _song()
        ..chordOverrides = {
          'C': ['x 3 2 0 1 0'],
        };

      final detail = LocalWebPayload.songDetail(song);

      expect(detail['chordOverrides'], {
        'C': ['x 3 2 0 1 0'],
      });
      expect(detail['typeTranspose'], TypeTranspose.czech.name);
    });

    test('a song with no overrides serializes an empty map, not null', () {
      expect(LocalWebPayload.songDetail(_song())['chordOverrides'], isEmpty);
    });
  });

  group('chordLibrary', () {
    test('keeps only the names that actually resolve to a grip', () {
      final library = LocalWebPayload.chordLibrary(['C', 'Xdim'], (name, {song}) {
        return name == 'C' ? ['x 3 2 0 1 0'] : <String>[];
      });

      expect(library.keys, ['C']);
    });

    test('is keyed by chord name so a transposed lookup finds its own grip', () {
      final library = LocalWebPayload.chordLibrary(['C', 'D'], (name, {song}) {
        return name == 'C' ? ['x 3 2 0 1 0'] : ['x x 0 2 3 2'];
      });

      expect(library['D'], ['x x 0 2 3 2']);
    });
  });

  group('playlists', () {
    test('summary counts the songs without resolving them', () {
      final playlist = Playlist(id: 'p1', name: 'Nedělní chvály');
      playlist.listSongIds.addAll(['a', 'b', 'c']);

      expect(LocalWebPayload.playlistSummary(playlist), {
        'id': 'p1',
        'name': 'Nedělní chvály',
        'songCount': 3,
      });
    });

    test('detail carries the songs in playlist order', () {
      final playlist = Playlist(id: 'p1', name: 'Chvály');
      final detail = LocalWebPayload.playlistDetail(playlist, [_song(id: 'b'), _song(id: 'a')]);

      expect((detail['songs'] as List).map((s) => s['id']), ['b', 'a']);
    });
  });
}

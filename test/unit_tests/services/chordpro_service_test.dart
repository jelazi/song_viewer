import 'package:song_viewer/services/chordpro_service.dart';
import 'package:song_viewer/services/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = ChordProService(chorusLabel: 'R:', bridgeLabel: 'B:');

  group('ChordProService - metadata', () {
    test('maps title, artist, tempo and time signature', () {
      final result = service.parse('''
{title: Sample Song}
{artist: Sample Author}
{tempo: 96}
{time: 3/4}
[C]first line of placeholder text
''');

      expect(result.songs, hasLength(1));
      final song = result.songs.single;
      expect(song.title, 'Sample Song');
      expect(song.interpret, 'Sample Author');
      expect(song.bmp, 96);
      expect(song.songBar, 3);
    });

    test('an explicit artist outranks a subtitle', () {
      final result = service.parse('''
{title: Sample Song}
{subtitle: some subtitle}
{artist: Real Author}
[C]placeholder
''');

      expect(result.songs.single.interpret, 'Real Author');
    });

    test('a subtitle is used when no artist is given', () {
      final result = service.parse('{title: T}\n{st: Fallback Author}\n[C]placeholder');
      expect(result.songs.single.interpret, 'Fallback Author');
    });

    test('imported songs use international chord naming', () {
      final result = service.parse('{title: T}\n[A#]placeholder');

      // The model defaults to czech (B/H), where A# would be read as a
      // different pitch and transpose wrong.
      expect(result.songs.single.typeTranspose, TypeTranspose.german);
    });

    test('falls back to the file name when there is no title directive', () {
      final result = service.parse('[C]placeholder line', fallbackTitle: 'my_file');
      expect(result.songs.single.title, 'my_file');
    });

    test('every song gets an id', () {
      final result = service.parse('{title: A}\n[C]x\n{new_song}\n{title: B}\n[D]y');
      final ids = result.songs.map((s) => s.id).toSet();
      expect(ids, hasLength(2));
      expect(ids.any((id) => id.isEmpty), isFalse);
    });
  });

  group('ChordProService - lyrics conversion', () {
    test('inline chords pass through unchanged', () {
      final result = service.parse('{title: T}\n[C]one [G7]two [Am]three');
      expect(result.songs.single.lyrics, '[C]one [G7]two [Am]three');
    });

    test('no brace ever survives into the lyrics', () {
      final result = service.parse('''
{title: T}
{key: G}
{capo: 2}
[C]placeholder with a stray } brace and a { one
{comment: a note for the player}
''');

      final lyrics = result.songs.single.lyrics;
      expect(lyrics.contains('{'), isFalse, reason: 'a brace would be parsed as a note by SongLine');
      expect(lyrics.contains('}'), isFalse);
      expect(lyrics, contains('a note for the player'));
    });

    test('escaped brackets are dropped rather than left as markup', () {
      final result = service.parse(r'{title: T}\[not a chord\] plain [C]chord');
      final lyrics = result.songs.single.lyrics;
      expect(lyrics, contains('not a chord'));
      expect(lyrics, contains('[C]'));
      expect(RegExp(r'\[').allMatches(lyrics).length, 1);
    });

    test('unbalanced brackets are repaired and reported', () {
      final result = service.parse('{title: T}\n[C placeholder line');
      final lyrics = result.songs.single.lyrics;
      expect(lyrics, '[C placeholder line]');
      expect(result.warnings.any((w) => w.contains('unbalanced')), isTrue);
    });

    test('a nested opening bracket is dropped', () {
      final result = service.parse('{title: T}\n[C[G]placeholder');
      expect(result.songs.single.lyrics, '[CG]placeholder');
    });

    test('source comments starting with # are removed', () {
      final result = service.parse('{title: T}\n# this is a source comment\n[C]placeholder');
      expect(result.songs.single.lyrics, '[C]placeholder');
    });

    test('chorus and bridge get a label, plain verses do not', () {
      final result = service.parse('''
{title: T}
{sov}
[C]verse placeholder
{eov}
{soc}
[G]chorus placeholder
{eoc}
{sob}
[Am]bridge placeholder
{eob}
''');

      final lines = result.songs.single.lyrics.split('\n');
      expect(lines, contains('R:'));
      expect(lines, contains('B:'));
      expect(lines.first, '[C]verse placeholder');
    });

    test('a named section keeps its own label', () {
      final result = service.parse('{title: T}\n{start_of_chorus: Refrén 1}\n[C]placeholder\n{eoc}');
      expect(result.songs.single.lyrics.split('\n').first, 'Refrén 1');
    });

    test('tab blocks are kept verbatim', () {
      final result = service.parse('''
{title: T}
{sot}
e|--0--3--|
B|--1--0--|
{eot}
[C]placeholder
''');

      final lyrics = result.songs.single.lyrics;
      expect(lyrics, contains('e|--0--3--|'));
      expect(lyrics, contains('B|--1--0--|'));
    });

    test('runs of blank lines are collapsed', () {
      final result = service.parse('{title: T}\n[C]a\n\n\n\n[D]b');
      expect(result.songs.single.lyrics, '[C]a\n\n[D]b');
    });
  });

  group('ChordProService - multiple songs per file', () {
    test('splits on the new_song directive', () {
      final result = service.parse('''
{title: First}
[C]placeholder one
{new_song}
{title: Second}
[D]placeholder two
''');

      expect(result.songs.map((s) => s.title), ['First', 'Second']);
      expect(result.songs[1].lyrics, '[D]placeholder two');
    });

    test('splits on a repeated title even without new_song', () {
      final result = service.parse('''
{title: First}
[C]placeholder one

{title: Second}
[D]placeholder two
''');

      expect(result.songs.map((s) => s.title), ['First', 'Second']);
    });

    test('untitled songs are numbered from the file name', () {
      final result = service.parse('[C]one\n{new_song}\n[D]two', fallbackTitle: 'batch');
      expect(result.songs.map((s) => s.title), ['batch', 'batch (2)']);
    });

    test('a block with directives but no lyrics is skipped and counted', () {
      final result = service.parse('{title: Ghost}\n{key: C}\n{new_song}\n{title: Real}\n[C]placeholder');

      expect(result.songs.map((s) => s.title), ['Real']);
      expect(result.skipped, 1);
    });
  });

  group('ChordProService - warnings', () {
    test('chord definitions are reported, never guessed at', () {
      final result = service.parse('{title: T}\n{define: Am base-fret 1 frets 0 0 2 2 1 0}\n[Am]placeholder');

      expect(result.songs.single.chordOverrides, isEmpty);
      expect(result.warnings.any((w) => w.contains('chord definitions')), isTrue);
    });

    test('recognised but unstorable metadata is reported, not silently dropped', () {
      final result = service.parse('{title: T}\n{copyright: 2020 Someone}\n[C]placeholder');
      expect(result.warnings.any((w) => w.contains('copyright')), isTrue);
    });

    test('unknown directives are reported', () {
      final result = service.parse('{title: T}\n{totally_made_up: 1}\n[C]placeholder');
      expect(result.warnings.any((w) => w.contains('totally_made_up')), isTrue);
    });

    test('layout-only directives produce no noise', () {
      final result = service.parse('{title: T}\n{new_page}\n{columns: 2}\n{textsize: 12}\n[C]placeholder');
      expect(result.warnings, isEmpty);
    });

    test('x_ prefixed extensions are ignored silently, per the spec', () {
      final result = service.parse('{title: T}\n{x_myapp_thing: 1}\n[C]placeholder');
      expect(result.warnings, isEmpty);
    });
  });

  group('ChordProService - robustness', () {
    test('empty input yields no songs and does not throw', () {
      final result = service.parse('');
      expect(result.isEmpty, isTrue);
      expect(result.skipped, 0);
    });

    test('a file with no directives at all still imports', () {
      final result = service.parse('[C]just [G]chords and words', fallbackTitle: 'plain');
      expect(result.songs.single.title, 'plain');
    });

    test('windows and classic mac line endings are normalised', () {
      final result = service.parse('{title: T}\r\n[C]one\r[D]two');
      expect(result.songs.single.lyrics, '[C]one\n[D]two');
    });
  });
}

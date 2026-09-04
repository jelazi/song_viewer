import 'package:song_viewer/services/chord_notation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChordNotationService - detection', () {
    test('a plain B with no H anywhere reads as the international notation', () {
      expect(ChordNotationService.looksInternational('[G]Amazing [B]grace'), isTrue);
    });

    test('a single H settles it as Czech, even next to a B', () {
      expect(ChordNotationService.looksInternational('[H]Sun [B]shine [C]on'), isFalse);
    });

    test('flats alone are enough — the Czech cycle has no Eb', () {
      expect(ChordNotationService.looksInternational('[Eb]Yesterday [Ab]all'), isTrue);
    });

    test('a song that is already Czech is left alone', () {
      expect(ChordNotationService.looksInternational('[C]Ma [D#]la [A]dy'), isFalse);
    });

    test('section markers are not chords', () {
      expect(ChordNotationService.looksInternational('[Bridge]\n[Chorus]\n[Coda]'), isFalse);
    });

    test('lyrics with no chords at all', () {
      expect(ChordNotationService.looksInternational('just a line of text'), isFalse);
    });
  });

  group('ChordNotationService - conversion', () {
    test('B becomes H and Bb becomes B', () {
      expect(ChordNotationService.toCzech('[B]one [Bb]two'), '[H]one [B]two');
    });

    test('the chord quality is kept', () {
      expect(ChordNotationService.toCzech('[Bm]a [Bbmaj7]b [Bsus4]c'), '[Hm]a [Bmaj7]b [Hsus4]c');
    });

    test('flats are respelled as the sharps the transposer knows', () {
      expect(ChordNotationService.toCzech('[Db][Eb][Gb][Ab][A#]'), '[C#][D#][F#][G#][B]');
    });

    test('bass notes are converted too', () {
      expect(ChordNotationService.toCzech('[Bb/D]x[G/B]'), '[B/D]x[G/H]');
    });

    test('section markers and lyrics survive untouched', () {
      expect(
        ChordNotationService.toCzech('[Bridge]\n[B]Be [C]still, my [Bb]soul'),
        '[Bridge]\n[H]Be [C]still, my [B]soul',
      );
    });

    test('chords already in the Czech spelling do not move', () {
      expect(ChordNotationService.toCzech('[C][D][Emi][F#][G7][A][H]'), '[C][D][Emi][F#][G7][A][H]');
    });

    test('converting twice changes nothing more', () {
      const lyrics = '[B]a [Bb]b [Eb]c';
      final once = ChordNotationService.toCzech(lyrics);
      expect(once, '[H]a [B]b [D#]c');
      expect(ChordNotationService.toCzech(once), once);
    });

    test('a song without a B keeps its H-free result stable', () {
      final once = ChordNotationService.toCzech('[Eb]a [Ab]b');
      expect(once, '[D#]a [G#]b');
      expect(ChordNotationService.toCzech(once), once);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:song_viewer/services/song_key_service.dart';

void main() {
  group('SongKeyService.displayedKey', () {
    test('takes the root of the first chord', () {
      expect(SongKeyService.displayedKey('[G]Amazing [C]grace [D]how sweet'), 7);
    });

    test('ignores section markers before the first chord', () {
      expect(SongKeyService.displayedKey('[Verse 1]\n[Bridge]\n[Ami]text [F]more'), 9);
    });

    test('reads Czech B as B flat and H as B', () {
      expect(SongKeyService.displayedKey('[B]text [F]text [H]x'), 10);
      expect(SongKeyService.displayedKey('[H]text [E]text'), 11);
    });

    test('converts international notation first', () {
      expect(SongKeyService.displayedKey('[Bb]text [Eb]text [F]text'), 10);
      expect(SongKeyService.displayedKey('[B]text [E]text [F#]text'), 11);
    });

    test('applies the transposition and wraps around', () {
      expect(SongKeyService.displayedKey('[A]text', transposeIncrement: 2), 11);
      expect(SongKeyService.displayedKey('[C]text', transposeIncrement: -1), 11);
      expect(SongKeyService.displayedKey('[H]text', transposeIncrement: 1), 0);
    });

    test('returns null without chords', () {
      expect(SongKeyService.displayedKey('just lyrics\n[Chorus]\nmore'), isNull);
    });
  });

  group('SongKeyService.soundingKey', () {
    test('adds the capo to the shown first chord', () {
      // Original A, transposed down 3 to F# shapes, capo 3: it still sounds in A.
      expect(SongKeyService.soundingKey('[A]text', transposeIncrement: -3, capo: 3), 9);
      expect(SongKeyService.displayedKey('[A]text', transposeIncrement: -3), 6);
    });

    test('without a capo it is the shown key', () {
      expect(SongKeyService.soundingKey('[G]text'), 7);
      expect(SongKeyService.soundingKey('[H]text', capo: 2), 1);
    });

    test('returns null without chords', () {
      expect(SongKeyService.soundingKey('no chords', capo: 3), isNull);
    });
  });
}

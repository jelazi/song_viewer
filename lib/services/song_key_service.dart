import 'chord_notation_service.dart';

/// Guesses the key a song is played in, for suggesting a worship pad.
///
/// Worship songs almost always start on the tonic, so the root of the first
/// chord is taken; the user can pick any other key in the pad window.
class SongKeyService {
  SongKeyService._();

  /// Key names in the app's Czech notation, indexed by semitone (0 = C).
  static const List<String> keyNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'B', 'H'];

  static final RegExp _bracket = RegExp(r'\[([^\]]*)\]');
  static final RegExp _root = RegExp(r'^[A-H]#?');

  /// Semitone of the first chord in [lyrics] as it is shown: shifted by the
  /// song's current transposition. Null when the lyrics hold no chord.
  static int? displayedKey(String lyrics, {int transposeIncrement = 0}) {
    final czech = ChordNotationService.toCzech(lyrics);
    for (final match in _bracket.allMatches(czech)) {
      final chord = match.group(1)!.trim();
      if (!ChordNotationService.isChord(chord)) continue;
      final root = _root.stringMatch(chord);
      final semitone = root == null ? -1 : keyNames.indexOf(root);
      if (semitone < 0) continue;
      return (semitone + transposeIncrement) % 12;
    }
    return null;
  }

  /// The key that actually sounds: the shown first chord played with the
  /// capo on fret [capo]. This is what the pad has to match.
  static int? soundingKey(String lyrics, {int transposeIncrement = 0, int capo = 0}) {
    final shown = displayedKey(lyrics, transposeIncrement: transposeIncrement);
    return shown == null ? null : (shown + capo) % 12;
  }
}

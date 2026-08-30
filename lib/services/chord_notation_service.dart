/// Rewrites chord roots from the international notation most foreign songbooks
/// use into the Czech one this app reads and transposes in.
///
/// The two differ in the eleventh and twelfth degree and in how the black keys
/// are spelled:
///
/// | international | Czech |
/// |---------------|-------|
/// | `Bb`, `A#`    | `B`   |
/// | `B`           | `H`   |
/// | `Db`,`Eb`,`Gb`,`Ab` | `C#`,`D#`,`F#`,`G#` |
///
/// The flats matter beyond looks: `ChordProcessor.transposeChord` walks the
/// cycle `C C# D D# E F F# G G# A B H`, so a chord spelled `Eb` or `Bb` is not
/// found there and silently refuses to transpose.
class ChordNotationService {
  ChordNotationService._();

  /// Everything between square brackets — the app's inline chord markup.
  static final RegExp _bracket = RegExp(r'\[([^\]]*)\]');

  /// Root note at the start of a chord, accidental included.
  static final RegExp _root = RegExp(r'^[A-H][#b]?');

  /// Czech spelling of every root either notation can produce. Roots that are
  /// already Czech map to themselves, so a lookup that returns the input is
  /// proof that nothing needs changing.
  static const Map<String, String> _czechRoot = {
    'C': 'C', 'C#': 'C#', 'Cb': 'H',
    'D': 'D', 'D#': 'D#', 'Db': 'C#',
    'E': 'E', 'E#': 'F', 'Eb': 'D#',
    'F': 'F', 'F#': 'F#', 'Fb': 'E',
    'G': 'G', 'G#': 'G#', 'Gb': 'F#',
    'A': 'A', 'A#': 'B', 'Ab': 'G#',
    'B': 'H', 'B#': 'C', 'Bb': 'B',
    'H': 'H', 'H#': 'C', 'Hb': 'B',
  };

  /// Pieces a chord suffix may be built from, longest first so that `maj` is
  /// consumed before `m`. Anything else means the bracket holds a section
  /// marker (`[Bridge]`, `[Chorus]`) rather than a chord.
  static const List<String> _suffixParts = [
    'maj', 'Maj', 'min', 'mi', 'dim', 'aug', 'sus', 'add', 'alt', 'no',
    'm', 'M', 'b', '#', '+', '-', '(', ')', '°', 'ø', 'Δ', '^', '*',
    '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  ];

  /// True when the lyrics look like they use the international notation, i.e.
  /// they hold at least one root that the Czech spelling writes differently.
  ///
  /// A single `H` anywhere settles it the other way: the international notation
  /// has no such note, so the song is already Czech and `B` in it means B flat.
  static bool looksInternational(String lyrics) {
    var needsChange = false;
    for (final match in _bracket.allMatches(lyrics)) {
      for (final root in _rootsOf(match.group(1) ?? '')) {
        if (root.startsWith('H')) return false;
        if (_czechRoot[root] != root) needsChange = true;
      }
    }
    return needsChange;
  }

  /// Rewrites every chord in [lyrics] into the Czech notation, leaving the
  /// lyrics themselves and any section marker untouched.
  ///
  /// Text that is already Czech is returned unchanged — the mapping is not
  /// idempotent on its own (`B` means B flat here but B natural there, so a
  /// second pass would turn it into `H`), so the guard is what makes running
  /// this twice safe.
  static String toCzech(String lyrics) {
    if (!looksInternational(lyrics)) return lyrics;
    return lyrics.replaceAllMapped(_bracket, (match) {
      final inner = match.group(1) ?? '';
      final converted = convertChord(inner);
      return '[$converted]';
    });
  }

  /// Rewrites one chord, its bass note included: `Bb/D` becomes `B/D`.
  ///
  /// Returns the input unchanged when it is not a chord.
  static String convertChord(String chord) {
    if (!_isChord(chord)) return chord;
    return chord.split('/').map(_convertPart).join('/');
  }

  static String _convertPart(String part) {
    final root = _root.stringMatch(part);
    if (root == null) return part;
    final czech = _czechRoot[root];
    if (czech == null) return part;
    return czech + part.substring(root.length);
  }

  /// Roots of a chord, bass note included; empty when it is not a chord.
  static Iterable<String> _rootsOf(String chord) {
    if (!_isChord(chord)) return const [];
    return chord.split('/').map((part) => _root.stringMatch(part)).whereType<String>();
  }

  /// Whether the bracket content is a chord rather than a section marker.
  ///
  /// Every slash-separated part has to be a known root followed by a suffix
  /// built only from [_suffixParts]; `[Bridge]` fails on `ridge`, `[Bb/D]`
  /// passes.
  static bool _isChord(String text) {
    if (text.isEmpty) return false;
    for (final part in text.split('/')) {
      final root = _root.stringMatch(part);
      if (root == null || !_czechRoot.containsKey(root)) return false;
      if (!_isSuffix(part.substring(root.length))) return false;
    }
    return true;
  }

  static bool _isSuffix(String suffix) {
    var index = 0;
    while (index < suffix.length) {
      final part = _suffixParts.firstWhere((p) => suffix.startsWith(p, index), orElse: () => '');
      if (part.isEmpty) return false;
      index += part.length;
    }
    return true;
  }
}

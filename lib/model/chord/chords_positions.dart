import 'guitar_chord_pattern.dart';

class ChordsPositions {
  static final _listPatterns = [
    GuitarChordPattern(
      tags: ['', 'dur', 'Dur'],
      names: ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'B', 'H'],
      basePositionString: '0 3 2 0 1 0',
    ),
    GuitarChordPattern(
      tags: ['', 'dur', 'Dur'],
      names: ['E', 'F', 'F#', 'G', 'G#', 'A', 'B', 'H', 'C', 'C#', 'D', 'D#'],
      basePositionString: '0 2 2 1 0 0',
    ),
    GuitarChordPattern(
      tags: ['', 'dur', 'Dur'],
      names: ['D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'B', 'H', 'C', 'C#'],
      basePositionString: 'x x 0 2 3 2',
    ),
    GuitarChordPattern(
      tags: ['', 'dur', 'Dur'],
      names: ['A', 'B', 'H', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'],
      basePositionString: 'x 0 2 2 2 0',
    ),
    GuitarChordPattern(
      tags: ['', 'dur', 'Dur'],
      names: ['G'],
      basePositionString: '3 2 0 0 0 3',
    ),
    GuitarChordPattern(
      tags: ['', 'dur', 'Dur'],
      names: ['G'],
      basePositionString: '3 2 0 0 3 3',
    ),
    GuitarChordPattern(
      tags: ['', 'dur', 'Dur'],
      names: ['C'],
      basePositionString: 'x 3 2 0 3 3',
    ),
    GuitarChordPattern(
      tags: ['', 'dur', 'Dur'],
      names: ['D'],
      basePositionString: '2 0 0 2 3 3',
    ),
    GuitarChordPattern(
      tags: ['m', 'mi', 'mol'],
      names: ['A', 'B', 'H', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'],
      basePositionString: 'x 0 2 2 1 0',
    ),
    GuitarChordPattern(
      tags: ['m', 'mi', 'mol'],
      names: ['E', 'F', 'F#', 'G', 'G#', 'A', 'B', 'H', 'C', 'C#', 'D', 'D#'],
      basePositionString: '0 2 2 0 0 0',
    ),
    GuitarChordPattern(
      tags: ['m', 'mi', 'mol'],
      names: ['D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'B', 'H', 'C', 'C#'],
      basePositionString: 'x x 0 2 3 1',
    ),
    GuitarChordPattern(
      tags: ['m7', 'mi7'],
      names: ['A', 'B', 'H', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'],
      basePositionString: 'x 0 2 0 1 3',
    ),
    GuitarChordPattern(
      tags: ['m7', 'mi7'],
      names: ['A'],
      basePositionString: 'x 0 2 2 1 3',
    ),
    GuitarChordPattern(
      tags: ['maj7'],
      names: ['A', 'B', 'H', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'],
      basePositionString: 'x 0 2 1 2 0',
    ),
    GuitarChordPattern(
      tags: ['maj7'],
      names: ['A', 'B', 'H', 'C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#'],
      basePositionString: 'x 0 2 2 2 4',
    ),
    GuitarChordPattern(
      tags: ['maj7'],
      names: ['F', 'F#', 'G', 'G#', 'A', 'B', 'H', 'C', 'C#', 'D', 'D#', 'E'],
      basePositionString: 'x x 3 2 1 0',
    ),
    GuitarChordPattern(
      tags: ['maj7'],
      names: ['C'],
      basePositionString: '3 3 2 0 0 0',
    ),
    GuitarChordPattern(
      tags: ['7'],
      names: ['H'],
      basePositionString: 'x 2 1 2 0 2',
    ),
    GuitarChordPattern(
      tags: ['7'],
      names: ['D'],
      basePositionString: 'x x 0 2 1 2',
    ),
    GuitarChordPattern(
      tags: ['6'],
      names: ['D'],
      basePositionString: 'x x 0 2 0 2',
    ),
    GuitarChordPattern(
      tags: ['maj7'],
      names: ['D'],
      basePositionString: 'x x 0 2 2 2',
    ),
    GuitarChordPattern(
      tags: ['sus', 'sus2'],
      names: ['A'],
      basePositionString: 'x 0 2 2 3 0',
    ),
    GuitarChordPattern(
      tags: ['sus', 'sus4', 'sus2'],
      names: ['C'],
      basePositionString: 'x 3 2 0 3 3',
    ),
    GuitarChordPattern(
      tags: ['4', 'sus4'],
      names: ['E', 'F', 'F#', 'G', 'G#', 'A', 'B'],
      basePositionString: '0 2 2 2 0 0',
    ),
    GuitarChordPattern(
      tags: ['sus4', 'sus2', '4'],
      names: ['D'],
      basePositionString: 'x x 0 2 3 3',
    ),
    GuitarChordPattern(
      tags: ['m7', 'mi7'],
      names: ['E', 'F', 'F#', 'G', 'G#'],
      basePositionString: '0 2 2 0 3 0',
    ),
  ];

  /// Returns all unique chord names available in the hardcoded patterns.
  static List<String> getAllChordNames() {
    final Set<String> names = {};
    for (final pattern in _listPatterns) {
      for (final tag in pattern.tags) {
        for (final name in pattern.names) {
          names.add(name + tag);
        }
      }
    }
    return names.toList()..sort();
  }

  static List<String> getPositionsChordsByName(String name) {
    List<String> positionChord = [];
    for (GuitarChordPattern pattern in _listPatterns) {
      if (pattern.containsFullName(name)) {
        positionChord.add(pattern.getPositionByName(name));
      }
    }
    positionChord = _sortPositionChords(positionChord);
    return positionChord;
  }

  static List<String> _sortPositionChords(List<String> unsortedList) {
    unsortedList.sort((a, b) => _getSumPositions(a).compareTo(_getSumPositions(b)));
    return unsortedList;
  }

  static int _getSumPositions(String positions) {
    List<String> posits = positions.split(' ');
    int sum = 0;
    for (String pos in posits) {
      int val = int.tryParse(pos) ?? -1;
      if (val != -1) sum += val;
    }
    return sum;
  }
}

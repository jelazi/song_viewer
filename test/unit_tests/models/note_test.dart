import 'package:default_project/model/note.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Note Model Tests', () {
    test('should create Note with index and noteText', () {
      // Arrange & Act
      final note = Note(index: 5, noteText: 'This is a test note');

      // Assert
      expect(note.index, 5);
      expect(note.noteText, 'This is a test note');
    });

    test('should create Note with zero index', () {
      // Arrange & Act
      final note = Note(index: 0, noteText: 'First line note');

      // Assert
      expect(note.index, 0);
      expect(note.noteText, 'First line note');
    });

    test('should create Note with empty text', () {
      // Arrange & Act
      final note = Note(index: 10, noteText: '');

      // Assert
      expect(note.index, 10);
      expect(note.noteText, '');
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final note = Note(index: 3, noteText: 'Test note text');

      // Act
      final json = note.toJson();

      // Assert
      expect(json['index'], 3);
      expect(json['noteText'], 'Test note text');
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'index': 7,
        'noteText': 'Deserialized note',
      };

      // Act
      final note = Note.fromJson(json);

      // Assert
      expect(note.index, 7);
      expect(note.noteText, 'Deserialized note');
    });

    test('should handle JSON round-trip', () {
      // Arrange
      final originalNote = Note(index: 15, noteText: 'Round trip note');

      // Act
      final json = originalNote.toJson();
      final deserializedNote = Note.fromJson(json);

      // Assert
      expect(deserializedNote.index, originalNote.index);
      expect(deserializedNote.noteText, originalNote.noteText);
    });

    test('should handle note with special characters', () {
      // Arrange
      final note = Note(index: 2, noteText: 'Special chars: @#\$%^&*()');

      // Act
      final json = note.toJson();
      final deserializedNote = Note.fromJson(json);

      // Assert
      expect(deserializedNote.noteText, 'Special chars: @#\$%^&*()');
    });

    test('should handle note with multiline text', () {
      // Arrange
      final note = Note(index: 4, noteText: 'Line 1\nLine 2\nLine 3');

      // Act
      final json = note.toJson();
      final deserializedNote = Note.fromJson(json);

      // Assert
      expect(deserializedNote.noteText, 'Line 1\nLine 2\nLine 3');
    });

    test('should handle large index values', () {
      // Arrange
      final note = Note(index: 999999, noteText: 'Large index note');

      // Act
      final json = note.toJson();
      final deserializedNote = Note.fromJson(json);

      // Assert
      expect(deserializedNote.index, 999999);
    });

    test('should handle note with unicode characters', () {
      // Arrange
      final note = Note(index: 1, noteText: 'Unicode: 你好 мир 🎵🎸');

      // Act
      final json = note.toJson();
      final deserializedNote = Note.fromJson(json);

      // Assert
      expect(deserializedNote.noteText, 'Unicode: 你好 мир 🎵🎸');
    });
  });

  group('Note Empty Constructor Tests', () {
    test('should create empty Note', () {
      // Arrange & Act
      const note = Note.empty();

      // Assert
      expect(note.index, 0);
      expect(note.noteText, '');
      expect(note.isEmpty, true);
    });
  });

  group('Note copyWith Tests', () {
    test('should create copy with updated index', () {
      // Arrange
      const original = Note(index: 1, noteText: 'Original text');

      // Act
      final copy = original.copyWith(index: 5);

      // Assert
      expect(copy.index, 5);
      expect(copy.noteText, 'Original text');
      expect(original.index, 1); // Original unchanged
    });

    test('should create copy with updated noteText', () {
      // Arrange
      const original = Note(index: 1, noteText: 'Original text');

      // Act
      final copy = original.copyWith(noteText: 'Updated text');

      // Assert
      expect(copy.index, 1);
      expect(copy.noteText, 'Updated text');
      expect(original.noteText, 'Original text'); // Original unchanged
    });

    test('should create copy with all fields updated', () {
      // Arrange
      const original = Note(index: 1, noteText: 'Original text');

      // Act
      final copy = original.copyWith(index: 10, noteText: 'Completely new');

      // Assert
      expect(copy.index, 10);
      expect(copy.noteText, 'Completely new');
    });

    test('should create identical copy when no parameters provided', () {
      // Arrange
      const original = Note(index: 3, noteText: 'Same text');

      // Act
      final copy = original.copyWith();

      // Assert
      expect(copy.index, original.index);
      expect(copy.noteText, original.noteText);
    });
  });

  group('Note Helper Methods Tests', () {
    test('isEmpty should return true for empty text', () {
      // Arrange
      const note = Note(index: 0, noteText: '');

      // Assert
      expect(note.isEmpty, true);
    });

    test('isEmpty should return true for whitespace-only text', () {
      // Arrange
      const note = Note(index: 0, noteText: '   \n  \t  ');

      // Assert
      expect(note.isEmpty, true);
    });

    test('isEmpty should return false for non-empty text', () {
      // Arrange
      const note = Note(index: 0, noteText: 'Some text');

      // Assert
      expect(note.isEmpty, false);
    });

    test('isNotEmpty should return false for empty text', () {
      // Arrange
      const note = Note(index: 0, noteText: '');

      // Assert
      expect(note.isNotEmpty, false);
    });

    test('isNotEmpty should return true for non-empty text', () {
      // Arrange
      const note = Note(index: 0, noteText: 'Some text');

      // Assert
      expect(note.isNotEmpty, true);
    });

    test('trimmedText should remove leading and trailing whitespace', () {
      // Arrange
      const note = Note(index: 0, noteText: '  Test text  \n');

      // Assert
      expect(note.trimmedText, 'Test text');
    });

    test('length should return correct text length', () {
      // Arrange
      const note = Note(index: 0, noteText: 'Hello');

      // Assert
      expect(note.length, 5);
    });

    test('isValid should return true for valid note', () {
      // Arrange
      const note = Note(index: 5, noteText: 'Valid note');

      // Assert
      expect(note.isValid, true);
    });

    test('isValid should return false for empty text', () {
      // Arrange
      const note = Note(index: 5, noteText: '');

      // Assert
      expect(note.isValid, false);
    });

    test('isValid should return false for negative index', () {
      // Arrange
      const note = Note(index: -1, noteText: 'Text');

      // Assert
      expect(note.isValid, false);
    });
  });

  group('Note Equality Tests', () {
    test('should be equal when index and noteText are the same', () {
      // Arrange
      const note1 = Note(index: 1, noteText: 'Same text');
      const note2 = Note(index: 1, noteText: 'Same text');

      // Assert
      expect(note1, equals(note2));
      expect(note1 == note2, true);
    });

    test('should not be equal when index differs', () {
      // Arrange
      const note1 = Note(index: 1, noteText: 'Same text');
      const note2 = Note(index: 2, noteText: 'Same text');

      // Assert
      expect(note1, isNot(equals(note2)));
      expect(note1 == note2, false);
    });

    test('should not be equal when noteText differs', () {
      // Arrange
      const note1 = Note(index: 1, noteText: 'Text 1');
      const note2 = Note(index: 1, noteText: 'Text 2');

      // Assert
      expect(note1, isNot(equals(note2)));
      expect(note1 == note2, false);
    });

    test('should have same hashCode for equal notes', () {
      // Arrange
      const note1 = Note(index: 1, noteText: 'Same text');
      const note2 = Note(index: 1, noteText: 'Same text');

      // Assert
      expect(note1.hashCode, equals(note2.hashCode));
    });

    test('should be identical when referencing same object', () {
      // Arrange
      const note = Note(index: 1, noteText: 'Text');

      // Assert
      expect(identical(note, note), true);
      expect(note == note, true);
    });
  });

  group('Note toString Tests', () {
    test('should return formatted string representation', () {
      // Arrange
      const note = Note(index: 5, noteText: 'Test note');

      // Act
      final result = note.toString();

      // Assert
      expect(result, 'Note(index: 5, noteText: Test note)');
    });

    test('should handle empty text in toString', () {
      // Arrange
      const note = Note(index: 0, noteText: '');

      // Act
      final result = note.toString();

      // Assert
      expect(result, 'Note(index: 0, noteText: )');
    });

    test('should handle special characters in toString', () {
      // Arrange
      const note = Note(index: 1, noteText: 'Test\nwith\ttabs');

      // Act
      final result = note.toString();

      // Assert
      expect(result, contains('Test\nwith\ttabs'));
    });
  });

  group('Note Boundary Tests', () {
    test('should handle zero index boundary', () {
      // Arrange & Act
      const note = Note(index: 0, noteText: 'Zero index');

      // Assert
      expect(note.index, 0);
      expect(note.isValid, true);
    });

    test('should handle negative index', () {
      // Arrange & Act
      const note = Note(index: -1, noteText: 'Negative');

      // Assert
      expect(note.index, -1);
      expect(note.isValid, false);
    });

    test('should handle very large index', () {
      // Arrange & Act
      const note = Note(index: 2147483647, noteText: 'Max int'); // Max 32-bit int

      // Assert
      expect(note.index, 2147483647);
      expect(note.isValid, true);
    });

    test('should handle very long text', () {
      // Arrange
      final longText = 'A' * 10000;
      final note = Note(index: 0, noteText: longText);

      // Assert
      expect(note.length, 10000);
      expect(note.noteText.length, 10000);
    });

    test('should handle empty string for length', () {
      // Arrange
      const note = Note(index: 0, noteText: '');

      // Assert
      expect(note.length, 0);
    });
  });

  group('Note Immutability Tests', () {
    test('should create new instance with copyWith', () {
      // Arrange
      const original = Note(index: 1, noteText: 'Original');

      // Act
      final modified = original.copyWith(noteText: 'Modified');

      // Assert
      expect(identical(original, modified), false);
      expect(original.noteText, 'Original');
      expect(modified.noteText, 'Modified');
    });

    test('should be const constructible', () {
      // Arrange & Act
      const note1 = Note(index: 1, noteText: 'Test');
      const note2 = Note(index: 1, noteText: 'Test');

      // Assert - const instances should be identical
      expect(identical(note1, note2), true);
    });

    test('empty constructor should be const', () {
      // Arrange & Act
      const note1 = Note.empty();
      const note2 = Note.empty();

      // Assert
      expect(identical(note1, note2), true);
    });
  });

  group('Note Collection Usage Tests', () {
    test('should work correctly in Set', () {
      // Arrange
      final note1 = Note(index: 1, noteText: 'Test');
      final note2 = Note(index: 1, noteText: 'Test');
      final note3 = Note(index: 2, noteText: 'Other');

      // Act
      final noteSet = {note1, note2, note3};

      // Assert - note1 and note2 should be treated as same
      expect(noteSet.length, 2);
      expect(noteSet.contains(note1), true);
      expect(noteSet.contains(note3), true);
    });

    test('should work correctly in List', () {
      // Arrange
      const notes = [
        Note(index: 0, noteText: 'First'),
        Note(index: 1, noteText: 'Second'),
        Note(index: 2, noteText: 'Third'),
      ];

      // Assert
      expect(notes.length, 3);
      expect(notes[0].index, 0);
      expect(notes[1].index, 1);
      expect(notes[2].index, 2);
    });

    test('should work correctly as Map key', () {
      // Arrange
      const note1 = Note(index: 1, noteText: 'Key1');
      const note2 = Note(index: 2, noteText: 'Key2');

      final noteMap = <Note, String>{
        note1: 'Value1',
        note2: 'Value2',
      };

      // Assert
      expect(noteMap[note1], 'Value1');
      expect(noteMap[note2], 'Value2');
      expect(noteMap.length, 2);
    });

    test('should be sortable in List', () {
      // Arrange
      const notes = [
        Note(index: 5, noteText: 'Fifth'),
        Note(index: 1, noteText: 'First'),
        Note(index: 3, noteText: 'Third'),
      ];

      // Act
      final sorted = List<Note>.from(notes)..sort((a, b) => a.index.compareTo(b.index));

      // Assert
      expect(sorted[0].index, 1);
      expect(sorted[1].index, 3);
      expect(sorted[2].index, 5);
    });

    test('should filter correctly', () {
      // Arrange
      const notes = [
        Note(index: 0, noteText: 'Valid'),
        Note(index: 1, noteText: ''),
        Note(index: -1, noteText: 'Invalid index'),
        Note(index: 2, noteText: 'Also valid'),
      ];

      // Act
      final validNotes = notes.where((note) => note.isValid).toList();

      // Assert
      expect(validNotes.length, 2);
      expect(validNotes[0].noteText, 'Valid');
      expect(validNotes[1].noteText, 'Also valid');
    });
  });

  group('Note trimmedText Edge Cases', () {
    test('should handle only spaces', () {
      // Arrange
      const note = Note(index: 0, noteText: '     ');

      // Assert
      expect(note.trimmedText, '');
      expect(note.isEmpty, true);
    });

    test('should handle only tabs', () {
      // Arrange
      const note = Note(index: 0, noteText: '\t\t\t');

      // Assert
      expect(note.trimmedText, '');
      expect(note.isEmpty, true);
    });

    test('should handle only newlines', () {
      // Arrange
      const note = Note(index: 0, noteText: '\n\n\n');

      // Assert
      expect(note.trimmedText, '');
      expect(note.isEmpty, true);
    });

    test('should handle mixed whitespace', () {
      // Arrange
      const note = Note(index: 0, noteText: '  \t\n  \r  ');

      // Assert
      expect(note.trimmedText, '');
      expect(note.isEmpty, true);
    });

    test('should preserve internal whitespace', () {
      // Arrange
      const note = Note(index: 0, noteText: '  Hello  World  ');

      // Assert
      expect(note.trimmedText, 'Hello  World');
    });

    test('should handle text with only internal whitespace', () {
      // Arrange
      const note = Note(index: 0, noteText: 'No leading or trailing');

      // Assert
      expect(note.trimmedText, 'No leading or trailing');
    });
  });

  group('Note isValid Complex Cases', () {
    test('should be invalid with negative index and empty text', () {
      // Arrange
      const note = Note(index: -1, noteText: '');

      // Assert
      expect(note.isValid, false);
    });

    test('should be invalid with zero index and empty text', () {
      // Arrange
      const note = Note(index: 0, noteText: '');

      // Assert
      expect(note.isValid, false);
    });

    test('should be invalid with positive index and empty text', () {
      // Arrange
      const note = Note(index: 10, noteText: '');

      // Assert
      expect(note.isValid, false);
    });

    test('should be invalid with negative index and whitespace-only text', () {
      // Arrange
      const note = Note(index: -1, noteText: '   ');

      // Assert
      expect(note.isValid, false);
    });

    test('should be valid with zero index and non-empty text', () {
      // Arrange
      const note = Note(index: 0, noteText: 'Valid');

      // Assert
      expect(note.isValid, true);
    });

    test('should consider whitespace-only text as invalid for isValid', () {
      // Arrange
      const note = Note(index: 5, noteText: '   ');

      // Assert
      expect(note.isValid, true); // Because noteText.isNotEmpty is true
      expect(note.isEmpty, true); // But trimmed version is empty
    });
  });

  group('Note JSON Edge Cases', () {
    test('should handle JSON with numeric index as double', () {
      // Arrange
      final json = {
        'index': 5.0,
        'noteText': 'Double index',
      };

      // Act
      final note = Note.fromJson(json);

      // Assert
      expect(note.index, 5);
    });

    test('should serialize and deserialize negative index', () {
      // Arrange
      const note = Note(index: -5, noteText: 'Negative');

      // Act
      final json = note.toJson();
      final deserialized = Note.fromJson(json);

      // Assert
      expect(deserialized.index, -5);
      expect(deserialized.noteText, 'Negative');
    });

    test('should handle JSON with very long text', () {
      // Arrange
      final longText = 'Lorem ipsum ' * 1000;
      final note = Note(index: 0, noteText: longText);

      // Act
      final json = note.toJson();
      final deserialized = Note.fromJson(json);

      // Assert
      expect(deserialized.noteText, longText);
      expect(deserialized.noteText.length, longText.length);
    });
  });

  group('Note copyWith Edge Cases', () {
    test('should handle copyWith with null-like behavior', () {
      // Arrange
      const original = Note(index: 5, noteText: 'Original');

      // Act
      final copy1 = original.copyWith(index: 0);
      final copy2 = original.copyWith(noteText: '');

      // Assert
      expect(copy1.index, 0);
      expect(copy1.noteText, 'Original');
      expect(copy2.index, 5);
      expect(copy2.noteText, '');
    });

    test('should allow copying from invalid to valid state', () {
      // Arrange
      const invalid = Note(index: -1, noteText: '');

      // Act
      final valid = invalid.copyWith(index: 0, noteText: 'Now valid');

      // Assert
      expect(invalid.isValid, false);
      expect(valid.isValid, true);
    });

    test('should allow copying from valid to invalid state', () {
      // Arrange
      const valid = Note(index: 5, noteText: 'Valid');

      // Act
      final invalid = valid.copyWith(index: -1, noteText: '');

      // Assert
      expect(valid.isValid, true);
      expect(invalid.isValid, false);
    });
  });
}

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
}

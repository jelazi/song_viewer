import 'package:song_viewer/model/song/song_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongItem Model Tests', () {
    test('should create SongItem with text and type', () {
      // Arrange & Act
      final songItem = SongItem('Test text', TypeSongItem.lyric);

      // Assert
      expect(songItem.text, 'Test text');
      expect(songItem.type, TypeSongItem.lyric);
      expect(songItem.index, 0); // default value
    });

    test('should create SongItem with chord type', () {
      // Arrange & Act
      final songItem = SongItem('C', TypeSongItem.chord);

      // Assert
      expect(songItem.text, 'C');
      expect(songItem.type, TypeSongItem.chord);
    });

    test('should create SongItem with note type', () {
      // Arrange & Act
      final songItem = SongItem('Test note', TypeSongItem.note);

      // Assert
      expect(songItem.text, 'Test note');
      expect(songItem.type, TypeSongItem.note);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final songItem = SongItem('Am', TypeSongItem.chord)..index = 5;

      // Act
      final json = songItem.toJson();

      // Assert
      expect(json['text'], 'Am');
      expect(json['type'], 'chord');
      expect(json['index'], 5);
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'text': 'G7',
        'type': 'chord',
        'index': 3,
      };

      // Act
      final songItem = SongItem.fromJson(json);

      // Assert
      expect(songItem.text, 'G7');
      expect(songItem.type, TypeSongItem.chord);
      expect(songItem.index, 3);
    });

    test('should handle JSON round-trip', () {
      // Arrange
      final originalItem = SongItem('Dm', TypeSongItem.chord)..index = 7;

      // Act
      final json = originalItem.toJson();
      final deserializedItem = SongItem.fromJson(json);

      // Assert
      expect(deserializedItem.text, originalItem.text);
      expect(deserializedItem.type, originalItem.type);
      expect(deserializedItem.index, originalItem.index);
    });

    test('should correctly identify same items', () {
      // Arrange
      final item1 = SongItem('C', TypeSongItem.chord)..index = 1;
      final item2 = SongItem('C', TypeSongItem.chord)..index = 1;

      // Act
      final result = item1.isSame(item2);

      // Assert
      expect(result, true);
    });

    test('should correctly identify different items with different text', () {
      // Arrange
      final item1 = SongItem('C', TypeSongItem.chord)..index = 1;
      final item2 = SongItem('D', TypeSongItem.chord)..index = 1;

      // Act
      final result = item1.isSame(item2);

      // Assert
      expect(result, false);
    });

    test('should correctly identify different items with different type', () {
      // Arrange
      final item1 = SongItem('C', TypeSongItem.chord)..index = 1;
      final item2 = SongItem('C', TypeSongItem.lyric)..index = 1;

      // Act
      final result = item1.isSame(item2);

      // Assert
      expect(result, false);
    });

    test('should correctly identify different items with different index', () {
      // Arrange
      final item1 = SongItem('C', TypeSongItem.chord)..index = 1;
      final item2 = SongItem('C', TypeSongItem.chord)..index = 2;

      // Act
      final result = item1.isSame(item2);

      // Assert
      expect(result, false);
    });

    test('should handle empty text', () {
      // Arrange & Act
      final songItem = SongItem('', TypeSongItem.lyric);

      // Assert
      expect(songItem.text, '');
    });

    test('should handle text with special characters', () {
      // Arrange & Act
      final songItem = SongItem('Test @#\$%', TypeSongItem.lyric);

      // Assert
      expect(songItem.text, 'Test @#\$%');
    });

    test('should handle text with unicode characters', () {
      // Arrange & Act
      final songItem = SongItem('Píseň 🎵', TypeSongItem.lyric);

      // Assert
      expect(songItem.text, 'Píseň 🎵');
    });

    test('should handle complex chord notation', () {
      // Arrange & Act
      final songItem = SongItem('Cmaj7/G', TypeSongItem.chord);

      // Assert
      expect(songItem.text, 'Cmaj7/G');
      expect(songItem.type, TypeSongItem.chord);
    });

    test('should allow modification of index', () {
      // Arrange
      final songItem = SongItem('C', TypeSongItem.chord);

      // Act
      songItem.index = 10;

      // Assert
      expect(songItem.index, 10);
    });
  });

  group('TypeSongItem Enum Tests', () {
    test('should have correct enum values', () {
      // Arrange & Act & Assert
      expect(TypeSongItem.chord.index, 0);
      expect(TypeSongItem.lyric.index, 1);
      expect(TypeSongItem.note.index, 2);
    });

    test('should serialize enum to JSON', () {
      // Arrange
      final chordItem = SongItem('C', TypeSongItem.chord);
      final lyricItem = SongItem('text', TypeSongItem.lyric);
      final noteItem = SongItem('note', TypeSongItem.note);

      // Act
      final chordJson = chordItem.toJson();
      final lyricJson = lyricItem.toJson();
      final noteJson = noteItem.toJson();

      // Assert
      expect(chordJson['type'], 'chord');
      expect(lyricJson['type'], 'lyric');
      expect(noteJson['type'], 'note');
    });
  });
}

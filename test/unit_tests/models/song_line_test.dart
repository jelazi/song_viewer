import 'package:default_project/model/song/song_item.dart';
import 'package:default_project/model/song/song_line.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger_pkg/logger_pkg.dart';

void main() {
  setUpAll(() {
    logger = MyLogger(debug: false, saveToFile: false, level: 0);
  });

  group('SongLine Model Tests', () {
    test('should create SongLine with index', () {
      // Arrange & Act
      final songLine = SongLine(5);

      // Assert
      expect(songLine.index, 5);
      expect(songLine.listItem, isEmpty);
    });

    test('should create items from simple text without chords', () {
      // Arrange
      final songLine = SongLine(0);

      // Act
      songLine.createItemsFromString('Simple lyrics', 0, false, false);

      // Assert
      expect(songLine.listItem.length, 1);
      expect(songLine.listItem[0].text, 'Simple lyrics');
      expect(songLine.listItem[0].type, TypeSongItem.lyric);
    });

    test('should create items from text with chords', () {
      // Arrange
      final songLine = SongLine(0);

      // Act
      songLine.createItemsFromString('Some [C]text with [G]chords', 0, true, false);

      // Assert
      expect(songLine.listItem.length, 5);
      expect(songLine.listItem[0].text, 'Some ');
      expect(songLine.listItem[0].type, TypeSongItem.lyric);
      expect(songLine.listItem[1].text, 'C');
      expect(songLine.listItem[1].type, TypeSongItem.chord);
      expect(songLine.listItem[2].text, 'text with ');
      expect(songLine.listItem[2].type, TypeSongItem.lyric);
      expect(songLine.listItem[3].text, 'G');
      expect(songLine.listItem[3].type, TypeSongItem.chord);
      expect(songLine.listItem[4].text, 'chords');
      expect(songLine.listItem[4].type, TypeSongItem.lyric);
    });

    test('should exclude chords when chords parameter is false', () {
      // Arrange
      final songLine = SongLine(0);

      // Act
      songLine.createItemsFromString('Some [C]text with [G]chords', 0, false, false);

      // Assert
      expect(songLine.listItem.length, 3);
      expect(songLine.listItem[0].text, 'Some ');
      expect(songLine.listItem[1].text, 'text with ');
      expect(songLine.listItem[2].text, 'chords');
      // Chords should not be included
    });

    test('should create items from text with notes', () {
      // Arrange
      final songLine = SongLine(0);

      // Act
      songLine.createItemsFromString('Text with {note1}notes', 0, false, true);

      // Assert
      expect(songLine.listItem.length, 3);
      expect(songLine.listItem[0].text, 'Text with ');
      expect(songLine.listItem[0].type, TypeSongItem.lyric);
      expect(songLine.listItem[1].text, 'note1');
      expect(songLine.listItem[1].type, TypeSongItem.note);
      expect(songLine.listItem[2].text, 'notes');
      expect(songLine.listItem[2].type, TypeSongItem.lyric);
    });

    test('should exclude notes when notes parameter is false', () {
      // Arrange
      final songLine = SongLine(0);

      // Act
      songLine.createItemsFromString('Text with {note1}notes', 0, false, false);

      // Assert
      expect(songLine.listItem.length, 2);
      expect(songLine.listItem[0].text, 'Text with ');
      expect(songLine.listItem[1].text, 'notes');
      // Notes should not be included
    });

    test('should handle mixed chords and notes', () {
      // Arrange
      final songLine = SongLine(0);

      // Act
      songLine.createItemsFromString('[C]Text {note}more [G]text', 0, true, true);

      // Assert
      expect(songLine.listItem.length, 6);
      expect(songLine.listItem[0].text, 'C');
      expect(songLine.listItem[0].type, TypeSongItem.chord);
      expect(songLine.listItem[1].text, 'Text ');
      expect(songLine.listItem[1].type, TypeSongItem.lyric);
      expect(songLine.listItem[2].text, 'note');
      expect(songLine.listItem[2].type, TypeSongItem.note);
      expect(songLine.listItem[3].text, 'more ');
      expect(songLine.listItem[3].type, TypeSongItem.lyric);
      expect(songLine.listItem[4].text, 'G');
      expect(songLine.listItem[4].type, TypeSongItem.chord);
      expect(songLine.listItem[5].text, 'text');
      expect(songLine.listItem[5].type, TypeSongItem.lyric);
    });

    test('should return correct lastChordItemIndex', () {
      // Arrange
      final songLine = SongLine(0);

      // Act
      final lastIndex = songLine.createItemsFromString('[C]text [G]more [D]end', 0, true, false);

      // Assert
      expect(lastIndex, 3); // 3 chords were created
    });

    test('should check if line is empty correctly', () {
      // Arrange
      final emptyLine = SongLine(0);
      final nonEmptyLine = SongLine(1);
      nonEmptyLine.createItemsFromString('Some text', 0, false, false);

      // Act & Assert
      expect(emptyLine.isEmpty(), true);
      expect(nonEmptyLine.isEmpty(), false);
    });

    test('should check if line with only empty items is empty', () {
      // Arrange
      final songLine = SongLine(0);
      songLine.listItem.add(SongItem('', TypeSongItem.lyric));
      songLine.listItem.add(SongItem('', TypeSongItem.lyric));

      // Act & Assert
      expect(songLine.isEmpty(), true);
    });

    test('should convert song items to string with chords', () {
      // Arrange
      final songLine = SongLine(0);
      songLine.createItemsFromString('Some [C]text with [G]chords', 0, true, false);

      // Act
      final result = songLine.songItemsToString(withChord: true);

      // Assert
      expect(result, 'Some [C]text with [G]chords');
    });

    test('should convert song items to string without chords', () {
      // Arrange
      final songLine = SongLine(0);
      songLine.createItemsFromString('Some [C]text with [G]chords', 0, true, false);

      // Act
      final result = songLine.songItemsToString(withChord: false);

      // Assert
      expect(result, 'Some text with chords');
    });

    test('should correctly identify same lines', () {
      // Arrange
      final line1 = SongLine(0);
      final line2 = SongLine(0);
      line1.createItemsFromString('Test [C]text', 0, true, false);
      line2.createItemsFromString('Test [C]text', 0, true, false);

      // Act
      final result = line1.isSame(line2);

      // Assert
      expect(result, true);
    });

    test('should correctly identify different lines with different index', () {
      // Arrange
      final line1 = SongLine(0);
      final line2 = SongLine(1);
      line1.createItemsFromString('Test', 0, false, false);
      line2.createItemsFromString('Test', 0, false, false);

      // Act
      final result = line1.isSame(line2);

      // Assert
      expect(result, false);
    });

    test('should correctly identify different lines with different content', () {
      // Arrange
      final line1 = SongLine(0);
      final line2 = SongLine(0);
      line1.createItemsFromString('Test1', 0, false, false);
      line2.createItemsFromString('Test2', 0, false, false);

      // Act
      final result = line1.isSame(line2);

      // Assert
      expect(result, false);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final songLine = SongLine(5);
      songLine.createItemsFromString('Test [C]text', 0, true, false);

      // Act
      final json = songLine.toJson();

      // Assert
      expect(json['index'], 5);
      expect(json['listItem'], isNotNull);
      expect(json['listItem'].length, 3); // 'Test ', 'C', 'text'
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'index': 3,
        'listItem': [
          {'text': 'Test', 'type': 'lyric', 'index': 0},
          {'text': 'C', 'type': 'chord', 'index': 0},
        ],
      };

      // Act
      final songLine = SongLine.fromJson(json);

      // Assert
      expect(songLine.index, 3);
      expect(songLine.listItem.length, 2);
      expect(songLine.listItem[0].text, 'Test');
      expect(songLine.listItem[1].text, 'C');
    });

    test('should handle JSON round-trip', () {
      // Arrange
      final originalLine = SongLine(7);
      originalLine.createItemsFromString('Round [G]trip', 0, true, false);

      // Act
      final json = originalLine.toJson();
      final deserializedLine = SongLine.fromJson(json);

      // Assert
      expect(deserializedLine.index, originalLine.index);
      expect(deserializedLine.listItem.length, originalLine.listItem.length);
    });

    test('should handle empty string', () {
      // Arrange
      final songLine = SongLine(0);

      // Act
      songLine.createItemsFromString('', 0, false, false);

      // Assert
      expect(songLine.listItem, isEmpty);
    });

    test('should handle string with only chords', () {
      // Arrange
      final songLine = SongLine(0);

      // Act
      songLine.createItemsFromString('[C][G][Am][F]', 0, true, false);

      // Assert
      expect(songLine.listItem.length, 4);
      expect(songLine.listItem.every((item) => item.type == TypeSongItem.chord), true);
    });

    test('should clear previous items when calling createItemsFromString', () {
      // Arrange
      final songLine = SongLine(0);
      songLine.createItemsFromString('First text', 0, false, false);

      // Act
      songLine.createItemsFromString('Second text', 0, false, false);

      // Assert
      expect(songLine.listItem.length, 1);
      expect(songLine.listItem[0].text, 'Second text');
    });
  });
}

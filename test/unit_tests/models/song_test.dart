import 'package:song_viewer/model/note.dart';
import 'package:song_viewer/model/song/song.dart';
import 'package:song_viewer/model/song/song_item.dart';
import 'package:song_viewer/model/youtube_video.dart';
import 'package:song_viewer/services/enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Song Model Tests', () {
    test('should create Song with required parameters', () {
      // Arrange & Act
      final song = Song(
        id: 'song-1',
        title: 'Test Song',
        lyrics: 'Test lyrics',
      );

      // Assert
      expect(song.id, 'song-1');
      expect(song.title, 'Test Song');
      expect(song.lyrics, 'Test lyrics');
      expect(song.typeTranspose, TypeTranspose.czech);
    });

    test('should create empty Song', () {
      // Arrange & Act
      final song = Song.empty();

      // Assert
      expect(song.id, '');
      expect(song.title, '');
      expect(song.lyrics, '');
      expect(song.originalLyrics, '');
      expect(song.interpret, '');
      expect(song.typeTranspose, TypeTranspose.czech);
      expect(song.songBar, 0);
      expect(song.bmp, 0);
      expect(song.sheets, isEmpty);
      expect(song.groups, isEmpty);
      expect(song.tags, isEmpty);
      expect(song.notes, isEmpty);
      expect(song.youtubeVideos, isEmpty);
    });

    test('should create Song with all parameters', () {
      // Arrange & Act
      final song = Song(
        id: 'song-1',
        title: 'Complete Song',
        lyrics: 'Complete lyrics',
        originalLyrics: 'Original text',
        indexSongBook: 42,
        interpret: 'Test Artist',
        typeTranspose: TypeTranspose.german,
        songBar: 4,
        bmp: 120,
        sheets: ['sheet1.pdf', 'sheet2.pdf'],
        groups: ['Group A', 'Group B'],
        tags: ['rock', 'popular'],
        notes: [Note(index: 0, noteText: 'Test note')],
        youtubeVideos: [YoutubeVideo(name: 'Video', path: 'abc123')],
      );

      // Assert
      expect(song.id, 'song-1');
      expect(song.title, 'Complete Song');
      expect(song.lyrics, 'Complete lyrics');
      expect(song.originalLyrics, 'Original text');
      expect(song.indexSongBook, 42);
      expect(song.interpret, 'Test Artist');
      expect(song.typeTranspose, TypeTranspose.german);
      expect(song.songBar, 4);
      expect(song.bmp, 120);
      expect(song.sheets?.length, 2);
      expect(song.groups?.length, 2);
      expect(song.tags?.length, 2);
      expect(song.notes?.length, 1);
      expect(song.youtubeVideos?.length, 1);
    });

    test('should generate id if empty', () {
      // Arrange
      final song = Song(id: '', title: 'Test', lyrics: 'Test');

      // Act
      song.generateId();

      // Assert
      expect(song.id, isNotEmpty);
    });

    test('should not regenerate id if already set', () {
      // Arrange
      final song = Song(id: 'existing-id', title: 'Test', lyrics: 'Test');
      final originalId = song.id;

      // Act
      song.generateId();

      // Assert
      expect(song.id, originalId);
    });

    test('should copyWith correctly', () {
      // Arrange
      final original = Song(
        id: 'song-1',
        title: 'Original Title',
        lyrics: 'Original lyrics',
        interpret: 'Original Artist',
      );

      // Act
      final copy = original.copyWith(
        title: 'New Title',
        interpret: 'New Artist',
      );

      // Assert
      expect(copy.id, 'song-1'); // unchanged
      expect(copy.title, 'New Title'); // changed
      expect(copy.lyrics, 'Original lyrics'); // unchanged
      expect(copy.interpret, 'New Artist'); // changed
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test Song',
        lyrics: 'Test lyrics',
        interpret: 'Test Artist',
        typeTranspose: TypeTranspose.german,
      );

      // Act
      final json = song.toJson();

      // Assert
      expect(json['id'], 'song-1');
      expect(json['title'], 'Test Song');
      expect(json['lyrics'], 'Test lyrics');
      expect(json['interpret'], 'Test Artist');
      expect(json['typeTranspose'], 'german');
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'id': 'song-1',
        'title': 'Test Song',
        'lyrics': 'Test lyrics',
        'interpret': 'Test Artist',
        'typeTranspose': 'czech',
      };

      // Act
      final song = Song.fromJson(json);

      // Assert
      expect(song.id, 'song-1');
      expect(song.title, 'Test Song');
      expect(song.lyrics, 'Test lyrics');
      expect(song.interpret, 'Test Artist');
      expect(song.typeTranspose, TypeTranspose.czech);
    });

    test('should handle JSON round-trip', () {
      // Arrange
      final originalSong = Song(
        id: 'song-1',
        title: 'Round Trip',
        lyrics: 'Round trip lyrics',
        groups: ['Group1', 'Group2'],
        tags: ['tag1', 'tag2'],
      );

      // Act
      final json = originalSong.toJson();
      final deserializedSong = Song.fromJson(json);

      // Assert
      expect(deserializedSong.id, originalSong.id);
      expect(deserializedSong.title, originalSong.title);
      expect(deserializedSong.lyrics, originalSong.lyrics);
      expect(deserializedSong.groups, originalSong.groups);
      expect(deserializedSong.tags, originalSong.tags);
    });

    test('should parse lyrics into SongLine objects', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test',
        lyrics: 'Line 1\nLine 2\nLine 3',
      );

      // Act
      final lines = song.listLyrics(false, false, TypeLyric.translate);

      // Assert
      expect(lines.length, 3);
      expect(lines[0].index, 0);
      expect(lines[1].index, 1);
      expect(lines[2].index, 2);
    });

    test('should parse lyrics with chords', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test',
        lyrics: '[C]Line with [G]chords',
      );

      // Act
      final lines = song.listLyrics(true, false, TypeLyric.translate);

      // Assert
      expect(lines.length, 1);
      expect(lines[0].listItem.length, 4);
      expect(lines[0].listItem[0].type, TypeSongItem.chord);
      expect(lines[0].listItem[0].text, 'C');
    });

    test('should get lyrics without chords', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test',
        lyrics: '[C]Some text [G]more text',
      );

      // Act
      final result = song.lyricsWithoutChords;

      // Assert
      expect(result, 'Some text more text');
    });

    test('should get lyrics without chords with lines', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test',
        lyrics: '[C]Line 1\n[G]Line 2',
      );

      // Act
      final result = song.lyricsWithoutChordsWithLines;

      // Assert
      expect(result, 'Line 1\nLine 2\n');
    });

    test('should get lyrics with chords formatted', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test',
        lyrics: '[C]Some text',
      );

      // Act
      final result = song.lyricsWithChords;

      // Assert
      expect(result, contains('C'));
      expect(result, contains('Some text'));
    });

    test('should check modified song correctly', () {
      // Arrange
      final song1 = Song(
        id: 'song-1',
        title: 'Original Title',
        lyrics: 'Original lyrics',
        interpret: 'Artist',
      );
      final song2 = Song(
        id: 'song-1',
        title: 'Modified Title',
        lyrics: 'Original lyrics',
        interpret: 'Artist',
      );

      // Act
      final modifications = song1.checkModifiedSong(song2, false);

      // Assert
      expect(modifications.contains('title'), true);
      expect(modifications.contains('lyrics'), false);
    });

    test('should detect all modified fields', () {
      // Arrange
      final song1 = Song(
        id: 'song-1',
        title: 'Title 1',
        lyrics: 'Lyrics 1',
        interpret: 'Artist 1',
        typeTranspose: TypeTranspose.czech,
      );
      final song2 = Song(
        id: 'song-1',
        title: 'Title 2',
        lyrics: 'Lyrics 2',
        interpret: 'Artist 2',
        typeTranspose: TypeTranspose.german,
      );

      // Act
      final modifications = song1.checkModifiedSong(song2, false);

      // Assert
      expect(modifications.contains('title'), true);
      expect(modifications.contains('lyrics'), true);
      expect(modifications.contains('interpret'), true);
      expect(modifications.contains('typeTranspose'), true);
    });

    test('should get all unique chords from song', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test',
        lyrics: '[C]Text [G]more [C]text [Am]end',
      );

      // Act
      final chords = song.getAllUniqueChordsFromSong(TypeLyric.translate);

      // Assert
      expect(chords.length, 3);
      expect(chords.contains('C'), true);
      expect(chords.contains('G'), true);
      expect(chords.contains('Am'), true);
    });

    test('should handle song with no chords', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test',
        lyrics: 'Just plain text without chords',
      );

      // Act
      final chords = song.getAllUniqueChordsFromSong(TypeLyric.translate);

      // Assert
      expect(chords, isEmpty);
    });

    test('should handle original lyrics when specified', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test',
        lyrics: 'Translated text',
        originalLyrics: 'Original text',
      );

      // Act
      final lines = song.listLyrics(false, false, TypeLyric.original);

      // Assert
      expect(lines.length, 1);
    });

    test('should handle both lyrics when undefined type', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test',
        lyrics: 'Line 1',
        originalLyrics: 'Line 2',
      );

      // Act
      final lines = song.listLyrics(false, false, TypeLyric.undefined);

      // Assert
      expect(lines.length, 2);
    });

    test('should handle null optional fields', () {
      // Arrange
      final song = Song(
        id: 'song-1',
        title: 'Test',
        lyrics: 'Test',
      );

      // Assert
      expect(song.originalLyrics, null);
      expect(song.indexSongBook, null);
      expect(song.interpret, null);
      expect(song.songBar, null);
      expect(song.bmp, null);
      expect(song.sheets, null);
      expect(song.groups, null);
      expect(song.tags, null);
      expect(song.notes, null);
      expect(song.youtubeVideos, null);
    });
  });

  group('TypeTranspose Enum Tests', () {
    test('should have correct enum values', () {
      // Arrange & Act & Assert
      expect(TypeTranspose.czech.index, 0);
      expect(TypeTranspose.german.index, 1);
    });

    test('should serialize enum to JSON', () {
      // Arrange
      final czechSong = Song(
        id: 'song-1',
        title: 'Czech',
        lyrics: 'Test',
        typeTranspose: TypeTranspose.czech,
      );
      final germanSong = Song(
        id: 'song-2',
        title: 'German',
        lyrics: 'Test',
        typeTranspose: TypeTranspose.german,
      );

      // Act
      final czechJson = czechSong.toJson();
      final germanJson = germanSong.toJson();

      // Assert
      expect(czechJson['typeTranspose'], 'czech');
      expect(germanJson['typeTranspose'], 'german');
    });
  });
}

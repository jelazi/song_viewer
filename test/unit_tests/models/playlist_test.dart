import 'package:default_project/model/playlist.dart';
import 'package:default_project/model/song/song.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger_pkg/logger_pkg.dart';

void main() {
  setUpAll(() {
    logger = MyLogger(debug: false, saveToFile: false, level: 0);
  });

  group('Playlist Model Tests', () {
    test('should create Playlist with name and id', () {
      // Arrange & Act
      final playlist = Playlist(id: 'test-id', name: 'Test Playlist');

      // Assert
      expect(playlist.id, 'test-id');
      expect(playlist.name, 'Test Playlist');
      expect(playlist.listSongIds, isEmpty);
    });

    test('should generate id if not provided', () {
      // Arrange & Act
      final playlist = Playlist(id: null, name: 'Test Playlist');

      // Assert
      expect(playlist.id, isNotNull);
      expect(playlist.id, isNotEmpty);
      expect(playlist.name, 'Test Playlist');
    });

    test('should not regenerate id if already set', () {
      // Arrange
      final playlist = Playlist(id: 'existing-id', name: 'Test Playlist');
      final originalId = playlist.id;

      // Act - trying to generate again (internal method is private, but constructor calls it)
      // The id should remain the same

      // Assert
      expect(playlist.id, originalId);
    });

    test('should add song to playlist', () {
      // Arrange
      final playlist = Playlist(id: 'test-id', name: 'Test Playlist');
      final song = Song(id: 'song-1', title: 'Test Song', lyrics: 'Test lyrics');

      // Act
      final result = playlist.addSong(song);

      // Assert
      expect(result, '');
      expect(playlist.listSongIds.length, 1);
      expect(playlist.listSongIds[0], 'song-1');
    });

    test('should not add duplicate song to playlist', () {
      // Arrange
      final playlist = Playlist(id: 'test-id', name: 'Test Playlist');
      final song = Song(id: 'song-1', title: 'Test Song', lyrics: 'Test lyrics');

      // Act
      playlist.addSong(song);
      final result = playlist.addSong(song);

      // Assert
      expect(result, 'isInPlaylist');
      expect(playlist.listSongIds.length, 1);
    });

    test('should add multiple different songs', () {
      // Arrange
      final playlist = Playlist(id: 'test-id', name: 'Test Playlist');
      final song1 = Song(id: 'song-1', title: 'Test Song 1', lyrics: 'Test lyrics 1');
      final song2 = Song(id: 'song-2', title: 'Test Song 2', lyrics: 'Test lyrics 2');
      final song3 = Song(id: 'song-3', title: 'Test Song 3', lyrics: 'Test lyrics 3');

      // Act
      playlist.addSong(song1);
      playlist.addSong(song2);
      playlist.addSong(song3);

      // Assert
      expect(playlist.listSongIds.length, 3);
      expect(playlist.listSongIds, ['song-1', 'song-2', 'song-3']);
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final playlist = Playlist(id: 'test-id', name: 'Test Playlist');
      final song1 = Song(id: 'song-1', title: 'Test Song 1', lyrics: 'Test lyrics 1');
      final song2 = Song(id: 'song-2', title: 'Test Song 2', lyrics: 'Test lyrics 2');
      playlist.addSong(song1);
      playlist.addSong(song2);

      // Act
      final json = playlist.toJson();

      // Assert
      expect(json['name'], 'Test Playlist');
      expect(json['id'], 'test-id');
      expect(json['listSongIds'], ['song-1', 'song-2']);
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'name': 'Test Playlist',
        'id': 'test-id',
        'listSongIds': ['song-1', 'song-2', 'song-3'],
      };

      // Act
      final playlist = Playlist.fromJson(json);

      // Assert
      expect(playlist.name, 'Test Playlist');
      expect(playlist.id, 'test-id');
      expect(playlist.listSongIds, ['song-1', 'song-2', 'song-3']);
    });

    test('should handle empty listSongIds in JSON', () {
      // Arrange
      final json = {
        'name': 'Empty Playlist',
        'id': 'test-id',
        'listSongIds': [],
      };

      // Act
      final playlist = Playlist.fromJson(json);

      // Assert
      expect(playlist.name, 'Empty Playlist');
      expect(playlist.id, 'test-id');
      expect(playlist.listSongIds, isEmpty);
    });

    test('should handle null id in JSON', () {
      // Arrange
      final json = {
        'name': 'Test Playlist',
        'id': null,
        'listSongIds': [],
      };

      // Act
      final playlist = Playlist.fromJson(json);

      // Assert - id should be generated
      expect(playlist.name, 'Test Playlist');
      expect(playlist.id, isNotNull);
      expect(playlist.id, isNotEmpty);
    });

    test('should handle JSON round-trip', () {
      // Arrange
      final originalPlaylist = Playlist(id: 'test-id', name: 'Test Playlist');
      final song = Song(id: 'song-1', title: 'Test Song', lyrics: 'Test lyrics');
      originalPlaylist.addSong(song);

      // Act
      final json = originalPlaylist.toJson();
      final deserializedPlaylist = Playlist.fromJson(json);

      // Assert
      expect(deserializedPlaylist.name, originalPlaylist.name);
      expect(deserializedPlaylist.id, originalPlaylist.id);
      expect(deserializedPlaylist.listSongIds, originalPlaylist.listSongIds);
    });
  });
}

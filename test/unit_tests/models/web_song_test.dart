import 'package:default_project/model/web_song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebSong Model Tests', () {
    test('should create WebSong with required parameters', () {
      // Arrange & Act
      final webSong = WebSong(
        title: 'Test Song',
        ref: 'https://example.com/song',
        interpret: 'Test Artist',
      );

      // Assert
      expect(webSong.title, 'Test Song');
      expect(webSong.ref, 'https://example.com/song');
      expect(webSong.interpret, 'Test Artist');
      expect(webSong.ischords, true); // default value
      expect(webSong.server, ''); // default value
      expect(webSong.lyric, ''); // default value
    });

    test('should create WebSong with all parameters', () {
      // Arrange & Act
      final webSong = WebSong(
        title: 'Complete Song',
        ref: 'https://example.com/complete',
        interpret: 'Complete Artist',
        ischords: false,
        server: 'TestServer',
      );

      // Assert
      expect(webSong.title, 'Complete Song');
      expect(webSong.ref, 'https://example.com/complete');
      expect(webSong.interpret, 'Complete Artist');
      expect(webSong.ischords, false);
      expect(webSong.server, 'TestServer');
    });

    test('should inherit properties from WebItem', () {
      // Arrange & Act
      final webSong = WebSong(
        title: 'Inherited Song',
        ref: 'https://example.com/inherited',
        interpret: 'Artist',
      );

      // Assert
      expect(webSong.title, 'Inherited Song');
      expect(webSong.ref, 'https://example.com/inherited');
    });

    test('should allow modification of lyric', () {
      // Arrange
      final webSong = WebSong(
        title: 'Song',
        ref: 'https://example.com/song',
        interpret: 'Artist',
      );

      // Act
      webSong.lyric = 'Test lyrics\nLine 2\nLine 3';

      // Assert
      expect(webSong.lyric, 'Test lyrics\nLine 2\nLine 3');
    });

    test('should allow modification of server', () {
      // Arrange
      final webSong = WebSong(
        title: 'Song',
        ref: 'https://example.com/song',
        interpret: 'Artist',
      );

      // Act
      webSong.server = 'NewServer';

      // Assert
      expect(webSong.server, 'NewServer');
    });

    test('should allow modification of ischords', () {
      // Arrange
      final webSong = WebSong(
        title: 'Song',
        ref: 'https://example.com/song',
        interpret: 'Artist',
      );

      // Act
      webSong.ischords = false;

      // Assert
      expect(webSong.ischords, false);
    });

    test('should handle empty interpret', () {
      // Arrange & Act
      final webSong = WebSong(
        title: 'Unknown Artist Song',
        ref: 'https://example.com/unknown',
        interpret: '',
      );

      // Assert
      expect(webSong.interpret, '');
    });

    test('should handle song without chords', () {
      // Arrange & Act
      final webSong = WebSong(
        title: 'No Chords Song',
        ref: 'https://example.com/nochords',
        interpret: 'Artist',
        ischords: false,
      );

      // Assert
      expect(webSong.ischords, false);
    });

    test('should handle interpret with special characters', () {
      // Arrange & Act
      final webSong = WebSong(
        title: 'Song',
        ref: 'https://example.com/song',
        interpret: 'Artist & The Band',
      );

      // Assert
      expect(webSong.interpret, 'Artist & The Band');
    });

    test('should handle interpret with unicode characters', () {
      // Arrange & Act
      final webSong = WebSong(
        title: 'Česká píseň',
        ref: 'https://example.com/czech',
        interpret: 'Český interpret',
      );

      // Assert
      expect(webSong.interpret, 'Český interpret');
    });

    test('should handle long lyrics', () {
      // Arrange
      final longLyrics = 'Verse 1\n' * 100;
      final webSong = WebSong(
        title: 'Long Song',
        ref: 'https://example.com/long',
        interpret: 'Artist',
      );

      // Act
      webSong.lyric = longLyrics;

      // Assert
      expect(webSong.lyric, longLyrics);
      // split('\n') creates 101 elements (100 lines + 1 empty string at the end)
      expect(webSong.lyric.split('\n').length, 101);
    });

    test('should handle different server values', () {
      // Arrange & Act
      final servers = ['VelkyZpevnik', 'PisnickyAkordy', 'Supermusic'];
      final webSongs = servers
          .map((server) => WebSong(
                title: 'Song',
                ref: 'https://example.com/song',
                interpret: 'Artist',
                server: server,
              ))
          .toList();

      // Assert
      expect(webSongs[0].server, 'VelkyZpevnik');
      expect(webSongs[1].server, 'PisnickyAkordy');
      expect(webSongs[2].server, 'Supermusic');
    });
  });
}

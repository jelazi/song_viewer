import 'package:song_viewer/model/youtube_video.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('YoutubeVideo Model Tests', () {
    test('should create YoutubeVideo with name and path', () {
      // Arrange & Act
      final video = YoutubeVideo(name: 'Test Video', path: 'https://youtube.com/watch?v=test123');

      // Assert
      expect(video.name, 'Test Video');
      expect(video.path, 'https://youtube.com/watch?v=test123');
    });

    test('should create YoutubeVideo with empty values', () {
      // Arrange & Act
      final video = YoutubeVideo(name: '', path: '');

      // Assert
      expect(video.name, '');
      expect(video.path, '');
    });

    test('should serialize to JSON correctly', () {
      // Arrange
      final video = YoutubeVideo(name: 'Amazing Song', path: 'https://youtube.com/watch?v=abc123');

      // Act
      final json = video.toJson();

      // Assert
      expect(json['name'], 'Amazing Song');
      expect(json['path'], 'https://youtube.com/watch?v=abc123');
    });

    test('should deserialize from JSON correctly', () {
      // Arrange
      final json = {
        'name': 'Cool Video',
        'path': 'https://youtube.com/watch?v=xyz789',
      };

      // Act
      final video = YoutubeVideo.fromJson(json);

      // Assert
      expect(video.name, 'Cool Video');
      expect(video.path, 'https://youtube.com/watch?v=xyz789');
    });

    test('should handle JSON round-trip', () {
      // Arrange
      final originalVideo = YoutubeVideo(name: 'Round Trip Video', path: 'https://youtube.com/watch?v=round123');

      // Act
      final json = originalVideo.toJson();
      final deserializedVideo = YoutubeVideo.fromJson(json);

      // Assert
      expect(deserializedVideo.name, originalVideo.name);
      expect(deserializedVideo.path, originalVideo.path);
    });

    test('should handle video with special characters in name', () {
      // Arrange
      final video = YoutubeVideo(name: 'Song: "Title" & More!', path: 'https://youtube.com/watch?v=test');

      // Act
      final json = video.toJson();
      final deserializedVideo = YoutubeVideo.fromJson(json);

      // Assert
      expect(deserializedVideo.name, 'Song: "Title" & More!');
    });

    test('should handle short YouTube ID', () {
      // Arrange
      final video = YoutubeVideo(name: 'Short ID', path: 'dQw4w9WgXcQ');

      // Act
      final json = video.toJson();
      final deserializedVideo = YoutubeVideo.fromJson(json);

      // Assert
      expect(deserializedVideo.path, 'dQw4w9WgXcQ');
    });

    test('should handle full YouTube URL', () {
      // Arrange
      final video = YoutubeVideo(
        name: 'Full URL',
        path: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s',
      );

      // Act
      final json = video.toJson();
      final deserializedVideo = YoutubeVideo.fromJson(json);

      // Assert
      expect(deserializedVideo.path, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ&t=30s');
    });

    test('should handle YouTube short URL', () {
      // Arrange
      final video = YoutubeVideo(name: 'Short URL', path: 'https://youtu.be/dQw4w9WgXcQ');

      // Act
      final json = video.toJson();
      final deserializedVideo = YoutubeVideo.fromJson(json);

      // Assert
      expect(deserializedVideo.path, 'https://youtu.be/dQw4w9WgXcQ');
    });

    test('should handle name with unicode characters', () {
      // Arrange
      final video = YoutubeVideo(name: 'Píseň s diakritikou 🎵', path: 'https://youtube.com/watch?v=test');

      // Act
      final json = video.toJson();
      final deserializedVideo = YoutubeVideo.fromJson(json);

      // Assert
      expect(deserializedVideo.name, 'Píseň s diakritikou 🎵');
    });
  });
}

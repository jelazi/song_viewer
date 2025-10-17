import 'package:default_project/model/web_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebItem Model Tests', () {
    test('should create WebItem with title and ref', () {
      // Arrange & Act
      final webItem = WebItem(title: 'Test Title', ref: 'https://example.com/test');

      // Assert
      expect(webItem.title, 'Test Title');
      expect(webItem.ref, 'https://example.com/test');
    });

    test('should create WebItem with empty values', () {
      // Arrange & Act
      final webItem = WebItem(title: '', ref: '');

      // Assert
      expect(webItem.title, '');
      expect(webItem.ref, '');
    });

    test('should allow modification of title', () {
      // Arrange
      final webItem = WebItem(title: 'Original Title', ref: 'https://example.com/test');

      // Act
      webItem.title = 'Modified Title';

      // Assert
      expect(webItem.title, 'Modified Title');
    });

    test('should allow modification of ref', () {
      // Arrange
      final webItem = WebItem(title: 'Test', ref: 'https://example.com/original');

      // Act
      webItem.ref = 'https://example.com/modified';

      // Assert
      expect(webItem.ref, 'https://example.com/modified');
    });

    test('should handle title with special characters', () {
      // Arrange & Act
      final webItem = WebItem(title: 'Title: "Special" & More!', ref: 'https://example.com/special');

      // Assert
      expect(webItem.title, 'Title: "Special" & More!');
    });

    test('should handle ref with query parameters', () {
      // Arrange & Act
      final webItem = WebItem(title: 'Test', ref: 'https://example.com/song?id=123&tab=lyrics');

      // Assert
      expect(webItem.ref, 'https://example.com/song?id=123&tab=lyrics');
    });

    test('should handle title with unicode characters', () {
      // Arrange & Act
      final webItem = WebItem(title: 'Píseň s diakritikou 🎵', ref: 'https://example.com/czech');

      // Assert
      expect(webItem.title, 'Píseň s diakritikou 🎵');
    });

    test('should handle long URLs', () {
      // Arrange
      final longUrl = 'https://example.com/very/long/path/to/song/with/many/segments/and/parameters?id=123&name=test&category=rock&year=2023';

      // Act
      final webItem = WebItem(title: 'Long URL', ref: longUrl);

      // Assert
      expect(webItem.ref, longUrl);
    });

    test('should handle relative URLs', () {
      // Arrange & Act
      final webItem = WebItem(title: 'Relative', ref: '/songs/123');

      // Assert
      expect(webItem.ref, '/songs/123');
    });

    test('should handle empty title with valid ref', () {
      // Arrange & Act
      final webItem = WebItem(title: '', ref: 'https://example.com/noname');

      // Assert
      expect(webItem.title, '');
      expect(webItem.ref, 'https://example.com/noname');
    });

    test('should handle valid title with empty ref', () {
      // Arrange & Act
      final webItem = WebItem(title: 'No Reference', ref: '');

      // Assert
      expect(webItem.title, 'No Reference');
      expect(webItem.ref, '');
    });
  });
}

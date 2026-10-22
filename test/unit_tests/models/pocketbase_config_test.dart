import 'package:flutter_test/flutter_test.dart';
import 'package:song_viewer/providers/pocketbase_provider.dart';

void main() {
  group('PocketBaseConfig file content', () {
    test('round-trips through toFileContent', () {
      final config = PocketBaseConfig(pocketbaseUrl: 'https://pb.example', email: 'band@example.com', password: 'secret');

      final parsed = PocketBaseConfig.fromFileContent(config.toFileContent());

      expect(parsed.pocketbaseUrl, 'https://pb.example');
      expect(parsed.email, 'band@example.com');
      expect(parsed.password, 'secret');
    });

    test('trims url and e-mail but not the password', () {
      final parsed = PocketBaseConfig.fromFileContent('{"pocketbaseUrl": " https://pb.example ", "email": " a@b.c ", "password": " p "}');

      expect(parsed.pocketbaseUrl, 'https://pb.example');
      expect(parsed.email, 'a@b.c');
      expect(parsed.password, ' p ');
    });

    test('rejects an incomplete config', () {
      expect(() => PocketBaseConfig.fromFileContent('{"pocketbaseUrl": "https://pb.example"}'), throwsFormatException);
    });

    test('rejects content that is not a JSON object', () {
      expect(() => PocketBaseConfig.fromFileContent('[1, 2]'), throwsFormatException);
      expect(() => PocketBaseConfig.fromFileContent('not json'), throwsFormatException);
    });
  });
}

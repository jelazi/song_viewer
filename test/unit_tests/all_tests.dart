// All unit tests for Songs Viewer BLoC application
// Run this file to execute all unit tests at once
//
// Usage:
//   flutter test test/unit_tests/all_tests.dart
//   flutter test --coverage test/unit_tests/all_tests.dart

// Provider tests
// firebase_provider_test removed — Firebase replaced by PocketBase
import 'providers/hive_provider_test.dart' as hive_provider_tests;
import 'providers/web_provider_test.dart' as web_provider_tests;
// Repository tests
import 'repositories/playlist_repository_test.dart' as playlist_repository_tests;
import 'repositories/settings_repository_test.dart' as settings_repository_tests;
import 'repositories/songs_repository_test.dart' as songs_repository_tests;
import 'repositories/web_repository_test.dart' as web_repository_tests;

void main() {
  // Provider tests
  hive_provider_tests.main();
  web_provider_tests.main();

  // Repository tests
  playlist_repository_tests.main();
  settings_repository_tests.main();
  songs_repository_tests.main();
  web_repository_tests.main();

  // Note: Add BLoC tests here when they are created
  // import 'blocs/home_page_bloc_test.dart' as home_page_bloc_tests;
  // home_page_bloc_tests.main();
}

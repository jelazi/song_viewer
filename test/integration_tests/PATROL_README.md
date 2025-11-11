# Patrol Integration Tests

This directory contains integration tests using Patrol framework for UI component testing.

## Setup

1. Dependencies are already installed in `pubspec.yaml`:
```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  patrol: ^3.10.0
```

2. Run `flutter pub get`

## Running Tests

### Simple way - Flutter integration test
```bash
# Run on macOS
flutter test test/integration_tests/simple_patrol_test.dart -d macos

# Run on iOS simulator
flutter test test/integration_tests/simple_patrol_test.dart -d "iPhone 15"

# Run on Android emulator
flutter test test/integration_tests/simple_patrol_test.dart -d emulator
```

### Advanced way - Patrol CLI (requires additional configuration)

Patrol CLI enables advanced features like native interactions, but requires properly configured UI test targets in Xcode/Android Studio.

```bash
# Install Patrol CLI
dart pub global activate patrol_cli

# Run all tests
patrol test -d macos
```

**Note:** If Patrol CLI reports xcodebuild or test scheme errors, use standard `flutter test` command above.

## Available Tests

### simple_patrol_test.dart ✅
Functional tests without BLoC or repository dependencies:
- ✅ Counter test - clicking and value changes
- ✅ TextField test - entering and clearing text  
- ✅ ListView test - scrolling
- ✅ Navigation test - switching between pages

### song_card_patrol_test.dart (DISABLED)
Advanced tests for SongCard widget - requires generated mocks:

**To activate:**
1. Ensure you have `mockito` in pubspec.yaml (✅ already present)
2. Generate mocks: `flutter pub run build_runner build --delete-conflicting-outputs`
3. Rename file: `mv song_card_patrol_test.dart.disabled song_card_patrol_test.dart`

## Patrol Usage Examples

### Basic test pattern
```dart
patrolTest(
  'test description',
  ($) async {
    // Arrange - prepare data
    final testData = ...;
    
    // Act - create widget and actions
    await $.pumpWidgetAndSettle(...);
    await $(Widget).tap();
    
    // Assert - verify
    expect($(Widget), findsOneWidget);
  },
);
```

### Finding widgets
```dart
// Text
$('Text to find')

// Widget type
$(SongCard)

// Icon
$(Icons.edit)

// Key
$(Key('unique_key'))

// Index in list
$(ListTile).at(5)
```

### Interactions
```dart
// Tap
await $(Widget).tap();

// Long press
await $(Widget).longPress();

// Scroll
await $(ListTile).at(99).scrollTo();

// Enter text
await $(TextField).enterText('text');

// Native actions (requires Patrol CLI)
await $.native.pressBack();
await $.native.grantPermissionWhenInUse();
```

## Patrol Advantages

1. **Simpler syntax** - `$('text')` instead of `find.text('text')`
2. **Native interactions** - can test system dialogs too (with Patrol CLI)
3. **Cross-platform** - works on iOS, Android, macOS, Windows, Linux
4. **Hot reload support** - faster test development
5. **Better debugging** - better error messages and screenshots on failure

## Tips & Troubleshooting

### flutter test vs patrol test
- `flutter test` - simpler, always works, recommended for beginners
- `patrol test` - advanced features, requires UI test target setup

### Physical iOS device
Patrol on physical iOS devices only works in release mode:
```bash
patrol test -d "iPhone" --release
```

### Build errors
If you see "mock file not found" errors, ensure you've run build_runner:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Test failures
- Use `pumpWidgetAndSettle()` to wait for animations to complete
- Patrol automatically takes screenshots on test failure to `build/app/outputs/`
- For debugging, add `await Future.delayed(Duration(seconds: 2));` for visual inspection

## Known Issues

### Version Compatibility (Current State)
- ⚠️ patrol_cli 3.1.1 + patrol 3.10.0 - build error with Flutter SDK
- ⚠️ PatrolIntegrationTester const constructor incompatibility
- ⚠️ Versions not compatible with current Flutter SDK
- ⚠️ Tests currently not executable via 'patrol test' or 'flutter test'

**Workaround:** These tests serve as examples and documentation. To use Patrol in production, ensure version compatibility with your Flutter SDK or wait for framework updates.


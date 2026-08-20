import 'package:default_project/model/user.dart';
import 'package:default_project/providers/hive_provider.dart';
import 'package:default_project/providers/pocketbase_provider.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/services/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../test_helpers/test_logger.dart';

@GenerateMocks([HiveProvider, PocketBaseProvider])
import 'settings_repository_test.mocks.dart';

void main() {
  group('SettingsRepository', () {
    late SettingsRepository settingsRepository;
    late MockHiveProvider mockHiveProvider;
    late MockPocketBaseProvider mockPocketBaseProvider;

    setUp(() {
      initTestLogger();
      mockHiveProvider = MockHiveProvider();
      mockPocketBaseProvider = MockPocketBaseProvider();
      settingsRepository = SettingsRepository(hiveProvider: mockHiveProvider, pocketBaseProvider: mockPocketBaseProvider);
    });

    group('Load Settings', () {
      test('should load all settings from Hive', () async {
        // Catch-all first, so the specific stubs below still win: the
        // repository reads more keys than this test asserts on, and each one it
        // does not read here falls back to its own default. Without it, every
        // new setting breaks this test.
        when(mockHiveProvider.getSettingsValue(any)).thenAnswer((_) async => null);

        // Mock all settings values
        when(mockHiveProvider.getSettingsValue('previewFontTextSize')).thenAnswer((_) async => 20.0);
        when(mockHiveProvider.getSettingsValue('previewFontChordSize')).thenAnswer((_) async => 20.0);
        when(mockHiveProvider.getSettingsValue('editFontTextSize')).thenAnswer((_) async => 20.0);
        when(mockHiveProvider.getSettingsValue('editFontChordSize')).thenAnswer((_) async => 20.0);
        when(mockHiveProvider.getSettingsValue('previewColorText')).thenAnswer((_) async => Colors.black.toARGB32());
        when(mockHiveProvider.getSettingsValue('previewColorChord')).thenAnswer((_) async => Colors.red.toARGB32());
        when(mockHiveProvider.getSettingsValue('editColorText')).thenAnswer((_) async => Colors.black.toARGB32());
        when(mockHiveProvider.getSettingsValue('editColorChord')).thenAnswer((_) async => Colors.red.toARGB32());
        when(mockHiveProvider.getSettingsValue('isEditIconVisible')).thenAnswer((_) async => true);
        when(mockHiveProvider.getSettingsValue('autoHideTopBar')).thenAnswer((_) async => false);
        when(mockHiveProvider.getSettingsValue('currentUser')).thenAnswer((_) async => User.empty());
        when(mockHiveProvider.getSettingsValue('typeClickCard')).thenAnswer((_) async => TypeClickCard.none);
        when(mockHiveProvider.getSettingsValue('twoColumns')).thenAnswer((_) async => false);

        await settingsRepository.loadLocalSettings();

        expect(settingsRepository.previewFontTextSize, equals(20.0));
        expect(settingsRepository.previewFontChordSize, equals(20.0));
        expect(settingsRepository.isEditIconVisible, isTrue);
        expect(settingsRepository.autoHideTopBar, isFalse);
      });

      test('should use default values when settings not found', () async {
        // Mock null returns (no settings found)
        when(mockHiveProvider.getSettingsValue(any)).thenAnswer((_) async => null);

        await settingsRepository.loadLocalSettings();

        expect(settingsRepository.previewFontTextSize, equals(20.0));
        expect(settingsRepository.previewFontChordSize, equals(20.0));
        expect(settingsRepository.isEditIconVisible, isTrue);
        expect(settingsRepository.autoHideTopBar, isFalse);
      });
    });

    group('Font Size Settings', () {
      test('should return correct preview font text size', () {
        expect(settingsRepository.previewFontTextSize, equals(20.0));
      });

      test('should return correct preview font chord size', () {
        expect(settingsRepository.previewFontChordSize, equals(20.0));
      });

      test('should return correct edit font text size', () {
        expect(settingsRepository.editFontTextSize, equals(20.0));
      });

      test('should return correct edit font chord size', () {
        expect(settingsRepository.editFontChordSize, equals(20.0));
      });
    });

    group('Color Settings', () {
      test('should return correct preview text color', () {
        expect(settingsRepository.previewColorText, equals(Colors.black));
      });

      test('should return correct preview chord color', () {
        expect(settingsRepository.previewColorChord, equals(Colors.red));
      });

      test('should return correct edit text color', () {
        expect(settingsRepository.editColorText, equals(Colors.black));
      });

      test('should return correct edit chord color', () {
        expect(settingsRepository.editColorChord, equals(Colors.red));
      });
    });

    group('User Settings', () {
      test('should set current user', () {
        final user = User('testUser', 'password');

        settingsRepository.setCurrentUser(user);

        expect(settingsRepository.currentUser.name, equals('testUser'));
        verify(mockHiveProvider.setSettingsValue('currentUser', user)).called(1);
      });

      test('should return current user', () {
        expect(settingsRepository.currentUser, isA<User>());
      });
    });

    group('Type Click Card Settings', () {
      test('should change type click card', () {
        settingsRepository.changeTypeClickCard(TypeClickCard.preview);

        expect(settingsRepository.typeClickCard, equals(TypeClickCard.preview));
        verify(mockHiveProvider.setSettingsValue('typeClickCard', TypeClickCard.preview)).called(1);
      });

      test('should return current type click card', () {
        expect(settingsRepository.typeClickCard, equals(TypeClickCard.none));
      });
    });

    group('Change Settings Value', () {
      test('should change preview font text size', () {
        settingsRepository.changeSettingsValue('previewFontTextSize', 25.0);

        expect(settingsRepository.previewFontTextSize, equals(25.0));
        verify(mockHiveProvider.setSettingsValue('previewFontTextSize', 25.0)).called(1);
      });

      test('should change preview font chord size', () {
        settingsRepository.changeSettingsValue('previewFontChordSize', 22.0);

        expect(settingsRepository.previewFontChordSize, equals(22.0));
        verify(mockHiveProvider.setSettingsValue('previewFontChordSize', 22.0)).called(1);
      });

      test('should change preview color text', () {
        settingsRepository.changeSettingsValue('previewColorText', Colors.blue);

        expect(settingsRepository.previewColorText, equals(Colors.blue));
        verify(mockHiveProvider.setSettingsValue('previewColorText', Colors.blue.toARGB32())).called(1);
      });

      test('should change preview color chord', () {
        settingsRepository.changeSettingsValue('previewColorChord', Colors.green);

        expect(settingsRepository.previewColorChord, equals(Colors.green));
        verify(mockHiveProvider.setSettingsValue('previewColorChord', Colors.green.toARGB32())).called(1);
      });

      test('should change isEditIconVisible', () {
        settingsRepository.changeSettingsValue('isEditIconVisible', false);

        expect(settingsRepository.isEditIconVisible, isFalse);
        verify(mockHiveProvider.setSettingsValue('isEditIconVisible', false)).called(1);
      });

      test('should change autoHideTopBar', () {
        settingsRepository.changeSettingsValue('autoHideTopBar', true);

        expect(settingsRepository.autoHideTopBar, isTrue);
        verify(mockHiveProvider.setSettingsValue('autoHideTopBar', true)).called(1);
      });

      test('should change twoColumns', () {
        settingsRepository.changeSettingsValue('twoColumns', true);

        expect(settingsRepository.twoColumns, isTrue);
        verify(mockHiveProvider.setSettingsValue('twoColumns', true)).called(1);
      });
    });

    group('App Info', () {
      test('should have version and build number strings', () {
        expect(settingsRepository.version, isA<String>());
        expect(settingsRepository.buildNumber, isA<String>());
      });
    });

    group('Screen Size', () {
      test('should have isLargeScreen property', () {
        expect(settingsRepository.isLargeScreen, isA<bool>());
      });
    });
  });
}

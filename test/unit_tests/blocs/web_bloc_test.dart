import 'package:song_viewer/blocs/export_blocs.dart';
import 'package:song_viewer/model/web_song.dart';
import 'package:song_viewer/providers/hive_provider.dart';
import 'package:song_viewer/repositories/settings_repository.dart';
import 'package:song_viewer/repositories/web_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'web_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<WebRepository>(), MockSpec<SettingsRepository>(), MockSpec<HiveProvider>()])
void main() {
  group('WebBloc - preview controls', () {
    late MockWebRepository webRepository;
    late MockSettingsRepository settingsRepository;
    late MockHiveProvider hiveProvider;
    late WebBloc bloc;

    setUp(() async {
      webRepository = MockWebRepository();
      settingsRepository = MockSettingsRepository();
      hiveProvider = MockHiveProvider();
      when(settingsRepository.previewFontTextSize).thenReturn(20);
      when(settingsRepository.previewFontChordSize).thenReturn(20);
      when(settingsRepository.previewColorText).thenReturn(Colors.black);
      when(settingsRepository.previewColorChord).thenReturn(Colors.red);

      bloc = WebBloc(webRepository: webRepository, settingsRepository: settingsRepository, hiveProvider: hiveProvider);
      await pumpEventQueue();
    });

    tearDown(() async {
      await bloc.close();
    });

    test('ChangeWebFontSize grows both the text and the chord style', () async {
      bloc.add(const ChangeWebFontSize(isIncrease: true));
      await pumpEventQueue();

      expect(bloc.state.textStyle.fontSize, 21);
      expect(bloc.state.chordStyle.fontSize, 21);
      verify(settingsRepository.changeSettingsValue('previewFontTextSize', 21.0)).called(1);
      verify(settingsRepository.changeSettingsValue('previewFontChordSize', 21.0)).called(1);
    });

    test('ChangeWebFontSize stops at the lower bound', () async {
      for (var i = 0; i < 20; i++) {
        bloc.add(const ChangeWebFontSize(isIncrease: false));
      }
      await pumpEventQueue();

      expect(bloc.state.textStyle.fontSize, minPreviewFontSize);
    });

    test('ChangeWebFontSize stops at the upper bound', () async {
      for (var i = 0; i < 30; i++) {
        bloc.add(const ChangeWebFontSize(isIncrease: true));
      }
      await pumpEventQueue();

      expect(bloc.state.textStyle.fontSize, maxPreviewFontSize);
    });

    test('TransposeWebChord accumulates and wraps around the octave', () async {
      bloc.add(const TransposeWebChord(increment: 1));
      bloc.add(const TransposeWebChord(increment: 1));
      await pumpEventQueue();
      expect(bloc.state.transposeIncrement, 2);
      expect(bloc.state.cap, 10);

      for (var i = 0; i < 10; i++) {
        bloc.add(const TransposeWebChord(increment: 1));
      }
      await pumpEventQueue();
      expect(bloc.state.transposeIncrement, 0);
      expect(bloc.state.cap, 0);
    });

    test('opening another song resets the transposition', () async {
      when(hiveProvider.getWebSong(any)).thenReturn(WebSong(title: 'Song', ref: 'ref', interpret: 'Interpret')..lyric = '[C]lyric');

      bloc.add(const TransposeWebChord(increment: 3));
      await pumpEventQueue();
      expect(bloc.state.transposeIncrement, 3);

      bloc.add(ChangeCurrentWebSong(
        song: WebSong(title: 'Song', ref: 'ref', interpret: 'Interpret'),
        typeSearching: 'velkyzpevnik.cz',
      ));
      await pumpEventQueue();

      expect(bloc.state.transposeIncrement, 0);
    });
  });

  group('WebBloc - chord notation', () {
    late MockWebRepository webRepository;
    late MockSettingsRepository settingsRepository;
    late MockHiveProvider hiveProvider;
    late WebBloc bloc;

    /// Opens a downloaded song with the given lyric, as the site published it.
    Future<void> openSong(String lyric) async {
      when(hiveProvider.getWebSong(any)).thenReturn(WebSong(title: 'Song', ref: 'ref', interpret: 'Interpret')..lyric = lyric);
      bloc.add(ChangeCurrentWebSong(
        song: WebSong(title: 'Song', ref: 'ref', interpret: 'Interpret'),
        typeSearching: 'worshipchords.com',
      ));
      await pumpEventQueue();
    }

    setUp(() async {
      webRepository = MockWebRepository();
      settingsRepository = MockSettingsRepository();
      hiveProvider = MockHiveProvider();
      when(settingsRepository.previewFontTextSize).thenReturn(20);
      when(settingsRepository.previewFontChordSize).thenReturn(20);
      when(settingsRepository.previewColorText).thenReturn(Colors.black);
      when(settingsRepository.previewColorChord).thenReturn(Colors.red);

      bloc = WebBloc(webRepository: webRepository, settingsRepository: settingsRepository, hiveProvider: hiveProvider);
      await pumpEventQueue();
    });

    tearDown(() async {
      await bloc.close();
    });

    test('a foreign notation is flagged when the song loads', () async {
      await openSong('[G]Amazing [B]grace, how [Bb]sweet');

      expect(bloc.state.foreignNotationDetected, isTrue);
      expect(bloc.state.isNotationConverted, isFalse);
      expect(bloc.state.displayedLyric, '[G]Amazing [B]grace, how [Bb]sweet');
    });

    test('a Czech song is not flagged', () async {
      await openSong('[G]Ma [H]la [B]dy');

      expect(bloc.state.foreignNotationDetected, isFalse);
    });

    test('ToggleChordNotation converts the shown lyric and switches back', () async {
      await openSong('[B]one [Bb]two');

      bloc.add(const ToggleChordNotation());
      await pumpEventQueue();
      expect(bloc.state.isNotationConverted, isTrue);
      expect(bloc.state.displayedLyric, '[H]one [B]two');
      // The fetched song keeps the spelling of its site.
      expect(bloc.state.currentSong?.lyric, '[B]one [Bb]two');

      bloc.add(const ToggleChordNotation());
      await pumpEventQueue();
      expect(bloc.state.isNotationConverted, isFalse);
      expect(bloc.state.displayedLyric, '[B]one [Bb]two');
    });

    test('opening another song drops the conversion', () async {
      await openSong('[B]one [Bb]two');
      bloc.add(const ToggleChordNotation());
      await pumpEventQueue();
      expect(bloc.state.isNotationConverted, isTrue);

      await openSong('[C]clean [D]song');

      expect(bloc.state.isNotationConverted, isFalse);
      expect(bloc.state.foreignNotationDetected, isFalse);
      expect(bloc.state.displayedLyric, '[C]clean [D]song');
    });
  });
}

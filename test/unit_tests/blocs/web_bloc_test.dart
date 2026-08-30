import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/model/web_song.dart';
import 'package:default_project/providers/hive_provider.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/repositories/web_repository.dart';
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
}

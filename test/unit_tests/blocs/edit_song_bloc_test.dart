import 'package:song_viewer/blocs/export_blocs.dart';
import 'package:song_viewer/model/song/song.dart';
import 'package:song_viewer/repositories/settings_repository.dart';
import 'package:song_viewer/repositories/songs_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'edit_song_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SongsRepository>(), MockSpec<SettingsRepository>()])
void main() {
  group('EditSongBloc - chord editing', () {
    late MockSongsRepository songsRepository;
    late MockSettingsRepository settingsRepository;
    late EditSongBloc bloc;

    const lyrics = '[C]Hello [G]world\n[C]second [C]line';

    setUp(() async {
      songsRepository = MockSongsRepository();
      settingsRepository = MockSettingsRepository();
      when(settingsRepository.previewFontTextSize).thenReturn(20);
      when(settingsRepository.previewFontChordSize).thenReturn(20);
      when(settingsRepository.previewColorText).thenReturn(Colors.black);
      when(settingsRepository.previewColorChord).thenReturn(Colors.red);
      when(songsRepository.listAllGroups).thenReturn([]);
      when(songsRepository.getSongById(any)).thenReturn(null);

      bloc = EditSongBloc(songsRepository: songsRepository, settingsRepository: settingsRepository);
      bloc.add(ChangeEditSong(song: Song(id: '1', title: 'Test', lyrics: lyrics), isOriginalLyrics: false));
      await pumpEventQueue();
    });

    tearDown(() async {
      await bloc.close();
    });

    /// Index of the closing bracket of the first chord — that is the index the
    /// UI passes for a chord span.
    int firstChordIndex() => bloc.state.currentText.indexOf(']');

    test('changeAllSameChords defaults to false', () {
      expect(bloc.state.changeAllSameChords, isFalse);
    });

    test('ChangeChord replaces only the selected chord by default', () async {
      bloc.add(ChangeChord(index: firstChordIndex(), chord: 'G'));
      await pumpEventQueue();

      expect(bloc.state.currentText, '[G]Hello [G]world\n[C]second [C]line');
    });

    test('ChangeChord replaces every identical chord when changeAllSameChords is on', () async {
      bloc.add(const SetChangeAllSameChords(value: true));
      await pumpEventQueue();
      expect(bloc.state.changeAllSameChords, isTrue);

      bloc.add(ChangeChord(index: firstChordIndex(), chord: 'G'));
      await pumpEventQueue();

      expect(bloc.state.currentText, '[G]Hello [G]world\n[G]second [G]line');
      expect(bloc.state.listUniqueChords, ['G']);
    });

    test('changeAllSameChords resets to false after a chord change', () async {
      bloc.add(const SetChangeAllSameChords(value: true));
      bloc.add(ChangeChord(index: firstChordIndex(), chord: 'G'));
      await pumpEventQueue();

      expect(bloc.state.changeAllSameChords, isFalse);
    });

    test('changing a chord to the same value leaves the lyrics untouched', () async {
      bloc.add(const SetChangeAllSameChords(value: true));
      bloc.add(ChangeChord(index: firstChordIndex(), chord: 'C'));
      await pumpEventQueue();

      expect(bloc.state.currentText, lyrics);
    });
  });
}

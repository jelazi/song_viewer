import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/model/song/song.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:default_project/services/chordpro_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'chordpro_import_bloc_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SongsRepository>()])
void main() {
  group('ChordProImportBloc', () {
    late MockSongsRepository songsRepository;
    late ChordProImportBloc bloc;

    const twoSongs = '''
{title: First Song}
{artist: Someone}
[C]placeholder line one

{title: Second Song}
[G]placeholder line two
''';

    setUp(() {
      songsRepository = MockSongsRepository();
      bloc = ChordProImportBloc(
        songsRepository: songsRepository,
        chordProService: const ChordProService(),
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    test('starts empty', () {
      expect(bloc.state.status, ChordProImportStatus.initial);
      expect(bloc.state.songs, isEmpty);
    });

    test('parsing does not touch the repository', () async {
      bloc.add(const ParseChordProFiles(files: [ChordProFile(name: 'songs.cho', content: twoSongs)]));
      await pumpEventQueue();

      expect(bloc.state.status, ChordProImportStatus.ready);
      expect(bloc.state.songs, hasLength(2));
      verifyNever(songsRepository.addImportedSongs(any));
    });

    test('everything is selected after parsing', () async {
      bloc.add(const ParseChordProFiles(files: [ChordProFile(name: 'songs.cho', content: twoSongs)]));
      await pumpEventQueue();

      expect(bloc.state.selectedIds, hasLength(2));
      expect(bloc.state.allSelected, isTrue);
    });

    test('files are parsed together and their names recorded', () async {
      bloc.add(const ParseChordProFiles(files: [
        ChordProFile(name: 'a.cho', content: '{title: A}\n[C]x'),
        ChordProFile(name: 'b.cho', content: '{title: B}\n[D]y'),
      ]));
      await pumpEventQueue();

      expect(bloc.state.songs.map((s) => s.title), ['A', 'B']);
      expect(bloc.state.sourceNames, ['a.cho', 'b.cho']);
    });

    test('a file with no usable song reports an error', () async {
      bloc.add(const ParseChordProFiles(files: [ChordProFile(name: 'empty.cho', content: '{title: Ghost}')]));
      await pumpEventQueue();

      expect(bloc.state.status, ChordProImportStatus.error);
      expect(bloc.state.errorMessage, 'chordProNoSongsFound');
      expect(bloc.state.skipped, 1);
    });

    test('toggling removes and restores a song', () async {
      bloc.add(const ParseChordProFiles(files: [ChordProFile(name: 'songs.cho', content: twoSongs)]));
      await pumpEventQueue();
      final id = bloc.state.songs.first.id;

      bloc.add(ToggleChordProSelection(songId: id));
      await pumpEventQueue();
      expect(bloc.state.selectedIds, isNot(contains(id)));

      bloc.add(ToggleChordProSelection(songId: id));
      await pumpEventQueue();
      expect(bloc.state.selectedIds, contains(id));
    });

    test('only the selected songs are imported', () async {
      when(songsRepository.addImportedSongs(any)).thenAnswer((_) async => 1);

      bloc.add(const ParseChordProFiles(files: [ChordProFile(name: 'songs.cho', content: twoSongs)]));
      await pumpEventQueue();

      bloc.add(ToggleChordProSelection(songId: bloc.state.songs.first.id));
      await pumpEventQueue();

      bloc.add(const ConfirmChordProImport());
      await pumpEventQueue();

      final captured = verify(songsRepository.addImportedSongs(captureAny)).captured.single as List<Song>;
      expect(captured, hasLength(1));
      expect(captured.single.title, 'Second Song');
      expect(bloc.state.status, ChordProImportStatus.done);
      expect(bloc.state.importedCount, 1);
    });

    test('deselecting everything makes confirm a no-op', () async {
      bloc.add(const ParseChordProFiles(files: [ChordProFile(name: 'songs.cho', content: twoSongs)]));
      await pumpEventQueue();

      bloc.add(const SetAllChordProSelected(selected: false));
      await pumpEventQueue();
      expect(bloc.state.selectedIds, isEmpty);

      bloc.add(const ConfirmChordProImport());
      await pumpEventQueue();

      verifyNever(songsRepository.addImportedSongs(any));
      expect(bloc.state.status, ChordProImportStatus.ready);
    });

    test('a repository failure surfaces as an error state', () async {
      when(songsRepository.addImportedSongs(any)).thenThrow(Exception('storage is gone'));

      bloc.add(const ParseChordProFiles(files: [ChordProFile(name: 'songs.cho', content: twoSongs)]));
      await pumpEventQueue();
      bloc.add(const ConfirmChordProImport());
      await pumpEventQueue();

      expect(bloc.state.status, ChordProImportStatus.error);
      expect(bloc.state.errorMessage, 'chordProImportFailed');
    });

    test('reset clears the parsed batch', () async {
      bloc.add(const ParseChordProFiles(files: [ChordProFile(name: 'songs.cho', content: twoSongs)]));
      await pumpEventQueue();

      bloc.add(const ResetChordProImport());
      await pumpEventQueue();

      expect(bloc.state.status, ChordProImportStatus.initial);
      expect(bloc.state.songs, isEmpty);
      expect(bloc.state.selectedIds, isEmpty);
    });

    test('an empty file list is ignored', () async {
      bloc.add(const ParseChordProFiles(files: []));
      await pumpEventQueue();

      expect(bloc.state.status, ChordProImportStatus.initial);
    });
  });
}

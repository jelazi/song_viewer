import 'package:flutter_test/flutter_test.dart';
import 'package:song_viewer/blocs/pad_bloc/pad_bloc.dart';
import 'package:song_viewer/model/pad_set.dart';
import 'package:song_viewer/repositories/pads_repository.dart';
import 'package:song_viewer/services/pad_audio_engine.dart';

const _warm = PadSet(id: 'warm', name: 'Warm', fileUrls: {0: 'https://pb/w0.m4a', 7: 'https://pb/w7.m4a'});
const _hillsong = PadSet(id: 'hillsong', name: 'Hillsong', fileUrls: {0: 'https://pb/h0.m4a', 7: 'https://pb/h7.m4a'});

class _FakePadsRepository extends Fake implements PadsRepository {
  @override
  bool isWindowOpen;
  @override
  bool isWindowMinimized;
  @override
  String? selectedSetId;
  @override
  double volume = 0.5;
  @override
  int fadeInSeconds = 3;
  @override
  int fadeOutSeconds = 5;
  @override
  PadFadeCurve fadeCurve = PadFadeCurve.linear;

  final downloaded = <String>{};
  Map<String, SongPadPreference> songPreferences = {};
  final savedPreferences = <String, SongPadPreference?>{};

  _FakePadsRepository({this.isWindowOpen = false, this.isWindowMinimized = false, this.selectedSetId});

  @override
  Future<List<PadSet>> loadSets() async => [_warm, _hillsong];

  @override
  Future<Map<String, SongPadPreference>> loadSongPreferences() async => songPreferences;

  @override
  Future<Map<String, SongPadPreference>> saveSongPreference(String songId, SongPadPreference? preference) async {
    savedPreferences[songId] = preference;
    songPreferences = {...songPreferences};
    preference == null ? songPreferences.remove(songId) : songPreferences[songId] = preference;
    return songPreferences;
  }

  @override
  Future<Set<int>> downloadedKeys(PadSet set) async =>
      set.fileUrls.keys.where((semitone) => downloaded.contains('${set.id}/$semitone')).toSet();

  @override
  Future<String> ensureFile(PadSet set, int semitone) async {
    downloaded.add('${set.id}/$semitone');
    return '/pads/${set.id}/$semitone.m4a';
  }
}

class _FakePadEngine extends PadAudioEngine {
  final played = <String>[];
  int stops = 0;
  double? volume;
  Duration? lastFadeIn;
  Duration? lastFadeOut;

  @override
  Future<void> play(String path, {required Duration fadeIn, required Duration fadeOut, required PadFadeCurve curve}) async {
    played.add(path);
    lastFadeIn = fadeIn;
    lastFadeOut = fadeOut;
  }

  @override
  Future<void> stop({required Duration fadeOut, required PadFadeCurve curve}) async => stops++;

  @override
  void setVolume(double volume) => this.volume = volume;

  @override
  Future<void> dispose() async {}
}

Future<PadState> _waitFor(PadBloc bloc, bool Function(PadState state) condition) {
  if (condition(bloc.state)) return Future.value(bloc.state);
  return bloc.stream.firstWhere(condition).timeout(const Duration(seconds: 2));
}

void main() {
  late _FakePadEngine engine;

  setUp(() => engine = _FakePadEngine());

  test('restores an open window with its set, volume and fades', () async {
    final repository = _FakePadsRepository(isWindowOpen: true, selectedSetId: 'hillsong');
    final bloc = PadBloc(padsRepository: repository, engine: engine);

    final state = await _waitFor(bloc, (state) => state.status == PadSetsStatus.ready);

    expect(state.isWindowOpen, isTrue);
    expect(state.selectedSetId, 'hillsong');
    expect(state.fadeInSeconds, 3);
    expect(state.fadeCurve, PadFadeCurve.linear);
    expect(engine.volume, 0.5);
    await bloc.close();
  });

  test('a closed window does not load the sets until it is opened', () async {
    final repository = _FakePadsRepository();
    final bloc = PadBloc(padsRepository: repository, engine: engine);
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state.status, PadSetsStatus.initial);

    bloc.add(const OpenPadWindow());
    final state = await _waitFor(bloc, (state) => state.status == PadSetsStatus.ready);

    expect(repository.isWindowOpen, isTrue);
    expect(state.selectedSetId, 'warm');
    await bloc.close();
  });

  test('tapping a key plays it with the configured fades, tapping it again stops it', () async {
    final bloc = PadBloc(padsRepository: _FakePadsRepository(isWindowOpen: true), engine: engine);
    await _waitFor(bloc, (state) => state.status == PadSetsStatus.ready);

    bloc.add(const TogglePadKey(semitone: 7));
    final playing = await _waitFor(bloc, (state) => state.playingKey == 7);

    expect(engine.played, ['/pads/warm/7.m4a']);
    expect(engine.lastFadeIn, const Duration(seconds: 3));
    expect(engine.lastFadeOut, const Duration(seconds: 5));
    expect(playing.downloadedKeys, contains(7));
    expect(playing.loadingKey, isNull);

    bloc.add(const TogglePadKey(semitone: 7));
    await _waitFor(bloc, (state) => state.playingKey == null);
    expect(engine.stops, 1);
    await bloc.close();
  });

  test('switching the set while playing continues in the same key', () async {
    final repository = _FakePadsRepository(isWindowOpen: true);
    final bloc = PadBloc(padsRepository: repository, engine: engine);
    await _waitFor(bloc, (state) => state.status == PadSetsStatus.ready);
    bloc.add(const TogglePadKey(semitone: 0));
    await _waitFor(bloc, (state) => state.playingKey == 0);

    bloc.add(const SelectPadSet(setId: 'hillsong'));
    await _waitFor(bloc, (state) => state.selectedSetId == 'hillsong' && engine.played.length == 2);

    expect(engine.played, ['/pads/warm/0.m4a', '/pads/hillsong/0.m4a']);
    expect(repository.selectedSetId, 'hillsong');
    expect(bloc.state.playingKey, 0);
    await bloc.close();
  });

  test('closing the window stops the pad and remembers it is closed', () async {
    final repository = _FakePadsRepository(isWindowOpen: true);
    final bloc = PadBloc(padsRepository: repository, engine: engine);
    await _waitFor(bloc, (state) => state.status == PadSetsStatus.ready);
    bloc.add(const TogglePadKey(semitone: 0));
    await _waitFor(bloc, (state) => state.playingKey == 0);

    bloc.add(const ClosePadWindow());
    final state = await _waitFor(bloc, (state) => !state.isWindowOpen);

    expect(state.playingKey, isNull);
    expect(engine.stops, 1);
    expect(repository.isWindowOpen, isFalse);
    await bloc.close();
  });

  test('volume and fade changes are applied and stored', () async {
    final repository = _FakePadsRepository();
    final bloc = PadBloc(padsRepository: repository, engine: engine);

    bloc.add(const ChangePadVolume(volume: 0.3));
    bloc.add(const ChangePadFade(fadeInSeconds: 8, curve: PadFadeCurve.gentle));
    await _waitFor(bloc, (state) => state.fadeInSeconds == 8);

    expect(engine.volume, 0.3);
    expect(repository.volume, 0.3);
    expect(repository.fadeInSeconds, 8);
    expect(repository.fadeOutSeconds, 5);
    expect(repository.fadeCurve, PadFadeCurve.gentle);
    await bloc.close();
  });

  test('minimizing keeps the pad playing and is remembered', () async {
    final repository = _FakePadsRepository(isWindowOpen: true);
    final bloc = PadBloc(padsRepository: repository, engine: engine);
    await _waitFor(bloc, (state) => state.status == PadSetsStatus.ready);
    bloc.add(const TogglePadKey(semitone: 7));
    await _waitFor(bloc, (state) => state.playingKey == 7);

    bloc.add(const MinimizePadWindow());
    final minimized = await _waitFor(bloc, (state) => state.isMinimized);

    expect(minimized.playingKey, 7);
    expect(minimized.isWindowOpen, isTrue);
    expect(engine.stops, 0);
    expect(repository.isWindowMinimized, isTrue);

    bloc.add(const RestorePadWindow());
    await _waitFor(bloc, (state) => !state.isMinimized);
    expect(repository.isWindowMinimized, isFalse);
    await bloc.close();
  });

  test('a minimized window comes back minimized, closing clears it', () async {
    final repository = _FakePadsRepository(isWindowOpen: true, isWindowMinimized: true);
    final bloc = PadBloc(padsRepository: repository, engine: engine);
    final restored = await _waitFor(bloc, (state) => state.status == PadSetsStatus.ready);
    expect(restored.isMinimized, isTrue);

    bloc.add(const ClosePadWindow());
    final closed = await _waitFor(bloc, (state) => !state.isWindowOpen);

    expect(closed.isMinimized, isFalse);
    expect(repository.isWindowMinimized, isFalse);
    await bloc.close();
  });

  test('saves the playing pad with its set for a song and removes it again', () async {
    final repository = _FakePadsRepository(isWindowOpen: true, selectedSetId: 'hillsong');
    final bloc = PadBloc(padsRepository: repository, engine: engine);
    await _waitFor(bloc, (state) => state.status == PadSetsStatus.ready);
    bloc.add(const TogglePadKey(semitone: 7));
    await _waitFor(bloc, (state) => state.playingKey == 7);

    bloc.add(const SaveSongPad(songId: 'song-1'));
    final saved = await _waitFor(bloc, (state) => state.songPreferences.containsKey('song-1'));

    expect(saved.songPreferences['song-1'], const SongPadPreference(semitone: 7, setId: 'hillsong'));
    expect(repository.savedPreferences['song-1'], const SongPadPreference(semitone: 7, setId: 'hillsong'));

    bloc.add(const RemoveSongPad(songId: 'song-1'));
    await _waitFor(bloc, (state) => !state.songPreferences.containsKey('song-1'));
    expect(repository.savedPreferences.containsKey('song-1'), isTrue);
    expect(repository.savedPreferences['song-1'], isNull);
    await bloc.close();
  });

  test('nothing is saved for a song while no pad plays', () async {
    final repository = _FakePadsRepository(isWindowOpen: true);
    final bloc = PadBloc(padsRepository: repository, engine: engine);
    await _waitFor(bloc, (state) => state.status == PadSetsStatus.ready);

    bloc.add(const SaveSongPad(songId: 'song-1'));
    await Future<void>.delayed(Duration.zero);

    expect(repository.savedPreferences, isEmpty);
    await bloc.close();
  });

  test('saved song pads are loaded with the sets', () async {
    final repository = _FakePadsRepository(isWindowOpen: true)..songPreferences = {'song-9': const SongPadPreference(semitone: 2, setId: 'warm')};
    final bloc = PadBloc(padsRepository: repository, engine: engine);

    final state = await _waitFor(bloc, (state) => state.status == PadSetsStatus.ready);

    expect(state.songPreferences['song-9']?.semitone, 2);
    await bloc.close();
  });

  test('the toggle opens, minimizes and restores without stopping the pad', () async {
    final bloc = PadBloc(padsRepository: _FakePadsRepository(), engine: engine);
    await Future<void>.delayed(Duration.zero);

    bloc.add(const TogglePadWindow());
    await _waitFor(bloc, (state) => state.isWindowOpen && state.status == PadSetsStatus.ready);
    bloc.add(const TogglePadWindow());
    await _waitFor(bloc, (state) => state.isMinimized);
    bloc.add(const TogglePadWindow());
    final restored = await _waitFor(bloc, (state) => !state.isMinimized);

    expect(restored.isWindowOpen, isTrue);
    expect(engine.stops, 0);
    await bloc.close();
  });
}

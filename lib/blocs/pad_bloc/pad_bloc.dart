import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../../model/pad_set.dart';
import '../../repositories/pads_repository.dart';
import '../../services/pad_audio_engine.dart';
import '../../view/desktop_view/widgets/my_toast.dart';

part 'pad_event.dart';
part 'pad_state.dart';

class PadBloc extends Bloc<PadEvent, PadState> {
  final PadsRepository padsRepository;
  final PadAudioEngine engine;

  PadBloc({required this.padsRepository, PadAudioEngine? engine})
      : engine = engine ?? PadAudioEngine(),
        super(const PadState()) {
    on<_PadInit>(_init);
    on<OpenPadWindow>(_openWindow);
    on<ClosePadWindow>(_closeWindow);
    on<MinimizePadWindow>(_minimizeWindow);
    on<TogglePadWindow>(_toggleWindow);
    on<SaveSongPad>(_saveSongPad);
    on<RemoveSongPad>(_removeSongPad);
    on<RestorePadWindow>(_restoreWindow);
    on<SelectPadSet>(_selectSet);
    on<TogglePadKey>(_toggleKey);
    on<StopPad>(_stop);
    on<ChangePadVolume>(_changeVolume);
    on<DownloadPadSet>(_downloadSet);
    on<ChangePadFade>(_changeFade);
    add(const _PadInit());
  }

  Duration get _fadeIn => Duration(seconds: state.fadeInSeconds);
  Duration get _fadeOut => Duration(seconds: state.fadeOutSeconds);

  Future<void> _init(_PadInit event, Emitter<PadState> emit) async {
    emit(state.copyWith(
      isWindowOpen: padsRepository.isWindowOpen,
      isMinimized: padsRepository.isWindowOpen && padsRepository.isWindowMinimized,
      selectedSetId: padsRepository.selectedSetId,
      volume: padsRepository.volume,
      fadeInSeconds: padsRepository.fadeInSeconds,
      fadeOutSeconds: padsRepository.fadeOutSeconds,
      fadeCurve: padsRepository.fadeCurve,
    ));
    engine.setVolume(state.volume);
    if (state.isWindowOpen) await _loadSets(emit);
  }

  Future<void> _openWindow(OpenPadWindow event, Emitter<PadState> emit) async {
    padsRepository.isWindowOpen = true;
    emit(state.copyWith(isWindowOpen: true));
    if (state.status == PadSetsStatus.ready) {
      emit(state.copyWith(songPreferences: await padsRepository.loadSongPreferences()));
    } else if (state.status != PadSetsStatus.loading) {
      await _loadSets(emit);
    }
  }

  Future<void> _closeWindow(ClosePadWindow event, Emitter<PadState> emit) async {
    padsRepository.isWindowOpen = false;
    padsRepository.isWindowMinimized = false;
    await engine.stop(fadeOut: _fadeOut, curve: state.fadeCurve);
    emit(state.copyWith(isWindowOpen: false, isMinimized: false, clearPlayingKey: true, clearLoadingKey: true));
  }

  void _minimizeWindow(MinimizePadWindow event, Emitter<PadState> emit) {
    if (!state.isWindowOpen) return;
    padsRepository.isWindowMinimized = true;
    emit(state.copyWith(isMinimized: true));
  }

  Future<void> _toggleWindow(TogglePadWindow event, Emitter<PadState> emit) async {
    if (!state.isWindowOpen) {
      await _openWindow(const OpenPadWindow(), emit);
    } else if (state.isMinimized) {
      _restoreWindow(const RestorePadWindow(), emit);
    } else {
      _minimizeWindow(const MinimizePadWindow(), emit);
    }
  }

  Future<void> _saveSongPad(SaveSongPad event, Emitter<PadState> emit) async {
    final playing = state.playingKey;
    if (playing == null || event.songId.isEmpty) return;
    final preference = SongPadPreference(semitone: playing, setId: state.selectedSetId);
    emit(state.copyWith(songPreferences: {...state.songPreferences, event.songId: preference}));
    emit(state.copyWith(songPreferences: await padsRepository.saveSongPreference(event.songId, preference)));
  }

  Future<void> _removeSongPad(RemoveSongPad event, Emitter<PadState> emit) async {
    emit(state.copyWith(songPreferences: {...state.songPreferences}..remove(event.songId)));
    emit(state.copyWith(songPreferences: await padsRepository.saveSongPreference(event.songId, null)));
  }

  void _restoreWindow(RestorePadWindow event, Emitter<PadState> emit) {
    padsRepository.isWindowMinimized = false;
    emit(state.copyWith(isMinimized: false));
  }

  Future<void> _loadSets(Emitter<PadState> emit) async {
    emit(state.copyWith(status: PadSetsStatus.loading));
    final preferencesFuture = padsRepository.loadSongPreferences();
    final sets = await padsRepository.loadSets();
    emit(state.copyWith(songPreferences: await preferencesFuture));
    if (sets.isEmpty) {
      emit(state.copyWith(status: PadSetsStatus.failure, sets: const []));
      return;
    }
    final selected = sets.any((set) => set.id == state.selectedSetId) ? state.selectedSetId! : sets.first.id;
    final downloaded = await padsRepository.downloadedKeys(sets.firstWhere((set) => set.id == selected));
    emit(state.copyWith(status: PadSetsStatus.ready, sets: sets, selectedSetId: selected, downloadedKeys: downloaded));
  }

  Future<void> _selectSet(SelectPadSet event, Emitter<PadState> emit) async {
    final set = state.sets.where((set) => set.id == event.setId).firstOrNull;
    if (set == null || set.id == state.selectedSetId) return;
    padsRepository.selectedSetId = set.id;
    emit(state.copyWith(selectedSetId: set.id, downloadedKeys: await padsRepository.downloadedKeys(set)));
    final playing = state.playingKey;
    if (playing != null) await _playKey(playing, emit);
  }

  Future<void> _toggleKey(TogglePadKey event, Emitter<PadState> emit) async {
    if (state.playingKey == event.semitone && state.loadingKey == null) {
      await engine.stop(fadeOut: _fadeOut, curve: state.fadeCurve);
      emit(state.copyWith(clearPlayingKey: true));
      return;
    }
    await _playKey(event.semitone, emit);
  }

  Future<void> _playKey(int semitone, Emitter<PadState> emit) async {
    final set = state.selectedSet;
    if (set == null || !set.fileUrls.containsKey(semitone)) return;
    emit(state.copyWith(loadingKey: semitone));

    final String path;
    try {
      path = await padsRepository.ensureFile(set, semitone);
    } catch (e) {
      logger.e('Pad download failed: $e');
      MyToast.showText(text: 'padDownloadFailed'.tr(), typeNotification: TypeNotification.error);
      if (state.loadingKey == semitone) emit(state.copyWith(clearLoadingKey: true));
      return;
    }
    // Another key was tapped while this one was downloading.
    if (state.loadingKey != semitone || state.selectedSetId != set.id) return;

    try {
      await engine.play(path, fadeIn: _fadeIn, fadeOut: _fadeOut, curve: state.fadeCurve);
      emit(state.copyWith(playingKey: semitone, clearLoadingKey: true, downloadedKeys: {...state.downloadedKeys, semitone}));
    } catch (_) {
      MyToast.showText(text: 'padPlayFailed'.tr(), typeNotification: TypeNotification.error);
      emit(state.copyWith(clearLoadingKey: true));
    }
  }

  Future<void> _stop(StopPad event, Emitter<PadState> emit) async {
    await engine.stop(fadeOut: _fadeOut, curve: state.fadeCurve);
    emit(state.copyWith(clearPlayingKey: true, clearLoadingKey: true));
  }

  void _changeVolume(ChangePadVolume event, Emitter<PadState> emit) {
    engine.setVolume(event.volume);
    padsRepository.volume = event.volume;
    emit(state.copyWith(volume: event.volume));
  }

  Future<void> _downloadSet(DownloadPadSet event, Emitter<PadState> emit) async {
    final set = state.selectedSet;
    if (set == null || state.setDownloadProgress != null) return;
    var done = state.downloadedKeys.length;
    emit(state.copyWith(setDownloadProgress: done));
    for (final semitone in set.fileUrls.keys) {
      if (state.downloadedKeys.contains(semitone)) continue;
      try {
        await padsRepository.ensureFile(set, semitone);
      } catch (e) {
        logger.e('Pad set download failed: $e');
        MyToast.showText(text: 'padDownloadFailed'.tr(), typeNotification: TypeNotification.error);
        emit(state.copyWith(clearSetDownloadProgress: true));
        return;
      }
      done++;
      final downloaded = state.selectedSetId == set.id ? {...state.downloadedKeys, semitone} : state.downloadedKeys;
      emit(state.copyWith(setDownloadProgress: done, downloadedKeys: downloaded));
    }
    emit(state.copyWith(clearSetDownloadProgress: true));
    MyToast.showText(text: 'padSetDownloaded'.tr(), typeNotification: TypeNotification.success);
  }

  void _changeFade(ChangePadFade event, Emitter<PadState> emit) {
    if (event.fadeInSeconds != null) padsRepository.fadeInSeconds = event.fadeInSeconds!;
    if (event.fadeOutSeconds != null) padsRepository.fadeOutSeconds = event.fadeOutSeconds!;
    if (event.curve != null) padsRepository.fadeCurve = event.curve!;
    emit(state.copyWith(fadeInSeconds: event.fadeInSeconds, fadeOutSeconds: event.fadeOutSeconds, fadeCurve: event.curve));
  }

  @override
  Future<void> close() async {
    await engine.dispose();
    return super.close();
  }
}

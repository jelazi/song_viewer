import 'package:bloc/bloc.dart';
import 'package:default_project/model/web_interpret.dart';
import 'package:default_project/repositories/web_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../../model/web_song.dart';
import '../../repositories/settings_repository.dart';

part 'web_event.dart';
part 'web_state.dart';

class WebBloc extends Bloc<WebEvent, WebState> {
  WebRepository webRepository;
  SettingsRepository settingsRepository;
  WebBloc({required this.webRepository, required this.settingsRepository})
      : super(WebInitial(
          currentSong: null,
          songs: const [],
          filteredSongs: const [],
          filteredInterprets: const [],
          currentInterpret: null,
          interprets: const [],
          searchWeb: 0,
          searchType: 0,
          isSearching: false,
          textStyle: const TextStyle(color: Colors.black, fontSize: 16),
          chordStyle: const TextStyle(color: Colors.red, fontSize: 16),
          appBarStatus: true,
          transposeIncrement: 0,
          scrollSpeed: 20,
        )) {
    on<_Init>(_init);
    on<ChangeCurrentWebSong>(_changeCurrentWebSong);
    on<ChangeCurrentInterpret>(_changeCurrentInterpret);
    on<FilterSongs>(_filterSongs);
    on<FilterInterprets>(_filterInterprets);
    on<LoadSongs>(_loadSongs);
    on<LoadInterprets>(_loadInterprets);
    on<ChangeSearchWeb>(_changeSearchWeb);
    on<ChangeSearchType>(_changeSearchType);
    on<TestWebEvent>(_testWebEvent);
    add(const _Init());
  }

  void _init(_Init event, Emitter<WebState> emit) async {
    final state = this.state;
    emit(state.copyWith(
      textStyle: TextStyle(fontSize: settingsRepository.previewFontTextSize, color: settingsRepository.previewColorText),
      chordStyle: TextStyle(
        fontSize: settingsRepository.previewFontChordSize,
        color: settingsRepository.previewColorChord,
      ),
    ));
    emit(state.copyWith(isSearching: true));
    final interpret = await webRepository.findInterpretPisnickyAkordy('a');

    emit(state.copyWith(
      isSearching: false,
      interprets: interpret,
      filteredInterprets: interpret,
    ));
  }

  void _changeCurrentWebSong(ChangeCurrentWebSong event, Emitter<WebState> emit) async {
    emit(state.copyWith(currentSong: event.song, currentInterpret: state.currentInterpret));
    final eventSong = event.song;
    if (eventSong != null) {
      WebSong currentSong = WebSong(title: eventSong.title, ref: eventSong.ref, interpret: eventSong.interpret);
      final text = await webRepository.getTextSongPisnickyAkordy(currentSong.ref);
      currentSong.lyric = text;
      emit(state.copyWith(currentSong: currentSong, currentInterpret: state.currentInterpret));
    }
  }

  void _changeCurrentInterpret(ChangeCurrentInterpret event, Emitter<WebState> emit) async {
    emit(state.copyWith(currentInterpret: event.interpret));
    if (event.interpret != null) {
      List<WebSong> songs = await webRepository.findSongOfInterpretPisnickyAkordy(event.interpret?.ref ?? '');
      if (songs.isNotEmpty) {
        emit(state.copyWith(currentInterpret: event.interpret, songs: songs, filteredSongs: songs, currentSong: null));
      }
    } else {
      emit(state.copyWith(currentInterpret: event.interpret, songs: [], filteredSongs: [], currentSong: null));
    }
  }

  void _filterSongs(FilterSongs event, Emitter<WebState> emit) async {
    if (event.filter.isEmpty) {
      emit(state.copyWith(filteredSongs: state.songs));
      return;
    }
    final List<WebSong> list = state.songs.where((element) => element.title.toLowerCase().contains(event.filter.toLowerCase())).toList();
    emit(state.copyWith(filteredSongs: list));
  }

  void _filterInterprets(FilterInterprets event, Emitter<WebState> emit) async {
    final state = this.state;
    if (event.filter.isEmpty) {
      emit(state.copyWith(interprets: [], isSearching: false, filteredInterprets: []));
    }
    final list = await webRepository.findInterpretPisnickyAkordy(event.filter);
    emit(state.copyWith(interprets: list, isSearching: false, filteredInterprets: list));
  }

  void _loadSongs(LoadSongs event, Emitter<WebState> emit) {}

  void _loadInterprets(LoadInterprets event, Emitter<WebState> emit) {}

  void _changeSearchWeb(ChangeSearchWeb event, Emitter<WebState> emit) {
    emit(state.copyWith(searchWeb: event.searchWeb));
  }

  void _changeSearchType(ChangeSearchType event, Emitter<WebState> emit) {
    emit(state.copyWith(searchType: event.searchType));
  }

  void _testWebEvent(TestWebEvent event, Emitter<WebState> emit) async {
    final state = this.state;
    final result = await webRepository.testGetSong();
  }
}

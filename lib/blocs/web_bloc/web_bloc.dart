import 'package:bloc/bloc.dart';
import 'package:default_project/model/web_interpret.dart';
import 'package:default_project/repositories/web_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

import '../../model/web_song.dart';

part 'web_event.dart';
part 'web_state.dart';

class WebBloc extends Bloc<WebEvent, WebState> {
  WebRepository webRepository;
  WebBloc({required this.webRepository})
      : super(WebInitial(
          currentSong: null,
          songs: const [],
          filteredSongs: const [],
          currentInterpret: null,
          interprets: const [],
          searchWeb: 0,
          searchType: 0,
        )) {
    on<ChangeCurrentWebSong>(_changeCurrentWebSong);
    on<ChangeCurrentInterpret>(_changeCurrentInterpret);
    on<FilterSongs>(_filterSongs);
    on<LoadSongs>(_loadSongs);
    on<LoadInterprets>(_loadInterprets);
    on<ChangeSearchWeb>(_changeSearchWeb);
    on<ChangeSearchType>(_changeSearchType);
  }

  void _changeCurrentWebSong(ChangeCurrentWebSong event, Emitter<WebState> emit) async {
    if (event.song == null) {
      emit(state.copyWith(currentSong: null));
      return;
    }
    WebSong currentSong = event.song!;
    switch (state.searchWeb) {
      case 0:
        break;
      case 1:
        currentSong = await webRepository.getTextSongVelkyZpevnik(event.song!);
        break;
    }
    emit(state.copyWith(currentSong: currentSong));
  }

  void _changeCurrentInterpret(ChangeCurrentInterpret event, Emitter<WebState> emit) {
    emit(state.copyWith(currentInterpret: event.interpret));
  }

  void _filterSongs(FilterSongs event, Emitter<WebState> emit) async {
    switch (state.searchWeb) {
      case 0:
        if (state.searchType == 0) {
          final list = await webRepository.findSongSupermusic(event.filter);
          emit(state.copyWith(filteredSongs: list));
          break;
        } else {
          final list = await webRepository.findInterpretSupermusic(event.filter);
          emit(state.copyWith(interprets: list));
          break;
        }
      case 1:
        if (state.searchType == 0) {
          final list = await webRepository.findSongVelkyZpevnik(event.filter);
          emit(state.copyWith(filteredSongs: list));
          break;
        } else {
          final list = await webRepository.findInterpretVelkyZpevnik(event.filter);
          emit(state.copyWith(interprets: list));
          break;
        }
    }
  }

  void _loadSongs(LoadSongs event, Emitter<WebState> emit) {}

  void _loadInterprets(LoadInterprets event, Emitter<WebState> emit) {}

  void _changeSearchWeb(ChangeSearchWeb event, Emitter<WebState> emit) {
    emit(state.copyWith(searchWeb: event.searchWeb));
  }

  void _changeSearchType(ChangeSearchType event, Emitter<WebState> emit) {
    emit(state.copyWith(searchType: event.searchType));
  }
}

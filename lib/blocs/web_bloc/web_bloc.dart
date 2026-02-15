import 'package:bloc/bloc.dart';
import 'package:default_project/model/web_interpret.dart';
import 'package:default_project/providers/hive_provider.dart';
import 'package:default_project/repositories/web_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../model/web_item.dart';
import '../../model/web_song.dart';
import '../../repositories/settings_repository.dart';

part 'web_event.dart';
part 'web_state.dart';

class WebBloc extends Bloc<WebEvent, WebState> {
  WebRepository webRepository;
  SettingsRepository settingsRepository;
  HiveProvider hiveProvider;
  WebBloc({required this.webRepository, required this.settingsRepository, required this.hiveProvider})
      : super(WebInitial(
          currentSong: null,
          songs: const [],
          filteredSongs: const [],
          filteredInterprets: const [],
          historyInterprets: const [],
          currentInterpret: WebInterpret(title: '', ref: ''),
          interprets: const [],
          searchWeb: 1,
          searchType: 0,
          isSearching: false,
          textStyle: const TextStyle(color: Colors.black, fontSize: 16),
          chordStyle: const TextStyle(color: Colors.red, fontSize: 16),
          appBarStatus: true,
          transposeIncrement: 0,
          scrollSpeed: 20,
          searchWebInterprets: false,
          searchWebSongs: false,
          downloadWebSong: false,
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

  final listSearchWeb = ['velkyzpevnik.cz', 'pisnicky-akordy.cz', 'zpevnik.proscholy.cz'];

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
    await webRepository.findInterpretPisnickyAkordy('a');
    final historyInterprets = hiveProvider.getInterpretsFromWebBox('pisnicky-akordy.cz');

    emit(state.copyWith(
      isSearching: false,
      historyInterprets: getLastTenInterpretsReverse(historyInterprets),
    ));
  }

  List<WebInterpret> getLastTenInterpretsReverse(List<WebInterpret> list) {
    return list.reversed.toList();
  }

  void _changeCurrentWebSong(ChangeCurrentWebSong event, Emitter<WebState> emit) async {
    emit(state.copyWith(currentSong: event.song, downloadWebSong: true));
    final eventSong = event.song;
    if (eventSong != null) {
      WebSong currentSong = WebSong(title: eventSong.title, ref: eventSong.ref, interpret: eventSong.interpret);
      var text = '';
      if (event.typeSearching == 'velkyzpevnik.cz') {
        currentSong.server = 'velkyzpevnik.cz';
        final savedSong = hiveProvider.getWebSong('velkyzpevnik.cz${currentSong.ref}');
        if (savedSong != null) {
          currentSong = savedSong;
        } else {
          currentSong.lyric = await webRepository.getTextSongVelkyZpevnik(currentSong);
          hiveProvider.setWebSong('velkyzpevnik.cz${currentSong.ref}', currentSong);
        }
      }
      if (event.typeSearching == 'pisnicky-akordy.cz') {
        currentSong.server = 'pisnicky-akordy.cz';
        final savedSong = hiveProvider.getWebSong('pisnicky-akordy.cz${currentSong.ref}');
        if (savedSong != null) {
          currentSong = savedSong;
        } else {
          currentSong.lyric = await webRepository.getTextSongPisnickyAkordy(currentSong.ref);
          hiveProvider.setWebSong('pisnicky-akordy.cz${currentSong.ref}', currentSong);
        }
      }
      if (event.typeSearching == 'zpevnik.proscholy.cz') {
        currentSong.server = 'zpevnik.proscholy.cz';
        final savedSong = hiveProvider.getWebSong('zpevnik.proscholy.cz${currentSong.ref}');
        if (savedSong != null) {
          currentSong = savedSong;
        } else {
          currentSong.lyric = await webRepository.getTextSongProScholy(currentSong.ref);
          hiveProvider.setWebSong('zpevnik.proscholy.cz${currentSong.ref}', currentSong);
        }
      }

      emit(state.copyWith(currentSong: currentSong, downloadWebSong: false));
    } else {
      emit(state.copyWith(currentSong: null, downloadWebSong: false));
    }
  }

  void _changeCurrentInterpret(ChangeCurrentInterpret event, Emitter<WebState> emit) async {
    emit(state.copyWith(currentInterpret: event.interpret, searchWebSongs: true));
    List<WebSong> songs = [];
    if (event.interpret != null) {
      if (state.searchWeb == 0 && event.interpret != null) {
        songs = await webRepository.findSongByInterpretFromVelkyZpevnik(event.interpret!);
      }
      if (state.searchWeb == 1) {
        songs = await webRepository.findSongOfInterpretPisnickyAkordy(event.interpret?.ref ?? '');
      }
      if (state.searchWeb == 2 && event.interpret != null) {
        songs = await webRepository.findSongByInterpretFromProScholy(event.interpret!);
      }
      hiveProvider.setHistoryInterpretToWebBox(listSearchWeb[state.searchWeb], event.interpret!);
      final historyInterprets = hiveProvider.getInterpretsFromWebBox(listSearchWeb[state.searchWeb]);
      if (songs.isNotEmpty) {
        emit(state.copyWith(
            currentInterpret: event.interpret,
            songs: songs,
            filteredSongs: songs,
            currentSong: null,
            searchWebSongs: false,
            historyInterprets: getLastTenInterpretsReverse(historyInterprets)));
      }
    } else {
      emit(state.copyWith(currentInterpret: WebInterpret(title: '', ref: ''), songs: [], filteredSongs: [], currentSong: null, searchWebSongs: false));
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
    List<WebInterpret> list = [];
    final state = this.state;
    emit(state.copyWith(isSearching: true));
    if (event.filter.isEmpty) {
      emit(state.copyWith(interprets: [], isSearching: false, filteredInterprets: [], searchWebInterprets: false));
    }
    if (state.searchWeb == 0) {
      List<WebItem> listItem = await webRepository.findSongAndInterpretsFromVelkyZpevnik(event.filter);
      list = listItem.map((e) => e is WebInterpret ? e : null).where((element) => element != null).toList().cast<WebInterpret>();
    }

    if (state.searchWeb == 1) {
      list = await webRepository.findInterpretPisnickyAkordy(event.filter);
    }
    if (state.searchWeb == 2) {
      list = await webRepository.findInterpretProScholy(event.filter);
      final searchedSongs = await webRepository.searchSongsProScholyLocal(event.filter);
      emit(state.copyWith(interprets: list, isSearching: false, filteredInterprets: list, searchWebInterprets: false, songs: searchedSongs, filteredSongs: searchedSongs));
      return;
    }
    emit(state.copyWith(interprets: list, isSearching: false, filteredInterprets: list, searchWebInterprets: false));
  }

  void _loadSongs(LoadSongs event, Emitter<WebState> emit) {}

  void _loadInterprets(LoadInterprets event, Emitter<WebState> emit) {}

  void _changeSearchWeb(ChangeSearchWeb event, Emitter<WebState> emit) {
    final historyInterprets = hiveProvider.getInterpretsFromWebBox(state.listSearchWeb[event.searchWeb]);
    emit(state.copyWith(
        searchWeb: event.searchWeb,
        currentSong: null,
        songs: [],
        filteredSongs: [],
        filteredInterprets: [],
        interprets: [],
        historyInterprets: getLastTenInterpretsReverse(historyInterprets),
        currentInterpret: WebInterpret(
          title: '',
          ref: '',
        )));
  }

  void _changeSearchType(ChangeSearchType event, Emitter<WebState> emit) {
    emit(state.copyWith(searchType: event.searchType, searchWebInterprets: false));
  }

  void _testWebEvent(TestWebEvent event, Emitter<WebState> emit) async {
    final state = this.state;
    final result = await webRepository.testGetSong();
  }
}

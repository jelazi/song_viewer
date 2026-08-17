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
    on<AddWebSearchHistory>(_addWebSearchHistory);
    on<ClearWebSearchHistory>(_clearWebSearchHistory);
    add(const _Init());
  }

  final listSearchWeb = ['velkyzpevnik.cz', 'pisnicky-akordy.cz', 'zpevnik.proscholy.cz', 'songs.worshipleaderapp.com', 'worshipchords.com'];

  void _init(_Init event, Emitter<WebState> emit) async {
    emit(state.copyWith(
      textStyle: TextStyle(fontSize: settingsRepository.previewFontTextSize, color: settingsRepository.previewColorText),
      chordStyle: TextStyle(
        fontSize: settingsRepository.previewFontChordSize,
        color: settingsRepository.previewColorChord,
      ),
    ));
    // No network call during init. The interpret list is populated lazily by
    // findInterpretPisnickyAkordy() on the first real search, so warming it up
    // here bought nothing and made startup depend on a third-party site being
    // reachable. Everything below is a local Hive read.
    final historyInterprets = hiveProvider.getInterpretsFromWebBox('pisnicky-akordy.cz');

    emit(state.copyWith(
      isSearching: false,
      historyInterprets: getLastTenInterpretsReverse(historyInterprets),
      searchHistory: hiveProvider.getSearchHistory(listSearchWeb[state.searchWeb]),
      allSearchHistory: hiveProvider.getAllSearchHistory(),
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
      try {
        if (event.typeSearching == 'velkyzpevnik.cz') {
          currentSong.server = 'velkyzpevnik.cz';
          final savedSong = hiveProvider.getWebSong('velkyzpevnik.cz${currentSong.ref}');
          if (savedSong != null && savedSong.lyric.isNotEmpty) {
            currentSong = savedSong;
          } else {
            currentSong.lyric = await webRepository.getTextSongVelkyZpevnik(currentSong);
            if (currentSong.lyric.isNotEmpty) {
              hiveProvider.setWebSong('velkyzpevnik.cz${currentSong.ref}', currentSong);
            }
          }
        }
        if (event.typeSearching == 'pisnicky-akordy.cz') {
          currentSong.server = 'pisnicky-akordy.cz';
          final savedSong = hiveProvider.getWebSong('pisnicky-akordy.cz${currentSong.ref}');
          if (savedSong != null && savedSong.lyric.isNotEmpty) {
            currentSong = savedSong;
          } else {
            currentSong.lyric = await webRepository.getTextSongPisnickyAkordy(currentSong.ref);
            // Fallback: try just the song slug if interpret/slug format failed
            if (currentSong.lyric.isEmpty && currentSong.ref.contains('/')) {
              final fallbackRef = currentSong.ref.split('/').last;
              debugPrint('[WEB_FALLBACK] trying slug=$fallbackRef');
              currentSong.lyric = await webRepository.getTextSongPisnickyAkordy(fallbackRef);
            }
            if (currentSong.lyric.isNotEmpty) {
              hiveProvider.setWebSong('pisnicky-akordy.cz${currentSong.ref}', currentSong);
            }
          }
        }
        if (event.typeSearching == 'zpevnik.proscholy.cz') {
          currentSong.server = 'zpevnik.proscholy.cz';
          final savedSong = hiveProvider.getWebSong('zpevnik.proscholy.cz${currentSong.ref}');
          if (savedSong != null && savedSong.lyric.isNotEmpty) {
            currentSong = savedSong;
          } else {
            currentSong.lyric = await webRepository.getTextSongProScholy(currentSong.ref);
            if (currentSong.lyric.isNotEmpty) {
              hiveProvider.setWebSong('zpevnik.proscholy.cz${currentSong.ref}', currentSong);
            }
          }
        }
        if (event.typeSearching == 'songs.worshipleaderapp.com') {
          currentSong.server = 'songs.worshipleaderapp.com';
          final savedSong = hiveProvider.getWebSong('songs.worshipleaderapp.com${currentSong.ref}');
          if (savedSong != null && savedSong.lyric.isNotEmpty) {
            currentSong = savedSong;
          } else {
            currentSong.lyric = await webRepository.getTextSongWorshipLeader(currentSong.ref);
            if (currentSong.lyric.isNotEmpty) {
              hiveProvider.setWebSong('songs.worshipleaderapp.com${currentSong.ref}', currentSong);
            }
          }
        }
        if (event.typeSearching == 'worshipchords.com') {
          currentSong.server = 'worshipchords.com';
          final savedSong = hiveProvider.getWebSong('worshipchords.com${currentSong.ref}');
          // Reuse the cache only when it actually holds lyrics; an empty entry
          // (e.g. a previous transient/blocked request) must be refetched.
          if (savedSong != null && savedSong.lyric.isNotEmpty) {
            currentSong = savedSong;
          } else {
            final data = await webRepository.getSongDataWorshipChords(currentSong.ref);
            currentSong.lyric = data.lyric;
            currentSong.youtube = data.youtube;
            // Never cache an empty result, otherwise the failure gets stuck.
            if (currentSong.lyric.isNotEmpty) {
              hiveProvider.setWebSong('worshipchords.com${currentSong.ref}', currentSong);
            }
          }
        }
      } catch (e) {
        debugPrint('[WEB_ERROR] Failed to load web song: $e');
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
      if (state.searchWeb == 4 && event.interpret != null) {
        songs = await webRepository.findSongByInterpretWorshipChords(event.interpret!);
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
    List<WebSong> songResults = [];
    emit(state.copyWith(isSearching: true));
    if (event.filter.isEmpty) {
      emit(state.copyWith(interprets: [], isSearching: false, filteredInterprets: [], searchWebInterprets: false));
      return;
    }
    final searchWeb = state.searchWeb;
    final isSongMode = state.searchType == 0;

    if (searchWeb == 0) {
      // VelkyZpevnik: typeahead returns both interprets and songs
      List<WebItem> listItem = await webRepository.findSongAndInterpretsFromVelkyZpevnik(event.filter);
      list = listItem.whereType<WebInterpret>().toList();
      if (isSongMode) {
        songResults = listItem.whereType<WebSong>().toList();
      }
    }

    if (searchWeb == 1) {
      if (isSongMode) {
        // Use MeiliSearch for direct song search
        songResults = await webRepository.findSongsPisnickyAkordy(event.filter);
        // If no songs found, also search interprets so user can browse their songs
        if (songResults.isEmpty) {
          list = await webRepository.findInterpretPisnickyAkordy(event.filter);
        }
      } else {
        list = await webRepository.findInterpretPisnickyAkordy(event.filter);
      }
    }

    if (searchWeb == 2) {
      list = await webRepository.findInterpretProScholy(event.filter);
      final searchedSongs = await webRepository.searchSongsProScholyLocal(event.filter);
      songResults = searchedSongs;
      emit(state.copyWith(
        interprets: list,
        isSearching: false,
        filteredInterprets: list,
        searchWebInterprets: false,
        songs: songResults,
        filteredSongs: songResults,
      ));
      return;
    }
    if (searchWeb == 3) {
      final searchedSongs = await webRepository.searchSongsWorshipLeader(event.filter);
      emit(state.copyWith(
        interprets: [],
        isSearching: false,
        filteredInterprets: [],
        searchWebInterprets: false,
        songs: searchedSongs,
        filteredSongs: searchedSongs,
      ));
      return;
    }
    if (searchWeb == 4) {
      if (isSongMode) {
        final searchedSongs = await webRepository.searchSongsWorshipChords(event.filter);
        emit(state.copyWith(
          interprets: [],
          isSearching: false,
          filteredInterprets: [],
          searchWebInterprets: false,
          songs: searchedSongs,
          filteredSongs: searchedSongs,
        ));
      } else {
        final foundInterprets = await webRepository.findInterpretWorshipChords(event.filter);
        emit(state.copyWith(
          interprets: foundInterprets,
          isSearching: false,
          filteredInterprets: foundInterprets,
          searchWebInterprets: false,
        ));
      }
      return;
    }
    emit(state.copyWith(
      interprets: list,
      isSearching: false,
      filteredInterprets: list,
      searchWebInterprets: false,
      songs: isSongMode ? songResults : state.songs,
      filteredSongs: isSongMode ? songResults : state.filteredSongs,
    ));
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
        searchHistory: hiveProvider.getSearchHistory(state.listSearchWeb[event.searchWeb]),
        allSearchHistory: hiveProvider.getAllSearchHistory(),
        currentInterpret: WebInterpret(
          title: '',
          ref: '',
        )));

  }

  void _changeSearchType(ChangeSearchType event, Emitter<WebState> emit) {
    emit(state.copyWith(searchType: event.searchType, searchWebInterprets: false));
  }

  void _testWebEvent(TestWebEvent event, Emitter<WebState> emit) async {
    await webRepository.testGetSong();
  }

  void _addWebSearchHistory(AddWebSearchHistory event, Emitter<WebState> emit) {
    final query = event.query.trim();
    if (query.isEmpty) return;
    final server = listSearchWeb[state.searchWeb];
    hiveProvider.addSearchHistory(server, query);
    emit(state.copyWith(
      searchHistory: hiveProvider.getSearchHistory(server),
      allSearchHistory: hiveProvider.getAllSearchHistory(),
    ));
  }

  void _clearWebSearchHistory(ClearWebSearchHistory event, Emitter<WebState> emit) {
    final server = listSearchWeb[state.searchWeb];
    hiveProvider.clearSearchHistory(server);
    emit(state.copyWith(
      searchHistory: hiveProvider.getSearchHistory(server),
      allSearchHistory: hiveProvider.getAllSearchHistory(),
    ));
  }
}

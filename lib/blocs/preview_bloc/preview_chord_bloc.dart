import 'package:default_project/model/web_song.dart';
import 'package:default_project/model/youtube_video.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/song/song.dart';
import '../../providers/hive_provider.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/songs_repository.dart';
import '../../repositories/web_repository.dart';
import '../../services/enums.dart';

part 'preview_chord_event.dart';
part 'preview_chord_state.dart';

class PreviewChordBloc extends Bloc<PreviewChordEvent, PreviewChordState> {
  final SettingsRepository settingsRepository;
  final SongsRepository songsRepository;
  final WebRepository webRepository;
  final HiveProvider hiveProvider;
  final double menuHeight = 140;

  PreviewChordBloc({
    required this.settingsRepository,
    required this.songsRepository,
    required this.webRepository,
    required this.hiveProvider,
  }) : super(PreviewChordInitial(
          data: CurrentData(song: null),
          textStyle: const TextStyle(),
          chordStyle: const TextStyle(),
          twoColumns: false,
          transposeIncrement: 0,
          scrollSpeed: 20,
          currentColumn: 0,
          maxLines: 20,
          appBarStatus: true,
          visibleButtons: false,
          cap: 0,
          selectedSongId: '',
          heightWindow: 300,
          isDataFromWeb: false,
        )) {
    on<_Init>(_init);
    on<ChangeCurrentSong>(_changeCurrentSong);
    on<ChangeTextFontSize>(_changeTextFontSize);
    on<ChangeChordFontSize>(_changeChordFontSize);
    on<ChangeFontSize>(_changeFontSize);
    on<ChangeAppBarStatus>(_changeAppBarStatus);
    on<ChangeVisibleButtons>(_changeVisibleButtons);
    on<TransposeChord>(_transposeChord);
    on<SelectSongInPreview>(_selectSong);
    on<ChangeColumnStatus>(_changeColumnStatus);
    on<ChangeHeightWindow>(_changeHeightWindow);
    on<ChangeCurrentColumn>(_changeCurrentColumn);
    on<ChangeLyricFromWebSongUpdate>(_changeLyricFromWebSongUpdate);
    on<UpdateSelectedSong>(_updateSelectedSong);

    songsRepository.selectSongData.listen((event) {
      add(UpdateSelectedSong(selectedSongId: event));
    });
    add(const _Init());
  }

  void _init(_Init event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    emit(state.copyWith(
      textStyle: TextStyle(fontSize: settingsRepository.previewFontTextSize, color: settingsRepository.previewColorText),
      twoColumns: settingsRepository.twoColumns,
      selectedSongId: songsRepository.selectedSongId,
      chordStyle: TextStyle(
        fontSize: settingsRepository.previewFontChordSize,
        color: settingsRepository.previewColorChord,
      ),
    ));
  }

  void _changeCurrentSong(ChangeCurrentSong event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    if (event.song == null) {
      emit(state.copyWith(data: state.data.copyWith(song: null), transposeIncrement: 0, cap: 0, currentColumn: 0));
      return;
    }

    final transposeIncrement = songsRepository.getTransposeForSong(event.song);

    if (state.textStyle.color != settingsRepository.previewColorText ||
        state.textStyle.fontSize != settingsRepository.previewFontTextSize ||
        state.chordStyle.color != settingsRepository.previewColorChord ||
        state.chordStyle.fontSize != settingsRepository.previewFontChordSize) {
      emit(state.copyWith(
          data: state.data.copyWith(song: event.song),
          textStyle: TextStyle(fontSize: settingsRepository.previewFontTextSize, color: settingsRepository.previewColorText),
          selectedSongId: songsRepository.selectedSongId,
          chordStyle: TextStyle(
            fontSize: settingsRepository.previewFontChordSize,
            color: settingsRepository.previewColorChord,
          ),
          transposeIncrement: transposeIncrement,
          cap: _getCapByIncrement(transposeIncrement),
          currentColumn: 0,
          isDataFromWeb: false));
    } else {
      emit(state.copyWith(
          data: state.data.copyWith(song: event.song),
          transposeIncrement: transposeIncrement,
          cap: _getCapByIncrement(transposeIncrement),
          currentColumn: 0,
          isDataFromWeb: false));
    }
  }

  void _changeTextFontSize(ChangeTextFontSize event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    settingsRepository.changeSettingsValue('previewFontTextSize', event.fontSize);
    emit(state.copyWith(textStyle: state.textStyle.copyWith(fontSize: event.fontSize)));
  }

  void _changeChordFontSize(ChangeChordFontSize event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    settingsRepository.changeSettingsValue('previewFontChordSize', event.fontSize);
    emit(state.copyWith(textStyle: state.chordStyle.copyWith(fontSize: event.fontSize)));
  }

  void _changeAppBarStatus(ChangeAppBarStatus event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    if (settingsRepository.autoHideTopBar) {
      emit(state.copyWith(appBarStatus: event.status));
    } else {
      emit(state.copyWith(appBarStatus: true));
    }
  }

  void _changeVisibleButtons(ChangeVisibleButtons event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    emit(state.copyWith(visibleButtons: event.status));
  }

  void _changeFontSize(ChangeFontSize event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    double fontSize = state.textStyle.fontSize!;
    double chordSize = state.chordStyle.fontSize!;
    if (event.isIncrease) {
      fontSize++;
      chordSize++;
    } else {
      fontSize--;
      chordSize--;
    }
    settingsRepository.changeSettingsValue('previewFontTextSize', fontSize);
    settingsRepository.changeSettingsValue('previewFontChordSize', chordSize);
    final textSizeHeight = this.textSizeHeight(state.textStyle.copyWith(fontSize: fontSize));
    int maxLines = (state.heightWindow - menuHeight) / textSizeHeight ~/ 1;
    emit(state.copyWith(textStyle: state.textStyle.copyWith(fontSize: fontSize), chordStyle: state.chordStyle.copyWith(fontSize: chordSize), maxLines: maxLines));
  }

  void _transposeChord(TransposeChord event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    int newIncrement = state.transposeIncrement + event.increment;
    if (newIncrement >= 12) {
      newIncrement = newIncrement - 12;
    }
    if (newIncrement <= -12) {
      newIncrement = newIncrement + 12;
    }

    songsRepository.changeTransposeChord(state.data.song!, newIncrement);
    emit(state.copyWith(transposeIncrement: newIncrement, cap: _getCapByIncrement(newIncrement)));
  }

  void _selectSong(SelectSongInPreview event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    songsRepository.selectSong(event.selectSongId, event.title, event.interpret, event.lyricsWithoutChords, event.lyricsWithChords);

    emit(state.copyWith(selectedSongId: songsRepository.selectedSongId));
  }

  int _getCapByIncrement(int increment) {
    int cap = 0;
    if (increment == 0) {
      cap = 0;
    } else {
      if (increment < 0) {
        cap = -1 * increment;
      } else {
        cap = 12 - increment;
      }
    }
    return cap;
  }

  void _changeColumnStatus(ChangeColumnStatus event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    final textSizeHeight = this.textSizeHeight(state.textStyle);
    int maxLines = (state.heightWindow - menuHeight) / textSizeHeight ~/ 1;
    settingsRepository.changeSettingsValue('twoColumns', event.status);
    emit(state.copyWith(twoColumns: event.status, maxLines: maxLines));
  }

  void _changeHeightWindow(ChangeHeightWindow event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    final textSizeHeight = this.textSizeHeight(state.textStyle);
    int maxLines = (event.height - menuHeight) / textSizeHeight ~/ 1;
    emit(state.copyWith(
      heightWindow: event.height,
      maxLines: maxLines,
    ));
  }

  void _changeCurrentColumn(ChangeCurrentColumn event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    if (event.column < 0) {
      emit(state.copyWith(currentColumn: 0));
      return;
    }
    final maxColumn = state.lyricWithColumns(true, true, TypeLyric.translate);
    if (maxColumn.length - 2 < event.column) {
      emit(state.copyWith(currentColumn: maxColumn.length - 1));
      return;
    }
    emit(state.copyWith(currentColumn: event.column));
  }

  void _updateSelectedSong(UpdateSelectedSong event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    emit(state.copyWith(selectedSongId: event.selectedSongId));
  }

  void _changeLyricFromWebSongUpdate(ChangeLyricFromWebSongUpdate event, Emitter<PreviewChordState> emit) async {
    final state = this.state;
    WebSong webSong = event.webSong;

    try {
      if (event.typeSearching == 0) {
        webSong.server = 'velkyzpevnik.cz';
        final savedSong = hiveProvider.getWebSong('velkyzpevnik.cz${webSong.ref}');
        if (savedSong != null) {
          webSong = savedSong;
        } else {
          webSong.lyric = await webRepository.getTextSongVelkyZpevnik(webSong);
          hiveProvider.setWebSong('velkyzpevnik.cz${webSong.ref}', webSong);
        }
      }
      if (event.typeSearching == 1) {
        webSong.server = 'pisnicky-akordy.cz';
        final savedSong = hiveProvider.getWebSong('pisnicky-akordy.cz${webSong.ref}');
        if (savedSong != null) {
          webSong = savedSong;
        } else {
          webSong.lyric = await webRepository.getTextSongPisnickyAkordy(webSong.ref);
          // Fallback: if first attempt returned empty, try just the slug (for songs without interpret prefix)
          if (webSong.lyric.isEmpty && webSong.ref.contains('/')) {
            final fallbackRef = webSong.ref.split('/').last;
            debugPrint('[PA_FALLBACK] trying slug=$fallbackRef');
            webSong.lyric = await webRepository.getTextSongPisnickyAkordy(fallbackRef);
            if (webSong.lyric.isEmpty) {
              debugPrint('[PA_FALLBACK] slug also failed');
            } else {
              debugPrint('[PA_FALLBACK] slug SUCCESS len=${webSong.lyric.length}');
            }
          }
          hiveProvider.setWebSong('pisnicky-akordy.cz${webSong.ref}', webSong);
        }
      }
      if (event.typeSearching == 2) {
        webSong.server = 'zpevnik.proscholy.cz';
        final savedSong = hiveProvider.getWebSong('zpevnik.proscholy.cz${webSong.ref}');
        if (savedSong != null) {
          webSong = savedSong;
        } else {
          webSong.lyric = await webRepository.getTextSongProScholy(webSong.ref);
          hiveProvider.setWebSong('zpevnik.proscholy.cz${webSong.ref}', webSong);
        }
      }
      if (event.typeSearching == 3) {
        webSong.server = 'songs.worshipleaderapp.com';
        final savedSong = hiveProvider.getWebSong('songs.worshipleaderapp.com${webSong.ref}');
        if (savedSong != null) {
          webSong = savedSong;
        } else {
          webSong.lyric = await webRepository.getTextSongWorshipLeader(webSong.ref);
          hiveProvider.setWebSong('songs.worshipleaderapp.com${webSong.ref}', webSong);
        }
      }
      if (event.typeSearching == 4) {
        webSong.server = 'worshipchords.com';
        final savedSong = hiveProvider.getWebSong('worshipchords.com${webSong.ref}');
        // Reuse the cache only when it actually holds lyrics; an empty entry
        // (e.g. a previous transient/blocked request) must be refetched.
        if (savedSong != null && savedSong.lyric.isNotEmpty) {
          webSong = savedSong;
        } else {
          final data = await webRepository.getSongDataWorshipChords(webSong.ref);
          webSong.lyric = data.lyric;
          webSong.youtube = data.youtube;
          // Never cache an empty result, otherwise the failure gets stuck.
          if (webSong.lyric.isNotEmpty) {
            hiveProvider.setWebSong('worshipchords.com${webSong.ref}', webSong);
          }
        }
      }
    } catch (e) {
      debugPrint('[PA_ERROR] Failed to load web song: $e');
    }

    webSong.title = webSong.title.replaceAll('  ', '');
    webSong.title = webSong.title.replaceAll('\n', '');
    Song song = Song(
      title: webSong.title,
      interpret: webSong.interpret,
      id: webSong.server + webSong.ref,
      lyrics: webSong.lyric,
      youtubeVideos: webSong.youtube.isNotEmpty ? [YoutubeVideo(name: webSong.title, path: webSong.youtube)] : null,
    );
    emit(state.copyWith(data: state.data.copyWith(song: song), currentColumn: 0, cap: 0, transposeIncrement: 0, isDataFromWeb: true));
  }

  List<String> lyricWithColumns(int maxLines, Song song, bool chords, bool notes, TypeLyric typeLyric) {
    List<String> listLines = typeLyric == TypeLyric.translate ? song.lyrics.split('\n') : (song.originalLyrics ?? '').split('\n');
    double realLines = 0;
    for (String line in listLines) {
      if (line.contains('[')) {
        realLines += 2;
      } else {
        realLines++;
      }
    }

    List<String> result = [];
    if (realLines <= maxLines) {
      result.add(typeLyric == TypeLyric.translate ? song.lyrics : song.originalLyrics ?? '');
      return result;
    }

    String item = '';
    int index = 0;
    for (String line in listLines) {
      item += '$line\n';
      if (index < maxLines) {
        if (line.contains('[')) {
          index += 2;
        } else {
          index++;
        }
      } else {
        result.add(item);
        item = '';
        index = 0;
      }
    }
    String it = item.replaceAll(' ', '');
    it = it.replaceAll('\n', '');

    if (it.isNotEmpty) {
      result.add(item);
    }

    return result;
  }

  double textSizeHeight(TextStyle textStyle) {
    final TextPainter textPainter = TextPainter(text: TextSpan(text: 'Firstline', style: textStyle), textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.height * 1.35;
  }
}

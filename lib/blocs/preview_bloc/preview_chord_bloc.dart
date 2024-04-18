import 'package:default_project/main.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../model/song/song.dart';
import '../../repositories/settings_repository.dart';
import '../../services/enums.dart';

part 'preview_chord_event.dart';
part 'preview_chord_state.dart';

class PreviewChordBloc extends Bloc<PreviewChordEvent, PreviewChordState> {
  SettingsRepository settingsRepository;
  final double menuHeight = 140;
  PreviewChordBloc({
    required this.settingsRepository,
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
    add(const _Init());
  }

  void _init(_Init event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    emit(state.copyWith(
        textStyle: TextStyle(fontSize: settingsRepository.previewFontTextSize, color: settingsRepository.previewColorText),
        twoColumns: settingsRepository.twoColumns,
        chordStyle: TextStyle(
          fontSize: settingsRepository.previewFontChordSize,
          color: settingsRepository.previewColorChord,
        )));
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
          currentColumn: 0));
    } else {
      emit(state.copyWith(data: state.data.copyWith(song: event.song), transposeIncrement: transposeIncrement, cap: _getCapByIncrement(transposeIncrement), currentColumn: 0));
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

    songsRepository.changeTransposeChord(state.data.song, newIncrement);
    emit(state.copyWith(transposeIncrement: newIncrement, cap: _getCapByIncrement(newIncrement)));
  }

  void _selectSong(SelectSongInPreview event, Emitter<PreviewChordState> emit) {
    final state = this.state;
    songsRepository.selectSong(event.selectSongId);
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

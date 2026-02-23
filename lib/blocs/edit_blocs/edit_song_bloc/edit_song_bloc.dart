import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../../model/song/song.dart';
import '../../../model/youtube_video.dart';
import '../../../services/enums.dart';
import '../../../view/mobile_view/widgets/chords_lyric/chord_parser.dart' as chordParser;

part 'edit_song_event.dart';
part 'edit_song_state.dart';

class EditSongBloc extends Bloc<EditSongEvent, EditSongState> {
  SongsRepository songsRepository;
  SettingsRepository settingsRepository;

  EditSongBloc({required this.songsRepository, required this.settingsRepository})
      : super(EditSongInitial(
          currentEditSong: Song.empty(),
          textStyle: const TextStyle(),
          chordStyle: const TextStyle(),
          selectChord: '',
          listUniqueChords: const [],
          transposeIncrement: 0,
          selectChordIndex: -1,
          listUniqueChordsIsVisible: false,
          currentText: '',
          selectedChord: -1,
          isOriginalLyrics: false,
          listAllGroups: const [],
          currentGroups: const [],
          titleController: TextEditingController(),
          interpretController: TextEditingController(),
          indexSongBookController: TextEditingController(),
          title: '',
          interpret: '',
          indexSongBook: '',
          tags: const [],
          notes: const [],
        )) {
    on<_Init>(_init);
    on<ChangeEditSong>(_changeEditSong);
    on<ChangeSongValue>(_changeSongValue);
    on<CheckModifiedSong>(_checkModifiedSong);
    on<ResetValue>(_resetValue);
    on<TransposeChordPermanent>(_transposeChords);
    on<ChangeFontSizeEdit>(_changeFontSizeEdit);
    on<SelectChord>(_selectChord);
    on<ChangeListUniqueChordsIsVisible>(_changeListUniqueChordsIsVisible);
    on<UpdateListUniqueChords>(_updateListUniqueChords);
    on<ChangePositionChord>(_changePositionChord);
    on<ChangeChord>(_changeChord);
    on<CreateChord>(_createChord);
    on<DeleteChord>(_deleteChord);
    on<SaveSong>(_saveSong);
    on<CreateNewSong>(_createNewSong);
    on<ChangeGroupForCurrentSong>(_changeGroupForCurrentSong);
    on<DeleteCurrentSong>(_deleteCurrentSong);
    on<AddYoutubeVideo>(_addYoutubeVideo);
    on<RemoveYoutubeVideo>(_removeYoutubeVideo);
    on<UpdateYoutubeVideo>(_updateYoutubeVideo);
    on<AddSheet>(_addSheet);
    on<RemoveSheet>(_removeSheet);

    add(const _Init());
  }

  void _init(_Init event, Emitter<EditSongState> emit) {
    final state = this.state;
    emit(state.copyWith(
      textStyle: TextStyle(fontSize: settingsRepository.previewFontTextSize, color: settingsRepository.previewColorText),
      chordStyle: TextStyle(
        fontSize: settingsRepository.previewFontChordSize,
        color: settingsRepository.previewColorChord,
      ),
      listAllGroups: songsRepository.listAllGroups,
    ));
  }

  void _changeEditSong(ChangeEditSong event, Emitter<EditSongState> emit) {
    final state = this.state;
    if (state.textStyle.color != settingsRepository.previewColorText ||
        state.textStyle.fontSize != settingsRepository.previewFontTextSize ||
        state.chordStyle.color != settingsRepository.previewColorChord ||
        state.chordStyle.fontSize != settingsRepository.previewFontChordSize) {
      emit(state.copyWith(
        currentEditSong: event.song,
        listUniqueChords: event.song.getAllUniqueChordsFromSong(event.isOriginalLyrics ? TypeLyric.original : TypeLyric.translate),
        textStyle: TextStyle(fontSize: settingsRepository.previewFontTextSize, color: settingsRepository.previewColorText),
        currentText: event.isOriginalLyrics ? event.song.originalLyrics ?? '' : event.song.lyrics,
        selectedChord: -1,
        currentGroups: event.song.groups ?? [],
        isOriginalLyrics: event.isOriginalLyrics,
        chordStyle: TextStyle(
          fontSize: settingsRepository.previewFontChordSize,
          color: settingsRepository.previewColorChord,
        ),
        titleController: TextEditingController(text: event.song.title),
        interpretController: TextEditingController(text: event.song.interpret),
        indexSongBookController: TextEditingController(text: (event.song.indexSongBook == null) ? '' : event.song.indexSongBook.toString()),
        title: event.song.title,
        interpret: event.song.interpret ?? '',
        indexSongBook: (event.song.indexSongBook == null) ? '' : event.song.indexSongBook.toString(),
        tags: event.song.tags ?? [],
      ));
    } else {
      emit(state.copyWith(
        currentText: event.isOriginalLyrics ? event.song.originalLyrics ?? '' : event.song.lyrics,
        isOriginalLyrics: event.isOriginalLyrics,
        currentEditSong: event.song,
        currentGroups: event.song.groups ?? [],
        selectedChord: -1,
        listUniqueChords: event.song.getAllUniqueChordsFromSong(event.isOriginalLyrics ? TypeLyric.original : TypeLyric.translate),
        titleController: TextEditingController(text: event.song.title),
        interpretController: TextEditingController(text: event.song.interpret),
        indexSongBookController: TextEditingController(text: (event.song.indexSongBook == null) ? '' : event.song.indexSongBook.toString()),
        title: event.song.title,
        interpret: event.song.interpret ?? '',
        indexSongBook: (event.song.indexSongBook == null) ? '' : event.song.indexSongBook.toString(),
        tags: event.song.tags ?? [],
      ));
    }
  }

  void _changeSongValue(ChangeSongValue event, Emitter<EditSongState> emit) {
    final state = this.state;
    if (event.appVersion == 'desktop') {
      switch (event.nameValue) {
        case 'title':
          {
            emit(state.copyWith(
              titleController: TextEditingController(
                text: event.value,
              )..selection = event.selection ?? TextSelection.collapsed(offset: event.value.length),
            ));

            break;
          }
        case 'interpret':
          {
            emit(state.copyWith(
                interpretController: TextEditingController(
              text: event.value,
            )..selection = event.selection ?? TextSelection.collapsed(offset: event.value.length)));
            break;
          }
        case 'indexSongBook':
          {
            emit(state.copyWith(
                indexSongBookController: TextEditingController(
              text: event.value,
            )..selection = event.selection ?? TextSelection.collapsed(offset: event.value.length)));
            break;
          }
        case 'lyrics':
          {
            emit(
              state.copyWith(currentText: event.value),
            );
            break;
          }
        case 'originalLyrics':
          {
            emit(state.copyWith(
              currentEditSong: state.currentEditSong.copyWith(
                originalLyrics: event.value,
              ),
            ));
            break;
          }
        case 'groups':
          {
            emit(state.copyWith(
              currentEditSong: state.currentEditSong.copyWith(
                groups: event.value,
              ),
            ));
            break;
          }
      }
    }
    if (event.appVersion == 'tablet') {
      switch (event.nameValue) {
        case 'title':
          {
            emit(state.copyWith(title: event.value));
            break;
          }
        case 'interpret':
          {
            emit(state.copyWith(interpret: event.value));
            break;
          }
        case 'indexSongBook':
          {
            emit(state.copyWith(indexSongBook: event.value));
            break;
          }
        case 'lyrics':
          {
            emit(state.copyWith(currentText: event.value));
            break;
          }
        case 'originalLyrics':
          {
            break;
          }
        case 'tags':
          {
            emit(state.copyWith(tags: event.value));
            break;
          }
        case 'groups':
          {
            emit(state.copyWith(currentGroups: event.value));
            break;
          }
      }
    }
    if (event.appVersion == 'mobile') {
      switch (event.nameValue) {
        case 'title':
          {
            emit(state.copyWith(title: event.value));
            break;
          }
        case 'interpret':
          {
            emit(state.copyWith(interpret: event.value));
            break;
          }
        case 'indexSongBook':
          {
            emit(state.copyWith(indexSongBook: event.value));
            break;
          }
        case 'lyrics':
          {
            emit(state.copyWith(currentText: event.value));
            break;
          }
        case 'originalLyrics':
          {
            break;
          }
      }
    }
  }

  void _checkModifiedSong(CheckModifiedSong event, Emitter<EditSongState> emit) {
    final state = this.state;
    final oldSong = songsRepository.getSongById(state.currentEditSong.id);
    if (oldSong != null) {
      final listModified = oldSong.checkModifiedSong(state.currentEditSong, false);
      if (listModified.isNotEmpty) {
        print('Modified: $listModified');
      }
    }
  }

  void _resetValue(ResetValue event, Emitter<EditSongState> emit) {
    final state = this.state;
    final oldSong = songsRepository.getSongById(state.currentEditSong.id);
    switch (event.nameValue) {
      case 'lyrics':
        {
          emit(state.copyWith(
            currentEditSong: state.currentEditSong.copyWith(
              lyrics: oldSong?.lyrics ?? '',
            ),
          ));
          break;
        }
      case 'originalLyrics':
        {
          emit(state.copyWith(
            currentEditSong: state.currentEditSong.copyWith(
              originalLyrics: oldSong?.originalLyrics ?? '',
            ),
          ));
          break;
        }
    }
  }

  void _transposeChords(TransposeChordPermanent event, Emitter<EditSongState> emit) {
    final state = this.state;
    var lyric = state.currentText;
    var newLyric = '';
    try {
      RegExp exp = RegExp(r'\[[^\]]+\]');

      newLyric = lyric.replaceAllMapped(exp, (match) {
        String? result = (match.group(0));

        if (result == null) return '';
        result = result.replaceFirst(RegExp(r'\['), '');
        result = result.replaceFirst(RegExp(r'\]'), '');
        result = chordParser.ChordProcessor.transposeChord(result, event.transposeIncrement, TypeTranspose.czech);
        result = '[$result]';
        return result;
      });
    } catch (e) {}

    final Song newSong = state.currentEditSong.copyWith(
      lyrics: event.isOriginalLyric ? state.currentEditSong.lyrics : newLyric,
      originalLyrics: event.isOriginalLyric ? newLyric : state.currentEditSong.originalLyrics,
    );
    final listUniqueChords = newSong.getAllUniqueChordsFromSong(event.isOriginalLyric ? TypeLyric.original : TypeLyric.translate);
    emit(state.copyWith(currentText: newLyric, listUniqueChords: listUniqueChords, selectChord: '', transposeIncrement: event.transposeIncrement));
  }

  void _changeFontSizeEdit(ChangeFontSizeEdit event, Emitter<EditSongState> emit) {
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
    settingsRepository.changeSettingsValue('fontTextSize', fontSize);
    settingsRepository.changeSettingsValue('fontChordSize', chordSize);
    emit(state.copyWith(textStyle: state.textStyle.copyWith(fontSize: fontSize), chordStyle: state.chordStyle.copyWith(fontSize: chordSize)));
  }

  void _selectChord(SelectChord event, Emitter<EditSongState> emit) {
    final state = this.state;

    emit(state.copyWith(selectedChord: state.selectedChord == event.index ? -1 : event.index));
  }

  void _changeListUniqueChordsIsVisible(ChangeListUniqueChordsIsVisible event, Emitter<EditSongState> emit) {
    final state = this.state;
    emit(state.copyWith(listUniqueChordsIsVisible: event.isVisible));
  }

  void _updateListUniqueChords(UpdateListUniqueChords event, Emitter<EditSongState> emit) {
    final state = this.state;
    final listUniqueChords = state.currentEditSong.getAllUniqueChordsFromSong(event.typeLyric);
    emit(state.copyWith(listUniqueChords: listUniqueChords));
  }

  void _changePositionChord(ChangePositionChord event, Emitter<EditSongState> emit) {
    final state = this.state;
    var text = state.currentText;
    final lastIndex = event.index;
    var firstIndex = event.index;
    for (int i = lastIndex; i >= 0; i--) {
      if (text[i] == '[') {
        firstIndex = i;
        break;
      }
    }
    var newFirstIndex = firstIndex;
    if (event.increase) {
      if (lastIndex == text.length - 1) {
        return;
      }
      final chord = text.substring(firstIndex, lastIndex + 1);
      text = text.replaceRange(firstIndex, lastIndex + 1, '');
      newFirstIndex = firstIndex + 1;
      if (text[firstIndex + 1] == '[') {
        for (int i = firstIndex + 1; i < text.length; i++) {
          if (text[i] == ']') {
            newFirstIndex = i + 1;
            break;
          }
        }
      }
      text = text.replaceRange(newFirstIndex, newFirstIndex, chord);
    } else {
      if (firstIndex == 0) {
        return;
      }
      final chord = text.substring(firstIndex, lastIndex + 1);
      text = text.replaceRange(firstIndex, lastIndex + 1, '');
      newFirstIndex = firstIndex - 1;
      if (text[firstIndex - 1] == ']') {
        for (int i = firstIndex - 1; i >= 0; i--) {
          if (text[i] == '[') {
            newFirstIndex = i;
            break;
          }
        }
      }
      text = text.replaceRange(newFirstIndex, newFirstIndex, chord);
    }

    var newLastIndex = lastIndex + (newFirstIndex - firstIndex);

    emit(state.copyWith(currentText: text, selectedChord: newLastIndex));
  }

  void _changeChord(ChangeChord event, Emitter<EditSongState> emit) {
    final state = this.state;
    var text = state.currentText;
    final lastIndex = event.index;
    var firstIndex = event.index;
    for (int i = lastIndex; i >= 0; i--) {
      if (text[i] == '[') {
        firstIndex = i;
        break;
      }
    }
    text = text.replaceRange(firstIndex, lastIndex + 1, '[${event.chord}]');
    Song currentSong = Song(id: '0', title: '', lyrics: text);
    emit(state.copyWith(
        currentText: text, listUniqueChords: currentSong.getAllUniqueChordsFromSong(state.isOriginalLyrics ? TypeLyric.original : TypeLyric.translate), selectedChord: -1));
  }

  void _createChord(CreateChord event, Emitter<EditSongState> emit) {
    final state = this.state;
    var text = state.currentText;
    // insert chord on index
    text = text.replaceRange(event.index, event.index, '[${event.chord}]');
    Song currentSong = Song(id: '0', title: '', lyrics: text);
    emit(state.copyWith(
        currentText: text, listUniqueChords: currentSong.getAllUniqueChordsFromSong(state.isOriginalLyrics ? TypeLyric.original : TypeLyric.translate), selectedChord: -1));
  }

  void _deleteChord(DeleteChord event, Emitter<EditSongState> emit) {
    final state = this.state;
    var text = state.currentText;
    final lastIndex = event.index;
    var firstIndex = event.index;
    for (int i = lastIndex; i >= 0; i--) {
      if (text[i] == '[') {
        firstIndex = i;
        break;
      }
    }

    text = text.replaceRange(firstIndex, lastIndex + 1, '');
    Song currentSong = Song(id: '0', title: '', lyrics: text);
    emit(state.copyWith(
        currentText: text,
        listUniqueChords: currentSong.getAllUniqueChordsFromSong(
          TypeLyric.translate,
        ),
        selectedChord: -1));
  }

  void _saveSong(SaveSong event, Emitter<EditSongState> emit) async {
    final state = this.state;
    if (event.typeApp == 'desktop') {
      var song = state.currentEditSong;
      bool isChanged = false;
      if (state.isOriginalLyrics) {
        if (song.originalLyrics != state.currentText) {
          song = song.copyWith(originalLyrics: state.currentText);
          isChanged = true;
        }
      } else {
        if (song.lyrics != state.currentText) {
          song = song.copyWith(lyrics: state.currentText);
          isChanged = true;
        }
      }
      if (song.title != state.titleController.text) {
        song = song.copyWith(title: state.titleController.text);
        isChanged = true;
      }
      if (song.interpret != state.interpretController.text) {
        song = song.copyWith(interpret: state.interpretController.text);
        isChanged = true;
      }
      if (state.indexSongBookController.text.isNotEmpty) {
        if (song.indexSongBook != int.parse(state.indexSongBookController.text)) {
          song = song.copyWith(indexSongBook: int.parse(state.indexSongBookController.text));
          isChanged = true;
        }
      }
      if (song.groups != state.currentGroups) {
        song = song.copyWith(groups: state.currentGroups);
        isChanged = true;
      }
      // YouTube videos and sheets are modified directly on currentEditSong,
      // so compare against the original song from repository
      final originalSong = songsRepository.getSongById(song.id);
      if (originalSong != null) {
        if (song.youtubeVideos?.length != originalSong.youtubeVideos?.length || song.youtubeVideos.toString() != originalSong.youtubeVideos.toString()) {
          isChanged = true;
        }
        if (song.sheets?.length != originalSong.sheets?.length || song.sheets.toString() != originalSong.sheets.toString()) {
          isChanged = true;
        }
      } else if (song.id.isEmpty) {
        // New song — always changed
        isChanged = true;
      }
      if (isChanged) {
        if (song.id.isEmpty) {
          song.generateId();
        }
        await songsRepository.updateSong(song);
        await songsRepository.updateSongsFromFirebase();
      }
      emit(state.copyWith(currentEditSong: song, selectedChord: -1));
    } else if (event.typeApp == 'tablet') {
      var song = state.currentEditSong;
      if (song.title != state.title) {
        song = song.copyWith(title: state.title);
      }
      if (song.interpret != state.interpret) {
        song = song.copyWith(interpret: state.interpret);
      }
      if (state.indexSongBook.isNotEmpty) {
        var indexSongBook = int.tryParse(state.indexSongBook);
        if (indexSongBook != null) {
          song = song.copyWith(indexSongBook: indexSongBook);
        }
      }
      if (song.lyrics != state.currentText) {
        song = song.copyWith(lyrics: state.currentText);
      }
      if (song.tags != state.tags) {
        song = song.copyWith(tags: state.tags);
      }
      if (song.groups != state.currentGroups) {
        song = song.copyWith(groups: state.currentGroups);
      }
      await songsRepository.updateSong(song);
      await songsRepository.updateSongsFromFirebase();
    }
  }

  void _createNewSong(CreateNewSong event, Emitter<EditSongState> emit) {
    final state = this.state;

    emit(state.copyWith(
      currentEditSong: event.song,
      listUniqueChords: event.song.getAllUniqueChordsFromSong(TypeLyric.translate),
      currentText: event.song.lyrics,
      selectedChord: -1,
      titleController: TextEditingController(text: event.song.title),
      interpretController: TextEditingController(text: event.song.interpret),
      indexSongBookController: TextEditingController(text: (event.song.indexSongBook == null) ? '' : event.song.indexSongBook.toString()),
      currentGroups: [],
      isOriginalLyrics: false,
    ));
  }

  void _changeGroupForCurrentSong(ChangeGroupForCurrentSong event, Emitter<EditSongState> emit) {
    final state = this.state;
    var currentGroup = List<String>.from(state.currentGroups);
    if (currentGroup.contains(event.group)) {
      currentGroup.remove(event.group);
    } else {
      currentGroup.add(event.group);
    }

    emit(state.copyWith(currentGroups: currentGroup));
  }

  bool checkModifiedSong() {
    final state = this.state;
    final oldSong = state.currentEditSong;
    if (oldSong.title != state.titleController.text || (oldSong.interpret ?? '') != state.interpretController.text) {
      return true;
    }
    final sortOldGroups = List<String>.from(oldSong.groups ?? [])..sort();
    final sortCurrentGroups = List<String>.from(state.currentGroups)..sort();
    if (sortOldGroups.toString() != sortCurrentGroups.toString()) {
      return true;
    }
    if (state.indexSongBookController.text.isNotEmpty) {
      if (oldSong.indexSongBook != int.parse(state.indexSongBookController.text)) {
        return true;
      }
    }
    if (state.isOriginalLyrics) {
      if (oldSong.originalLyrics != state.currentText) {
        return true;
      }
    } else {
      if (oldSong.lyrics != state.currentText) {
        return true;
      }
    }
    // Check youtube videos and sheets
    if (oldSong.youtubeVideos?.length != state.currentEditSong.youtubeVideos?.length || oldSong.youtubeVideos.toString() != state.currentEditSong.youtubeVideos.toString()) {
      return true;
    }
    if (oldSong.sheets?.length != state.currentEditSong.sheets?.length || oldSong.sheets.toString() != state.currentEditSong.sheets.toString()) {
      return true;
    }
    return false;
  }

  void _deleteCurrentSong(DeleteCurrentSong event, Emitter<EditSongState> emit) async {
    final state = this.state;
    final result = await songsRepository.deleteSong(state.currentEditSong.id);
    if (result) {
      emit(state.copyWith(
        currentEditSong: null,
        selectedChord: -1,
        currentText: '',
        titleController: TextEditingController(),
        interpretController: TextEditingController(),
        indexSongBookController: TextEditingController(),
        currentGroups: [],
      ));
    }
  }

  void _addYoutubeVideo(AddYoutubeVideo event, Emitter<EditSongState> emit) {
    final state = this.state;
    final videos = List<YoutubeVideo>.from(state.currentEditSong.youtubeVideos ?? []);
    videos.add(event.video);
    emit(state.copyWith(
      currentEditSong: state.currentEditSong.copyWith(youtubeVideos: videos),
    ));
  }

  void _removeYoutubeVideo(RemoveYoutubeVideo event, Emitter<EditSongState> emit) {
    final state = this.state;
    final videos = List<YoutubeVideo>.from(state.currentEditSong.youtubeVideos ?? []);
    if (event.index >= 0 && event.index < videos.length) {
      videos.removeAt(event.index);
      emit(state.copyWith(
        currentEditSong: state.currentEditSong.copyWith(youtubeVideos: videos),
      ));
    }
  }

  void _updateYoutubeVideo(UpdateYoutubeVideo event, Emitter<EditSongState> emit) {
    final state = this.state;
    final videos = List<YoutubeVideo>.from(state.currentEditSong.youtubeVideos ?? []);
    if (event.index >= 0 && event.index < videos.length) {
      videos[event.index] = event.video;
      emit(state.copyWith(
        currentEditSong: state.currentEditSong.copyWith(youtubeVideos: videos),
      ));
    }
  }

  void _addSheet(AddSheet event, Emitter<EditSongState> emit) {
    final state = this.state;
    final sheets = List<String>.from(state.currentEditSong.sheets ?? []);
    sheets.add(event.sheetUrl);
    emit(state.copyWith(
      currentEditSong: state.currentEditSong.copyWith(sheets: sheets),
    ));
  }

  void _removeSheet(RemoveSheet event, Emitter<EditSongState> emit) {
    final state = this.state;
    final sheets = List<String>.from(state.currentEditSong.sheets ?? []);
    if (event.index >= 0 && event.index < sheets.length) {
      sheets.removeAt(event.index);
      emit(state.copyWith(
        currentEditSong: state.currentEditSong.copyWith(sheets: sheets),
      ));
    }
  }
}

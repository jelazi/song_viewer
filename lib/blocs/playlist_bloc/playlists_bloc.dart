import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/repositories/playlist_repository.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:default_project/view/desktop_view/widgets/my_toast.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../../model/playlist.dart';
import '../../model/song/song.dart';
import '../../repositories/settings_repository.dart';
import '../../services/enums.dart';

part 'playlists_event.dart';
part 'playlists_state.dart';

class PlaylistsBloc extends Bloc<PlaylistsEvent, PlaylistsState> {
  PlaylistRepository playlistRepository;
  SongsRepository songsRepository;
  SettingsRepository settingsRepository;
  final double menuHeight = 140;
  PlaylistsBloc({required this.playlistRepository, required this.songsRepository, required this.settingsRepository})
      : super(PlaylistsInitial(
          playlists: const [],
          currentPlaylist: Playlist(id: null, name: ''),
          namePlaylist: '',
          currentSongs: const [],
          allSongs: const [],
          filteredSongs: const [],
          heightWindow: 0,
          currentSong: Song(id: '', title: '', lyrics: ''),
          selectedSongId: '',
          textStyle: const TextStyle(),
          chordStyle: const TextStyle(),
          appBarStatus: false,
          transposeIncrement: 0,
          scrollSpeed: 0,
          currentColumn: 0,
          maxLines: 0,
          cap: 0,
          indexCurrentSongInPlaylist: 0,
        )) {
    on<_Init>(_init);
    on<OpenPlaylist>(_openPlaylist);
    on<FilterSongPlaylist>(_filterSongPlaylist);
    on<ClosePlaylist>(_closePlaylist);
    on<SavePlaylist>(_savePlaylist);
    on<DeletePlaylist>(_deletePlaylist);
    on<AddSongToPlaylist>(_addSongToPlaylist);
    on<RemoveSongFromPlaylist>(_removeSongFromPlaylist);
    on<ChangeNamePlaylist>(_changeNamePlaylist);
    on<ChangeAppBarStatusPlaylist>(_changeAppBarStatusPlaylist);
    on<ChangeHeightWindowPlaylist>(_changeHeightWindowPlaylist);
    on<ChangeFontSizePlaylist>(_changeFontSizePlaylist);
    on<TransposeChordPlaylist>(_transposeChordPlaylist);
    on<SelectSongInPreviewPlaylist>(_selectSongInPreviewPlaylist);
    on<ChangeCurrentColumnPlaylist>(_changeCurrentColumnPlaylist);
    on<MoveSongInPlaylist>(_moveSongInPlaylist);

    add(const _Init());
  }

  void _init(_Init event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    emit(state.copyWith(
      playlists: playlistRepository.playlists,
      allSongs: songsRepository.songs,
      filteredSongs: [],
      textStyle: TextStyle(fontSize: settingsRepository.previewFontTextSize, color: settingsRepository.previewColorText),
      chordStyle: TextStyle(
        fontSize: settingsRepository.previewFontChordSize,
        color: settingsRepository.previewColorChord,
      ),
    ));
  }

  void _filterSongPlaylist(FilterSongPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    emit(state.copyWith(filteredSongs: songsRepository.getSongByFilter(event.filter)));
  }

  void _openPlaylist(OpenPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    List<Song> currentSongs = [];
    if (event.playlist != null) {
      for (var songId in event.playlist!.listSongIds) {
        final song = state.allSongs.firstWhere((element) => element.id == songId);
        currentSongs.add(song);
      }
    }
    if (event.forEdit) {
      var playlist = event.playlist;
      if (playlist == null) {
        emit(state.copyWith(currentPlaylist: Playlist(id: null, name: ''), currentSongs: []));
        return;
      }

      emit(state.copyWith(currentPlaylist: event.playlist, currentSongs: currentSongs, filteredSongs: [], namePlaylist: playlist.name));
    } else {
      emit(state.copyWith(
          currentSongs: currentSongs,
          filteredSongs: [],
          currentSong: currentSongs.isNotEmpty ? currentSongs[0] : state.currentSong,
          indexCurrentSongInPlaylist: currentSongs.isNotEmpty ? 0 : state.indexCurrentSongInPlaylist));
    }
  }

  void _closePlaylist(ClosePlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    emit(state.copyWith(
      currentPlaylist: Playlist(id: null, name: ''),
      currentSongs: [],
      currentSong: Song(id: '', title: '', lyrics: ''),
      selectedSongId: '',
      indexCurrentSongInPlaylist: 0,
      currentColumn: 0,
    ));
  }

  void _savePlaylist(SavePlaylist event, Emitter<PlaylistsState> emit) async {
    final state = this.state;
    final playlist = state.currentPlaylist;
    if (state.namePlaylist.isEmpty) {
      MyToast.showText(text: 'Name is empty', typeNotification: TypeNotification.warning);
      return;
    }
    if (state.currentSongs.isEmpty) {
      MyToast.showText(text: 'No song', typeNotification: TypeNotification.warning);
      return;
    }
    final isChange = checkSongChange();
    if (isChange.isEmpty) {
      MyToast.showText(text: 'No change', typeNotification: TypeNotification.warning);
      return;
    }
    playlist.name = state.namePlaylist;
    playlist.listSongIds = state.currentSongs.map((e) => e.id).toList();
    await playlistRepository.savePlaylist(playlist);
    logger.d(playlist.toJson());
    MyToast.showText(text: 'Playlist saved', typeNotification: TypeNotification.success);
    emit(state.copyWith(playlists: List<Playlist>.from(playlistRepository.playlists)));
  }

  void _deletePlaylist(DeletePlaylist event, Emitter<PlaylistsState> emit) async {
    final state = this.state;
    await playlistRepository.deletePlaylist(event.playlist);
    MyToast.showText(text: 'Playlist deleted', typeNotification: TypeNotification.success);
    emit(state.copyWith(playlists: playlistRepository.playlists));
  }

  void _addSongToPlaylist(AddSongToPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    final song = event.song;
    emit(state.copyWith(
      currentSongs: [...state.currentSongs, song],
    ));
  }

  void _removeSongFromPlaylist(RemoveSongFromPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    var currentSongs = List<Song>.from(state.currentSongs);
    currentSongs.removeAt(event.index);
    emit(state.copyWith(
      currentSongs: currentSongs,
    ));
  }

  void _changeNamePlaylist(ChangeNamePlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    emit(state.copyWith(namePlaylist: event.name));
  }

  List<String> checkSongChange() {
    var listChange = <String>[];
    final state = this.state;
    if (state.currentPlaylist.name != state.namePlaylist) {
      listChange.add('name');
    }
    if (state.currentPlaylist.listSongIds.length != state.currentSongs.length) {
      listChange.add('songs');
    } else {
      for (var i = 0; i < state.currentPlaylist.listSongIds.length; i++) {
        if (state.currentPlaylist.listSongIds[i] != state.currentSongs[i].id) {
          listChange.add('songs');
          break;
        }
      }
    }
    return listChange;
  }

  void _changeAppBarStatusPlaylist(ChangeAppBarStatusPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    if (settingsRepository.autoHideTopBar) {
      emit(state.copyWith(appBarStatus: event.status));
    } else {
      emit(state.copyWith(appBarStatus: true));
    }
  }

  void _changeHeightWindowPlaylist(ChangeHeightWindowPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    final textSizeHeight = this.textSizeHeight(state.textStyle);
    int maxLines = (event.height - menuHeight) / textSizeHeight ~/ 1;
    emit(state.copyWith(
      heightWindow: event.height,
      maxLines: maxLines,
    ));
  }

  void _changeFontSizePlaylist(ChangeFontSizePlaylist event, Emitter<PlaylistsState> emit) {
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

  void _transposeChordPlaylist(TransposeChordPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    int newIncrement = state.transposeIncrement + event.increment;
    if (newIncrement >= 12) {
      newIncrement = newIncrement - 12;
    }
    if (newIncrement <= -12) {
      newIncrement = newIncrement + 12;
    }

    songsRepository.changeTransposeChord(state.currentSong, newIncrement);
    emit(state.copyWith(transposeIncrement: newIncrement, cap: _getCapByIncrement(newIncrement)));
  }

  void _selectSongInPreviewPlaylist(SelectSongInPreviewPlaylist event, Emitter<PlaylistsState> emit) {
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

  void _changeCurrentColumnPlaylist(ChangeCurrentColumnPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    if (event.column < 0 && state.indexCurrentSongInPlaylist == 0) {
      emit(state.copyWith(currentColumn: 0));
      return;
    }
    final lyricsColumn = state.lyricWithColumns(true, true, TypeLyric.translate, state.currentSong);
    if (lyricsColumn.length - 2 < event.column && state.indexCurrentSongInPlaylist == state.currentSongs.length - 1) {
      emit(state.copyWith(currentColumn: lyricsColumn.length - 1));
      return;
    }
    if (lyricsColumn.length - 1 < event.column) {
      //change song
      final newCurrentSong = state.currentSongs[state.indexCurrentSongInPlaylist + 1];
      emit(state.copyWith(indexCurrentSongInPlaylist: state.indexCurrentSongInPlaylist + 1, currentColumn: 0, currentSong: newCurrentSong));
      return;
    }
    if (event.column < 0) {
      //change song
      final newCurrentSong = state.currentSongs[state.indexCurrentSongInPlaylist - 1];
      final lyricsColumn = state.lyricWithColumns(true, true, TypeLyric.translate, newCurrentSong);
      final lastIndexNewSong = lyricsColumn.length % 2 == 0 ? lyricsColumn.length - 2 : lyricsColumn.length - 1;
      emit(state.copyWith(indexCurrentSongInPlaylist: state.indexCurrentSongInPlaylist - 1, currentColumn: lastIndexNewSong, currentSong: newCurrentSong));
      return;
    }
    emit(state.copyWith(currentColumn: event.column));
  }

  double textSizeHeight(TextStyle textStyle) {
    final TextPainter textPainter = TextPainter(text: TextSpan(text: 'Firstline', style: textStyle), textDirection: TextDirection.ltr)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.height * 1.35;
  }

  void _moveSongInPlaylist(MoveSongInPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    final currentSongs = List<Song>.from(state.currentSongs);
    final song = currentSongs.removeAt(event.oldIndex);
    currentSongs.insert(event.newIndex, song);
    emit(state.copyWith(currentSongs: currentSongs));
  }
}

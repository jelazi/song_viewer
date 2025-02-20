import 'package:bloc/bloc.dart';
import 'package:default_project/repositories/playlist_repository.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:default_project/view/desktop_view/widgets/my_toast.dart';
import 'package:equatable/equatable.dart';

import '../../model/playlist.dart';
import '../../model/song/song.dart';

part 'playlists_event.dart';
part 'playlists_state.dart';

class PlaylistsBloc extends Bloc<PlaylistsEvent, PlaylistsState> {
  PlaylistRepository playlistRepository;
  SongsRepository songsRepository;
  PlaylistsBloc({required this.playlistRepository, required this.songsRepository})
      : super(PlaylistsInitial(
          playlists: [],
          currentPlaylist: Playlist(id: '', name: ''),
          namePlaylist: '',
          currentSongs: [],
          allSongs: [],
          filteredSongs: [],
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

    add(const _Init());
  }

  void _init(_Init event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    emit(state.copyWith(playlists: playlistRepository.playlists, allSongs: songsRepository.songs, filteredSongs: []));
  }

  void _filterSongPlaylist(FilterSongPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    emit(state.copyWith(filteredSongs: songsRepository.getSongByFilter(event.filter)));
  }

  void _openPlaylist(OpenPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    List<Song> currentSongs = [];
    var playlist = event.playlist;
    if (playlist == null) {
      emit(state.copyWith(currentPlaylist: Playlist(id: '', name: ''), currentSongs: []));
      return;
    }
    event.playlist!.listSongIds.forEach((songId) {
      final song = state.allSongs.firstWhere((element) => element.id == songId);
      currentSongs.add(song);
    });
    emit(state.copyWith(currentPlaylist: event.playlist, currentSongs: currentSongs, filteredSongs: []));
  }

  void _closePlaylist(ClosePlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    emit(state.copyWith(
      currentPlaylist: Playlist(id: '', name: ''),
      currentSongs: [],
    ));
  }

  void _savePlaylist(SavePlaylist event, Emitter<PlaylistsState> emit) async {
    final state = this.state;
    final newPlaylist = event.playlist;
    var playlistId = <String>[];
    for (var song in state.currentSongs) {
      playlistId.add(song.id);
    }
    newPlaylist.listSongIds = playlistId;
    newPlaylist.name = state.namePlaylist;
    await playlistRepository.savePlaylist(event.playlist);
    MyToast.showText(text: 'Playlist saved', typeNotification: TypeNotification.success);
    emit(state.copyWith(playlists: playlistRepository.playlists));
  }

  void _deletePlaylist(DeletePlaylist event, Emitter<PlaylistsState> emit) async {
    final state = this.state;
    await playlistRepository.deletePlaylist(event.playlist);
    MyToast.showText(text: 'Playlist deleted', typeNotification: TypeNotification.success);
    emit(state.copyWith(playlists: playlistRepository.playlists));
  }

  void _addSongToPlaylist(AddSongToPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    final playlist = state.currentPlaylist;
    final song = event.song;
    playlist.listSongIds.add(song.id);
    emit(state.copyWith(
      currentPlaylist: playlist,
      currentSongs: [...state.currentSongs, song],
    ));
  }

  void _removeSongFromPlaylist(RemoveSongFromPlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    final playlist = state.currentPlaylist;
    var currentSongs = List<Song>.from(state.currentSongs);
    currentSongs.removeAt(event.index);
    playlist.listSongIds.removeAt(event.index);
    emit(state.copyWith(
      currentPlaylist: playlist,
      currentSongs: currentSongs,
    ));
  }

  void _changeNamePlaylist(ChangeNamePlaylist event, Emitter<PlaylistsState> emit) {
    final state = this.state;
    final playlist = state.currentPlaylist;
    playlist.name = event.name;
    emit(state.copyWith(currentPlaylist: playlist));
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
}

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../model/playlist.dart';
import '../../model/presentation_playlist.dart';
import '../../model/song/song.dart';
import '../../repositories/playlist_repository.dart';
import '../../repositories/songs_repository.dart';

part 'presentation_playlist_event.dart';
part 'presentation_playlist_state.dart';

class PresentationPlaylistBloc extends Bloc<PresentationPlaylistEvent, PresentationPlaylistState> {
  final PlaylistRepository? playlistRepository;
  final SongsRepository? songsRepository;

  PresentationPlaylistBloc({
    this.playlistRepository,
    this.songsRepository,
  }) : super(const PresentationPlaylistState.initial()) {
    on<AddSongToPresentation>(_onAddSong);
    on<RemoveSongFromPresentation>(_onRemoveSong);
    on<ReorderPresentationSongs>(_onReorderSongs);
    on<SelectPresentationSong>(_onSelectSong);
    on<NextPresentationSong>(_onNextSong);
    on<PreviousPresentationSong>(_onPreviousSong);
    on<ClearPresentationPlaylist>(_onClearPlaylist);
    on<ClearPresentationSelection>(_onClearSelection);
    on<SavePresentationPlaylist>(_onSavePlaylist);
    on<LoadPresentationPlaylist>(_onLoadPlaylist);
  }

  void _onAddSong(
    AddSongToPresentation event,
    Emitter<PresentationPlaylistState> emit,
  ) {
    final updatedPlaylist = state.playlist.addSong(event.song);
    emit(state.copyWith(playlist: updatedPlaylist));
  }

  void _onRemoveSong(
    RemoveSongFromPresentation event,
    Emitter<PresentationPlaylistState> emit,
  ) {
    final updatedPlaylist = state.playlist.removeSong(event.index);
    emit(state.copyWith(playlist: updatedPlaylist));
  }

  void _onReorderSongs(
    ReorderPresentationSongs event,
    Emitter<PresentationPlaylistState> emit,
  ) {
    final updatedPlaylist = state.playlist.reorderSongs(
      event.oldIndex,
      event.newIndex,
    );
    emit(state.copyWith(playlist: updatedPlaylist));
  }

  void _onSelectSong(
    SelectPresentationSong event,
    Emitter<PresentationPlaylistState> emit,
  ) {
    final updatedPlaylist = state.playlist.selectSong(event.index);
    emit(state.copyWith(playlist: updatedPlaylist));
  }

  void _onNextSong(
    NextPresentationSong event,
    Emitter<PresentationPlaylistState> emit,
  ) {
    if (state.hasNext) {
      final updatedPlaylist = state.playlist.nextSong();
      emit(state.copyWith(playlist: updatedPlaylist));
    }
  }

  void _onPreviousSong(
    PreviousPresentationSong event,
    Emitter<PresentationPlaylistState> emit,
  ) {
    if (state.hasPrevious) {
      final updatedPlaylist = state.playlist.previousSong();
      emit(state.copyWith(playlist: updatedPlaylist));
    }
  }

  void _onClearPlaylist(
    ClearPresentationPlaylist event,
    Emitter<PresentationPlaylistState> emit,
  ) {
    final updatedPlaylist = state.playlist.clear();
    emit(state.copyWith(playlist: updatedPlaylist));
  }

  void _onClearSelection(
    ClearPresentationSelection event,
    Emitter<PresentationPlaylistState> emit,
  ) {
    final updatedPlaylist = state.playlist.clearSelection();
    emit(state.copyWith(playlist: updatedPlaylist));
  }

  Future<void> _onSavePlaylist(
    SavePresentationPlaylist event,
    Emitter<PresentationPlaylistState> emit,
  ) async {
    if (playlistRepository == null) {
      debugPrint('PlaylistRepository not available');
      return;
    }
    if (state.isEmpty) return;

    try {
      // Convert PresentationPlaylist → Playlist (extracting song IDs)
      final songIds = state.playlist.songs.map((s) => s.id).toList();
      final playlist = Playlist(
        id: event.playlistId ?? const Uuid().v1(),
        name: event.name,
      );
      playlist.listSongIds = songIds;

      final success = await playlistRepository!.savePlaylist(playlist);
      if (success) {
        debugPrint('Presentation playlist saved: ${event.name} (${songIds.length} songs)');
      } else {
        debugPrint('Failed to save presentation playlist');
      }
    } catch (e) {
      debugPrint('Error saving presentation playlist: $e');
    }
  }

  Future<void> _onLoadPlaylist(
    LoadPresentationPlaylist event,
    Emitter<PresentationPlaylistState> emit,
  ) async {
    if (songsRepository == null) {
      debugPrint('SongsRepository not available');
      return;
    }

    try {
      final playlist = event.playlist;
      final allSongs = songsRepository!.songs;

      // Resolve song IDs to Song objects, preserving order
      final songs = <Song>[];
      for (final songId in playlist.listSongIds) {
        final song = allSongs.firstWhere(
          (s) => s.id == songId,
          orElse: () => Song(title: 'Unknown', lyrics: '', id: songId),
        );
        if (song.title != 'Unknown') {
          songs.add(song);
        }
      }

      if (songs.isEmpty) {
        debugPrint('No valid songs found in playlist: ${playlist.name}');
        return;
      }

      final presentationPlaylist = PresentationPlaylist(
        songs: songs,
        currentIndex: 0,
      );
      emit(state.copyWith(playlist: presentationPlaylist));
      debugPrint('Loaded playlist: ${playlist.name} (${songs.length} songs)');
    } catch (e) {
      debugPrint('Error loading presentation playlist: $e');
    }
  }
}

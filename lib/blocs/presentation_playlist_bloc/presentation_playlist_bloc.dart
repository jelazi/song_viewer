import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/presentation_playlist.dart';
import '../../model/song/song.dart';

part 'presentation_playlist_event.dart';
part 'presentation_playlist_state.dart';

class PresentationPlaylistBloc extends Bloc<PresentationPlaylistEvent, PresentationPlaylistState> {
  PresentationPlaylistBloc() : super(const PresentationPlaylistState.initial()) {
    on<AddSongToPresentation>(_onAddSong);
    on<RemoveSongFromPresentation>(_onRemoveSong);
    on<ReorderPresentationSongs>(_onReorderSongs);
    on<SelectPresentationSong>(_onSelectSong);
    on<NextPresentationSong>(_onNextSong);
    on<PreviousPresentationSong>(_onPreviousSong);
    on<ClearPresentationPlaylist>(_onClearPlaylist);
    on<ClearPresentationSelection>(_onClearSelection);
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
}

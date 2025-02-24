part of 'playlists_bloc.dart';

class PlaylistsEvent extends Equatable {
  const PlaylistsEvent();

  @override
  List<Object> get props => [];
}

class _Init extends PlaylistsEvent {
  const _Init();

  @override
  List<Object> get props => [];
}

class OpenPlaylist extends PlaylistsEvent {
  final Playlist? playlist;
  final bool forEdit;
  const OpenPlaylist({required this.playlist, required this.forEdit});
  @override
  List<Object> get props => [playlist!, forEdit];
}

class ClosePlaylist extends PlaylistsEvent {
  const ClosePlaylist();
  @override
  List<Object> get props => [];
}

class FilterSongPlaylist extends PlaylistsEvent {
  final String filter;
  const FilterSongPlaylist({required this.filter});
  @override
  List<Object> get props => [filter];
}

class SavePlaylist extends PlaylistsEvent {
  const SavePlaylist();
}

class DeletePlaylist extends PlaylistsEvent {
  final Playlist playlist;
  const DeletePlaylist({required this.playlist});
  @override
  List<Object> get props => [playlist];
}

class AddSongToPlaylist extends PlaylistsEvent {
  final Playlist playlist;
  final Song song;
  const AddSongToPlaylist({required this.playlist, required this.song});
  @override
  List<Object> get props => [playlist, song];
}

class RemoveSongFromPlaylist extends PlaylistsEvent {
  final index;
  const RemoveSongFromPlaylist({required this.index});
  @override
  List<Object> get props => [index];
}

class ChangeNamePlaylist extends PlaylistsEvent {
  final Playlist playlist;
  final String name;
  const ChangeNamePlaylist({required this.playlist, required this.name});
  @override
  List<Object> get props => [playlist, name];
}

class ChangeAppBarStatusPlaylist extends PlaylistsEvent {
  final bool status;
  const ChangeAppBarStatusPlaylist({required this.status});
  @override
  List<Object> get props => [status];
}

class ChangeHeightWindowPlaylist extends PlaylistsEvent {
  final double height;
  const ChangeHeightWindowPlaylist({required this.height});
  @override
  List<Object> get props => [height];
}

class ChangeFontSizePlaylist extends PlaylistsEvent {
  final bool isIncrease;
  const ChangeFontSizePlaylist({required this.isIncrease});
  @override
  List<Object> get props => [isIncrease];
}

class TransposeChordPlaylist extends PlaylistsEvent {
  final int increment;
  const TransposeChordPlaylist({required this.increment});
  @override
  List<Object> get props => [increment];
}

class SelectSongInPreviewPlaylist extends PlaylistsEvent {
  final String selectSongId;
  const SelectSongInPreviewPlaylist({required this.selectSongId});
  @override
  List<Object> get props => [selectSongId];
}

class ChangeCurrentColumnPlaylist extends PlaylistsEvent {
  final int column;
  const ChangeCurrentColumnPlaylist({required this.column});
  @override
  List<Object> get props => [column];
}

class MoveSongInPlaylist extends PlaylistsEvent {
  final int oldIndex;
  final int newIndex;
  const MoveSongInPlaylist({required this.oldIndex, required this.newIndex});
  @override
  List<Object> get props => [oldIndex, newIndex];
}

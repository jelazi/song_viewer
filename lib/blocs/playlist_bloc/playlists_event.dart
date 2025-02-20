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
  const OpenPlaylist({required this.playlist});
  @override
  List<Object> get props => [playlist!];
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
  final Playlist playlist;
  const SavePlaylist({required this.playlist});
  @override
  List<Object> get props => [playlist];
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

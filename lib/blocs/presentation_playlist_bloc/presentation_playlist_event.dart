part of 'presentation_playlist_bloc.dart';

abstract class PresentationPlaylistEvent extends Equatable {
  const PresentationPlaylistEvent();

  @override
  List<Object?> get props => [];
}

/// Add a song to the presentation playlist
class AddSongToPresentation extends PresentationPlaylistEvent {
  final Song song;

  const AddSongToPresentation({required this.song});

  @override
  List<Object?> get props => [song];
}

/// Remove a song from the presentation playlist by index
class RemoveSongFromPresentation extends PresentationPlaylistEvent {
  final int index;

  const RemoveSongFromPresentation({required this.index});

  @override
  List<Object?> get props => [index];
}

/// Reorder songs in the presentation playlist
class ReorderPresentationSongs extends PresentationPlaylistEvent {
  final int oldIndex;
  final int newIndex;

  const ReorderPresentationSongs({
    required this.oldIndex,
    required this.newIndex,
  });

  @override
  List<Object?> get props => [oldIndex, newIndex];
}

/// Select a song in the presentation playlist
class SelectPresentationSong extends PresentationPlaylistEvent {
  final int index;

  const SelectPresentationSong({required this.index});

  @override
  List<Object?> get props => [index];
}

/// Move to the next song in the playlist
class NextPresentationSong extends PresentationPlaylistEvent {
  const NextPresentationSong();
}

/// Move to the previous song in the playlist
class PreviousPresentationSong extends PresentationPlaylistEvent {
  const PreviousPresentationSong();
}

/// Clear the entire presentation playlist
class ClearPresentationPlaylist extends PresentationPlaylistEvent {
  const ClearPresentationPlaylist();
}

/// Clear selection without removing songs
class ClearPresentationSelection extends PresentationPlaylistEvent {
  const ClearPresentationSelection();
}

/// Save the current presentation playlist to Firebase
class SavePresentationPlaylist extends PresentationPlaylistEvent {
  final String name;
  final String? playlistId;

  const SavePresentationPlaylist({required this.name, this.playlistId});

  @override
  List<Object?> get props => [name, playlistId];
}

/// Load a playlist from Firebase into the presentation playlist
class LoadPresentationPlaylist extends PresentationPlaylistEvent {
  final Playlist playlist;

  const LoadPresentationPlaylist({required this.playlist});

  @override
  List<Object?> get props => [playlist];
}

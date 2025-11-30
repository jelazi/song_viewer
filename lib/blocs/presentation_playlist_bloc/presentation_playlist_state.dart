part of 'presentation_playlist_bloc.dart';

class PresentationPlaylistState extends Equatable {
  final PresentationPlaylist playlist;

  const PresentationPlaylistState({
    required this.playlist,
  });

  /// Initial state with empty playlist
  const PresentationPlaylistState.initial() : playlist = const PresentationPlaylist.empty();

  /// Create a copy with updated fields
  PresentationPlaylistState copyWith({
    PresentationPlaylist? playlist,
  }) {
    return PresentationPlaylistState(
      playlist: playlist ?? this.playlist,
    );
  }

  /// Get currently selected song
  Song? get currentSong => playlist.currentSong;

  /// Check if playlist is empty
  bool get isEmpty => playlist.isEmpty;

  /// Check if playlist is not empty
  bool get isNotEmpty => playlist.isNotEmpty;

  /// Check if there is a next song
  bool get hasNext => playlist.hasNext;

  /// Check if there is a previous song
  bool get hasPrevious => playlist.hasPrevious;

  /// Get number of songs
  int get songCount => playlist.length;

  @override
  List<Object?> get props => [playlist];
}

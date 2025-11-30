// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:json_annotation/json_annotation.dart';

import 'song/song.dart';

part 'presentation_playlist.g.dart';

/// Represents a playlist for presentation mode with sequential song playback
@JsonSerializable(explicitToJson: true)
class PresentationPlaylist {
  /// List of songs in the playlist
  final List<Song> songs;

  /// Index of currently selected song (null if no song selected)
  final int? currentIndex;

  const PresentationPlaylist({
    required this.songs,
    this.currentIndex,
  });

  /// Creates an empty playlist
  const PresentationPlaylist.empty()
      : songs = const [],
        currentIndex = null;

  /// Creates a copy with updated fields
  PresentationPlaylist copyWith({
    List<Song>? songs,
    int? currentIndex,
  }) {
    return PresentationPlaylist(
      songs: songs ?? this.songs,
      currentIndex: currentIndex ?? this.currentIndex,
    );
  }

  /// Check if playlist is empty
  bool get isEmpty => songs.isEmpty;

  /// Check if playlist is not empty
  bool get isNotEmpty => songs.isNotEmpty;

  /// Get number of songs in playlist
  int get length => songs.length;

  /// Get currently selected song (null if none selected or invalid index)
  Song? get currentSong {
    if (currentIndex == null || currentIndex! < 0 || currentIndex! >= songs.length) {
      return null;
    }
    return songs[currentIndex!];
  }

  /// Check if there is a next song available
  bool get hasNext => currentIndex != null && currentIndex! < songs.length - 1;

  /// Check if there is a previous song available
  bool get hasPrevious => currentIndex != null && currentIndex! > 0;

  /// Add a song to the end of the playlist
  PresentationPlaylist addSong(Song song) {
    final updatedSongs = List<Song>.from(songs)..add(song);
    return copyWith(songs: updatedSongs);
  }

  /// Remove a song at the specified index
  PresentationPlaylist removeSong(int index) {
    if (index < 0 || index >= songs.length) {
      return this;
    }

    final updatedSongs = List<Song>.from(songs)..removeAt(index);

    // Adjust currentIndex if necessary
    int? newCurrentIndex = currentIndex;
    if (currentIndex != null) {
      if (index == currentIndex) {
        // If removing current song, select next song (or null if last)
        newCurrentIndex = index < updatedSongs.length ? index : null;
      } else if (index < currentIndex!) {
        // If removing song before current, decrement current index
        newCurrentIndex = currentIndex! - 1;
      }
    }

    return PresentationPlaylist(
      songs: updatedSongs,
      currentIndex: newCurrentIndex,
    );
  }

  /// Reorder songs by moving a song from oldIndex to newIndex
  PresentationPlaylist reorderSongs(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= songs.length || newIndex < 0 || newIndex >= songs.length || oldIndex == newIndex) {
      return this;
    }

    final updatedSongs = List<Song>.from(songs);
    final song = updatedSongs.removeAt(oldIndex);
    updatedSongs.insert(newIndex, song);

    // Adjust currentIndex if necessary
    int? newCurrentIndex = currentIndex;
    if (currentIndex != null) {
      if (oldIndex == currentIndex) {
        newCurrentIndex = newIndex;
      } else if (oldIndex < currentIndex! && newIndex >= currentIndex!) {
        newCurrentIndex = currentIndex! - 1;
      } else if (oldIndex > currentIndex! && newIndex <= currentIndex!) {
        newCurrentIndex = currentIndex! + 1;
      }
    }

    return PresentationPlaylist(
      songs: updatedSongs,
      currentIndex: newCurrentIndex,
    );
  }

  /// Select a song by index
  PresentationPlaylist selectSong(int index) {
    if (index < 0 || index >= songs.length) {
      return this;
    }
    return copyWith(currentIndex: index);
  }

  /// Move to the next song
  PresentationPlaylist nextSong() {
    if (!hasNext) {
      return this;
    }
    return copyWith(currentIndex: currentIndex! + 1);
  }

  /// Move to the previous song
  PresentationPlaylist previousSong() {
    if (!hasPrevious) {
      return this;
    }
    return copyWith(currentIndex: currentIndex! - 1);
  }

  /// Clear the playlist
  PresentationPlaylist clear() {
    return const PresentationPlaylist.empty();
  }

  /// Clear selection without removing songs
  PresentationPlaylist clearSelection() {
    return copyWith(currentIndex: null);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PresentationPlaylist && runtimeType == other.runtimeType && songs == other.songs && currentIndex == other.currentIndex;

  @override
  int get hashCode => songs.hashCode ^ currentIndex.hashCode;

  @override
  String toString() => 'PresentationPlaylist(songs: ${songs.length}, currentIndex: $currentIndex)';

  factory PresentationPlaylist.fromJson(Map<String, dynamic> json) => _$PresentationPlaylistFromJson(json);

  Map<String, dynamic> toJson() => _$PresentationPlaylistToJson(this);
}

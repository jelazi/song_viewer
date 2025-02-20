// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'playlists_bloc.dart';

class PlaylistsState extends Equatable {
  final List<Playlist> playlists;
  final Playlist currentPlaylist;
  final String namePlaylist;
  final List<Song> currentSongs;
  final List<Song> allSongs;
  final List<Song> filteredSongs;
  const PlaylistsState(
      {required this.playlists, required this.currentPlaylist, required this.namePlaylist, required this.currentSongs, required this.allSongs, required this.filteredSongs});

  @override
  List<Object> get props => [playlists, currentPlaylist, namePlaylist, currentSongs, allSongs, filteredSongs];

  PlaylistsState copyWith({
    List<Playlist>? playlists,
    Playlist? currentPlaylist,
    String? namePlaylist,
    List<Song>? currentSongs,
    List<Song>? allSongs,
    List<Song>? filteredSongs,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      namePlaylist: namePlaylist ?? this.namePlaylist,
      currentSongs: currentSongs ?? this.currentSongs,
      allSongs: allSongs ?? this.allSongs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
    );
  }
}

final class PlaylistsInitial extends PlaylistsState {
  const PlaylistsInitial(
      {required super.playlists, required super.currentPlaylist, required super.namePlaylist, required super.currentSongs, required super.allSongs, required super.filteredSongs});
}

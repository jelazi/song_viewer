// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'playlists_bloc.dart';

class PlaylistsState extends Equatable {
  final List<Playlist> playlists;
  final Playlist currentPlaylist;
  final String namePlaylist;
  final List<Song> currentSongs;
  final List<Song> allSongs;
  final List<Song> filteredSongs;
  final double heightWindow;
  final Song currentSong;
  final String selectedSongId;
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final bool appBarStatus;
  final int transposeIncrement;
  final int scrollSpeed;
  final int currentColumn;
  final int maxLines;
  final int cap;
  final int indexCurrentSongInPlaylist;
  const PlaylistsState({
    required this.playlists,
    required this.currentPlaylist,
    required this.namePlaylist,
    required this.currentSongs,
    required this.allSongs,
    required this.filteredSongs,
    required this.heightWindow,
    required this.currentSong,
    required this.selectedSongId,
    required this.textStyle,
    required this.chordStyle,
    required this.appBarStatus,
    required this.transposeIncrement,
    required this.scrollSpeed,
    required this.currentColumn,
    required this.maxLines,
    required this.cap,
    required this.indexCurrentSongInPlaylist,
  });

  @override
  List<Object> get props => [
        playlists,
        currentPlaylist,
        namePlaylist,
        currentSongs,
        allSongs,
        filteredSongs,
        heightWindow,
        currentSong,
        selectedSongId,
        textStyle,
        chordStyle,
        appBarStatus,
        transposeIncrement,
        scrollSpeed,
        currentColumn,
        maxLines,
        cap,
        indexCurrentSongInPlaylist,
      ];

  PlaylistsState copyWith({
    List<Playlist>? playlists,
    Playlist? currentPlaylist,
    String? namePlaylist,
    List<Song>? currentSongs,
    List<Song>? allSongs,
    List<Song>? filteredSongs,
    double? heightWindow,
    Song? currentSong,
    String? selectedSongId,
    TextStyle? textStyle,
    TextStyle? chordStyle,
    bool? appBarStatus,
    int? transposeIncrement,
    int? scrollSpeed,
    int? currentColumn,
    int? maxLines,
    int? cap,
    int? indexCurrentSongInPlaylist,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      currentPlaylist: currentPlaylist ?? this.currentPlaylist,
      namePlaylist: namePlaylist ?? this.namePlaylist,
      currentSongs: currentSongs ?? this.currentSongs,
      allSongs: allSongs ?? this.allSongs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      heightWindow: heightWindow ?? this.heightWindow,
      currentSong: currentSong ?? this.currentSong,
      selectedSongId: selectedSongId ?? this.selectedSongId,
      textStyle: textStyle ?? this.textStyle,
      chordStyle: chordStyle ?? this.chordStyle,
      appBarStatus: appBarStatus ?? this.appBarStatus,
      transposeIncrement: transposeIncrement ?? this.transposeIncrement,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      currentColumn: currentColumn ?? this.currentColumn,
      maxLines: maxLines ?? this.maxLines,
      cap: cap ?? this.cap,
      indexCurrentSongInPlaylist: indexCurrentSongInPlaylist ?? this.indexCurrentSongInPlaylist,
    );
  }

  List<String> lyricWithColumns(bool chords, bool notes, TypeLyric typeLyric, Song song) {
    List<String> listLines = typeLyric == TypeLyric.translate ? song.lyrics.split('\n') : (song.originalLyrics ?? '').split('\n');
    double realLines = 0;
    for (String line in listLines) {
      if (line.contains('[')) {
        realLines += 2;
      } else {
        realLines++;
      }
    }

    List<String> result = [];
    if (realLines <= maxLines) {
      result.add(typeLyric == TypeLyric.translate ? song.lyrics : song.originalLyrics ?? '');
      return result;
    }

    String item = '';
    int index = 0;
    for (String line in listLines) {
      item += '$line\n';
      if (index < maxLines) {
        if (line.contains('[')) {
          index += 2;
        } else {
          index++;
        }
      } else {
        result.add(item);
        item = '';
        index = 0;
      }
    }
    String it = item.replaceAll(' ', '');
    it = it.replaceAll('\n', '');

    if (it.isNotEmpty) {
      result.add(item);
    }

    return result;
  }
}

final class PlaylistsInitial extends PlaylistsState {
  const PlaylistsInitial({
    required super.playlists,
    required super.currentPlaylist,
    required super.namePlaylist,
    required super.currentSongs,
    required super.allSongs,
    required super.filteredSongs,
    required super.heightWindow,
    required super.currentSong,
    required super.selectedSongId,
    required super.textStyle,
    required super.chordStyle,
    required super.appBarStatus,
    required super.transposeIncrement,
    required super.scrollSpeed,
    required super.currentColumn,
    required super.maxLines,
    required super.cap,
    required super.indexCurrentSongInPlaylist,
  });
}

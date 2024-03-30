// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'web_bloc.dart';

class WebState extends Equatable {
  final WebSong? currentSong;
  final List<WebSong> songs;
  final List<WebSong> filteredSongs;
  final List<WebInterpret> interprets;
  final WebInterpret? currentInterpret;
  final int searchWeb;
  final listSearchWeb = [
    'superMusic'.tr(),
    'velkyZpevnik'.tr(),
  ];
  WebState({
    this.currentSong,
    required this.songs,
    required this.filteredSongs,
    required this.interprets,
    this.currentInterpret,
    required this.searchWeb,
  });

  @override
  List<Object> get props => [currentSong ?? '', songs, filteredSongs, currentInterpret ?? '', interprets, searchWeb];

  WebState copyWith({
    WebSong? currentSong,
    List<WebSong>? songs,
    List<WebSong>? filteredSongs,
    List<WebInterpret>? interprets,
    WebInterpret? currentInterpret,
    int? searchWeb,
  }) {
    return WebState(
      currentSong: currentSong,
      songs: songs ?? this.songs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      interprets: interprets ?? this.interprets,
      currentInterpret: currentInterpret,
      searchWeb: searchWeb ?? this.searchWeb,
    );
  }
}

class WebInitial extends WebState {
  WebInitial({
    required super.currentSong,
    required super.songs,
    required super.filteredSongs,
    required super.currentInterpret,
    required super.interprets,
    required super.searchWeb,
  });
}

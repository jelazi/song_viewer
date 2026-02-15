// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'web_bloc.dart';

class WebState extends Equatable {
  final WebSong? currentSong;
  final List<WebSong> songs;
  final List<WebSong> filteredSongs;
  final List<WebInterpret> interprets;
  final List<WebInterpret> filteredInterprets;
  final List<WebInterpret> historyInterprets;
  final WebInterpret currentInterpret;
  final int searchWeb;
  final bool isSearching;
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final bool appBarStatus;
  final int transposeIncrement;
  final int scrollSpeed;
  final bool searchWebInterprets;
  final bool searchWebSongs;
  final bool downloadWebSong;

  final listSearchWeb = [
    'velkyzpevnik.cz',
    'pisnicky-akordy.cz',
    'zpevnik.proscholy.cz',
  ];

  final int searchType;
  final listSelectTypeSearch = ['song'.tr(), 'interpret'.tr()];

  WebState({
    this.currentSong,
    required this.songs,
    required this.filteredSongs,
    required this.interprets,
    required this.filteredInterprets,
    required this.currentInterpret,
    required this.searchWeb,
    required this.searchType,
    required this.isSearching,
    required this.textStyle,
    required this.chordStyle,
    required this.appBarStatus,
    required this.transposeIncrement,
    required this.scrollSpeed,
    required this.searchWebInterprets,
    required this.searchWebSongs,
    required this.downloadWebSong,
    required this.historyInterprets,
  });

  @override
  List<Object> get props => [
        currentSong ?? '',
        songs,
        filteredSongs,
        currentInterpret,
        interprets,
        filteredInterprets,
        searchWeb,
        searchType,
        isSearching,
        textStyle,
        chordStyle,
        appBarStatus,
        transposeIncrement,
        scrollSpeed,
        searchWebInterprets,
        searchWebSongs,
        downloadWebSong,
        historyInterprets,
      ];

  WebState copyWith({
    WebSong? currentSong,
    List<WebSong>? songs,
    List<WebSong>? filteredSongs,
    List<WebInterpret>? interprets,
    List<WebInterpret>? historyInterprets,
    WebInterpret? currentInterpret,
    int? searchWeb,
    int? searchType,
    bool? isSearching,
    List<WebInterpret>? filteredInterprets,
    TextStyle? textStyle,
    TextStyle? chordStyle,
    bool? appBarStatus,
    int? transposeIncrement,
    int? scrollSpeed,
    bool? searchWebInterprets,
    bool? searchWebSongs,
    bool? downloadWebSong,
  }) {
    return WebState(
      currentSong: currentSong,
      songs: songs ?? this.songs,
      filteredSongs: filteredSongs ?? this.filteredSongs,
      interprets: interprets ?? this.interprets,
      historyInterprets: historyInterprets ?? this.historyInterprets,
      currentInterpret: currentInterpret ?? this.currentInterpret,
      searchWeb: searchWeb ?? this.searchWeb,
      searchType: searchType ?? this.searchType,
      isSearching: isSearching ?? this.isSearching,
      filteredInterprets: filteredInterprets ?? this.filteredInterprets,
      textStyle: textStyle ?? this.textStyle,
      chordStyle: chordStyle ?? this.chordStyle,
      appBarStatus: appBarStatus ?? this.appBarStatus,
      transposeIncrement: transposeIncrement ?? this.transposeIncrement,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      searchWebInterprets: searchWebInterprets ?? this.searchWebInterprets,
      searchWebSongs: searchWebSongs ?? this.searchWebSongs,
      downloadWebSong: downloadWebSong ?? this.downloadWebSong,
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
    required super.searchType,
    required super.isSearching,
    required super.filteredInterprets,
    required super.textStyle,
    required super.chordStyle,
    required super.appBarStatus,
    required super.transposeIncrement,
    required super.scrollSpeed,
    required super.searchWebInterprets,
    required super.searchWebSongs,
    required super.downloadWebSong,
    required super.historyInterprets,
  });
}

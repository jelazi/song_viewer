// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'web_bloc.dart';

const _sentinel = Object();

/// Font-size bounds for the web song preview, mirroring the library preview.
const double minPreviewFontSize = 10;
const double maxPreviewFontSize = 40;

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

  /// Lyric of [currentSong] rewritten into the Czech notation, or null while
  /// the song is shown exactly as the site published it.
  ///
  /// Kept beside the fetched song instead of replacing its lyric, so switching
  /// the notation off restores the original spelling verbatim.
  final String? czechNotationLyric;

  /// True when the fetched lyric looks like it uses the international notation
  /// (`B` for what Czech calls `H`, flats instead of sharps).
  final bool foreignNotationDetected;

  /// Persisted search-query history for the current server (most recent first).
  final List<String> searchHistory;

  /// Persisted search-query history combined across all servers.
  final List<String> allSearchHistory;

  final listSearchWeb = [
    'velkyzpevnik.cz',
    'pisnicky-akordy.cz',
    'zpevnik.proscholy.cz',
    'songs.worshipleaderapp.com',
    'worshipchords.com',
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
    this.czechNotationLyric,
    this.foreignNotationDetected = false,
    this.searchHistory = const [],
    this.allSearchHistory = const [],
  });

  /// Capo position matching [transposeIncrement], the same reading the library
  /// preview shows in its song header.
  int get cap {
    if (transposeIncrement == 0) return 0;
    return transposeIncrement < 0 ? -transposeIncrement : 12 - transposeIncrement;
  }

  /// Lyric to render and to save: the converted one when the Czech notation is
  /// switched on, the fetched one otherwise.
  String get displayedLyric => czechNotationLyric ?? currentSong?.lyric ?? '';

  /// True while the song is shown in the Czech notation.
  bool get isNotationConverted => czechNotationLyric != null;

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
        czechNotationLyric ?? '',
        foreignNotationDetected,
        searchHistory,
        allSearchHistory,
      ];

  WebState copyWith({
    Object? currentSong = _sentinel,
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
    Object? czechNotationLyric = _sentinel,
    bool? foreignNotationDetected,
    List<String>? searchHistory,
    List<String>? allSearchHistory,
  }) {
    return WebState(
      currentSong: identical(currentSong, _sentinel) ? this.currentSong : currentSong as WebSong?,
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
      czechNotationLyric: identical(czechNotationLyric, _sentinel) ? this.czechNotationLyric : czechNotationLyric as String?,
      foreignNotationDetected: foreignNotationDetected ?? this.foreignNotationDetected,
      searchHistory: searchHistory ?? this.searchHistory,
      allSearchHistory: allSearchHistory ?? this.allSearchHistory,
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

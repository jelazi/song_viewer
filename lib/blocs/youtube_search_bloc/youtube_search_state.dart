part of 'youtube_search_bloc.dart';

enum YoutubeSearchStatus { initial, loading, success, failure }

class YoutubeSearchState extends Equatable {
  final YoutubeSearchStatus status;
  final String query;
  final List<YoutubeSearchResult> results;

  /// The song after the latest successful add, so a BlocListener can push it
  /// to the preview.
  final Song? updatedSong;

  const YoutubeSearchState({
    this.status = YoutubeSearchStatus.initial,
    this.query = '',
    this.results = const [],
    this.updatedSong,
  });

  @override
  List<Object?> get props => [status, query, results, updatedSong];

  YoutubeSearchState copyWith({
    YoutubeSearchStatus? status,
    String? query,
    List<YoutubeSearchResult>? results,
    Song? updatedSong,
  }) {
    return YoutubeSearchState(
      status: status ?? this.status,
      query: query ?? this.query,
      results: results ?? this.results,
      updatedSong: updatedSong ?? this.updatedSong,
    );
  }
}

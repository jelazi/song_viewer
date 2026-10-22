part of 'youtube_search_bloc.dart';

abstract class YoutubeSearchEvent extends Equatable {
  const YoutubeSearchEvent();

  @override
  List<Object?> get props => [];
}

class SearchYoutube extends YoutubeSearchEvent {
  final String query;
  const SearchYoutube({required this.query});

  @override
  List<Object?> get props => [query];
}

class AddYoutubeVideoToSong extends YoutubeSearchEvent {
  final Song song;
  final YoutubeSearchResult result;
  const AddYoutubeVideoToSong({required this.song, required this.result});

  @override
  List<Object?> get props => [song.id, result.videoId];
}

class ClearYoutubeSearch extends YoutubeSearchEvent {
  const ClearYoutubeSearch();
}

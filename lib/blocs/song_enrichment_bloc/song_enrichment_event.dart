part of 'song_enrichment_bloc.dart';

abstract class SongEnrichmentEvent extends Equatable {
  const SongEnrichmentEvent();

  @override
  List<Object?> get props => [];
}

class StartEnrichment extends SongEnrichmentEvent {
  final Song song;
  const StartEnrichment({required this.song});

  @override
  List<Object?> get props => [song.id];
}

class SearchYoutubeVideos extends SongEnrichmentEvent {
  final String query;
  const SearchYoutubeVideos({required this.query});

  @override
  List<Object?> get props => [query];
}

class SearchSheetMusic extends SongEnrichmentEvent {
  const SearchSheetMusic();
}

class ApproveAuthor extends SongEnrichmentEvent {
  final String author;
  const ApproveAuthor({required this.author});

  @override
  List<Object?> get props => [author];
}

class ApproveOriginalTitle extends SongEnrichmentEvent {
  final String originalTitle;
  const ApproveOriginalTitle({required this.originalTitle});

  @override
  List<Object?> get props => [originalTitle];
}

class ApproveYoutubeVideo extends SongEnrichmentEvent {
  final YoutubeSearchResult video;
  const ApproveYoutubeVideo({required this.video});

  @override
  List<Object?> get props => [video.videoId];
}

class RemoveEnrichmentVideo extends SongEnrichmentEvent {
  final String videoId;
  const RemoveEnrichmentVideo({required this.videoId});

  @override
  List<Object?> get props => [videoId];
}

class ApproveSheetMusic extends SongEnrichmentEvent {
  final SheetMusicResult sheet;
  const ApproveSheetMusic({required this.sheet});

  @override
  List<Object?> get props => [sheet.imageUrl];
}

class RemoveSheetMusic extends SongEnrichmentEvent {
  final String imageUrl;
  const RemoveSheetMusic({required this.imageUrl});

  @override
  List<Object?> get props => [imageUrl];
}

class SaveEnrichment extends SongEnrichmentEvent {
  const SaveEnrichment();
}

class ResetEnrichment extends SongEnrichmentEvent {
  const ResetEnrichment();
}

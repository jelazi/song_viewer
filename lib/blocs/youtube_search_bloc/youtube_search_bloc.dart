import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html/parser.dart' as html_parser;

import '../../core/youtube_helper.dart';
import '../../model/song/song.dart';
import '../../model/youtube_video.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/songs_repository.dart';
import '../../services/ai_search_service.dart';

part 'youtube_search_event.dart';
part 'youtube_search_state.dart';

class YoutubeSearchBloc extends Bloc<YoutubeSearchEvent, YoutubeSearchState> {
  static const _maxResults = 15;

  final AiSearchService aiSearchService;
  final SettingsRepository settingsRepository;
  final SongsRepository songsRepository;

  YoutubeSearchBloc({
    required this.aiSearchService,
    required this.settingsRepository,
    required this.songsRepository,
  }) : super(const YoutubeSearchState()) {
    on<SearchYoutube>(_searchYoutube);
    on<AddYoutubeVideoToSong>(_addVideoToSong);
    on<ClearYoutubeSearch>(_clearSearch);
  }

  Future<void> _searchYoutube(SearchYoutube event, Emitter<YoutubeSearchState> emit) async {
    final query = event.query.trim();
    if (query.isEmpty) return;
    emit(state.copyWith(status: YoutubeSearchStatus.loading, query: query));
    try {
      final results = await aiSearchService.searchYoutube(
        apiKey: settingsRepository.youtubeApiKey,
        query: query,
        maxResults: _maxResults,
        throwOnError: true,
      );
      emit(state.copyWith(status: YoutubeSearchStatus.success, results: results.map(_withPlainTitle).toList()));
    } catch (_) {
      emit(state.copyWith(status: YoutubeSearchStatus.failure, results: const []));
    }
  }

  Future<void> _addVideoToSong(AddYoutubeVideoToSong event, Emitter<YoutubeSearchState> emit) async {
    final videos = event.song.youtubeVideos ?? [];
    if (videos.any((video) => extractYoutubeVideoId(video.path) == event.result.videoId)) return;

    final updated = event.song.copyWith(
      youtubeVideos: [...videos, YoutubeVideo(name: event.result.title, path: event.result.videoUrl)],
    );
    await songsRepository.updateSong(updated);
    songsRepository.notifySongsChanged();
    emit(state.copyWith(updatedSong: updated));
  }

  void _clearSearch(ClearYoutubeSearch event, Emitter<YoutubeSearchState> emit) {
    emit(const YoutubeSearchState());
  }

  /// The Data API returns HTML-escaped titles (`&#39;`, `&amp;`).
  YoutubeSearchResult _withPlainTitle(YoutubeSearchResult result) {
    return YoutubeSearchResult(
      title: html_parser.parseFragment(result.title).text ?? result.title,
      videoId: result.videoId,
      thumbnailUrl: result.thumbnailUrl,
      channelTitle: result.channelTitle,
    );
  }
}

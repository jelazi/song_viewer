import 'package:default_project/model/song/song.dart';
import 'package:default_project/model/youtube_video.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/services/ai_search_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'song_enrichment_event.dart';
part 'song_enrichment_state.dart';

class SongEnrichmentBloc extends Bloc<SongEnrichmentEvent, SongEnrichmentState> {
  final AiSearchService aiSearchService;
  final SettingsRepository settingsRepository;

  SongEnrichmentBloc({
    required this.aiSearchService,
    required this.settingsRepository,
  }) : super(const SongEnrichmentState()) {
    on<StartEnrichment>(_startEnrichment);
    on<SearchYoutubeVideos>(_searchYoutubeVideos);
    on<SearchSheetMusic>(_searchSheetMusic);
    on<ApproveAuthor>(_approveAuthor);
    on<ApproveOriginalTitle>(_approveOriginalTitle);
    on<ApproveYoutubeVideo>(_approveYoutubeVideo);
    on<RemoveEnrichmentVideo>(_removeYoutubeVideo);
    on<ApproveSheetMusic>(_approveSheetMusic);
    on<RemoveSheetMusic>(_removeSheetMusic);
    on<SaveEnrichment>(_saveEnrichment);
    on<ResetEnrichment>(_resetEnrichment);
    on<RejectAnalysis>(_rejectAnalysis);
    on<RejectYoutubeResults>(_rejectYoutubeResults);
  }

  void _startEnrichment(StartEnrichment event, Emitter<SongEnrichmentState> emit) async {
    emit(SongEnrichmentState(
      song: event.song,
      status: EnrichmentStatus.analyzing,
    ));

    final groqApiKey = settingsRepository.groqApiKey;
    if (groqApiKey.isEmpty) {
      emit(state.copyWith(
        status: EnrichmentStatus.error,
        errorMessage: 'groqApiKeyNotSet'.tr(),
      ));
      return;
    }

    // Step 1: AI Analysis (uses Groq + optionally Gemini for better accuracy)
    final analysis = await aiSearchService.analyzeSong(
      apiKey: groqApiKey,
      songTitle: event.song.title,
      songLyrics: event.song.lyrics,
      currentInterpret: event.song.interpret,
      geminiApiKey: settingsRepository.geminiApiKey,
    );

    if (analysis == null) {
      emit(state.copyWith(
        status: EnrichmentStatus.error,
        errorMessage: 'aiAnalysisFailed'.tr(),
      ));
      return;
    }

    emit(state.copyWith(
      analysis: analysis,
      status: EnrichmentStatus.analyzed,
    ));

    // Step 2: Search YouTube
    final youtubeApiKey = settingsRepository.youtubeApiKey;
    if (youtubeApiKey.isNotEmpty && analysis.youtubeSearchQueries.isNotEmpty) {
      emit(state.copyWith(status: EnrichmentStatus.searchingYoutube));

      final allResults = <YoutubeSearchResult>[];
      final seenIds = <String>{};
      for (final query in analysis.youtubeSearchQueries.take(4)) {
        final results = await aiSearchService.searchYoutube(
          apiKey: youtubeApiKey,
          query: query,
          maxResults: 4,
        );
        for (final r in results) {
          if (seenIds.add(r.videoId)) {
            allResults.add(r);
          }
        }
      }

      emit(state.copyWith(youtubeResults: allResults));
    }

    // Step 3: Search sheet music
    emit(state.copyWith(status: EnrichmentStatus.searchingSheets));
    final sheets = await aiSearchService.searchSheetMusic(
      songTitle: event.song.title,
      interpret: analysis.author ?? event.song.interpret,
    );

    emit(state.copyWith(
      sheetResults: sheets,
      status: EnrichmentStatus.analyzed,
    ));
  }

  void _searchYoutubeVideos(SearchYoutubeVideos event, Emitter<SongEnrichmentState> emit) async {
    final youtubeApiKey = settingsRepository.youtubeApiKey;
    if (youtubeApiKey.isEmpty) return;

    emit(state.copyWith(status: EnrichmentStatus.searchingYoutube));

    final results = await aiSearchService.searchYoutube(
      apiKey: youtubeApiKey,
      query: event.query,
      maxResults: 8,
    );

    emit(state.copyWith(
      youtubeResults: results,
      status: EnrichmentStatus.analyzed,
    ));
  }

  void _searchSheetMusic(SearchSheetMusic event, Emitter<SongEnrichmentState> emit) async {
    if (state.song == null) return;

    emit(state.copyWith(status: EnrichmentStatus.searchingSheets));

    final sheets = await aiSearchService.searchSheetMusic(
      songTitle: state.song!.title,
      interpret: state.analysis?.author ?? state.song!.interpret,
    );

    emit(state.copyWith(
      sheetResults: sheets,
      status: EnrichmentStatus.analyzed,
    ));
  }

  void _approveAuthor(ApproveAuthor event, Emitter<SongEnrichmentState> emit) {
    if (state.song == null) return;
    final updatedSong = state.song!.copyWith(interpret: event.author);
    emit(state.copyWith(
      approvedAuthor: event.author,
      song: updatedSong,
      songVersion: state.songVersion + 1,
    ));
  }

  void _approveOriginalTitle(ApproveOriginalTitle event, Emitter<SongEnrichmentState> emit) {
    if (state.song == null) return;
    final newTags = List<String>.from(state.song!.tags ?? []);
    if (!newTags.contains(event.originalTitle)) {
      newTags.add(event.originalTitle);
    }
    final updatedSong = state.song!.copyWith(tags: newTags);
    emit(state.copyWith(
      approvedOriginalTitle: event.originalTitle,
      song: updatedSong,
      songVersion: state.songVersion + 1,
    ));
  }

  void _approveYoutubeVideo(ApproveYoutubeVideo event, Emitter<SongEnrichmentState> emit) {
    if (state.song == null) return;
    final alreadyApproved = state.approvedVideos.any((v) => v.videoId == event.video.videoId);
    if (!alreadyApproved) {
      final newYoutubeVideos = List<YoutubeVideo>.from(state.song!.youtubeVideos ?? []);
      if (!newYoutubeVideos.any((v) => v.path.contains(event.video.videoId))) {
        newYoutubeVideos.add(YoutubeVideo(name: event.video.title, path: event.video.videoUrl));
      }
      final updatedSong = state.song!.copyWith(youtubeVideos: newYoutubeVideos);
      emit(state.copyWith(
        approvedVideos: [...state.approvedVideos, event.video],
        song: updatedSong,
        songVersion: state.songVersion + 1,
      ));
    }
  }

  void _removeYoutubeVideo(RemoveEnrichmentVideo event, Emitter<SongEnrichmentState> emit) {
    emit(state.copyWith(
      approvedVideos: state.approvedVideos.where((v) => v.videoId != event.videoId).toList(),
    ));
  }

  void _approveSheetMusic(ApproveSheetMusic event, Emitter<SongEnrichmentState> emit) {
    if (state.song == null) return;
    final alreadyApproved = state.approvedSheets.any((s) => s.imageUrl == event.sheet.imageUrl);
    if (!alreadyApproved) {
      final newSheets = List<String>.from(state.song!.sheets ?? []);
      if (!newSheets.contains(event.sheet.imageUrl)) {
        newSheets.add(event.sheet.imageUrl);
      }
      final updatedSong = state.song!.copyWith(sheets: newSheets);
      emit(state.copyWith(
        approvedSheets: [...state.approvedSheets, event.sheet],
        song: updatedSong,
        songVersion: state.songVersion + 1,
      ));
    }
  }

  void _removeSheetMusic(RemoveSheetMusic event, Emitter<SongEnrichmentState> emit) {
    emit(state.copyWith(
      approvedSheets: state.approvedSheets.where((s) => s.imageUrl != event.imageUrl).toList(),
    ));
  }

  void _saveEnrichment(SaveEnrichment event, Emitter<SongEnrichmentState> emit) {
    if (state.song == null || !state.hasApprovedChanges) return;

    emit(state.copyWith(status: EnrichmentStatus.saving));

    final song = state.song!;

    // Build updated song
    String? newInterpret = state.approvedAuthor ?? song.interpret;

    // Merge YouTube videos
    List<YoutubeVideo> newYoutubeVideos = List.from(song.youtubeVideos ?? []);
    for (final video in state.approvedVideos) {
      final alreadyExists = newYoutubeVideos.any((v) => v.path.contains(video.videoId));
      if (!alreadyExists) {
        newYoutubeVideos.add(YoutubeVideo(name: video.title, path: video.videoUrl));
      }
    }

    // Merge sheets
    List<String> newSheets = List.from(song.sheets ?? []);
    for (final sheet in state.approvedSheets) {
      if (!newSheets.contains(sheet.imageUrl)) {
        newSheets.add(sheet.imageUrl);
      }
    }

    // Build tags with original title if approved
    List<String> newTags = List.from(song.tags ?? []);
    if (state.approvedOriginalTitle != null && !newTags.contains(state.approvedOriginalTitle)) {
      newTags.add(state.approvedOriginalTitle!);
    }

    final updatedSong = song.copyWith(
      interpret: newInterpret,
      youtubeVideos: newYoutubeVideos,
      sheets: newSheets,
      tags: newTags,
    );

    // The UI will handle dispatching UpdateSong to HomePageBloc
    emit(state.copyWith(
      song: updatedSong,
      status: EnrichmentStatus.saved,
    ));
  }

  void _resetEnrichment(ResetEnrichment event, Emitter<SongEnrichmentState> emit) {
    emit(const SongEnrichmentState());
  }

  void _rejectAnalysis(RejectAnalysis event, Emitter<SongEnrichmentState> emit) async {
    if (state.song == null) return;

    final newRejectedAuthors = List<String>.from(state.rejectedAuthors);
    final newRejectedTitles = List<String>.from(state.rejectedTitles);
    if (event.rejectedAuthor != null) newRejectedAuthors.add(event.rejectedAuthor!);
    if (event.rejectedTitle != null) newRejectedTitles.add(event.rejectedTitle!);

    emit(state.copyWith(
      status: EnrichmentStatus.analyzing,
      rejectedAuthors: newRejectedAuthors,
      rejectedTitles: newRejectedTitles,
    ));

    final groqApiKey = settingsRepository.groqApiKey;
    if (groqApiKey.isEmpty) return;

    final analysis = await aiSearchService.analyzeSong(
      apiKey: groqApiKey,
      songTitle: state.song!.title,
      songLyrics: state.song!.lyrics,
      currentInterpret: state.song!.interpret,
      geminiApiKey: settingsRepository.geminiApiKey,
      rejectedAuthors: newRejectedAuthors,
      rejectedTitles: newRejectedTitles,
    );

    if (analysis == null) {
      emit(state.copyWith(
        status: EnrichmentStatus.error,
        errorMessage: 'aiRetryFailed'.tr(),
      ));
      return;
    }

    emit(state.copyWith(
      analysis: analysis,
      status: EnrichmentStatus.analyzed,
    ));
  }

  void _rejectYoutubeResults(RejectYoutubeResults event, Emitter<SongEnrichmentState> emit) async {
    if (state.song == null || state.analysis == null) return;

    final newRejectedIds = List<String>.from(state.rejectedVideoIds);
    for (final v in state.youtubeResults) {
      if (!state.approvedVideos.any((a) => a.videoId == v.videoId)) {
        newRejectedIds.add(v.videoId);
      }
    }

    emit(state.copyWith(
      status: EnrichmentStatus.searchingYoutube,
      rejectedVideoIds: newRejectedIds,
    ));

    final youtubeApiKey = settingsRepository.youtubeApiKey;
    if (youtubeApiKey.isEmpty) {
      emit(state.copyWith(status: EnrichmentStatus.analyzed));
      return;
    }

    // Use the song title + interpret as an alternative query set
    final altQueries = <String>[
      'songKaraokeQuery'.tr(args: [state.song!.title]),
      '${state.song!.title} ${state.analysis?.author ?? ''} live',
      '${state.analysis?.originalTitle ?? state.song!.title} worship',
      '${state.analysis?.originalTitle ?? state.song!.title} lyrics',
    ];

    final allResults = <YoutubeSearchResult>[];
    final seenIds = <String>{...newRejectedIds, ...state.approvedVideos.map((v) => v.videoId)};
    for (final query in altQueries) {
      final results = await aiSearchService.searchYoutube(
        apiKey: youtubeApiKey,
        query: query,
        maxResults: 5,
      );
      for (final r in results) {
        if (seenIds.add(r.videoId)) {
          allResults.add(r);
        }
      }
    }

    emit(state.copyWith(
      youtubeResults: allResults,
      status: EnrichmentStatus.analyzed,
    ));
  }
}

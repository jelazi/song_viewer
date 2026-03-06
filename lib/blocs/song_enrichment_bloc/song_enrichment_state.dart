part of 'song_enrichment_bloc.dart';

enum EnrichmentStatus {
  initial,
  analyzing,
  analyzed,
  searchingYoutube,
  searchingSheets,
  saving,
  saved,
  error,
}

class SongEnrichmentState extends Equatable {
  final Song? song;
  final EnrichmentStatus status;
  final String? errorMessage;

  // AI analysis results
  final AiSongAnalysis? analysis;

  // YouTube search results
  final List<YoutubeSearchResult> youtubeResults;
  final List<YoutubeSearchResult> approvedVideos;

  // Sheet music results
  final List<SheetMusicResult> sheetResults;
  final List<SheetMusicResult> approvedSheets;

  // Approved metadata
  final String? approvedAuthor;
  final String? approvedOriginalTitle;

  const SongEnrichmentState({
    this.song,
    this.status = EnrichmentStatus.initial,
    this.errorMessage,
    this.analysis,
    this.youtubeResults = const [],
    this.approvedVideos = const [],
    this.sheetResults = const [],
    this.approvedSheets = const [],
    this.approvedAuthor,
    this.approvedOriginalTitle,
  });

  bool get hasApprovedChanges => approvedAuthor != null || approvedOriginalTitle != null || approvedVideos.isNotEmpty || approvedSheets.isNotEmpty;

  @override
  List<Object?> get props => [
        song?.id,
        status,
        errorMessage,
        analysis?.author,
        analysis?.originalTitle,
        youtubeResults.length,
        approvedVideos.length,
        sheetResults.length,
        approvedSheets.length,
        approvedAuthor,
        approvedOriginalTitle,
      ];

  SongEnrichmentState copyWith({
    Song? song,
    EnrichmentStatus? status,
    String? errorMessage,
    AiSongAnalysis? analysis,
    List<YoutubeSearchResult>? youtubeResults,
    List<YoutubeSearchResult>? approvedVideos,
    List<SheetMusicResult>? sheetResults,
    List<SheetMusicResult>? approvedSheets,
    String? approvedAuthor,
    String? approvedOriginalTitle,
    bool clearApprovedAuthor = false,
    bool clearApprovedOriginalTitle = false,
    bool clearError = false,
  }) {
    return SongEnrichmentState(
      song: song ?? this.song,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      analysis: analysis ?? this.analysis,
      youtubeResults: youtubeResults ?? this.youtubeResults,
      approvedVideos: approvedVideos ?? this.approvedVideos,
      sheetResults: sheetResults ?? this.sheetResults,
      approvedSheets: approvedSheets ?? this.approvedSheets,
      approvedAuthor: clearApprovedAuthor ? null : (approvedAuthor ?? this.approvedAuthor),
      approvedOriginalTitle: clearApprovedOriginalTitle ? null : (approvedOriginalTitle ?? this.approvedOriginalTitle),
    );
  }
}

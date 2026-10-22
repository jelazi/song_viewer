part of 'pad_bloc.dart';

enum PadSetsStatus { initial, loading, ready, failure }

class PadState extends Equatable {
  final bool isWindowOpen;
  final bool isMinimized;
  final PadSetsStatus status;
  final List<PadSet> sets;
  final String? selectedSetId;

  /// Keys of the selected set that are already on the device.
  final Set<int> downloadedKeys;
  final int? playingKey;

  /// Key being downloaded before it starts playing.
  final int? loadingKey;

  /// Keys finished while the whole set downloads; null when no download runs.
  final int? setDownloadProgress;
  final double volume;
  final int fadeInSeconds;
  final int fadeOutSeconds;
  final PadFadeCurve fadeCurve;

  /// Pads the user saved for songs, keyed by song id.
  final Map<String, SongPadPreference> songPreferences;

  const PadState({
    this.isWindowOpen = false,
    this.isMinimized = false,
    this.status = PadSetsStatus.initial,
    this.sets = const [],
    this.selectedSetId,
    this.downloadedKeys = const {},
    this.playingKey,
    this.loadingKey,
    this.setDownloadProgress,
    this.volume = 0.8,
    this.fadeInSeconds = 4,
    this.fadeOutSeconds = 4,
    this.fadeCurve = PadFadeCurve.smooth,
    this.songPreferences = const {},
  });

  PadSet? get selectedSet => sets.where((set) => set.id == selectedSetId).firstOrNull;

  @override
  List<Object?> get props => [
        isWindowOpen,
        isMinimized,
        status,
        sets,
        selectedSetId,
        downloadedKeys,
        playingKey,
        loadingKey,
        setDownloadProgress,
        volume,
        fadeInSeconds,
        fadeOutSeconds,
        fadeCurve,
        songPreferences,
      ];

  PadState copyWith({
    bool? isWindowOpen,
    bool? isMinimized,
    PadSetsStatus? status,
    List<PadSet>? sets,
    String? selectedSetId,
    Set<int>? downloadedKeys,
    int? playingKey,
    bool clearPlayingKey = false,
    int? loadingKey,
    bool clearLoadingKey = false,
    int? setDownloadProgress,
    bool clearSetDownloadProgress = false,
    double? volume,
    int? fadeInSeconds,
    int? fadeOutSeconds,
    PadFadeCurve? fadeCurve,
    Map<String, SongPadPreference>? songPreferences,
  }) {
    return PadState(
      isWindowOpen: isWindowOpen ?? this.isWindowOpen,
      isMinimized: isMinimized ?? this.isMinimized,
      status: status ?? this.status,
      sets: sets ?? this.sets,
      selectedSetId: selectedSetId ?? this.selectedSetId,
      downloadedKeys: downloadedKeys ?? this.downloadedKeys,
      playingKey: clearPlayingKey ? null : playingKey ?? this.playingKey,
      loadingKey: clearLoadingKey ? null : loadingKey ?? this.loadingKey,
      setDownloadProgress: clearSetDownloadProgress ? null : setDownloadProgress ?? this.setDownloadProgress,
      volume: volume ?? this.volume,
      fadeInSeconds: fadeInSeconds ?? this.fadeInSeconds,
      fadeOutSeconds: fadeOutSeconds ?? this.fadeOutSeconds,
      fadeCurve: fadeCurve ?? this.fadeCurve,
      songPreferences: songPreferences ?? this.songPreferences,
    );
  }
}

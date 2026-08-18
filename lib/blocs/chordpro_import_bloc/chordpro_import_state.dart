part of 'chordpro_import_bloc.dart';

enum ChordProImportStatus {
  initial,
  parsing,
  ready,
  importing,
  done,
  error,
}

class ChordProImportState extends Equatable {
  final ChordProImportStatus status;

  /// Songs parsed out of the picked files, not yet stored.
  final List<Song> songs;

  /// Ids of the songs that will actually be imported.
  final Set<String> selectedIds;

  /// Translation keys or plain notes about what could not be mapped.
  final List<String> warnings;

  /// Blocks that held directives but no lyrics.
  final int skipped;

  /// Number of songs written on the last confirmed import.
  final int importedCount;

  /// Names of the picked files, shown so the user can see what was read.
  final List<String> sourceNames;

  /// Translation key of the failure, when [status] is
  /// [ChordProImportStatus.error].
  final String? errorMessage;

  const ChordProImportState({
    this.status = ChordProImportStatus.initial,
    this.songs = const [],
    this.selectedIds = const {},
    this.warnings = const [],
    this.skipped = 0,
    this.importedCount = 0,
    this.sourceNames = const [],
    this.errorMessage,
  });

  List<Song> get selectedSongs => songs.where((s) => selectedIds.contains(s.id)).toList();

  bool get isBusy => status == ChordProImportStatus.parsing || status == ChordProImportStatus.importing;

  bool get allSelected => songs.isNotEmpty && selectedIds.length == songs.length;

  @override
  List<Object?> get props => [
        status,
        songs.length,
        selectedIds,
        warnings,
        skipped,
        importedCount,
        sourceNames,
        errorMessage,
      ];

  ChordProImportState copyWith({
    ChordProImportStatus? status,
    List<Song>? songs,
    Set<String>? selectedIds,
    List<String>? warnings,
    int? skipped,
    int? importedCount,
    List<String>? sourceNames,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChordProImportState(
      status: status ?? this.status,
      songs: songs ?? this.songs,
      selectedIds: selectedIds ?? this.selectedIds,
      warnings: warnings ?? this.warnings,
      skipped: skipped ?? this.skipped,
      importedCount: importedCount ?? this.importedCount,
      sourceNames: sourceNames ?? this.sourceNames,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/song/song.dart';
import '../../repositories/songs_repository.dart';
import '../../services/chordpro_service.dart';

part 'chordpro_import_event.dart';
part 'chordpro_import_state.dart';

/// Drives the two-step ChordPro import: parse first, show what was found, and
/// only write to the library once the user confirms.
///
/// The bloc is handed file *contents*, never a file path or a picker. Choosing
/// files is platform I/O and belongs to the view; parsing and storing is the
/// logic and belongs here — which also keeps the whole flow testable without a
/// plugin.
class ChordProImportBloc extends Bloc<ChordProImportEvent, ChordProImportState> {
  final SongsRepository songsRepository;
  final ChordProService chordProService;

  ChordProImportBloc({
    required this.songsRepository,
    required this.chordProService,
  }) : super(const ChordProImportState()) {
    on<ParseChordProFiles>(_parseFiles);
    on<ToggleChordProSelection>(_toggleSelection);
    on<SetAllChordProSelected>(_setAllSelected);
    on<ConfirmChordProImport>(_confirmImport);
    on<ResetChordProImport>(_reset);
  }

  void _parseFiles(ParseChordProFiles event, Emitter<ChordProImportState> emit) {
    if (event.files.isEmpty) return;

    emit(const ChordProImportState(status: ChordProImportStatus.parsing));

    final songs = <Song>[];
    final warnings = <String>[];
    var skipped = 0;

    for (final file in event.files) {
      final result = chordProService.parse(file.content, fallbackTitle: file.baseName);
      songs.addAll(result.songs);
      warnings.addAll(result.warnings);
      skipped += result.skipped;
    }

    if (songs.isEmpty) {
      emit(ChordProImportState(
        status: ChordProImportStatus.error,
        errorMessage: 'chordProNoSongsFound',
        warnings: warnings,
        skipped: skipped,
        sourceNames: event.files.map((f) => f.name).toList(),
      ));
      return;
    }

    emit(ChordProImportState(
      status: ChordProImportStatus.ready,
      songs: songs,
      // Everything is selected up front; the user deselects what they don't want.
      selectedIds: songs.map((s) => s.id).toSet(),
      warnings: warnings,
      skipped: skipped,
      sourceNames: event.files.map((f) => f.name).toList(),
    ));
  }

  void _toggleSelection(ToggleChordProSelection event, Emitter<ChordProImportState> emit) {
    final selected = Set<String>.from(state.selectedIds);
    if (!selected.remove(event.songId)) selected.add(event.songId);
    emit(state.copyWith(selectedIds: selected));
  }

  void _setAllSelected(SetAllChordProSelected event, Emitter<ChordProImportState> emit) {
    emit(state.copyWith(
      selectedIds: event.selected ? state.songs.map((s) => s.id).toSet() : <String>{},
    ));
  }

  Future<void> _confirmImport(ConfirmChordProImport event, Emitter<ChordProImportState> emit) async {
    final toImport = state.selectedSongs;
    if (toImport.isEmpty) return;

    emit(state.copyWith(status: ChordProImportStatus.importing));

    try {
      final added = await songsRepository.addImportedSongs(toImport);
      emit(state.copyWith(status: ChordProImportStatus.done, importedCount: added));
    } catch (e) {
      emit(state.copyWith(
        status: ChordProImportStatus.error,
        errorMessage: 'chordProImportFailed',
      ));
    }
  }

  void _reset(ResetChordProImport event, Emitter<ChordProImportState> emit) {
    emit(const ChordProImportState());
  }
}

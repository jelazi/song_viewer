part of 'chordpro_import_bloc.dart';

/// One picked file, already read into memory by the view.
class ChordProFile extends Equatable {
  final String name;
  final String content;

  const ChordProFile({required this.name, required this.content});

  /// File name without its extension — the fallback title for songs whose
  /// ChordPro source carries no `{title}`.
  String get baseName {
    final dot = name.lastIndexOf('.');
    return dot > 0 ? name.substring(0, dot) : name;
  }

  @override
  List<Object?> get props => [name, content];
}

abstract class ChordProImportEvent extends Equatable {
  const ChordProImportEvent();

  @override
  List<Object?> get props => [];
}

/// Parse the given files and show the result for review. Nothing is stored yet.
class ParseChordProFiles extends ChordProImportEvent {
  final List<ChordProFile> files;
  const ParseChordProFiles({required this.files});

  @override
  List<Object?> get props => [files];
}

/// Include or exclude a single parsed song.
class ToggleChordProSelection extends ChordProImportEvent {
  final String songId;
  const ToggleChordProSelection({required this.songId});

  @override
  List<Object?> get props => [songId];
}

/// Select or deselect every parsed song at once.
class SetAllChordProSelected extends ChordProImportEvent {
  final bool selected;
  const SetAllChordProSelected({required this.selected});

  @override
  List<Object?> get props => [selected];
}

/// Write the selected songs into the library.
class ConfirmChordProImport extends ChordProImportEvent {
  const ConfirmChordProImport();
}

/// Back to an empty screen, discarding the parsed batch.
class ResetChordProImport extends ChordProImportEvent {
  const ResetChordProImport();
}

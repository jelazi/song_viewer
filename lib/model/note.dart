// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:json_annotation/json_annotation.dart';

part 'note.g.dart';

/// Represents a note/annotation for a specific line in a song.
///
/// [index] - The line number (0-based) where this note applies
/// [noteText] - The actual text content of the note
@JsonSerializable()
class Note {
  final int index; // Index of the line (0-based)
  final String noteText; // Text content of the note

  const Note({
    required this.index,
    required this.noteText,
  });

  /// Creates an empty Note with index 0 and empty text
  const Note.empty()
      : index = 0,
        noteText = '';

  /// Creates a copy of this Note with updated fields
  Note copyWith({
    int? index,
    String? noteText,
  }) {
    return Note(
      index: index ?? this.index,
      noteText: noteText ?? this.noteText,
    );
  }

  /// Check if note text is empty
  bool get isEmpty => noteText.trim().isEmpty;

  /// Check if note text is not empty
  bool get isNotEmpty => !isEmpty;

  /// Get trimmed note text
  String get trimmedText => noteText.trim();

  /// Get length of note text
  int get length => noteText.length;

  /// Check if the note is valid (non-negative index and non-empty text)
  bool get isValid => index >= 0 && noteText.isNotEmpty;

  @override
  bool operator ==(Object other) => identical(this, other) || other is Note && runtimeType == other.runtimeType && index == other.index && noteText == other.noteText;

  @override
  int get hashCode => index.hashCode ^ noteText.hashCode;

  @override
  String toString() => 'Note(index: $index, noteText: $noteText)';

  factory Note.fromJson(Map<String, dynamic> json) => _$NoteFromJson(json);
  Map<String, dynamic> toJson() => _$NoteToJson(this);
}

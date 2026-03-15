import 'package:json_annotation/json_annotation.dart';

part 'chord_diagram.g.dart';

/// Represents a guitar chord diagram stored in PocketBase.
/// Each chord has a name (e.g. "C", "Am7", "G/B") and a list of
/// fingering position strings (e.g. ["0 3 2 0 1 0", "x 3 5 5 5 3"]).
@JsonSerializable()
class ChordDiagram {
  final String name;
  final List<String> positions;

  ChordDiagram({
    required this.name,
    required this.positions,
  });

  factory ChordDiagram.fromJson(Map<String, dynamic> json) =>
      _$ChordDiagramFromJson(json);

  Map<String, dynamic> toJson() => _$ChordDiagramToJson(this);

  ChordDiagram copyWith({
    String? name,
    List<String>? positions,
  }) {
    return ChordDiagram(
      name: name ?? this.name,
      positions: positions ?? List.from(this.positions),
    );
  }
}

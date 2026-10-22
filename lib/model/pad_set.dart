import 'package:equatable/equatable.dart';

/// One set of worship pads: a looped recording for each of the twelve keys.
class PadSet extends Equatable {
  final String id;
  final String name;

  /// Download URL per key, keyed by semitone (0 = C, 11 = H).
  final Map<int, String> fileUrls;

  const PadSet({required this.id, required this.name, required this.fileUrls});

  factory PadSet.fromJson(Map<String, dynamic> json) => PadSet(
        id: json['id'] as String,
        name: json['name'] as String,
        fileUrls: (json['fileUrls'] as Map<String, dynamic>).map((key, value) => MapEntry(int.parse(key), value as String)),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fileUrls': fileUrls.map((key, value) => MapEntry('$key', value)),
      };

  @override
  List<Object?> get props => [id, name, fileUrls];
}

/// The pad the user picked for one song: the key (semitone, 0 = C) and the
/// set it sounded best in.
class SongPadPreference extends Equatable {
  final int semitone;
  final String? setId;

  const SongPadPreference({required this.semitone, this.setId});

  factory SongPadPreference.fromJson(Map<String, dynamic> json) => SongPadPreference(
        semitone: (json['semitone'] as num).toInt(),
        setId: json['setId'] as String?,
      );

  Map<String, dynamic> toJson() => {'semitone': semitone, 'setId': setId};

  @override
  List<Object?> get props => [semitone, setId];
}

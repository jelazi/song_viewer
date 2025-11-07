// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'settings_bloc.dart';

class SettingsState extends Equatable {
  final double previewFontTextSize;
  final double previewFontChordSize;
  final double editFontTextSize;
  final double editFontChordSize;
  final Color previewColorText;
  final Color previewColorChord;
  final Color editColorText;
  final Color editColorChord;
  final bool isEditIconVisible;
  final bool autoHideTopBar;
  final TypeClickCard typeClickCard;
  const SettingsState({
    required this.previewFontTextSize,
    required this.previewFontChordSize,
    required this.editFontTextSize,
    required this.editFontChordSize,
    required this.previewColorText,
    required this.previewColorChord,
    required this.editColorText,
    required this.editColorChord,
    required this.isEditIconVisible,
    required this.autoHideTopBar,
    required this.typeClickCard,
  });

  @override
  List<Object> get props => [
        previewFontTextSize,
        previewColorChord,
        previewFontChordSize,
        previewColorText,
        previewColorChord,
        editColorChord,
        editFontChordSize,
        editColorText,
        isEditIconVisible,
        autoHideTopBar,
        typeClickCard,
      ];

  SettingsState copyWith({
    double? previewFontTextSize,
    double? previewFontChordSize,
    double? editFontTextSize,
    double? editFontChordSize,
    Color? previewColorText,
    Color? previewColorChord,
    Color? editColorText,
    Color? editColorChord,
    bool? isEditIconVisible,
    bool? autoHideTopBar,
    TypeClickCard? typeClickCard,
  }) {
    return SettingsState(
      previewFontTextSize: previewFontTextSize ?? this.previewFontTextSize,
      previewFontChordSize: previewFontChordSize ?? this.previewFontChordSize,
      editFontTextSize: editFontTextSize ?? this.editFontTextSize,
      editFontChordSize: editFontChordSize ?? this.editFontChordSize,
      previewColorText: previewColorText ?? this.previewColorText,
      previewColorChord: previewColorChord ?? this.previewColorChord,
      editColorText: editColorText ?? this.editColorText,
      editColorChord: editColorChord ?? this.editColorChord,
      isEditIconVisible: isEditIconVisible ?? this.isEditIconVisible,
      autoHideTopBar: autoHideTopBar ?? this.autoHideTopBar,
      typeClickCard: typeClickCard ?? this.typeClickCard,
    );
  }
}

class SettingsInitial extends SettingsState {
  const SettingsInitial({
    required super.previewFontTextSize,
    required super.previewFontChordSize,
    required super.editFontTextSize,
    required super.editFontChordSize,
    required super.previewColorText,
    required super.previewColorChord,
    required super.editColorText,
    required super.editColorChord,
    required super.isEditIconVisible,
    required super.autoHideTopBar,
    required super.typeClickCard,
  });
}

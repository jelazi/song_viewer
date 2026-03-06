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
  // Presentation settings
  final int presentationScreenIndex;
  final int presentationLinesPerPage;
  final double presentationFontSize;
  final Color presentationFontColor;
  final bool presentationShowChords;
  final bool presentationBlackFirstPage;
  final bool presentationBlackLastPage;
  final bool presentationShowPageNumber;
  final bool presentationShowTitle;
  final bool presentationAutoPageByParagraphs;
  // QR code URLs — dynamic list
  final List<QrLink> qrLinks;
  // AI enrichment API keys
  final String groqApiKey;
  final String youtubeApiKey;
  final String geminiApiKey;
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
    required this.presentationScreenIndex,
    required this.presentationLinesPerPage,
    required this.presentationFontSize,
    required this.presentationFontColor,
    required this.presentationShowChords,
    required this.presentationBlackFirstPage,
    required this.presentationBlackLastPage,
    required this.presentationShowPageNumber,
    required this.presentationShowTitle,
    required this.presentationAutoPageByParagraphs,
    required this.qrLinks,
    required this.groqApiKey,
    required this.youtubeApiKey,
    required this.geminiApiKey,
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
        presentationScreenIndex,
        presentationLinesPerPage,
        presentationFontSize,
        presentationFontColor,
        presentationShowChords,
        presentationBlackFirstPage,
        presentationBlackLastPage,
        presentationShowPageNumber,
        presentationShowTitle,
        presentationAutoPageByParagraphs,
        qrLinks,
        groqApiKey,
        youtubeApiKey,
        geminiApiKey,
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
    int? presentationScreenIndex,
    int? presentationLinesPerPage,
    double? presentationFontSize,
    Color? presentationFontColor,
    bool? presentationShowChords,
    bool? presentationBlackFirstPage,
    bool? presentationBlackLastPage,
    bool? presentationShowPageNumber,
    bool? presentationShowTitle,
    bool? presentationAutoPageByParagraphs,
    List<QrLink>? qrLinks,
    String? groqApiKey,
    String? youtubeApiKey,
    String? geminiApiKey,
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
      presentationScreenIndex: presentationScreenIndex ?? this.presentationScreenIndex,
      presentationLinesPerPage: presentationLinesPerPage ?? this.presentationLinesPerPage,
      presentationFontSize: presentationFontSize ?? this.presentationFontSize,
      presentationFontColor: presentationFontColor ?? this.presentationFontColor,
      presentationShowChords: presentationShowChords ?? this.presentationShowChords,
      presentationBlackFirstPage: presentationBlackFirstPage ?? this.presentationBlackFirstPage,
      presentationBlackLastPage: presentationBlackLastPage ?? this.presentationBlackLastPage,
      presentationShowPageNumber: presentationShowPageNumber ?? this.presentationShowPageNumber,
      presentationShowTitle: presentationShowTitle ?? this.presentationShowTitle,
      presentationAutoPageByParagraphs: presentationAutoPageByParagraphs ?? this.presentationAutoPageByParagraphs,
      qrLinks: qrLinks ?? this.qrLinks,
      groqApiKey: groqApiKey ?? this.groqApiKey,
      youtubeApiKey: youtubeApiKey ?? this.youtubeApiKey,
      geminiApiKey: geminiApiKey ?? this.geminiApiKey,
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
    required super.presentationScreenIndex,
    required super.presentationLinesPerPage,
    required super.presentationFontSize,
    required super.presentationFontColor,
    required super.presentationShowChords,
    required super.presentationBlackFirstPage,
    required super.presentationBlackLastPage,
    required super.presentationShowPageNumber,
    required super.presentationShowTitle,
    required super.presentationAutoPageByParagraphs,
    required super.qrLinks,
    required super.groqApiKey,
    required super.youtubeApiKey,
    required super.geminiApiKey,
  });
}

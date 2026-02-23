part of 'presentation_bloc.dart';

class PresentationState {
  final Song? currentSong;
  final bool isPresenting;
  final bool isFullScreen;
  final bool hasMultipleMonitors;
  final int monitorCount;
  final Display? primaryDisplay;
  final Display? secondaryDisplay;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  // Pagination
  final int currentPage;
  final int totalPages;
  final int linesPerPage;
  final bool showChords;
  final int screenIndex;
  final bool autoPageByParagraphs;
  // Computed page content
  final List<String> pageLines;

  const PresentationState({
    this.currentSong,
    this.isPresenting = false,
    this.isFullScreen = false,
    this.hasMultipleMonitors = false,
    this.monitorCount = 1,
    this.primaryDisplay,
    this.secondaryDisplay,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
    this.fontSize = 36.0,
    this.currentPage = 0,
    this.totalPages = 1,
    this.linesPerPage = 8,
    this.showChords = false,
    this.screenIndex = 0,
    this.autoPageByParagraphs = false,
    this.pageLines = const [],
  });

  PresentationState copyWith({
    Song? currentSong,
    bool? isPresenting,
    bool? isFullScreen,
    bool? hasMultipleMonitors,
    int? monitorCount,
    Display? primaryDisplay,
    Display? secondaryDisplay,
    Color? backgroundColor,
    Color? textColor,
    double? fontSize,
    int? currentPage,
    int? totalPages,
    int? linesPerPage,
    bool? showChords,
    int? screenIndex,
    bool? autoPageByParagraphs,
    List<String>? pageLines,
  }) {
    return PresentationState(
      currentSong: currentSong ?? this.currentSong,
      isPresenting: isPresenting ?? this.isPresenting,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      hasMultipleMonitors: hasMultipleMonitors ?? this.hasMultipleMonitors,
      monitorCount: monitorCount ?? this.monitorCount,
      primaryDisplay: primaryDisplay ?? this.primaryDisplay,
      secondaryDisplay: secondaryDisplay ?? this.secondaryDisplay,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      linesPerPage: linesPerPage ?? this.linesPerPage,
      showChords: showChords ?? this.showChords,
      screenIndex: screenIndex ?? this.screenIndex,
      autoPageByParagraphs: autoPageByParagraphs ?? this.autoPageByParagraphs,
      pageLines: pageLines ?? this.pageLines,
    );
  }

  /// Whether there is a next page
  bool get hasNextPage => currentPage < totalPages - 1;

  /// Whether there is a previous page
  bool get hasPreviousPage => currentPage > 0;

  /// Get current page content as string
  String get currentPageContent => pageLines.join('\n');
}

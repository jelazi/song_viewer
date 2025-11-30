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
    );
  }
}

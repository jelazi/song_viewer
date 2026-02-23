part of 'presentation_bloc.dart';

abstract class PresentationEvent {
  const PresentationEvent();
}

class OpenPresentation extends PresentationEvent {
  final bool useSecondaryMonitor;

  const OpenPresentation({
    this.useSecondaryMonitor = true,
  });
}

class ClosePresentation extends PresentationEvent {
  const ClosePresentation();
}

class UpdatePresentationSong extends PresentationEvent {
  final Song song;
  final int? page;

  const UpdatePresentationSong({required this.song, this.page});
}

class ToggleFullScreen extends PresentationEvent {
  const ToggleFullScreen();
}

class CheckMonitors extends PresentationEvent {
  const CheckMonitors();
}

class SetBackgroundColor extends PresentationEvent {
  final Color color;

  const SetBackgroundColor({required this.color});
}

class SetTextColor extends PresentationEvent {
  final Color color;

  const SetTextColor({required this.color});
}

class SetFontSize extends PresentationEvent {
  final double fontSize;

  const SetFontSize({required this.fontSize});
}

/// Navigate to next page of lyrics
class NextPresentationPage extends PresentationEvent {
  const NextPresentationPage();
}

/// Navigate to previous page of lyrics
class PreviousPresentationPage extends PresentationEvent {
  const PreviousPresentationPage();
}

/// Update presentation settings
class UpdatePresentationSettings extends PresentationEvent {
  final int? linesPerPage;
  final double? fontSize;
  final Color? textColor;
  final bool? showChords;
  final int? screenIndex;
  final bool? autoPageByParagraphs;

  const UpdatePresentationSettings({
    this.linesPerPage,
    this.fontSize,
    this.textColor,
    this.showChords,
    this.screenIndex,
    this.autoPageByParagraphs,
  });
}

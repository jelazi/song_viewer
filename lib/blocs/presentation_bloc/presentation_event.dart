part of 'presentation_bloc.dart';

abstract class PresentationEvent {
  const PresentationEvent();
}

class OpenPresentation extends PresentationEvent {
  final Song song;
  final bool useSecondaryMonitor;

  const OpenPresentation({
    required this.song,
    this.useSecondaryMonitor = true,
  });
}

class ClosePresentation extends PresentationEvent {
  const ClosePresentation();
}

class UpdatePresentationSong extends PresentationEvent {
  final Song song;

  const UpdatePresentationSong({required this.song});
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

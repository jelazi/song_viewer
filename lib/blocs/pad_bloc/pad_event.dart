part of 'pad_bloc.dart';

abstract class PadEvent extends Equatable {
  const PadEvent();

  @override
  List<Object?> get props => [];
}

class _PadInit extends PadEvent {
  const _PadInit();
}

class OpenPadWindow extends PadEvent {
  const OpenPadWindow();
}

class ClosePadWindow extends PadEvent {
  const ClosePadWindow();
}

/// Shrinks the open window to a small bar (tablet) or into the app bar (phone).
class MinimizePadWindow extends PadEvent {
  const MinimizePadWindow();
}

class RestorePadWindow extends PadEvent {
  const RestorePadWindow();
}

/// What the app bar / ribbon button does: open the window, then switch it
/// between full size and minimized. It never stops a pad.
class TogglePadWindow extends PadEvent {
  const TogglePadWindow();
}

/// Remembers the playing pad (key and set) for the song [songId].
class SaveSongPad extends PadEvent {
  final String songId;
  const SaveSongPad({required this.songId});

  @override
  List<Object?> get props => [songId];
}

class RemoveSongPad extends PadEvent {
  final String songId;
  const RemoveSongPad({required this.songId});

  @override
  List<Object?> get props => [songId];
}

class SelectPadSet extends PadEvent {
  final String setId;
  const SelectPadSet({required this.setId});

  @override
  List<Object?> get props => [setId];
}

/// Plays the pad in [semitone], or stops it when it is the one playing.
class TogglePadKey extends PadEvent {
  final int semitone;
  const TogglePadKey({required this.semitone});

  @override
  List<Object?> get props => [semitone];
}

class StopPad extends PadEvent {
  const StopPad();
}

class ChangePadVolume extends PadEvent {
  final double volume;
  const ChangePadVolume({required this.volume});

  @override
  List<Object?> get props => [volume];
}

class DownloadPadSet extends PadEvent {
  const DownloadPadSet();
}

class ChangePadFade extends PadEvent {
  final int? fadeInSeconds;
  final int? fadeOutSeconds;
  final PadFadeCurve? curve;
  const ChangePadFade({this.fadeInSeconds, this.fadeOutSeconds, this.curve});

  @override
  List<Object?> get props => [fadeInSeconds, fadeOutSeconds, curve];
}

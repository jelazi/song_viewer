part of 'preview_chord_bloc.dart';

class PreviewChordEvent extends Equatable {
  const PreviewChordEvent();

  @override
  List<Object> get props => [];
}

class _Init extends PreviewChordEvent {
  const _Init();
}

class ChangeCurrentSong extends PreviewChordEvent {
  final Song? song;
  const ChangeCurrentSong({required this.song});

  @override
  List<Object> get props => [song ?? ''];
}

class ChangeTextFontSize extends PreviewChordEvent {
  final double fontSize;
  const ChangeTextFontSize({required this.fontSize});

  @override
  List<Object> get props => [fontSize];
}

class ChangeChordFontSize extends PreviewChordEvent {
  final double fontSize;
  const ChangeChordFontSize({required this.fontSize});

  @override
  List<Object> get props => [fontSize];
}

class ChangeFontSize extends PreviewChordEvent {
  final bool isIncrease;
  const ChangeFontSize({
    required this.isIncrease,
  });

  @override
  List<Object> get props => [isIncrease];
}

class ChangeAppBarStatus extends PreviewChordEvent {
  final bool status;
  const ChangeAppBarStatus({required this.status});

  @override
  List<Object> get props => [status];
}

class ChangeVisibleButtons extends PreviewChordEvent {
  final bool status;
  const ChangeVisibleButtons({required this.status});

  @override
  List<Object> get props => [status];
}

class TransposeChord extends PreviewChordEvent {
  final int increment;
  const TransposeChord({required this.increment});

  @override
  List<Object> get props => [increment];
}

class SelectSongInPreview extends PreviewChordEvent {
  final String selectSongId;
  final String title;
  final String interpret;
  final String lyricsWithoutChords;
  const SelectSongInPreview({required this.selectSongId, required this.title, required this.interpret, required this.lyricsWithoutChords});

  @override
  List<Object> get props => [selectSongId];
}

class UpdateSelectedSong extends PreviewChordEvent {
  final String selectedSongId;
  const UpdateSelectedSong({required this.selectedSongId});

  @override
  List<Object> get props => [selectedSongId];
}

class ChangeColumnStatus extends PreviewChordEvent {
  final bool status;
  const ChangeColumnStatus({
    required this.status,
  });

  @override
  List<Object> get props => [
        status,
      ];
}

class ChangeHeightWindow extends PreviewChordEvent {
  final double height;
  const ChangeHeightWindow({required this.height});

  @override
  List<Object> get props => [height];
}

class ChangeCurrentColumn extends PreviewChordEvent {
  final int column;
  const ChangeCurrentColumn({required this.column});

  @override
  List<Object> get props => [column];
}

class ChangeLyricFromWebSongUpdate extends PreviewChordEvent {
  final int typeSearching;
  final WebSong webSong;
  const ChangeLyricFromWebSongUpdate({required this.typeSearching, required this.webSong});

  @override
  List<Object> get props => [typeSearching, webSong];
}

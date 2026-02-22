part of 'edit_song_bloc.dart';

class EditSongEvent extends Equatable {
  const EditSongEvent();

  @override
  List<Object> get props => [];
}

class _Init extends EditSongEvent {
  const _Init();

  @override
  List<Object> get props => [];
}

class ChangeEditSong extends EditSongEvent {
  final Song song;
  final bool isOriginalLyrics;
  const ChangeEditSong({required this.song, required this.isOriginalLyrics});
}

class ChangeSongValue extends EditSongEvent {
  final dynamic value;
  final String nameValue;
  final String appVersion;
  final TextSelection? selection;
  const ChangeSongValue({required this.value, required this.nameValue, required this.appVersion, this.selection});
}

class CheckModifiedSong extends EditSongEvent {
  const CheckModifiedSong();
}

class ResetValue extends EditSongEvent {
  final String nameValue;
  const ResetValue({required this.nameValue});
  @override
  List<Object> get props => [nameValue];
}

class TransposeChordPermanent extends EditSongEvent {
  final int transposeIncrement;
  final bool isOriginalLyric;
  const TransposeChordPermanent({required this.transposeIncrement, required this.isOriginalLyric});
  @override
  List<Object> get props => [transposeIncrement, isOriginalLyric];
}

class ChangeFontSizeEdit extends EditSongEvent {
  final bool isIncrease;
  const ChangeFontSizeEdit({required this.isIncrease});

  @override
  List<Object> get props => [isIncrease];
}

class SelectChord extends EditSongEvent {
  final int index;
  const SelectChord({required this.index});

  @override
  List<Object> get props => [index];
}

class ChangeListUniqueChordsIsVisible extends EditSongEvent {
  final bool isVisible;
  const ChangeListUniqueChordsIsVisible({required this.isVisible});

  @override
  List<Object> get props => [isVisible];
}

class UpdateListUniqueChords extends EditSongEvent {
  final TypeLyric typeLyric;
  const UpdateListUniqueChords({required this.typeLyric});

  @override
  List<Object> get props => [typeLyric];
}

class ChangePositionChord extends EditSongEvent {
  final int index;
  final bool increase;
  const ChangePositionChord({required this.index, required this.increase});

  @override
  List<Object> get props => [index, increase];
}

class ChangeChord extends EditSongEvent {
  final int index;
  final String chord;
  const ChangeChord({required this.index, required this.chord});

  @override
  List<Object> get props => [index, chord];
}

class CreateChord extends EditSongEvent {
  final int index;
  final String chord;
  const CreateChord({required this.index, required this.chord});

  @override
  List<Object> get props => [index, chord];
}

class DeleteChord extends EditSongEvent {
  final int index;
  const DeleteChord({required this.index});

  @override
  List<Object> get props => [index];
}

class SaveSong extends EditSongEvent {
  final String typeApp;
  const SaveSong({required this.typeApp});
  @override
  List<Object> get props => [typeApp];
}

class CreateNewSong extends EditSongEvent {
  final Song song;
  const CreateNewSong({required this.song});

  @override
  List<Object> get props => [song];
}

class ChangeGroupForCurrentSong extends EditSongEvent {
  final String group;
  const ChangeGroupForCurrentSong({required this.group});

  @override
  List<Object> get props => [group];
}

class DeleteCurrentSong extends EditSongEvent {
  const DeleteCurrentSong();
}

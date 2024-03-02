// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'edit_song_bloc.dart';

class EditSongState extends Equatable {
  final Song currentEditSong;
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final String selectChord;
  final int selectChordIndex;
  final List<String> listUniqueChords;
  final int transposeIncrement;
  final bool listUniqueChordsIsVisible;
  final String currentText;
  final List<int> listSelectedChords;
  final bool isOriginalLyrics;
  final List<String> listAllGroups;
  final List<String> currentGroups;
  final TextEditingController titleController;
  final TextEditingController interpretController;
  final TextEditingController indexSongBookController;

  const EditSongState({
    required this.currentEditSong,
    required this.textStyle,
    required this.chordStyle,
    required this.selectChord,
    required this.selectChordIndex,
    required this.listUniqueChords,
    required this.transposeIncrement,
    required this.listUniqueChordsIsVisible,
    required this.currentText,
    required this.listSelectedChords,
    required this.isOriginalLyrics,
    required this.listAllGroups,
    required this.currentGroups,
    required this.titleController,
    required this.interpretController,
    required this.indexSongBookController,
  });

  @override
  List<Object> get props => [
        currentEditSong,
        textStyle,
        chordStyle,
        selectChord,
        selectChordIndex,
        listUniqueChords,
        transposeIncrement,
        listUniqueChordsIsVisible,
        currentText,
        listSelectedChords,
        isOriginalLyrics,
        listAllGroups,
        currentGroups,
        titleController,
        interpretController,
        indexSongBookController,
      ];

  EditSongState copyWith({
    Song? currentEditSong,
    TextStyle? textStyle,
    TextStyle? chordStyle,
    String? selectChord,
    int? selectChordIndex,
    List<String>? listUniqueChords,
    int? transposeIncrement,
    bool? listUniqueChordsIsVisible,
    String? currentText,
    List<int>? listSelectedChords,
    bool? isOriginalLyrics,
    List<String>? listAllGroups,
    List<String>? currentGroups,
    TextEditingController? titleController,
    TextEditingController? interpretController,
    TextEditingController? indexSongBookController,
  }) {
    return EditSongState(
      currentEditSong: currentEditSong ?? this.currentEditSong,
      textStyle: textStyle ?? this.textStyle,
      chordStyle: chordStyle ?? this.chordStyle,
      selectChord: selectChord ?? this.selectChord,
      selectChordIndex: selectChordIndex ?? this.selectChordIndex,
      listUniqueChords: listUniqueChords ?? this.listUniqueChords,
      transposeIncrement: transposeIncrement ?? this.transposeIncrement,
      listUniqueChordsIsVisible: listUniqueChordsIsVisible ?? this.listUniqueChordsIsVisible,
      currentText: currentText ?? this.currentText,
      listSelectedChords: listSelectedChords ?? this.listSelectedChords,
      isOriginalLyrics: isOriginalLyrics ?? this.isOriginalLyrics,
      listAllGroups: listAllGroups ?? this.listAllGroups,
      currentGroups: currentGroups ?? this.currentGroups,
      titleController: titleController ?? this.titleController,
      interpretController: interpretController ?? this.interpretController,
      indexSongBookController: indexSongBookController ?? this.indexSongBookController,
    );
  }
}

class EditSongInitial extends EditSongState {
  const EditSongInitial(
      {required super.currentEditSong,
      required super.textStyle,
      required super.chordStyle,
      required super.selectChord,
      required super.listUniqueChords,
      required super.transposeIncrement,
      required super.selectChordIndex,
      required super.listUniqueChordsIsVisible,
      required super.currentText,
      required super.listSelectedChords,
      required super.isOriginalLyrics,
      required super.listAllGroups,
      required super.currentGroups,
      required super.titleController,
      required super.interpretController,
      required super.indexSongBookController});
}

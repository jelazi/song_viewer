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
  final int selectedChord;
  final bool isOriginalLyrics;
  final List<String> listAllGroups;
  final List<String> currentGroups;
  final TextEditingController titleController;
  final TextEditingController interpretController;
  final TextEditingController indexSongBookController;
  final String title;
  final String interpret;
  final String indexSongBook;
  final List<String> tags;
  final List<String> notes;

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
    required this.selectedChord,
    required this.isOriginalLyrics,
    required this.listAllGroups,
    required this.currentGroups,
    required this.titleController,
    required this.interpretController,
    required this.indexSongBookController,
    required this.title,
    required this.interpret,
    required this.indexSongBook,
    required this.tags,
    required this.notes,
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
        selectedChord,
        isOriginalLyrics,
        listAllGroups,
        currentGroups,
        titleController,
        interpretController,
        indexSongBookController,
        title,
        interpret,
        indexSongBook,
        tags,
        notes,
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
    int? selectedChord,
    bool? isOriginalLyrics,
    List<String>? listAllGroups,
    List<String>? currentGroups,
    TextEditingController? titleController,
    TextEditingController? interpretController,
    TextEditingController? indexSongBookController,
    String? title,
    String? interpret,
    String? indexSongBook,
    List<String>? tags,
    List<String>? notes,
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
      selectedChord: selectedChord ?? this.selectedChord,
      isOriginalLyrics: isOriginalLyrics ?? this.isOriginalLyrics,
      listAllGroups: listAllGroups ?? this.listAllGroups,
      currentGroups: currentGroups ?? this.currentGroups,
      titleController: titleController ?? this.titleController,
      interpretController: interpretController ?? this.interpretController,
      indexSongBookController: indexSongBookController ?? this.indexSongBookController,
      title: title ?? this.title,
      interpret: interpret ?? this.interpret,
      indexSongBook: indexSongBook ?? this.indexSongBook,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
    );
  }

  List<String> checkEditSong() {
    List<String> list = [];
    if (currentEditSong.title != title) {
      list.add('title');
    }
    if (currentEditSong.interpret != interpret && (currentEditSong.interpret != null || interpret != '')) {
      list.add('interpret');
    }
    if (currentEditSong.indexSongBook.toString() != indexSongBook && (currentEditSong.indexSongBook != null || indexSongBook != '')) {
      list.add('indexSongBook');
    }
    if (currentEditSong.tags != tags && (currentEditSong.tags != null || tags.isNotEmpty)) {
      list.add('tags');
    }
    if (currentEditSong.groups != currentGroups && (currentEditSong.groups != null || currentGroups.isNotEmpty)) {
      list.add('groups');
    }
    if (currentEditSong.lyrics != currentText) {
      list.add('lyrics');
    }
    return list;
  }
}

class EditSongInitial extends EditSongState {
  const EditSongInitial({
    required super.currentEditSong,
    required super.textStyle,
    required super.chordStyle,
    required super.selectChord,
    required super.listUniqueChords,
    required super.transposeIncrement,
    required super.selectChordIndex,
    required super.listUniqueChordsIsVisible,
    required super.currentText,
    required super.selectedChord,
    required super.isOriginalLyrics,
    required super.listAllGroups,
    required super.currentGroups,
    required super.titleController,
    required super.interpretController,
    required super.indexSongBookController,
    required super.title,
    required super.interpret,
    required super.indexSongBook,
    required super.tags,
    required super.notes,
  });
}

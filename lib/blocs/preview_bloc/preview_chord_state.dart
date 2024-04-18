// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'preview_chord_bloc.dart';

class PreviewChordState extends Equatable {
  final CurrentData data;
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final bool twoColumns;
  final String selectedSongId;
  final int transposeIncrement;
  final int scrollSpeed;
  final int currentColumn;
  final int maxLines;
  final bool appBarStatus;
  final bool visibleButtons;
  final int cap;
  final double heightWindow;
  const PreviewChordState({
    required this.data,
    required this.textStyle,
    required this.chordStyle,
    required this.twoColumns,
    required this.selectedSongId,
    required this.transposeIncrement,
    required this.scrollSpeed,
    required this.currentColumn,
    required this.maxLines,
    required this.appBarStatus,
    required this.visibleButtons,
    required this.cap,
    required this.heightWindow,
  });

  @override
  List<Object> get props => [
        data,
        appBarStatus,
        textStyle,
        chordStyle,
        twoColumns,
        transposeIncrement,
        scrollSpeed,
        currentColumn,
        maxLines,
        appBarStatus,
        visibleButtons,
        cap,
        selectedSongId,
      ];

  PreviewChordState copyWith({
    CurrentData? data,
    TextStyle? textStyle,
    TextStyle? chordStyle,
    bool? twoColumns,
    String? selectedSongId,
    int? transposeIncrement,
    int? scrollSpeed,
    int? currentColumn,
    int? maxLines,
    bool? appBarStatus,
    bool? visibleButtons,
    int? cap,
    double? heightWindow,
  }) {
    return PreviewChordState(
      data: data ?? this.data,
      textStyle: textStyle ?? this.textStyle,
      chordStyle: chordStyle ?? this.chordStyle,
      twoColumns: twoColumns ?? this.twoColumns,
      selectedSongId: selectedSongId ?? this.selectedSongId,
      transposeIncrement: transposeIncrement ?? this.transposeIncrement,
      scrollSpeed: scrollSpeed ?? this.scrollSpeed,
      currentColumn: currentColumn ?? this.currentColumn,
      maxLines: maxLines ?? this.maxLines,
      appBarStatus: appBarStatus ?? this.appBarStatus,
      visibleButtons: visibleButtons ?? this.visibleButtons,
      cap: cap ?? this.cap,
      heightWindow: heightWindow ?? this.heightWindow,
    );
  }

  List<String> lyricWithColumns(bool chords, bool notes, TypeLyric typeLyric) {
    Song? song = data.song;
    if (song == null) {
      return [];
    }
    List<String> listLines = typeLyric == TypeLyric.translate ? data.song!.lyrics.split('\n') : (song.originalLyrics ?? '').split('\n');
    double realLines = 0;
    for (String line in listLines) {
      if (line.contains('[')) {
        realLines += 2;
      } else {
        realLines++;
      }
    }

    List<String> result = [];
    if (realLines <= maxLines) {
      result.add(typeLyric == TypeLyric.translate ? song.lyrics : song.originalLyrics ?? '');
      return result;
    }

    String item = '';
    int index = 0;
    for (String line in listLines) {
      item += '$line\n';
      if (index < maxLines) {
        if (line.contains('[')) {
          index += 2;
        } else {
          index++;
        }
      } else {
        result.add(item);
        item = '';
        index = 0;
      }
    }
    String it = item.replaceAll(' ', '');
    it = it.replaceAll('\n', '');

    if (it.isNotEmpty) {
      result.add(item);
    }

    return result;
  }
}

class CurrentData {
  final Song? song;
  CurrentData({required this.song});

  CurrentData copyWith({
    Song? song,
  }) {
    return CurrentData(
      song: song,
    );
  }
}

class PreviewChordInitial extends PreviewChordState {
  const PreviewChordInitial({
    required super.data,
    required super.textStyle,
    required super.chordStyle,
    required super.twoColumns,
    required super.transposeIncrement,
    required super.scrollSpeed,
    required super.currentColumn,
    required super.maxLines,
    required super.appBarStatus,
    required super.visibleButtons,
    required super.cap,
    required super.selectedSongId,
    required super.heightWindow,
  });
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:collection/collection.dart';
import 'package:default_project/model/youtube_video.dart';
import 'package:default_project/services/enums.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:uuid/uuid.dart';

import '../note.dart';
import 'song_item.dart';
import 'song_line.dart';

part 'song.g.dart';

@JsonSerializable(explicitToJson: true)
class Song {
  String id;
  String title;
  String lyrics;
  String? originalLyrics;
  int? indexSongBook;
  String? interpret;
  TypeTranspose typeTranspose = TypeTranspose.czech;

  int? songBar;
  int? bmp;

  List<String>? sheets;
  List<String>? groups;
  List<String>? tags;
  List<Note>? notes;

  List<YoutubeVideo>? youtubeVideos;

  Song({
    required this.id,
    required this.title,
    required this.lyrics,
    this.originalLyrics,
    this.indexSongBook,
    this.interpret,
    this.typeTranspose = TypeTranspose.czech,
    this.songBar,
    this.bmp,
    this.sheets,
    this.groups,
    this.tags,
    this.notes,
    this.youtubeVideos,
  });

  Song.empty()
      : id = '',
        title = '',
        lyrics = '',
        originalLyrics = '',
        interpret = '',
        typeTranspose = TypeTranspose.czech,
        songBar = 0,
        bmp = 0,
        sheets = [],
        groups = [],
        tags = [],
        notes = [],
        youtubeVideos = [];

  Song copyWith({
    String? id,
    String? title,
    String? lyrics,
    String? originalLyrics,
    int? indexSongBook,
    String? interpret,
    TypeTranspose? typeTranspose,
    int? songBar,
    int? bmp,
    List<String>? sheets,
    List<String>? groups,
    List<String>? tags,
    List<Note>? notes,
    List<YoutubeVideo>? youtubeVideos,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      lyrics: lyrics ?? this.lyrics,
      originalLyrics: originalLyrics ?? this.originalLyrics,
      indexSongBook: indexSongBook ?? this.indexSongBook,
      interpret: interpret ?? this.interpret,
      typeTranspose: typeTranspose ?? this.typeTranspose,
      songBar: songBar ?? this.songBar,
      bmp: bmp ?? this.bmp,
      sheets: sheets ?? this.sheets,
      groups: groups ?? this.groups,
      tags: tags ?? this.tags,
      notes: notes ?? this.notes,
      youtubeVideos: youtubeVideos ?? this.youtubeVideos,
    );
  }

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
  Map<String, dynamic> toJson() => _$SongToJson(this);

  List<SongLine> listLyrics(bool chords, bool notes, TypeLyric typeLyric) {
    List<SongLine> listLyrics = [];
    List<String> listLines = lyrics.split(('\n'));
    switch (typeLyric) {
      case TypeLyric.undefined:
        listLines = lyrics.split(('\n'));
        listLines += (originalLyrics ?? '').split(('\n'));
        break;
      case TypeLyric.original:
        listLines = (originalLyrics ?? '').split(('\n'));
        break;
      case TypeLyric.translate:
        listLines = lyrics.split(('\n'));
        break;
    }

    int index = 0;
    for (var i = 0; i < listLines.length; i++) {
      SongLine line = SongLine(i);

      index = line.createItemsFromString(listLines[i], index, chords, notes);

      listLyrics.add(line);
    }
    return listLyrics;
  }

  String get lyricsWithoutChords {
    String lyrics = '';
    for (SongLine line in listLyrics(false, false, TypeLyric.translate)) {
      for (SongItem item in line.listItem) {
        if (item.type == TypeSongItem.lyric) {
          lyrics += item.text;
        }
      }
    }
    return lyrics;
  }

  String get lyricsWithoutChordsWithLines {
    String lyrics = '';
    for (SongLine line in listLyrics(false, false, TypeLyric.translate)) {
      for (SongItem item in line.listItem) {
        if (item.type == TypeSongItem.lyric) {
          lyrics += item.text;
        }
      }
      lyrics += '\n';
    }
    return lyrics;
  }

  String get lyricsWithChords {
    String lyrics = '';
    for (SongLine line in listLyrics(true, false, TypeLyric.translate)) {
      String chordLine = '';
      String lyricLine = '';
      int indexFromStartLine = 0;
      for (SongItem item in line.listItem) {
        if (item.type == TypeSongItem.lyric) {
          lyricLine += item.text;
          indexFromStartLine += item.text.length;
        } else {
          if (chordLine.isNotEmpty && indexFromStartLine <= 0) {
            chordLine += ',${item.text}';
            indexFromStartLine = 0 - (item.text.length + 1);
          } else if (chordLine.isNotEmpty && indexFromStartLine == 1) {
            chordLine += ', ${item.text}';
            indexFromStartLine = 0 - (item.text.length + 2);
          } else {
            chordLine += '${' ' * (indexFromStartLine)}${item.text}';
            indexFromStartLine = 0 - item.text.length;
          }
        }
      }
      if (chordLine.isNotEmpty) {
        lyrics += '$chordLine\n';
      }
      if (lyricLine.isNotEmpty) {
        lyrics += '$lyricLine\n';
      }
    }
    return lyrics;
  }

  List<String> checkModifiedSong(Song otherSong, bool withBmpSongBar) {
    Function eq = const ListEquality().equals;
    List<String> listModified = [];
    if (title != otherSong.title) {
      listModified.add('title');
    }
    if (lyrics != otherSong.lyrics) {
      listModified.add('lyrics');
    }
    if (originalLyrics != otherSong.originalLyrics) {
      listModified.add('originalLyrics');
    }
    if (indexSongBook != otherSong.indexSongBook) {
      listModified.add('indexSongBook');
    }
    if (interpret != otherSong.interpret && (interpret != '' && otherSong.interpret != null) && (interpret != null && otherSong.interpret != '')) {
      listModified.add('interpret');
    }
    if (typeTranspose != otherSong.typeTranspose) {
      listModified.add('typeTranspose');
    }
    if (withBmpSongBar && songBar != otherSong.songBar) {
      listModified.add('songBar');
    }
    if (withBmpSongBar && bmp != otherSong.bmp) {
      listModified.add('bmp');
    }
    if (sheets != otherSong.sheets) {
      listModified.add('sheets');
    }
    if (eq(groups, otherSong.groups) == false) {
      listModified.add('groups');
    }
    if (eq(tags, otherSong.tags) == false) {
      listModified.add('tags');
    }
    if (notes != otherSong.notes) {
      listModified.add('notes');
    }
    if (youtubeVideos != otherSong.youtubeVideos) {
      listModified.add('youtubeVideos');
    }
    return listModified;
  }

  List<String> getAllUniqueChordsFromSong(TypeLyric typeLyric) {
    List<String> listChords = [];
    List<SongLine> list = listLyrics(true, true, typeLyric);

    for (SongLine songLine in list) {
      for (SongItem songItem in songLine.listItem) {
        if (songItem.type == TypeSongItem.chord) {
          if (!listChords.contains(songItem.text)) {
            listChords.add(songItem.text);
          }
        }
      }
    }
    return listChords;
  }

  void generateId() {
    if (id.isNotEmpty) return;
    var uuidGener = const Uuid();
    id = uuidGener.v1();
  }
}

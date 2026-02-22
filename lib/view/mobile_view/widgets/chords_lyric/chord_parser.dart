import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../services/constants.dart';
import '../../../../services/enums.dart';
import 'chord_lyrics_document.dart';
import 'chord_lyrics_line.dart';

class ChordProcessor {
  final BuildContext context;
  ChordProcessor(this.context);
  TypeTranspose _typeTranspose = TypeTranspose.czech;

  /// Process the text to get the parsed ChordLyricsDocument
  ChordLyricsDocument processText({
    required String text,
    required TextStyle lyricsStyle,
    required chordStyle,
    int transposeIncrement = 0,
    TypeTranspose typeTranspose = TypeTranspose.czech,
  }) {
    _typeTranspose = typeTranspose;
    final lines = text.split('\n');
    int index = 0;
    List<ChordLyricsLine> chordLyricsLines = lines.map<ChordLyricsLine>((line) {
      ChordLyricsLine chordLyricsLine = ChordLyricsLine(index, [], '');
      String lyricsSoFar = '';
      String chordsSoFar = '';
      bool chordHasStarted = false;
      line.split('').forEach((character) {
        if (character == ']') {
          final sizeOfLeadingLyrics = textWidth(lyricsSoFar, lyricsStyle);

          final lastChordText = chordLyricsLine.chords.isNotEmpty ? chordLyricsLine.chords.last.chordText : '';

          final lastChordWidth = textWidth(lastChordText, chordStyle);
          // final sizeOfThisChord = textWidth(_chordsSoFar, chordStyle);

          double leadingSpace = 0;
          leadingSpace = (sizeOfLeadingLyrics - lastChordWidth);

          leadingSpace = max(0, leadingSpace);

          final transposedChord = ChordProcessor.transposeChord(
            chordsSoFar,
            transposeIncrement,
            _typeTranspose,
          );

          chordLyricsLine.chords.add(Chord(leadingSpace, transposedChord, index));
          index++;
          chordLyricsLine.lyrics += lyricsSoFar;
          lyricsSoFar = '';
          chordsSoFar = '';
          chordHasStarted = false;
        } else if (character == '[') {
          chordHasStarted = true;
        } else {
          if (chordHasStarted) {
            chordsSoFar += character;
          } else {
            lyricsSoFar += character;
          }
        }
      });

      chordLyricsLine.lyrics += lyricsSoFar;

      return chordLyricsLine;
    }).toList();

    return ChordLyricsDocument(chordLyricsLines);
  }

  /// Return the textwidth of the text in the given style
  double textWidth(String text, TextStyle textStyle) {
    return (TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 1,
      textScaleFactor: MediaQuery.of(context).textScaleFactor,
      textDirection: TextDirection.ltr,
    )..layout())
        .size
        .width;
  }

  /// Transpose the chord text by the given increment
  static String transposeChord(String chord, int increment, TypeTranspose typeTranspose) {
    if (chord.isEmpty || increment == 0) return chord;
    if (chord == 'Bmi/G#') {
      //FIXME: prroblem with transponse chord
    }
    var cycle = [];
    if (typeTranspose == TypeTranspose.german) {
      cycle = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
    } else {
      cycle = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "B", "H"];
    }

    String el = chord[0];
    if (chord.length > 1 && chord[1] == '#') {
      el += "#";
    }
    final ind = cycle.indexOf(el);
    if (ind == -1) return chord;

    final newInd = (ind + increment + cycle.length) % cycle.length;
    final newChar = cycle[newInd];
    String newChord = newChar + chord.substring(el.length);
    if (newChord.contains('/')) {
      String apend = newChord.substring(newChord.indexOf('/') + 1);
      final indApp = cycle.indexOf(apend);
      if (indApp == -1) {
        return newChord;
      }
      final newIndApp = (indApp + increment + cycle.length) % cycle.length;
      final newCharApp = cycle[newIndApp];
      newChord = newChord.substring(0, newChord.indexOf('/') + 1) + newCharApp;
    }
    return newChord;
  }

  static List<String> getListFromChord(String chord) {
    List<String> list = ['', '', ''];
    if (chord.isEmpty) return list;
    if (AppChord.firstChar.contains(chord[0])) {
      list[0] = chord[0];
    }
    if (AppChord.lastChar.contains(chord.substring(chord.length - 1))) {
      list[2] = chord.substring(chord.length - 1);
    }

    if (chord.length > 2) {
      String substring = chord.substring(1, list[2].isNotEmpty ? chord.length - 1 : null);

      if (AppChord.midleChar.contains(substring)) {
        list[1] = substring;
      }
    }

    return list;
  }

  String getSuperScript(String char) {
    if (char == '0') return '\u2070';
    if (char == '1') return '\u00B9';
    if (char == '2') return '\u00B2';
    if (char == '3') return '\u00B3';
    if (char == '4') return '\u2074';
    if (char == '5') return '\u2075';
    if (char == '6') return '\u2076';
    if (char == '7') return '\u2077';
    if (char == '8') return '\u2078';
    if (char == '9') return '\u2079';
    return char;
  }
}

extension E on String {
  String lastChars(int n) => substring(length - n);
}

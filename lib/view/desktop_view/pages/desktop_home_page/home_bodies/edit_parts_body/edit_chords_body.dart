import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../blocs/export_blocs.dart';
import '../../../../../../model/song/song_item.dart';
import '../../../../../../services/constants.dart';
import '../../../../widgets/edit_span_desktop.dart';

class EditChordsBody extends StatefulWidget {
  const EditChordsBody({super.key});

  @override
  State<EditChordsBody> createState() => _EditChordsBodyState();
}

class _EditChordsBodyState extends State<EditChordsBody> {
  bool isOriginalLyrics = false;
  OverlayEntry overlayEntry = OverlayEntry(
    builder: (context) => Container(),
  );
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditSongBloc, EditSongState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width - 300,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(state.currentEditSong.title, style: const TextStyle(fontSize: 15)),
                    SizedBox(
                      width: 400,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () {
                                  context.read<EditSongBloc>().add(TransposeChordPermanent(transposeIncrement: -1, isOriginalLyric: state.isOriginalLyrics));
                                },
                                child: Container(
                                    height: 30,
                                    width: 40,
                                    margin: const EdgeInsets.only(left: 5, right: 5),
                                    decoration: BoxDecoration(
                                      color: AppColor.defaultBackgroundColor,
                                      border: Border.all(color: AppColor.grey1Color),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.remove,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                        Icon(
                                          Icons.music_note,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ))),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () {
                                  context.read<EditSongBloc>().add(TransposeChordPermanent(transposeIncrement: 1, isOriginalLyric: state.isOriginalLyrics));
                                },
                                child: Container(
                                    height: 30,
                                    width: 40,
                                    margin: const EdgeInsets.only(left: 5, right: 5),
                                    decoration: BoxDecoration(
                                      color: AppColor.defaultBackgroundColor,
                                      border: Border.all(color: AppColor.grey1Color),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                        Icon(
                                          Icons.music_note,
                                          size: 16,
                                          color: Colors.black,
                                        ),
                                      ],
                                    ))),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () {
                                  context.read<EditSongBloc>().add(ChangeEditSong(song: state.currentEditSong, isOriginalLyrics: !state.isOriginalLyrics));
                                },
                                child: Container(
                                    height: 30,
                                    width: 150,
                                    margin: const EdgeInsets.only(left: 5, right: 5),
                                    decoration: BoxDecoration(
                                      color: AppColor.defaultBackgroundColor,
                                      border: Border.all(color: AppColor.grey1Color),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(child: Text(state.isOriginalLyrics ? 'changeToTranslate'.tr() : 'changeToOriginal'.tr())))),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () {
                                  context.read<EditSongBloc>().add(const SaveSong(typeApp: 'desktop'));
                                },
                                child: Container(
                                    height: 30,
                                    width: 30,
                                    margin: const EdgeInsets.only(left: 5, right: 5),
                                    decoration: BoxDecoration(
                                      color: state.isOriginalLyrics
                                          ? state.currentText == state.currentEditSong.originalLyrics
                                              ? AppColor.defaultBackgroundColor
                                              : AppColor.primaryColor
                                          : state.currentText == state.currentEditSong.lyrics
                                              ? AppColor.defaultBackgroundColor
                                              : AppColor.primaryColor,
                                      border: Border.all(color: AppColor.grey1Color),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child:
                                        Center(child: Icon(Icons.save, size: 16, color: state.currentText == state.currentEditSong.originalLyrics ? Colors.black : Colors.white)))),
                          )
                        ],
                      ),
                    )
                  ],
                )),
            Container(
              height: MediaQuery.of(context).size.height - 160,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.only(left: 15),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: RichText(softWrap: true, text: TextSpan(children: _getCLickableText(state.currentText, state.chordStyle, state.textStyle))),
              ),
            ),
          ],
        );
      },
    );
  }

  void closeOverlay() {
    overlayEntry.remove();
    Navigator.pop(context, 'changeChord');
  }

  List<TextSpan> _getCLickableText(String text, TextStyle chordStyle, TextStyle textStyle) {
    List<TextSpan> list = [];
    List<WidgetSpan> line = [];
    String chord = '';
    bool isChord = false;

    var stringText = (text.split(''));
    int index = 0;
    for (String chara in stringText) {
      if (chara == '[') {
        isChord = true;
        index++;
        continue;
      }
      if (chara == ']') {
        isChord = false;
        line.add((WidgetSpan(child: EditSpanDesktop(index, chord, TypeSongItem.chord, chordStyle, overlayEntry))));
        chord = '';
        index++;
        continue;
      }
      if (isChord) {
        chord = chord + chara;
        index++;
        continue;
      }
      if (chara == '\n') {
        list.add(TextSpan(children: line));
        list.add(const TextSpan(text: '\n'));
        line = [];
        index++;
        continue;
      }

      line.add(WidgetSpan(
        child: EditSpanDesktop(index, chara, TypeSongItem.lyric, textStyle, overlayEntry),
      ));
      index++;
    }
    return list;
  }

  void transposeChords(int increment) {
    /*   if (songData != null) {
      try {
        RegExp exp = RegExp(r'\[.?.?.?.?.?\]');
        if (isOriginal) {
          songData!.originalLyrics.value = lyrics.value.replaceAllMapped(exp, (match) {
            String? result = (match.group(0));

            if (result == null) return '';
            result = result.replaceFirst(RegExp(r'\['), '');
            result = result.replaceFirst(RegExp(r'\]'), '');
            result = chordParser.ChordProcessor.transposeChord(result, increment, TypeTranspose.czech);
            result = '[$result]';
            return result;
          });
        } else {
          songData!.lyrics.value = lyrics.value.replaceAllMapped(exp, (match) {
            String? result = (match.group(0));

            if (result == null) return '';
            result = result.replaceFirst(RegExp(r'\['), '');
            result = result.replaceFirst(RegExp(r'\]'), '');
            result = chordParser.ChordProcessor.transposeChord(result, increment, TypeTranspose.czech);
            result = '[$result]';
            return result;
          });
        }

        lyrics.value = isOriginal ? songData?.originalLyrics.value ?? lyrics.value : songData?.lyrics.value ?? lyrics.value;

        transposeIncrement = transposeIncrement + increment;
      } catch (e) {}
      listUniqueChords.value = songController.getAllUniqueChordsFromSong(songData!, isOriginal ? TypeLyric.original : TypeLyric.translate);
      selectChordIndex.value = -1;
      selectChord.value = '';
    }
  }*/
  }
}

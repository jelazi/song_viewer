// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../../../../blocs/export_blocs.dart';
import '../../../../model/chord/guitar_chord.dart';
import '../../../../model/song/song_item.dart';
import '../../widgets/chord_radio_list_tile.dart';
import '../../widgets/edit_span.dart';

class EditChordsPageMobile extends StatefulWidget {
  final bool isOriginalLyrics;
  const EditChordsPageMobile({
    super.key,
    required this.isOriginalLyrics,
  });

  @override
  State<EditChordsPageMobile> createState() => _EditChordsPageMobileState();
}

class _EditChordsPageMobileState extends State<EditChordsPageMobile> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditSongBloc, EditSongState>(
      builder: (context, state) {
        return Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                    onPressed: () {
                      context.read<EditSongBloc>().add(const ChangeFontSizeEdit(isIncrease: true));
                    },
                    icon: const Icon(Icons.zoom_in)),
                IconButton(
                    onPressed: () {
                      context.read<EditSongBloc>().add(const ChangeFontSizeEdit(isIncrease: false));
                    },
                    icon: const Icon(Icons.zoom_out)),
                const SizedBox(
                  width: 20,
                ),
                TextButton.icon(
                    onPressed: () {
                      context.read<EditSongBloc>().add(TransposeChordPermanent(transposeIncrement: state.transposeIncrement + 1, isOriginalLyric: widget.isOriginalLyrics));
                    },
                    label: const Text('+', style: TextStyle(color: Colors.white)),
                    icon: const Icon(Icons.music_note, color: Colors.white)),
                TextButton.icon(
                    onPressed: () {
                      context.read<EditSongBloc>().add(TransposeChordPermanent(transposeIncrement: state.transposeIncrement - 1, isOriginalLyric: widget.isOriginalLyrics));
                    },
                    label: const Text('-', style: TextStyle(color: Colors.white)),
                    icon: const Icon(Icons.music_note, color: Colors.white)),
                const SizedBox(
                  width: 20,
                ),
                IconButton(
                  onPressed: () {
                    context.read<EditSongBloc>().add(ChangeListUniqueChordsIsVisible(isVisible: !state.listUniqueChordsIsVisible));
                  },
                  icon: const Icon(Icons.list),
                ),
              ],
            ),
            body: Stack(
              children: [
                SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(
                        height: 10,
                      ),
                      const Divider(),
                      Padding(
                        padding: const EdgeInsets.all(15.0),
                        child: RichText(
                            softWrap: true,
                            text: TextSpan(
                                children: _getCLickableText(
                                    widget.isOriginalLyrics ? state.currentEditSong.originalLyrics ?? '' : state.currentEditSong.lyrics, state.chordStyle, state.textStyle))),
                      ),
                    ],
                  ),
                ),
                Visibility(
                  visible: state.listUniqueChordsIsVisible,
                  child: Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        width: 250,
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: state.listUniqueChords
                              .map((e) => ChordRadioListTile(
                                  index: state.listUniqueChords.indexOf(e),
                                  groupIndex: state.selectChordIndex,
                                  onChanged: (value) {
                                    context.read<EditSongBloc>().add(SelectChord(index: state.selectChordIndex == value ? -1 : value));
                                  },
                                  leading: e))
                              .toList(),
                        ),
                      )),
                ),
              ],
            ));
      },
    );
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
        line.add((WidgetSpan(child: EditSpan(index, chord, TypeSongItem.chord, openChordsDialog, copyChords, pasteChord, chordStyle))));
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
        child: EditSpan(index, chara, TypeSongItem.lyric, openChordsDialog, copyChords, pasteChord, textStyle),
      ));
      index++;
    }
    return list;
  }

  void copyChords(int positionIndex, String char, Offset position, TypeSongItem typeSongItem) {
    ('copyChord: $char');
  }

  void pasteChord(int positionIndex, String char, Offset position, TypeSongItem typeSongItem) {
    /*  if (selectChord.isNotEmpty) {
      String selChord = selectChord.value;
      int index = selectChordIndex.value;
      ChordData chord = ChordData(2, typeSongItem == TypeSongItem.chord ? char : lastChord, 0);
      changeChord(chord, selectChord.value, typeSongItem, positionIndex);

      selectChord.value = selChord;
      selectChordIndex.value = index;*/
  }
}

void openChordsDialog(int positionIndex, String char, Offset position, TypeSongItem typeSongItem, bool isDelete) {
  /*   if (isDelete) {
      deleteChords(positionIndex, char, position, typeSongItem);
    } else {
      openPicker(
        ChordData(2, typeSongItem == TypeSongItem.chord ? char : lastChord, 0),
        typeSongItem,
        positionIndex,
      );
    }*/
}

void deleteChords(int positionIndex, String char, Offset position, TypeSongItem typeSongItem, BuildContext context) {
  /*   showMenu(color: Colors.transparent, context: context, position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy), items: [
      PopupMenuItem(
        child: Column(
          children: [
            SizedBox(
              width: 250,
              child: ElevatedButton(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(
                        width: 10,
                      ),
                      Text('Edit chords: $char'),
                    ],
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  openPicker(GuitarChord(2, typeSongItem == TypeSongItem.chord ? char : 'C', 0), typeSongItem, positionIndex);
                },
              ),
            ),
            const SizedBox(
              height: 10,
            ),
            SizedBox(
              width: 250,
              child: ElevatedButton(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.delete),
                      const SizedBox(
                        width: 10,
                      ),
                      Text('Delete chords: $char'),
                    ],
                  ),
                ),
                onPressed: () {
                  songData?.deleteChord(positionIndex, char, isOriginal);
                  lyrics.value = isOriginal ? songData?.originalLyrics.value ?? lyrics.value : songData?.lyrics.value ?? lyrics.value;

                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      )
    ]);*/
}

void openPicker(GuitarChord chord, TypeSongItem typeSongItem, int positionIndex) {
  /*   List<dynamic> listAdapter = [];
    listAdapter.add(firstChar);
    listAdapter.add(midleChar);
    listAdapter.add(lastChar);
    List<String> listChord = chordParser.ChordProcessor.getListFromChord(chord.chordText);
    List<int> selectedList = [0, 0, 0];
    selectedList[0] = firstChar.indexOf(listChord[0]);
    selectedList[1] = midleChar.indexOf(listChord[1]);
    selectedList[2] = lastChar.indexOf(listChord[2]);

    Picker picker = Picker(
        adapter: PickerDataAdapter<dynamic>(pickerData: listAdapter, isArray: true),
        headerColor: Colors.blue,
        title: Text('selectChord'.tr),
        // textAlign: TextAlign.left,
        selecteds: selectedList,
        columnPadding: const EdgeInsets.all(8.0),
        onConfirm: (Picker picker, List value) {


          List values = picker.getSelectedValues();
          String newValue = values.join();
          newValue = newValue.replaceAll(' ', '');
          changeChord(chord, newValue, typeSongItem, positionIndex);
        });
    Get.dialog(AlertDialog(
        content: SizedBox(
      height: 350,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 400,
            height: 300,
            child: picker.makePicker(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ElevatedButton(onPressed: () => picker.doConfirm(Get.overlayContext!), child: Text('ok'.tr)),
              ElevatedButton(onPressed: () => picker.doCancel(Get.overlayContext!), child: Text('cancel'.tr)),
              ElevatedButton(
                  onPressed: () {
                    Get.back();
                    openWriteChordDialog(chord, typeSongItem, positionIndex);
                  },
                  child: Text('writeChord'.tr)),
            ],
          ),
        ],
      ),
    )));*/
}

void changeChord(GuitarChord chord, String newValue, TypeSongItem typeSongItem, int positionIndex) {
  /*  chord.chordText = newValue;
    var lastChord = newValue;
    if (typeSongItem == TypeSongItem.lyric) {
      songData?.addChord(chord, positionIndex, isOriginal);
    } else {
      songData?.editChord(positionIndex, newValue, isOriginal);
    }
    lyrics.value = isOriginal ? songData?.originalLyrics.value ?? lyrics.value : songData?.lyrics.value ?? lyrics.value;
    if (songData != null) {
      listUniqueChords.value = songController.getAllUniqueChordsFromSong(songData!, isOriginal ? TypeLyric.original : TypeLyric.translate);
    }

    selectChordIndex.value = -1;
    selectChord.value = '';
  }

  void openWriteChordDialog(ChordData chord, TypeSongItem typeSongItem, int positionIndex) {
    TextEditingController textEditingController = TextEditingController(text: chord.chordText);
    Get.dialog(CustomDialogView(
      titleString: 'writeChord'.tr,
      contentWidget: TextField(controller: textEditingController),
      actionsWidget: [
        ElevatedButton(
          onPressed: () {
            String newValue = textEditingController.text;
            lastChord = newValue;
            chord.chordText = newValue;
            changeChord(chord, newValue, typeSongItem, positionIndex);

            Get.back();
          },
          child: Text('ok'.tr),
        ),
        ElevatedButton(
          onPressed: () {
            Get.back();
          },
          child: Text('cancel'.tr),
        ),
      ],
    ));*/
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

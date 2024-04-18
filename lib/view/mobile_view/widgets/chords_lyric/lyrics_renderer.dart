import 'package:collection/collection.dart';
import 'package:default_project/blocs/export_blocs.dart';
//import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:logger_pkg/logger_pkg.dart';
import '../../../../model/note.dart';

import '../../../../services/enums.dart';
import './flutter_chord.dart';

// ignore: must_be_immutable
class LyricsRenderer extends StatefulWidget {
  final String lyrics;
  var listNotes = [];
  final TextStyle textStyle;
  final TextStyle chordStyle;
  final bool showChord;
  final Function onTapChord;
  ScrollController scrollController;

  /// Transpose Increment for the Chords,
  /// defaule value is 0, which means no transpose is applied
  final int transposeIncrement;

  /// Auto Scroll Speed,
  /// default value is 0, which means no auto scroll is applied
  final int scrollSpeed;

  final TypeTranspose typeTranspose;
  int startIndex = 0;
  bool isVisibleNote;
  bool appBarStatus;
  final double baseFontSize;

  LyricsRenderer({
    Key? key,
    required this.lyrics,
    required this.textStyle,
    required this.chordStyle,
    required this.onTapChord,
    required this.isVisibleNote,
    required this.scrollController,
    required this.baseFontSize,
    required this.appBarStatus,
    this.startIndex = 0,
    this.listNotes = const [],
    this.showChord = true,
    this.transposeIncrement = 0,
    this.scrollSpeed = 20,
    this.typeTranspose = TypeTranspose.czech,
  }) : super(key: key);

  @override
  State<LyricsRenderer> createState() => _LyricsRendererState();
}

class _LyricsRendererState extends State<LyricsRenderer> {
  final ScrollController _scrollControllerHorizontal = ScrollController();
  List<String> superScripts = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '#'];
  double _fontScale = 1;
  double _baseFontScale = 1;

  @override
  Widget build(BuildContext context) {
    ChordProcessor chordProcessor = ChordProcessor(context);
    final chordLyricsDocument = chordProcessor.processText(
      text: widget.lyrics,
      lyricsStyle: widget.textStyle,
      chordStyle: widget.chordStyle,
      transposeIncrement: widget.transposeIncrement,
      typeTranspose: widget.typeTranspose,
    );
    if (chordLyricsDocument.chordLyricsLines.isEmpty) return Container();
    return GestureDetector(
      onScaleStart: ((details) {
        _baseFontScale = _fontScale;
      }),
      onScaleUpdate: (details) {
        if (details.scale == 1.0) {
          return;
        }
        _fontScale = (_baseFontScale * details.scale).clamp(0.5, 5.0);

        context.read<PreviewChordBloc>().add(ChangeTextFontSize(fontSize: _fontScale * widget.baseFontSize));
        context.read<PreviewChordBloc>().add(ChangeChordFontSize(fontSize: _fontScale * widget.baseFontSize));
      },
      onScaleEnd: (details) {
        /// ????
      },
      child: ListView.separated(
        // shrinkWrap: true,
        scrollDirection: Axis.vertical,
        controller: widget.scrollController,
        physics: const BouncingScrollPhysics(),
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final line = chordLyricsDocument.chordLyricsLines[index];

          if (widget.listNotes.isNotEmpty) {
            for (Note note in widget.listNotes) {
              //    Get.find<ChordLyricsController>().notes[note.index].value = note.noteText;
            }
          }
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _scrollControllerHorizontal,
            child: Padding(
              padding: EdgeInsets.only(
                  top: index == 0
                      ? !widget.appBarStatus
                          ? 70.0
                          : 10.0
                      : 0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showChord)
                    Row(
                      children: line.chords.map((chord) {
                        if (superScripts.firstWhereOrNull((element) => chord.chordText.contains(element)) != null) {
                          List<String> list = chord.chordText.split('');

                          return Row(
                            children: [
                              SizedBox(
                                width: chord.leadingSpace,
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (TapDownDetails details) {
                                  Offset pos = details.globalPosition;
                                  widget.onTapChord(chord, pos);
                                },
                                child: RichText(
                                  softWrap: true,
                                  text: TextSpan(
                                    children: list.map((e) {
                                      if (superScripts.contains(e)) {
                                        return WidgetSpan(
                                            child: Transform.translate(
                                          offset: Offset(0, -(widget.chordStyle.fontSize! * 0.4)),
                                          child: Text(
                                            e,
                                            //superscript is usually smaller in size
                                            textScaleFactor: 0.6,
                                            style: widget.chordStyle,
                                          ),
                                        ));
                                      } else {
                                        return TextSpan(text: e, style: widget.chordStyle);
                                      }
                                    }).toList(),
                                  ),
                                ),
                              )
                            ],
                          );
                        } else {
                          return Row(
                            children: [
                              SizedBox(
                                width: chord.leadingSpace,
                              ),
                              GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTapDown: (TapDownDetails details) {
                                  Offset pos = details.globalPosition;
                                  widget.onTapChord(chord, pos);
                                },
                                child: RichText(
                                  softWrap: true,
                                  text: TextSpan(
                                    text: chord.chordText,
                                    style: widget.chordStyle,
                                  ),
                                ),
                              )
                            ],
                          );
                        }
                      }).toList(),
                    ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    controller: _scrollControllerHorizontal,
                    child: GestureDetector(
                      onLongPress: () {
                        //TODO:
                        /*    if (Get.find<UserController>().currentUser.value?.typeUser != TypeUser.superuser || !settingsController.editNotes.value) {
                          return;
                        }
                      
                        String currentNote = '';
                        for (Note note in widget.listNotes!) {
                          if (note.index == index) {
                            currentNote = note.noteText.value;
                            break;
                          }
                        }
                        TextEditingController textEditingController = TextEditingController(text: currentNote);
                      
                        Get.dialog(CustomDialogView(
                            titleString: 'note'.tr,
                            contentWidget: TextField(
                              autofocus: true,
                              controller: textEditingController,
                            ),
                            actionsWidget: [
                              ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      Get.find<ChordLyricsController>().addNotes(index + widget.startIndex, textEditingController.text);
                                    });
                      
                                    Get.back();
                                  },
                                  child: Text('ok'.tr())),
                              ElevatedButton(
                                  onPressed: () {
                                    Get.back();
                                  },
                                  child: Text('cancel'.tr())),
                            ]));*/
                      },
                      child: Row(
                        children: [
                          RichText(
                            softWrap: true,
                            text: TextSpan(
                              text: line.lyrics,
                              style: widget.textStyle,
                            ),
                          ),
                          getNote(index),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        },
        itemCount: chordLyricsDocument.chordLyricsLines.length,
      ),
    );
  }

  Widget getNote(int index) {
    GlobalKey key = GlobalKey();

    if (widget.isVisibleNote && widget.listNotes.isNotEmpty
        //TODO:
        //&& Get.find<ChordLyricsController>().notes[index + widget.startIndex].value.isNotEmpty
        ) {
      return SizedBox(
        height: 18,
        child: IconButton(
            padding: const EdgeInsets.all(0),
            key: key,
            onPressed: () {
              //TODO:
              /*   RenderBox box = key.currentContext!.findRenderObject() as RenderBox;
              Offset position = box.localToGlobal(Offset.zero);
              Get.find<ChordLyricsController>().openNoteOverlay(index + widget.startIndex, Get.find<ChordLyricsController>().notes[index + widget.startIndex].value, position);*/
            },
            icon: Stack(
              children: [
                const Align(
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.note,
                    color: Color.fromARGB(255, 255, 209, 59),
                  ),
                ),
                Align(
                    alignment: Alignment.center,
                    child: Text(
                      '${index + widget.startIndex}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                      ),
                    ))
              ],
            )),
      );
    } else {
      return Container();
    }
  }

  @override
  void didUpdateWidget(covariant LyricsRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
  }
}

class TextRender extends CustomPainter {
  final String text;
  final TextStyle style;
  TextRender(this.text, this.style);

  @override
  void paint(Canvas canvas, Size size) {
    final textSpan = TextSpan(
      text: text,
      style: style,
    );
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout(
      minWidth: 0,
      maxWidth: size.width,
    );
    textPainter.paint(canvas, Offset.zero);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}

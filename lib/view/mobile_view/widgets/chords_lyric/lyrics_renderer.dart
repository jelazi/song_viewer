import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

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
  final Function? onLongPressChord;
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
    super.key,
    required this.lyrics,
    required this.textStyle,
    required this.chordStyle,
    required this.onTapChord,
    this.onLongPressChord,
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
  });

  @override
  State<LyricsRenderer> createState() => _LyricsRendererState();
}

class _LyricsRendererState extends State<LyricsRenderer> {
  final ScrollController _scrollControllerHorizontal = ScrollController();
  List<String> superScripts = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '#'];
  double _fontScale = 1;
  double _baseFontScale = 1;

  // Memoization cache for chord processing
  ChordLyricsDocument? _cachedDocument;
  String? _cachedLyrics;
  TextStyle? _cachedLyricsStyle;
  TextStyle? _cachedChordStyle;
  int? _cachedTransposeIncrement;
  TypeTranspose? _cachedTypeTranspose;

  ChordLyricsDocument _processText(BuildContext context) {
    if (_cachedDocument != null &&
        _cachedLyrics == widget.lyrics &&
        _cachedLyricsStyle == widget.textStyle &&
        _cachedChordStyle == widget.chordStyle &&
        _cachedTransposeIncrement == widget.transposeIncrement &&
        _cachedTypeTranspose == widget.typeTranspose) {
      return _cachedDocument!;
    }

    final chordProcessor = ChordProcessor(context);
    _cachedDocument = chordProcessor.processText(
      text: widget.lyrics,
      lyricsStyle: widget.textStyle,
      chordStyle: widget.chordStyle,
      transposeIncrement: widget.transposeIncrement,
      typeTranspose: widget.typeTranspose,
    );
    _cachedLyrics = widget.lyrics;
    _cachedLyricsStyle = widget.textStyle;
    _cachedChordStyle = widget.chordStyle;
    _cachedTransposeIncrement = widget.transposeIncrement;
    _cachedTypeTranspose = widget.typeTranspose;
    return _cachedDocument!;
  }

  @override
  Widget build(BuildContext context) {
    final chordLyricsDocument = _processText(context);
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

        //  context.read<PreviewChordBloc>().add(ChangeTextFontSize(fontSize: _fontScale * widget.baseFontSize));
        //   context.read<PreviewChordBloc>().add(ChangeChordFontSize(fontSize: _fontScale * widget.baseFontSize));
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
                                onLongPress: widget.onLongPressChord != null ? () => widget.onLongPressChord!(chord) : null,
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
                                            textScaler: const TextScaler.linear(0.6),
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
                                onLongPress: widget.onLongPressChord != null ? () => widget.onLongPressChord!(chord) : null,
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

    if (widget.isVisibleNote && widget.listNotes.isNotEmpty) {
      return SizedBox(
        height: 18,
        child: IconButton(
            padding: const EdgeInsets.all(0),
            key: key,
            // The note overlay this button used to open has no implementation
            // in the current state management; tapping it does nothing.
            onPressed: () {},
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
    // Invalidate cache if inputs changed
    if (oldWidget.lyrics != widget.lyrics ||
        oldWidget.textStyle != widget.textStyle ||
        oldWidget.chordStyle != widget.chordStyle ||
        oldWidget.transposeIncrement != widget.transposeIncrement ||
        oldWidget.typeTranspose != widget.typeTranspose) {
      _cachedDocument = null;
    }
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

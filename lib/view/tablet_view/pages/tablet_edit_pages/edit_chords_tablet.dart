// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../../../../blocs/export_blocs.dart';
import '../../../../model/song/song_item.dart';
import '../../widgets/edit_span_tablet.dart';

class EditChordsPageTablet extends StatefulWidget {
  final bool isOriginalLyrics;
  const EditChordsPageTablet({
    super.key,
    required this.isOriginalLyrics,
  });

  @override
  State<EditChordsPageTablet> createState() => _EditChordsPageTabletState();
}

class _EditChordsPageTabletState extends State<EditChordsPageTablet> {
  OverlayEntry? overlayEntry;

  @override
  void initState() {
    super.initState();
    overlayEntry = OverlayEntry(
      builder: (context) => Container(),
    );
  }

  @override
  void dispose() {
    if (overlayEntry != null && overlayEntry!.mounted) {
      overlayEntry?.remove();
      overlayEntry = null;
    }
    super.dispose();
  }

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
                    label: const Text('+'),
                    icon: const Icon(Icons.music_note)),
                TextButton.icon(
                    onPressed: () {
                      context.read<EditSongBloc>().add(TransposeChordPermanent(transposeIncrement: state.transposeIncrement - 1, isOriginalLyric: widget.isOriginalLyrics));
                    },
                    label: const Text('-'),
                    icon: const Icon(Icons.music_note)),
                const SizedBox(
                  width: 20,
                ),
              ],
            ),
            body: Stack(
              children: [
                Container(
                  height: MediaQuery.of(context).size.height - 160,
                  alignment: Alignment.topLeft,
                  padding: const EdgeInsets.only(left: 15),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: RichText(softWrap: true, text: TextSpan(children: _getCLickableText(state.currentText, state.chordStyle, state.textStyle))),
                  ),
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
        if (overlayEntry != null) {
          line.add((WidgetSpan(child: EditSpanTablet(index, chord, TypeSongItem.chord, chordStyle, overlayEntry!))));
        }
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
      if (overlayEntry != null) {
        line.add(WidgetSpan(
          child: EditSpanTablet(index, chara, TypeSongItem.lyric, textStyle, overlayEntry!),
        ));
      }

      index++;
    }
    return list;
  }
}

import 'dart:math';

import 'package:default_project/services/constants.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../model/chord/chords_positions.dart';
import '../../../../mobile_view/widgets/chords_lyric/chord_lyrics_line.dart';
import '../../../../mobile_view/widgets/chords_lyric/guitar_tabs.dart';
import '../../../../mobile_view/widgets/chords_lyric/lyrics_renderer.dart';
import 'list_web_song.dart';

class WebBody extends StatefulWidget {
  const WebBody({super.key});

  @override
  State<WebBody> createState() => _WebBodyState();
}

class _WebBodyState extends State<WebBody> {
  ScrollController scrollController = ScrollController();
  OverlayEntry? overlayChord;

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    disableAllOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebBloc, WebState>(
      builder: (context, state) {
        return GestureDetector(
          onTap: () {
            disableAllOverlay();
          },
          child: Row(
            children: [
              ListWebSong(),
              Expanded(
                  child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(state.currentSong?.title ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(state.currentInterpret.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.grey2Color)),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: state.currentSong == null || (state.currentSong?.lyric ?? '').isEmpty
                          ? Container() //: Text(state.currentSong?.lyric ?? '')
                          : LyricsRenderer(
                              scrollController: scrollController,
                              isVisibleNote: true,
                              lyrics: state.currentSong!.lyric,
                              textStyle: state.textStyle,
                              chordStyle: state.chordStyle,
                              appBarStatus: state.appBarStatus,
                              onTapChord: (Chord chord, Offset pos) {
                                openChordImage(chord, pos, context);
                              },
                              transposeIncrement: state.transposeIncrement,
                              scrollSpeed: state.scrollSpeed,
                              baseFontSize: state.textStyle.fontSize ?? 20,
                            ),
                    )
                  ],
                ),
              )),
            ],
          ),
        );
      },
    );
  }

  // ignore: unused_element
  Widget _getLyricsRenderer(WebState state, ScrollController scrollController, String lyric) {
    return LyricsRenderer(
      scrollController: scrollController,
      isVisibleNote: true,
      lyrics: lyric,
      textStyle: state.textStyle,
      chordStyle: state.chordStyle,
      appBarStatus: state.appBarStatus,
      onTapChord: (Chord chord, Offset pos) {
        openChordImage(chord, pos, context);
      },
      transposeIncrement: state.transposeIncrement,
      scrollSpeed: state.scrollSpeed,
      baseFontSize: state.textStyle.fontSize ?? 20,
    );
  }

  void openChordImage(Chord chord, Offset pos, BuildContext context) {
    if (overlayChord != null) {
      overlayChord!.remove();
      overlayChord = null;
    }
    if (ChordsPositions.getPositionsChordsByName(chord.chordText).isEmpty) {
      return;
    }

    OverlayState? overlayState = Overlay.of(context);

    overlayChord = OverlayEntry(
      builder: (context) => Positioned(
        top: max(pos.dy - 130, 0),
        left: max(pos.dx - 60, 0),
        child: TabWidget(
          name: chord.chordText,
          tabs: ChordsPositions.getPositionsChordsByName(chord.chordText),
          size: 3,
        ),
      ),
    );
    overlayState.insert(overlayChord!);
  }

  void disableAllOverlay() {
    if (overlayChord != null) {
      overlayChord!.remove();
      overlayChord = null;
    }
  }
}

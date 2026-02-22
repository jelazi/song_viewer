import 'dart:math';

import 'package:default_project/services/constants.dart';
import 'package:default_project/view/desktop_view/pages/desktop_home_page/home_bodies/list_song.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../model/chord/chords_positions.dart';
import '../../../../../services/enums.dart';
import '../../../../mobile_view/widgets/chords_lyric/flutter_chord.dart';
import '../../../../mobile_view/widgets/chords_lyric/guitar_tabs.dart';
import '../../../../mobile_view/widgets/my_floating_button.dart';

class PreviewBody extends StatefulWidget {
  const PreviewBody({super.key});

  @override
  State<PreviewBody> createState() => _PreviewBodyState();
}

class _PreviewBodyState extends State<PreviewBody> {
  ScrollController scrollController = ScrollController();
  OverlayEntry? overlayChord;
  double _listSongWidth = 300.0;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (scrollController.position.userScrollDirection == ScrollDirection.reverse) {
        context.read<PreviewChordBloc>().add(const ChangeAppBarStatus(status: false));
      }
      if (scrollController.position.userScrollDirection == ScrollDirection.forward) {
        context.read<PreviewChordBloc>().add(const ChangeAppBarStatus(status: true));
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    scrollController.dispose();
    disableAllOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePageBloc, HomePageState>(
      builder: (context, state) {
        return Row(
          children: [
            ListSong(width: _listSongWidth),
            // Resizable vertical divider between song list and content
            MouseRegion(
              cursor: SystemMouseCursors.resizeColumn,
              child: GestureDetector(
                onHorizontalDragUpdate: (details) {
                  setState(() {
                    _listSongWidth = (_listSongWidth + details.delta.dx).clamp(200.0, 600.0);
                  });
                },
                child: Container(
                  width: 8,
                  color: Colors.transparent,
                  child: Center(
                    child: Container(
                      width: 2,
                      color: AppColor.grey3Color,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: BlocBuilder<PreviewChordBloc, PreviewChordState>(
              builder: (context, state) {
                if (state.data.song == null) {
                  return Center(
                    child: Text('noSongSelected'.tr()),
                  );
                }
                return GestureDetector(
                  onTap: () {
                    disableAllOverlay();
                  },
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            BlocBuilder<PreviewChordBloc, PreviewChordState>(
                              builder: (context, state) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text('cap: ${state.cap}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColor.primaryColor,
                                      )),
                                );
                              },
                            ),
                            SizedBox(
                              height: MediaQuery.of(context).size.height - 120,
                              child: _getLyricsRenderer(state, scrollController),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: AnimatedOpacity(
                            opacity: state.visibleButtons && state.appBarStatus ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 500),
                            child: Column(
                              children: [
                                MyFloatingButton(
                                    enabled: state.textStyle.fontSize! < 40,
                                    onPressed: () {
                                      context.read<PreviewChordBloc>().add(const ChangeFontSize(isIncrease: true));
                                    },
                                    icon: const Icon(Icons.zoom_in)),
                                MyFloatingButton(
                                    enabled: state.textStyle.fontSize! > 10,
                                    onPressed: () {
                                      context.read<PreviewChordBloc>().add(const ChangeFontSize(isIncrease: false));
                                    },
                                    icon: const Icon(Icons.zoom_out)),
                                MyFloatingButton(
                                    onPressed: () {
                                      context.read<PreviewChordBloc>().add(const TransposeChord(increment: 1));
                                    },
                                    icon: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 18,
                                        ),
                                        Icon(
                                          Icons.music_note,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                    enabled: true),
                                MyFloatingButton(
                                    onPressed: () {
                                      context.read<PreviewChordBloc>().add(const TransposeChord(increment: -1));
                                    },
                                    icon: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.remove,
                                          size: 18,
                                        ),
                                        Icon(
                                          Icons.music_note,
                                          size: 18,
                                        ),
                                      ],
                                    ),
                                    enabled: true)
                              ],
                            )),
                      )
                    ],
                  ),
                );
              },
            ))
          ],
        );
      },
    );
  }

  Widget _getLyricsRenderer(PreviewChordState state, ScrollController scrollController) {
    String lyric = state.data.song?.lyrics ?? '';
    List<String> list = lyric.split('\n');
    //TODO: controller.notes.value = List.generate(list.length + 1, (index) => RxString(''));
    if (state.twoColumns) {
      List<String> splittedLyric = state.lyricWithColumns(true, true, TypeLyric.translate);
      //TODO:  controller.maxColumns.value = splittedLyric.length;

      if (splittedLyric.length == 1) {
        return LyricsRenderer(
          scrollController: scrollController,
          lyrics: splittedLyric[0],
          textStyle: state.textStyle,
          chordStyle: state.chordStyle,
          appBarStatus: state.appBarStatus,
          onTapChord: (Chord chord, Offset pos) {
            openChordImage(chord, pos, context);
          },
          transposeIncrement: state.transposeIncrement,
          scrollSpeed: state.scrollSpeed,
          isVisibleNote: true,
          baseFontSize: state.textStyle.fontSize ?? 20,
        );
      } else {
        int firstIndex = 0;
        if (state.currentColumn > 0) {
          for (String partSong in splittedLyric) {
            if (splittedLyric.indexOf(partSong) < state.currentColumn) {
              List<String> listLines = partSong.split('\n');
              firstIndex += listLines.length - 1;
            }
          }
        }
        int secondIndex = 0;
        if (state.currentColumn + 1 > 0) {
          for (String partSong in splittedLyric) {
            if (splittedLyric.indexOf(partSong) < state.currentColumn + 1) {
              List<String> listLines = partSong.split('\n');
              secondIndex += listLines.length - 1;
            }
          }
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Flexible(
            child: LyricsRenderer(
              scrollController: scrollController,
              isVisibleNote: true,
              lyrics: splittedLyric[state.currentColumn],
              textStyle: state.textStyle,
              chordStyle: state.chordStyle,
              appBarStatus: state.appBarStatus,
              onTapChord: (Chord chord, Offset pos) {
                openChordImage(chord, pos, context);
              },
              transposeIncrement: state.transposeIncrement,
              scrollSpeed: state.scrollSpeed,
              listNotes: state.data.song?.notes ?? [],
              startIndex: firstIndex,
              baseFontSize: state.textStyle.fontSize ?? 20,
            ),
          ),
          const VerticalDivider(
            color: Colors.blue,
          ),
          splittedLyric.length > state.currentColumn + 1
              ? Flexible(
                  child: LyricsRenderer(
                    scrollController: scrollController,
                    isVisibleNote: true,
                    lyrics: splittedLyric[state.currentColumn + 1],
                    textStyle: state.textStyle,
                    chordStyle: state.chordStyle,
                    appBarStatus: state.appBarStatus,
                    onTapChord: (Chord chord, Offset pos) {
                      openChordImage(chord, pos, context);
                    },
                    transposeIncrement: state.transposeIncrement,
                    scrollSpeed: state.scrollSpeed,
                    startIndex: secondIndex,
                    baseFontSize: state.textStyle.fontSize ?? 20,
                  ),
                )
              : Container(),
        ]);
      }
    } else {
      //TODO: state.maxColumns.value = 0;
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
    /*
    if (listVisibleNotes.isNotEmpty) {
      for (NoteOverlayEntry noteOverlayEntry in listVisibleNotes) {
        noteOverlayEntry.overlayEntry.remove();
      }
    }
    listVisibleNotes.clear();
    return true;*/
  }
}

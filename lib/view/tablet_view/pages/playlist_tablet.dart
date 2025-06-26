import 'dart:math';

import 'package:default_project/view/mobile_view/widgets/chords_lyric/lyrics_renderer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../blocs/export_blocs.dart';
import '../../../model/chord/chords_positions.dart';
import '../../../services/constants.dart';
import '../../../services/enums.dart';
import '../../mobile_view/widgets/chords_lyric/chord_lyrics_line.dart';
import '../../mobile_view/widgets/chords_lyric/guitar_tabs.dart';

class PlaylistTablet extends StatefulWidget {
  const PlaylistTablet({super.key});

  @override
  State<PlaylistTablet> createState() => _PlaylistTabletState();
}

class _PlaylistTabletState extends State<PlaylistTablet> {
  ScrollController scrollController = ScrollController();
  OverlayEntry? overlayChord;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (mounted) {
        if (scrollController.position.userScrollDirection == ScrollDirection.reverse) {
          context.read<PlaylistsBloc>().add(const ChangeAppBarStatusPlaylist(status: false));
        }
        if (scrollController.position.userScrollDirection == ScrollDirection.forward) {
          context.read<PlaylistsBloc>().add(const ChangeAppBarStatusPlaylist(status: true));
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    disableAllOverlay();
  }

  @override
  Widget build(BuildContext context) {
    if (context.read<PlaylistsBloc>().state.heightWindow != MediaQuery.of(context).size.height) {
      context.read<PlaylistsBloc>().add(ChangeHeightWindowPlaylist(height: MediaQuery.of(context).size.height));
    }
    return PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            context.read<PlaylistsBloc>().add(const ClosePlaylist());
            return;
          }
        },
        child: Scaffold(
            appBar: AppBar(
              title: BlocConsumer<PlaylistsBloc, PlaylistsState>(listener: (context, state) {
                if (state.heightWindow != MediaQuery.of(context).size.height) {
                  context.read<PlaylistsBloc>().add(ChangeHeightWindowPlaylist(height: MediaQuery.of(context).size.height));
                }
              }, builder: (context, state) {
                return state.currentSong.interpret != null
                    ? Column(
                        children: [Text(state.currentSong.title), Text(state.currentSong.interpret ?? '', style: labelTextStyle.copyWith(color: AppColor.primaryDarkColor))],
                      )
                    : Text(state.currentSong.title);
              }),
              actions: [
                IconButton(
                    onPressed: () {
                      context.read<PlaylistsBloc>().add(const ChangeFontSizePlaylist(isIncrease: true));
                    },
                    icon: const Icon(
                      Icons.zoom_in,
                      color: AppColor.primaryDarkColor,
                    )),
                IconButton(
                    onPressed: () {
                      context.read<PlaylistsBloc>().add(const ChangeFontSizePlaylist(isIncrease: false));
                    },
                    icon: const Icon(
                      Icons.zoom_out,
                      color: AppColor.primaryDarkColor,
                    )),
                IconButton(
                  onPressed: () {
                    context.read<PlaylistsBloc>().add(const TransposeChordPlaylist(increment: 1));
                  },
                  icon: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add,
                        size: 18,
                        color: AppColor.primaryDarkColor,
                      ),
                      Icon(
                        Icons.music_note,
                        size: 18,
                        color: AppColor.primaryDarkColor,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    context.read<PlaylistsBloc>().add(const TransposeChordPlaylist(increment: -1));
                  },
                  icon: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.remove,
                        size: 18,
                        color: AppColor.primaryDarkColor,
                      ),
                      Icon(
                        Icons.music_note,
                        size: 18,
                        color: AppColor.primaryDarkColor,
                      ),
                    ],
                  ),
                ),
                BlocBuilder<PlaylistsBloc, PlaylistsState>(
                  builder: (context, state) {
                    return IconButton(
                        icon: Icon(
                          MdiIcons.radioboxMarked,
                          color: (state.currentSong.id != '' && state.selectedSongId == state.currentSong.id) ? Colors.green : AppColor.primaryDarkColor,
                        ),
                        onPressed: () {
                          context.read<PreviewChordBloc>().add(SelectSongInPreview(selectSongId: state.currentSong.id, title: '', interpret: '', lyricsWithoutChords: ''));
                          context.read<PlaylistsBloc>().add(SelectSongInPreviewPlaylist(selectSongId: state.currentSong.id));
                        });
                  },
                ),
              ],
            ),
            body: BlocBuilder<PlaylistsBloc, PlaylistsState>(builder: (context, state) {
              return GestureDetector(
                  onTap: () {
                    disableAllOverlay();
                  },
                  child: Stack(children: [
                    Padding(
                        padding: const EdgeInsets.only(left: 10.0),
                        child: Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text('cap: ${state.cap}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: AppColor.primaryColor,
                                )),
                          ),
                          Container(
                            height: MediaQuery.of(context).size.height - 120,
                            child: _getLyricsTwoColumnsRenderer(state, scrollController),
                          ),
                        ])),
                    Visibility(
                        visible: state.currentSong.indexSongBook != null,
                        child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                                alignment: Alignment.topRight,
                                child: Text('${'indexSongBook'.tr()}: ${state.currentSong.indexSongBook ?? ''}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColor.primaryColor,
                                    ))))),
                    Visibility(
                        visible: state.lyricWithColumns(true, true, TypeLyric.translate, state.currentSong).length > 2 || state.indexCurrentSongInPlaylist != 0,
                        child: Align(
                            alignment: Alignment.bottomLeft,
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all<Color>(state.currentColumn > 0 || state.indexCurrentSongInPlaylist != 0
                                        ? AppColor.primaryColor.withOpacity(0.7)
                                        : AppColor.grey4Color.withOpacity(0.7)),
                                  ),
                                  onPressed: () {
                                    if (state.currentColumn <= 0 && state.indexCurrentSongInPlaylist == 0) {
                                      return;
                                    }
                                    context.read<PlaylistsBloc>().add(ChangeCurrentColumnPlaylist(column: state.currentColumn - 2));
                                  },
                                  child: Icon(Icons.turn_left, color: state.currentColumn > 0 || state.indexCurrentSongInPlaylist != 0 ? AppColor.whiteColor : AppColor.grey2Color),
                                )))),
                    Visibility(
                        visible: state.lyricWithColumns(true, true, TypeLyric.translate, state.currentSong).length > 2 ||
                            state.indexCurrentSongInPlaylist != state.currentSongs.length - 1,
                        child: Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton(
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all<Color>(
                                        state.currentColumn + 2 < state.lyricWithColumns(true, true, TypeLyric.translate, state.currentSong).length ||
                                                state.indexCurrentSongInPlaylist != state.currentSongs.length - 1
                                            ? AppColor.primaryColor.withOpacity(0.7)
                                            : AppColor.grey4Color.withOpacity(0.7)),
                                  ),
                                  onPressed: () {
                                    if (state.currentColumn + 2 >= state.lyricWithColumns(true, true, TypeLyric.translate, state.currentSong).length &&
                                        state.indexCurrentSongInPlaylist == state.currentSongs.length - 1) {
                                      return;
                                    }
                                    context.read<PlaylistsBloc>().add(ChangeCurrentColumnPlaylist(column: state.currentColumn + 2));
                                  },
                                  child: Icon(Icons.turn_right,
                                      color: state.currentColumn + 2 < state.lyricWithColumns(true, true, TypeLyric.translate, state.currentSong).length ||
                                              state.indexCurrentSongInPlaylist != state.currentSongs.length - 1
                                          ? AppColor.whiteColor
                                          : AppColor.grey2Color),
                                ))))
                  ]));
            })));
  }

  Widget _getLyricsTwoColumnsRenderer(PlaylistsState state, ScrollController scrollController) {
    List<String> splittedLyric = state.lyricWithColumns(true, true, TypeLyric.translate, state.currentSong);

    if (splittedLyric.isEmpty) {
      // when the song is from web and the lyrics are not loaded
      return Center(
        child: Text('empty'.tr()),
      );
    }
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
            appBarStatus: true,
            onTapChord: (Chord chord, Offset pos) {
              openChordImage(chord, pos, context);
            },
            transposeIncrement: state.transposeIncrement,
            scrollSpeed: state.scrollSpeed,
            listNotes: state.currentSong.notes ?? [],
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
                  appBarStatus: true,
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

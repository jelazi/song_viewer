import 'dart:math';

import 'package:default_project/services/constants.dart';
import 'package:default_project/view/desktop_view/pages/desktop_home_page/home_bodies/list_song.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../services/enums.dart';
import '../../../../mobile_view/widgets/chords_lyric/flutter_chord.dart';
import '../../../../mobile_view/widgets/chords_lyric/guitar_tabs.dart';
import '../../../../mobile_view/widgets/my_floating_button.dart';
import '../../../widgets/chord_editor_dialog.dart';

class PreviewBody extends StatefulWidget {
  final VoidCallback? onRequestFocus;
  final Widget? contentOverride;

  const PreviewBody({super.key, this.onRequestFocus, this.contentOverride});

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
            ListSong(width: _listSongWidth, onRequestFocus: widget.onRequestFocus),
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
            Expanded(
                child: widget.contentOverride ??
                    BlocBuilder<PreviewChordBloc, PreviewChordState>(
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
                                        final song = state.data.song;
                                        final parts = <String>[];
                                        if (song?.indexSongBook != null && song!.indexSongBook! > 0) {
                                          parts.add('#${song.indexSongBook}');
                                        }
                                        if (song?.interpret != null && song!.interpret!.isNotEmpty) {
                                          parts.add(song.interpret!);
                                        }
                                        parts.add('cap: ${state.cap}');
                                        if (song?.bmp != null && song!.bmp! > 0) {
                                          parts.add('bpm: ${song.bmp}');
                                        }
                                        if (song?.songBar != null && song!.songBar! > 0) {
                                          parts.add('${song.songBar}/4');
                                        }
                                        if (song?.tags != null && song!.tags!.isNotEmpty) {
                                          parts.add(song.tags!.join(', '));
                                        }
                                        return Align(
                                          alignment: Alignment.centerLeft,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4),
                                            child: Text(
                                              parts.join('  ·  '),
                                              style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColor.primaryColor,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
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

    final bloc = context.read<PreviewChordBloc>();
    final chordService = bloc.songsRepository.chordService;
    final song = bloc.state.data.song;
    final positions = chordService.resolveChordPositions(chord.chordText, song: song);

    if (positions.isEmpty) {
      _openChordEditor(chord.chordText, context);
      return;
    }

    OverlayState? overlayState = Overlay.of(context);

    overlayChord = OverlayEntry(
      builder: (context) => Positioned(
        top: max(pos.dy - 130, 0),
        left: max(pos.dx - 60, 0),
        child: GestureDetector(
          onSecondaryTap: () {
            _openChordEditor(chord.chordText, context);
          },
          child: TabWidget(
            name: chord.chordText,
            tabs: positions,
            size: 3,
          ),
        ),
      ),
    );
    overlayState.insert(overlayChord!);
  }

  void _openChordEditor(String chordName, BuildContext context) {
    disableAllOverlay();
    final bloc = context.read<PreviewChordBloc>();
    final chordService = bloc.songsRepository.chordService;
    final song = bloc.state.data.song;

    showDialog(
      context: context,
      builder: (dialogContext) => ChordEditorDialog(
        chordName: chordName,
        chordService: chordService,
        song: song,
        onSongUpdated: (updatedSong) {
          bloc.songsRepository.updateSong(updatedSong);
          bloc.add(ChangeCurrentSong(song: updatedSong));
        },
      ),
    );
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

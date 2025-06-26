import 'dart:math';

import 'package:default_project/model/song/song.dart';
import 'package:default_project/services/constants.dart';
import 'package:default_project/view/desktop_view/widgets/my_toast.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/dialogs_export.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../blocs/export_blocs.dart';
import '../../../model/chord/chords_positions.dart';
import '../../../services/enums.dart';
import '../../mobile_view/widgets/chords_lyric/flutter_chord.dart';
import '../../mobile_view/widgets/chords_lyric/guitar_tabs.dart';

class PreviewPageTablet extends StatefulWidget {
  const PreviewPageTablet({super.key});

  @override
  State<PreviewPageTablet> createState() => _PreviewPageTabletState();
}

class _PreviewPageTabletState extends State<PreviewPageTablet> {
  ScrollController scrollController = ScrollController();
  OverlayEntry? overlayChord;

  @override
  void initState() {
    super.initState();
    scrollController.addListener(() {
      if (mounted) {
        if (context.read<PreviewChordBloc>().state.twoColumns) {
          return;
        }
        if (scrollController.position.userScrollDirection == ScrollDirection.reverse) {
          context.read<PreviewChordBloc>().add(const ChangeAppBarStatus(status: false));
        }
        if (scrollController.position.userScrollDirection == ScrollDirection.forward) {
          context.read<PreviewChordBloc>().add(const ChangeAppBarStatus(status: true));
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
    if (context.read<PreviewChordBloc>().state.heightWindow != MediaQuery.of(context).size.height) {
      context.read<PreviewChordBloc>().add(ChangeHeightWindow(height: MediaQuery.of(context).size.height));
    }
    return Scaffold(
      appBar: AppBar(
        title: BlocConsumer<PreviewChordBloc, PreviewChordState>(listener: (context, state) {
          if (state.heightWindow != MediaQuery.of(context).size.height) {
            context.read<PreviewChordBloc>().add(ChangeHeightWindow(height: MediaQuery.of(context).size.height));
          }
        }, builder: (context, state) {
          return state.data.song?.interpret != null
              ? Column(
                  children: [Text(state.data.song?.title ?? ''), Text(state.data.song?.interpret ?? '', style: labelTextStyle.copyWith(color: AppColor.primaryDarkColor))],
                )
              : Text(state.data.song?.title ?? '');
        }),
        actions: [
          BlocBuilder<PreviewChordBloc, PreviewChordState>(
            builder: (context, state) {
              return Visibility(
                visible: state.isDataFromWeb,
                child: IconButton(
                    onPressed: () {
                      TextEditingController nameSongController = TextEditingController(text: state.data.song?.title ?? '');
                      TextEditingController interpretController = TextEditingController(text: state.data.song?.interpret ?? '');
                      List listAllGroups = context.read<HomePageBloc>().state.listAllGroups;
                      var selectedGroups = <String>[];
                      showDialog(
                          context: context,
                          builder: (context) => StatefulBuilder(builder: (context, setState) {
                                return EditDialog(
                                    okBack: false,
                                    height: 540,
                                    width: 400,
                                    title: 'saveSong'.tr(),
                                    okClick: () {
                                      if (selectedGroups.isEmpty) {
                                        MyToast.showText(text: 'selectGroups'.tr(), typeNotification: TypeNotification.error);
                                        return;
                                      }
                                      if (nameSongController.text.isEmpty) {
                                        MyToast.showText(text: 'enterTitle'.tr(), typeNotification: TypeNotification.error);
                                        return;
                                      }
                                      Song song = Song.empty();
                                      song.generateId();
                                      song.title = nameSongController.text;
                                      song.interpret = interpretController.text;
                                      song.lyrics = state.data.song?.lyrics ?? '';
                                      song.notes = state.data.song?.notes ?? [];
                                      song.groups = selectedGroups;
                                      context.read<HomePageBloc>().songsRepository.updateSong(song);
                                      Navigator.of(context).pop();
                                      Navigator.of(context).pop();
                                    },
                                    widgetContent: SizedBox(
                                      height: 400,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          SizedBox(
                                            height: 150,
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text('title'.tr()),
                                                    SizedBox(
                                                      width: 200,
                                                      child: TextField(
                                                        style: const TextStyle(color: AppColor.primaryColor),
                                                        controller: nameSongController,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text('interpret'.tr()),
                                                    SizedBox(
                                                      width: 150,
                                                      child: TextField(
                                                        style: const TextStyle(color: AppColor.grey1Color),
                                                        controller: interpretController,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(
                                              height: 150,
                                              child: Wrap(
                                                children: listAllGroups
                                                    .map((e) => Padding(
                                                          padding: const EdgeInsets.all(4.0),
                                                          child: ChoiceChip(
                                                              checkmarkColor: selectedGroups.contains(e) ? AppColor.whiteColor : AppColor.primaryColor,
                                                              onSelected: (value) {
                                                                setState(() {
                                                                  if (selectedGroups.contains(e)) {
                                                                    selectedGroups.remove(e);
                                                                  } else {
                                                                    selectedGroups.add(e);
                                                                  }
                                                                });
                                                              },
                                                              selectedColor: AppColor.primaryColor,
                                                              label: Text(e, style: TextStyle(color: selectedGroups.contains(e) ? AppColor.whiteColor : AppColor.primaryColor)),
                                                              selected: selectedGroups.contains(e)),
                                                        ))
                                                    .toList(),
                                              ))
                                        ],
                                      ),
                                    ));
                              }));
                    },
                    icon: const Icon(
                      Icons.save,
                      color: AppColor.primaryDarkColor,
                    )),
              );
            },
          ),
          IconButton(
              onPressed: () {
                context.read<PreviewChordBloc>().add(const ChangeFontSize(isIncrease: true));
              },
              icon: const Icon(
                Icons.zoom_in,
                color: AppColor.primaryDarkColor,
              )),
          IconButton(
              onPressed: () {
                context.read<PreviewChordBloc>().add(const ChangeFontSize(isIncrease: false));
              },
              icon: const Icon(
                Icons.zoom_out,
                color: AppColor.primaryDarkColor,
              )),
          IconButton(
            onPressed: () {
              context.read<PreviewChordBloc>().add(const TransposeChord(increment: 1));
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
              context.read<PreviewChordBloc>().add(const TransposeChord(increment: -1));
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
          BlocBuilder<PreviewChordBloc, PreviewChordState>(
            builder: (context, state) {
              return IconButton(
                onPressed: () {
                  context.read<PreviewChordBloc>().add(ChangeColumnStatus(status: !state.twoColumns));
                },
                icon: Icon(
                  state.twoColumns ? Icons.view_column : Icons.format_align_justify,
                  size: 18,
                  color: AppColor.primaryDarkColor,
                ),
              );
            },
          ),
          BlocBuilder<PreviewChordBloc, PreviewChordState>(
            builder: (context, state) {
              return IconButton(
                  icon: Icon(
                    MdiIcons.radioboxMarked,
                    color: (state.data.song != null && state.selectedSongId == state.data.song?.id) ? Colors.green : AppColor.primaryDarkColor,
                  ),
                  onPressed: () {
                    context.read<PreviewChordBloc>().add(SelectSongInPreview(
                        selectSongId: state.data.song?.id ?? '',
                        title: state.data.song?.title ?? '',
                        interpret: state.data.song?.interpret ?? '',
                        lyricsWithoutChords: state.data.song?.lyricsWithoutChordsWithLines ?? ''));
                  });
            },
          ),
        ],
      ),
      body: BlocBuilder<PreviewChordBloc, PreviewChordState>(
        builder: (context, state) {
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
                      Container(
                        height: MediaQuery.of(context).size.height - 120,
                        child: state.twoColumns ? _getLyricsTwoColumnsRenderer(state, scrollController) : _getLyricsOneColumnRenderer(state, scrollController),
                      ),
                    ],
                  ),
                ),
                BlocBuilder<PreviewChordBloc, PreviewChordState>(
                  builder: (context, state) {
                    return Visibility(
                      visible: state.data.song?.indexSongBook != null,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: Text('${'indexSongBook'.tr()}: ${state.data.song?.indexSongBook ?? ''}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColor.primaryColor,
                              )),
                        ),
                      ),
                    );
                  },
                ),
                Visibility(
                  visible: state.twoColumns && state.lyricWithColumns(true, true, TypeLyric.translate).length > 2,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: WidgetStateProperty.all<Color>(state.currentColumn > 0 ? AppColor.primaryColor.withOpacity(0.7) : AppColor.grey4Color.withOpacity(0.7)),
                        ),
                        onPressed: () {
                          if (state.currentColumn <= 0) {
                            return;
                          }
                          context.read<PreviewChordBloc>().add(ChangeCurrentColumn(column: state.currentColumn - 2));
                        },
                        child: Icon(Icons.turn_left, color: state.currentColumn > 0 ? AppColor.whiteColor : AppColor.grey2Color),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: state.twoColumns && state.lyricWithColumns(true, true, TypeLyric.translate).length > 2,
                  child: Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all<Color>(state.currentColumn + 2 < state.lyricWithColumns(true, true, TypeLyric.translate).length
                              ? AppColor.primaryColor.withOpacity(0.7)
                              : AppColor.grey4Color.withOpacity(0.7)),
                        ),
                        onPressed: () {
                          if (state.currentColumn + 2 >= state.lyricWithColumns(true, true, TypeLyric.translate).length) {
                            return;
                          }
                          context.read<PreviewChordBloc>().add(ChangeCurrentColumn(column: state.currentColumn + 2));
                        },
                        child: Icon(Icons.turn_right,
                            color: state.currentColumn + 2 < state.lyricWithColumns(true, true, TypeLyric.translate).length ? AppColor.whiteColor : AppColor.grey2Color),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getLyricsOneColumnRenderer(PreviewChordState state, ScrollController scrollController) {
    String lyric = state.data.song?.lyrics ?? '';
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

  Widget _getLyricsTwoColumnsRenderer(PreviewChordState state, ScrollController scrollController) {
    List<String> splittedLyric = state.lyricWithColumns(true, true, TypeLyric.translate);

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

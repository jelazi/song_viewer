import 'dart:math';

import 'package:default_project/model/song/song.dart';
import 'package:default_project/services/constants.dart';
import 'package:default_project/view/desktop_view/widgets/my_toast.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/dialogs_export.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../blocs/export_blocs.dart';
import '../../../services/enums.dart';
import '../../desktop_view/widgets/chord_editor_dialog.dart';
import '../widgets/chords_lyric/flutter_chord.dart';
import '../widgets/chords_lyric/guitar_tabs.dart';
import '../widgets/my_floating_button.dart';

class PreviewPageMobile extends StatefulWidget {
  const PreviewPageMobile({super.key});

  @override
  State<PreviewPageMobile> createState() => _PreviewPageMobileState();
}

class _PreviewPageMobileState extends State<PreviewPageMobile> {
  ScrollController scrollController = ScrollController();
  OverlayEntry? overlayChord;

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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(110),
        child: BlocBuilder<PreviewChordBloc, PreviewChordState>(
          builder: (context, state) {
            return GestureDetector(
              onPanUpdate: (details) {
                if (details.delta.dy < 0) {
                  context.read<PreviewChordBloc>().add(const ChangeAppBarStatus(status: false));
                }
              },
              child: AnimatedContainer(
                  height: state.appBarStatus ? 100.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AppBar(
                    iconTheme: const IconThemeData(
                      color: Colors.white,
                    ),
                    backgroundColor: AppColor.primaryColor,
                    title: Column(
                      children: [
                        Text(state.data.song?.title ?? '', style: h4TextStyle.copyWith(color: Colors.white)),
                        Text(state.data.song?.interpret ?? '', style: pTextStyle.copyWith(color: Colors.white))
                      ],
                    ),
                    actions: [
                      if (state.isDataFromWeb)
                        IconButton(
                          icon: const Icon(Icons.save, color: Colors.white),
                          onPressed: () {
                            TextEditingController nameSongController = TextEditingController(text: state.data.song?.title ?? '');
                            TextEditingController interpretController = TextEditingController(text: state.data.song?.interpret ?? '');
                            List listAllGroups = context.read<HomePageBloc>().state.listAllGroups;
                            var selectedGroups = <String>[];
                            showDialog(
                              context: context,
                              builder: (context) => StatefulBuilder(
                                builder: (context, setState) {
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
                                      if ((state.data.song?.lyrics ?? '').isEmpty) {
                                        MyToast.showText(text: 'webSongError'.tr(), typeNotification: TypeNotification.error);
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
                                                          selected: selectedGroups.contains(e),
                                                        ),
                                                      ))
                                                  .toList(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      IconButton(
                          icon: Icon(
                            Icons.radio_button_checked,
                            color: (state.data.song != null && state.selectedSongId == state.data.song?.id) ? Colors.green : AppColor.primaryDarkColor,
                          ),
                          onPressed: () {
                            context
                                .read<PreviewChordBloc>()
                                .add(SelectSongInPreview(selectSongId: state.data.song?.id ?? '', title: '', interpret: '', lyricsWithoutChords: '', lyricsWithChords: ''));
                          }),
                      IconButton(
                          onPressed: () {
                            context.read<PreviewChordBloc>().add(ChangeVisibleButtons(status: !state.visibleButtons));
                          },
                          icon: const Icon(Icons.menu, color: Colors.white))
                    ],
                  )),
            );
          },
        ),
      ),
      body: BlocBuilder<PreviewChordBloc, PreviewChordState>(
        builder: (context, state) {
          return GestureDetector(
            onTap: () {
              disableAllOverlay();
            },
            child: Stack(
              children: [
                BlocBuilder<PreviewChordBloc, PreviewChordState>(
                  builder: (context, state) {
                    return Visibility(
                      visible: state.data.song?.indexSongBook != null,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
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
                        height: MediaQuery.of(context).size.height - 130,
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
      ),
    );
  }

  Widget _getLyricsRenderer(PreviewChordState state, ScrollController scrollController) {
    String lyric = state.data.song?.lyrics ?? '';
    // Handle web song with empty lyrics
    if (lyric.isEmpty && state.isDataFromWeb) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: AppColor.grey3Color),
              const SizedBox(height: 16),
              Text('webSongError'.tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColor.grey1Color)),
              const SizedBox(height: 8),
              Text('webSongErrorHint'.tr(), textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColor.grey1Color.withValues(alpha: 0.7))),
            ],
          ),
        ),
      );
    }
    if (state.twoColumns) {
      List<String> splittedLyric = state.lyricWithColumns(true, true, TypeLyric.translate);

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
          onLongPress: () {
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

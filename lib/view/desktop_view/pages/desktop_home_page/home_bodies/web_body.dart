import 'dart:math';

import 'package:default_project/model/song/song.dart';
import 'package:default_project/model/web_song.dart';
import 'package:default_project/model/youtube_video.dart';
import 'package:default_project/services/chord_notation_service.dart';
import 'package:default_project/services/constants.dart';
import 'package:default_project/view/desktop_view/widgets/my_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../mobile_view/widgets/chords_lyric/chord_lyrics_line.dart';
import '../../../../mobile_view/widgets/chords_lyric/guitar_tabs.dart';
import '../../../../mobile_view/widgets/chords_lyric/lyrics_renderer.dart';
import '../../../../mobile_view/widgets/dialogs/dialogs_export.dart';
import '../../../widgets/chord_editor_dialog.dart';
import 'list_web_song.dart';

class WebBody extends StatefulWidget {
  const WebBody({super.key});

  @override
  State<WebBody> createState() => _WebBodyState();
}

class _WebBodyState extends State<WebBody> {
  ScrollController scrollController = ScrollController();
  OverlayEntry? overlayChord;

  /// Song built from the currently selected web song. Holds chord overrides
  /// edited in the preview so they survive until the song is saved.
  Song? _webSong;
  String? _webSongKey;

  /// Library id of the web song once it has been saved in this session.
  ///
  /// Sharing a song with the other devices broadcasts an id, so a song that is
  /// not in the library yet has to be saved before it can be shared.
  String? _savedSongId;

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
    disableAllOverlay();
  }

  Song _buildSongFromWeb(WebSong web, String lyrics) {
    final song = Song.empty();
    song.title = web.title;
    song.interpret = web.interpret;
    song.lyrics = lyrics;
    if (web.youtube.isNotEmpty) {
      song.youtubeVideos = [YoutubeVideo(name: web.title, path: web.youtube)];
    }
    return song;
  }

  /// Renames chord-diagram overrides along with the chords they belong to when
  /// the lyrics are switched to the Czech notation, so an override edited for
  /// `Bb` still applies once that chord reads `B`.
  ///
  /// Switching back leaves the keys alone: `H` and `B` both map back ambiguously
  /// and an override that matches no chord is merely unused, never wrong.
  Map<String, List<String>>? _convertOverrideKeys(Map<String, List<String>>? overrides, bool toCzech) {
    if (!toCzech || overrides == null || overrides.isEmpty) return overrides;
    return overrides.map((chord, positions) => MapEntry(ChordNotationService.convertChord(chord), positions));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WebBloc, WebState>(
      // Also react to the lyric arriving: the song is emitted first with an empty
      // lyric (download in progress) and again once the text is fetched. Without
      // watching the lyric, _webSong would keep the empty version and saving would
      // store only title/interpret. The converted lyric is watched for the same
      // reason — switching the notation has to reach the copy that gets saved.
      listenWhen: (previous, current) =>
          previous.currentSong?.server != current.currentSong?.server ||
          previous.currentSong?.ref != current.currentSong?.ref ||
          previous.currentSong?.lyric != current.currentSong?.lyric ||
          previous.czechNotationLyric != current.czechNotationLyric,
      listener: (context, state) {
        disableAllOverlay();
        final web = state.currentSong;
        final key = web == null ? null : '${web.server}${web.ref}';
        if (key != _webSongKey) {
          setState(() {
            _webSongKey = key;
            _webSong = web == null ? null : _buildSongFromWeb(web, state.displayedLyric);
            // Another song is on screen now; the saved id belonged to the
            // previous one.
            _savedSongId = null;
          });
        } else if (web != null && state.displayedLyric.isNotEmpty && state.displayedLyric != _webSong?.lyrics) {
          // Same song, but its text changed: the download finished, or the
          // notation was switched. Keep the chord overrides edited so far and
          // rename their keys along with the chords they belong to.
          setState(() {
            final song = _webSong ?? _buildSongFromWeb(web, state.displayedLyric);
            song.lyrics = state.displayedLyric;
            song.chordOverrides = _convertOverrideKeys(song.chordOverrides, state.isNotationConverted);
            _webSong = song;
          });
        }
      },
      builder: (context, state) {
        final hasSong = state.currentSong != null && (state.currentSong?.lyric ?? '').isNotEmpty;
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
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(state.currentSong?.title ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  Text(state.currentInterpret.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.grey2Color)),
                                  if (hasSong && state.transposeIncrement != 0) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      'cap: ${state.cap}',
                                      style: const TextStyle(fontSize: 13, color: AppColor.primaryColor),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (hasSong) _buildActions(context, state),
                      ],
                    ),
                    SizedBox(
                      height: MediaQuery.of(context).size.height - 200,
                      child: state.currentSong == null
                          ? Container()
                          : (state.currentSong?.lyric ?? '').isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.cloud_off, size: 48, color: AppColor.grey3Color),
                                      const SizedBox(height: 12),
                                      Text('webSongError'.tr(), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: AppColor.grey1Color)),
                                    ],
                                  ),
                                )
                              : LyricsRenderer(
                              scrollController: scrollController,
                              isVisibleNote: true,
                              lyrics: state.displayedLyric,
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

  Widget _buildActions(BuildContext context, WebState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: 'editChordHint'.tr(),
          child: const Icon(Icons.info_outline, size: 18, color: AppColor.grey2Color),
        ),
        const SizedBox(width: 8),
        // Offered only when the site's spelling differs from the Czech one, or
        // once it has been converted, so that it can be switched back.
        if (state.foreignNotationDetected || state.isNotationConverted)
          Tooltip(
            message: state.isNotationConverted ? 'revertChordNotationHint'.tr() : 'convertChordNotationHint'.tr(),
            child: TextButton.icon(
              onPressed: () => context.read<WebBloc>().add(const ToggleChordNotation()),
              icon: Icon(
                state.isNotationConverted ? Icons.undo : Icons.published_with_changes,
                color: state.isNotationConverted ? AppColor.alertSuccessColor : AppColor.primaryDarkColor,
              ),
              label: Text(
                state.isNotationConverted ? 'revertChordNotation'.tr() : 'convertChordNotation'.tr(),
                style: TextStyle(color: state.isNotationConverted ? AppColor.alertSuccessColor : AppColor.primaryDarkColor),
              ),
            ),
          ),
        BlocBuilder<HomePageBloc, HomePageState>(
          buildWhen: (previous, current) => previous.selectedSongId != current.selectedSongId,
          builder: (context, homeState) {
            final isShared = _savedSongId != null && homeState.selectedSongId == _savedSongId;
            return Tooltip(
              message: _savedSongId == null ? 'shareWebSongHint'.tr() : '',
              child: TextButton.icon(
                onPressed: () => _shareSong(context, state),
                icon: Icon(isShared ? Icons.cloud_done : Icons.cloud_upload, color: isShared ? AppColor.alertSuccessColor : AppColor.primaryDarkColor),
                label: Text(
                  'currentSong'.tr(),
                  style: TextStyle(color: isShared ? AppColor.alertSuccessColor : AppColor.primaryDarkColor),
                ),
              ),
            );
          },
        ),
        TextButton.icon(
          onPressed: () => _openSaveDialog(context, state),
          icon: const Icon(Icons.save, color: AppColor.primaryDarkColor),
          label: Text('saveSong'.tr(), style: const TextStyle(color: AppColor.primaryDarkColor)),
        ),
      ],
    );
  }

  /// Broadcasts the web song as the current song for the other devices.
  ///
  /// Only an id travels over the realtime channel, so a song that is not in the
  /// library yet is saved first — the save dialog then shares it on success.
  void _shareSong(BuildContext context, WebState state) {
    final savedId = _savedSongId;
    if (savedId == null) {
      _openSaveDialog(context, state, shareAfterSave: true);
      return;
    }
    final homeBloc = context.read<HomePageBloc>();
    final song = homeBloc.songsRepository.getSongById(savedId);
    if (song == null) {
      // Deleted meanwhile — fall back to saving it again.
      setState(() => _savedSongId = null);
      _openSaveDialog(context, state, shareAfterSave: true);
      return;
    }
    _selectSongForOthers(homeBloc, song);
  }

  void _selectSongForOthers(HomePageBloc homeBloc, Song song) {
    homeBloc.add(SelectSong(
      selectedSongId: song.id,
      title: song.title,
      interpret: song.interpret ?? '',
      lyricsWithoutChords: song.lyricsWithoutChords,
      lyricsWithChords: song.lyrics,
    ));
  }

  /// Remembers the id the web song was stored under; kept out of the save
  /// dialog because `StatefulBuilder` shadows [setState] there.
  void _markSaved(String songId) {
    setState(() => _savedSongId = songId);
  }

  void _openSaveDialog(BuildContext context, WebState state, {bool shareAfterSave = false}) {
    final web = state.currentSong;
    if (web == null) return;
    final base = _webSong ?? _buildSongFromWeb(web, state.displayedLyric);
    // The text on screen is the source of truth; fall back to it if the cached
    // edit copy is still empty (e.g. lyrics finished loading after _webSong was
    // first built). Without this the song could be saved with only title/interpret.
    final lyrics = base.lyrics.isNotEmpty ? base.lyrics : state.displayedLyric;
    final nameSongController = TextEditingController(text: base.title);
    final interpretController = TextEditingController(text: base.interpret ?? '');
    final listAllGroups = context.read<HomePageBloc>().state.listAllGroups;
    final selectedGroups = <String>[];

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
            if (lyrics.isEmpty) {
              MyToast.showText(text: 'webSongError'.tr(), typeNotification: TypeNotification.error);
              return;
            }
            final song = Song.empty();
            song.generateId();
            song.title = nameSongController.text;
            song.interpret = interpretController.text;
            song.lyrics = lyrics;
            song.notes = base.notes ?? [];
            song.youtubeVideos = base.youtubeVideos ?? [];
            song.chordOverrides = base.chordOverrides ?? {};
            song.groups = selectedGroups;
            final homeBloc = context.read<HomePageBloc>();
            final songsRepository = homeBloc.songsRepository;
            final saved = songsRepository.updateSong(song);
            // Carry the transposition made in the web preview over to the saved
            // song, so reopening it in the library shows the same key.
            if (state.transposeIncrement != 0) {
              songsRepository.changeTransposeChord(song, state.transposeIncrement);
            }
            _markSaved(song.id);
            if (shareAfterSave) {
              // Only an id is broadcast, so wait until the song has actually
              // been written (and pushed to the server, when there is one).
              saved.then((_) => _selectSongForOthers(homeBloc, song));
            }
            Navigator.of(context).pop();
            MyToast.showText(text: 'songSaved'.tr(), typeNotification: TypeNotification.success);
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
                            width: 250,
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
                            width: 250,
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
                  height: 200,
                  child: SingleChildScrollView(
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
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  void openChordImage(Chord chord, Offset pos, BuildContext context) {
    if (overlayChord != null) {
      overlayChord!.remove();
      overlayChord = null;
    }

    final chordService = context.read<HomePageBloc>().songsRepository.chordService;
    final positions = chordService.resolveChordPositions(chord.chordText, song: _webSong);

    if (positions.isEmpty) {
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
    final chordService = context.read<HomePageBloc>().songsRepository.chordService;

    showDialog(
      context: context,
      builder: (dialogContext) => ChordEditorDialog(
        chordName: chordName,
        chordService: chordService,
        song: _webSong,
        onSongUpdated: (updatedSong) {
          // The web song isn't in the library yet; keep the override locally so
          // it is included when the user saves the song.
          setState(() {
            _webSong = updatedSong;
          });
        },
      ),
    );
  }

  void disableAllOverlay() {
    if (overlayChord != null) {
      overlayChord!.remove();
      overlayChord = null;
    }
  }
}

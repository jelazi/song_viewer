import 'package:default_project/model/song/song.dart';
import 'package:default_project/services/presentation_window_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../services/constants.dart';
import '../../../widgets/presentation_playlist_widget.dart';

class ListSong extends StatefulWidget {
  final double? width;
  final VoidCallback? onRequestFocus;

  const ListSong({
    super.key,
    this.width,
    this.onRequestFocus,
  });

  @override
  State<ListSong> createState() => _ListSongState();
}

class _ListSongState extends State<ListSong> {
  final TextEditingController _filter = TextEditingController();
  double _songListHeight = 400.0; // Absolute height instead of flex

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePageBloc, HomePageState>(
      builder: (context, state) {
        return Container(
            width: widget.width ?? 300,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColor.grey3Color, width: 1.0), right: BorderSide(color: AppColor.grey3Color, width: 1.0)),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                height: 50,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _filter,
                  builder: (context, value, child) {
                    return TextField(
                      controller: _filter,
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'filterSong'.tr(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () {
                                context.read<HomePageBloc>().add(FilterSong(filter: _filter.text));
                              },
                              icon: const Icon(Icons.search, size: 18),
                            ),
                            if (value.text.isNotEmpty)
                              IconButton(
                                onPressed: () {
                                  _filter.clear();
                                  context.read<HomePageBloc>().add(const FilterSong(filter: ''));
                                },
                                icon: const Icon(Icons.clear, size: 18),
                              ),
                          ],
                        ),
                      ),
                      onChanged: (value) {
                        context.read<HomePageBloc>().add(FilterSong(filter: value));
                      },
                      onSubmitted: (value) {
                        context.read<HomePageBloc>().add(FilterSong(filter: value));
                      },
                    );
                  },
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    final minPlaylistHeight = 150.0;
                    final dividerSpacing = 24.0; // 8 + 8 + 8 for divider and spacing
                    final maxSongListHeight = availableHeight - minPlaylistHeight - dividerSpacing;

                    // Clamp song list height
                    final clampedSongListHeight = _songListHeight.clamp(100.0, maxSongListHeight);
                    final playlistHeight = availableHeight - clampedSongListHeight - dividerSpacing;

                    return Column(
                      children: [
                        SizedBox(
                          height: clampedSongListHeight,
                          child: ListView(
                            children: state.listSong
                                .map((song) => Draggable<Song>(
                                      data: song,
                                      feedback: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          width: 280,
                                          height: 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColor.primaryColor.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.music_note, size: 16, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  song.title,
                                                  style: const TextStyle(fontSize: 14, color: Colors.white),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      child: Container(
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: state.selectedSongId == song.id ? AppColor.alertSuccessLightColor : Colors.transparent,
                                          border: Border(
                                            top: BorderSide(color: state.selectedSongId == song.id ? AppColor.alertErrorDarkColor : AppColor.grey3Color, width: 1.0),
                                          ),
                                        ),
                                        child: BlocBuilder<PreviewChordBloc, PreviewChordState>(
                                          builder: (context, state) {
                                            return ListTile(
                                              selected: state.data.song?.id == song.id,
                                              selectedTileColor: state.selectedSongId == song.id ? AppColor.alertErrorLightColor : AppColor.grey4Color,
                                              hoverColor: state.selectedSongId == song.id ? AppColor.alertSuccessDarkColor : AppColor.grey5Color,
                                              title: SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    song.title,
                                                    style: const TextStyle(fontSize: 14),
                                                    overflow: TextOverflow.ellipsis,
                                                  )),
                                              onTap: () {
                                                _handleSongTap(context, state.data.song, song);
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Resizable divider
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeRow,
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) {
                              setState(() {
                                _songListHeight = (_songListHeight + details.delta.dy).clamp(100.0, maxSongListHeight);
                              });
                            },
                            child: Container(
                              height: 8,
                              color: Colors.transparent,
                              child: Center(
                                child: Container(
                                  height: 2,
                                  color: AppColor.grey3Color,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: playlistHeight,
                          child: PresentationPlaylistWidget(
                            onSongSelected: (song) {
                              final manager = PresentationWindowManager();
                              if (!manager.isPresentationWindowOpen) return;

                              // Update the song in the presentation bloc
                              final presentationBloc = context.read<PresentationBloc>();
                              final settingsState = context.read<SettingsBloc>().state;
                              presentationBloc.add(UpdatePresentationSong(song: song));

                              // Compute page content directly — no race condition
                              final result = PresentationBloc.computePageContent(
                                song: song,
                                linesPerPage: settingsState.presentationLinesPerPage,
                                showChords: settingsState.presentationShowChords,
                                page: 0,
                              );
                              manager.sendPageToPresentation(
                                context,
                                title: song.title,
                                pageContent: result.pageContent,
                                fontSize: settingsState.presentationFontSize,
                                textColor: settingsState.presentationFontColor,
                                showChords: settingsState.presentationShowChords,
                                currentPage: result.currentPage,
                                totalPages: result.totalPages,
                                linesPerPage: settingsState.presentationLinesPerPage,
                              );
                            },
                            onSongDoubleTap: (song, index) {
                              // Double-click starts presentation from this song
                              final manager = PresentationWindowManager();
                              final presentationBloc = context.read<PresentationBloc>();
                              final settingsState = context.read<SettingsBloc>().state;

                              // Update presentation bloc with the song
                              presentationBloc.add(UpdatePresentationSong(song: song));
                              presentationBloc.add(UpdatePresentationSettings(
                                linesPerPage: settingsState.presentationLinesPerPage,
                                fontSize: settingsState.presentationFontSize,
                                textColor: settingsState.presentationFontColor,
                                showChords: settingsState.presentationShowChords,
                                screenIndex: settingsState.presentationScreenIndex,
                              ));

                              // Compute first page of this song
                              final result = PresentationBloc.computePageContent(
                                song: song,
                                linesPerPage: settingsState.presentationLinesPerPage,
                                showChords: settingsState.presentationShowChords,
                                page: 0,
                              );

                              if (manager.isPresentationWindowOpen) {
                                // Presentation already open - just send the new song
                                manager.sendPageToPresentation(
                                  context,
                                  title: song.title,
                                  pageContent: result.pageContent,
                                  fontSize: settingsState.presentationFontSize,
                                  textColor: settingsState.presentationFontColor,
                                  showChords: settingsState.presentationShowChords,
                                  currentPage: result.currentPage,
                                  totalPages: result.totalPages,
                                  linesPerPage: settingsState.presentationLinesPerPage,
                                  showTitle: settingsState.presentationShowTitle,
                                  showPageNumber: settingsState.presentationShowPageNumber,
                                );
                              } else {
                                // Open presentation window from this song
                                manager.openPresentationWindow(
                                  context,
                                  title: song.title,
                                  pageContent: result.pageContent,
                                  fontSize: settingsState.presentationFontSize,
                                  textColor: settingsState.presentationFontColor,
                                  showChords: settingsState.presentationShowChords,
                                  currentPage: result.currentPage,
                                  totalPages: result.totalPages,
                                  linesPerPage: settingsState.presentationLinesPerPage,
                                  showTitle: settingsState.presentationShowTitle,
                                  showPageNumber: settingsState.presentationShowPageNumber,
                                  screenIndex: settingsState.presentationScreenIndex,
                                );
                              }

                              // Re-request focus so keyboard shortcuts work
                              Future.delayed(const Duration(milliseconds: 300), () {
                                widget.onRequestFocus?.call();
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ]));
      },
    );
  }

  void _switchToSong(BuildContext context, Song song) {
    context.read<DesktopRibbonMenuBloc>().add(ChangeIsSelectedSong(song: song));
    context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: song));
    context.read<EditSongBloc>().add(ChangeEditSong(song: song, isOriginalLyrics: false));
  }

  void _deselectSong(BuildContext context) {
    context.read<DesktopRibbonMenuBloc>().add(const ChangeIsSelectedSong(song: null));
    context.read<PreviewChordBloc>().add(const ChangeCurrentSong(song: null));
    context.read<EditSongBloc>().add(ChangeEditSong(song: Song.empty(), isOriginalLyrics: false));
  }

  void _handleSongTap(BuildContext context, Song? currentSong, Song tappedSong) {
    if (currentSong?.id == tappedSong.id) {
      // Deselecting current song — check for unsaved changes
      final editState = context.read<EditSongBloc>().state;
      if (editState.isCurrentSongModified) {
        _showUnsavedChangesDialog(context, editState.listModifications, () {
          _deselectSong(context);
        });
      } else {
        _deselectSong(context);
      }
    } else {
      // Switching to a different song — check for unsaved changes
      final editState = context.read<EditSongBloc>().state;
      if (editState.isCurrentSongModified) {
        _showUnsavedChangesDialog(context, editState.listModifications, () {
          _switchToSong(context, tappedSong);
        });
      } else {
        _switchToSong(context, tappedSong);
      }
    }
  }

  String _getModificationLabel(String key) {
    switch (key) {
      case 'title':
        return 'modTitle'.tr();
      case 'interpret':
        return 'modInterpret'.tr();
      case 'indexSongBook':
        return 'modIndexSongBook'.tr();
      case 'groups':
        return 'modGroups'.tr();
      case 'lyrics':
        return 'modLyrics'.tr();
      case 'originalLyrics':
        return 'modOriginalLyrics'.tr();
      case 'youtubeVideos':
        return 'modYoutubeVideos'.tr();
      case 'sheets':
        return 'modSheets'.tr();
      default:
        return key;
    }
  }

  void _showUnsavedChangesDialog(BuildContext context, List<String> modifications, VoidCallback onProceed) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('unsavedChangesTitle'.tr()),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('unsavedChangesMessage'.tr()),
              const SizedBox(height: 8),
              ...modifications.map((mod) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.edit, size: 14, color: Colors.orange),
                        const SizedBox(width: 6),
                        Text(_getModificationLabel(mod), style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                  )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr()),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onProceed();
              },
              child: Text('discardChanges'.tr(), style: const TextStyle(color: Colors.red)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<EditSongBloc>().add(const SaveSong(typeApp: 'desktop'));
                // Small delay to let save complete before switching
                Future.delayed(const Duration(milliseconds: 100), () {
                  onProceed();
                });
              },
              child: Text('saveAndSwitch'.tr()),
            ),
          ],
        );
      },
    );
  }
}

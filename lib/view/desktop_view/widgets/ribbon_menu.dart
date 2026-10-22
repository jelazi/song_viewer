import 'dart:io';

import 'package:song_viewer/config/features.dart';

import 'package:song_viewer/services/constants.dart';
import 'package:song_viewer/services/presentation_window_manager.dart';
import 'package:song_viewer/view/mobile_view/widgets/dialogs/dialogs_export.dart';
import 'package:song_viewer/view/mobile_view/widgets/dialogs/qr_code_dialog.dart';
import 'package:song_viewer/view/mobile_view/widgets/dialogs/question_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';
import '../../../model/playlist.dart';
import '../../../model/song/song.dart';
import '../../../services/song_key_service.dart';
import '../../widgets/pad_window.dart';
import 'my_toast.dart';
import 'ribbon_button.dart';

class RibbonMenu extends StatelessWidget {
  const RibbonMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
      builder: (context, state) {
        // Rebuild the ribbon when superuser mode changes (or finishes loading at
        // startup); the section selector and context actions read it via
        // context.read, so they need a rebuild to pick up the new value.
        return BlocBuilder<SettingsBloc, SettingsState>(
          buildWhen: (previous, current) => previous.superuserMode != current.superuserMode,
          builder: (context, _) {
            final isPreviewBody = state.bodyName == 'preview' ||
                state.bodyName == 'browse_youtube' ||
                state.bodyName == 'browse_sheets';
            final isSettingsBody = state.bodyName == 'groups' ||
                state.bodyName == 'users' ||
                state.bodyName == 'presentation_settings' ||
                state.bodyName == 'general_settings' ||
                state.bodyName == 'backup_restore';

            return Container(
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppColor.whiteColor,
            border: Border(
              bottom: BorderSide(color: AppColor.grey4Color),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _buildNavigationGroup(context, state, isPreviewBody, isSettingsBody),
                  if (!isSettingsBody) ...[
                    const ToolbarDivider(),
                    const SizedBox(width: 4),
                    _buildSectionSelector(context, state),
                  ],
                ],
              ),
              if (_hasContextActions(context, state, isSettingsBody)) ...[
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildContextActions(context, state, isPreviewBody, isSettingsBody),
                    ],
                  ),
                ),
              ],
            ],
          ),
            );
          },
        );
      },
    );
  }

  Widget _buildNavigationGroup(
    BuildContext context,
    DesktopRibbonMenuState state,
    bool isPreviewBody,
    bool isSettingsBody,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RibbonButton(
          text: 'home'.tr(),
          icon: Icon(
            Icons.home,
            size: 16,
            color: !isSettingsBody ? AppColor.whiteColor : AppColor.grey1Color,
          ),
          isEnabled: true,
          isSelected: !isSettingsBody,
          onPressed: () {
            context.read<DesktopRibbonMenuBloc>().add(const ChangeHomeBody(bodyName: 'preview'));
          },
        ),
        const SizedBox(width: 2),
        RibbonButton(
          text: 'settings'.tr(),
          icon: Icon(
            Icons.settings,
            size: 16,
            color: isSettingsBody ? AppColor.whiteColor : AppColor.grey1Color,
          ),
          isEnabled: true,
          isSelected: isSettingsBody,
          onPressed: () {
            context.read<DesktopRibbonMenuBloc>().add(const ChangeHomeBody(bodyName: 'general_settings'));
          },
        ),
        if (padsSupported) ...[
          const SizedBox(width: 2),
          const _PadRibbonButton(),
        ],
      ],
    );
  }

  Widget _buildSectionSelector(BuildContext context, DesktopRibbonMenuState state) {
    final isPreviewBody = state.bodyName == 'preview' ||
        state.bodyName == 'browse_youtube' ||
        state.bodyName == 'browse_sheets';
    final isSuperuser = context.read<SettingsBloc>().state.superuserMode;

    return ToolbarSegmentedControl<String>(
      selectedValue: isPreviewBody ? 'preview' : state.bodyName,
      onChanged: (value) {
        context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: value));
      },
      items: [
        ToolbarSegment(label: 'preview'.tr(), icon: const Icon(Icons.preview), value: 'preview'),
        if (isSuperuser)
          ToolbarSegment(label: 'edit'.tr(), icon: const Icon(Icons.edit), value: 'edit'),
        // Personal flavour only — see plans/store-release-plan.md §10.
        if (Features.webImport) ToolbarSegment(label: 'web'.tr(), icon: const Icon(Icons.web), value: 'web'),
        ToolbarSegment(label: 'playlist'.tr(), icon: const Icon(Icons.playlist_play), value: 'playlist'),
        // Every flavour — importing a file the user already has is not
        // content distribution, so this is not behind a feature flag.
        ToolbarSegment(label: 'chordProImport'.tr(), icon: const Icon(Icons.file_download), value: 'chordpro_import'),
        if (Features.aiEnrichment)
          ToolbarSegment(label: 'song_enrichment'.tr(), icon: const Icon(Icons.auto_awesome), value: 'song_enrichment'),
      ],
    );
  }

  bool _hasContextActions(BuildContext context, DesktopRibbonMenuState state, bool isSettingsBody) {
    if (isSettingsBody) return true;
    if (state.bodyName == 'edit') {
      final isSuperuser = context.read<SettingsBloc>().state.superuserMode;
      return isSuperuser;
    }
    if (state.bodyName == 'preview' || state.bodyName == 'browse_youtube' || state.bodyName == 'browse_sheets') return true;
    if (state.bodyName == 'playlist') return true;
    if (state.bodyName == 'web') return true;
    return false;
  }

  Widget _buildContextActions(
    BuildContext context,
    DesktopRibbonMenuState state,
    bool isPreviewBody,
    bool isSettingsBody,
  ) {
    if (isSettingsBody) {
      return _buildSettingsActions(context, state);
    }

    if (state.bodyName == 'edit') {
      return _buildEditActions(context, state);
    }

    if (isPreviewBody) {
      return _buildPreviewActions(context, state);
    }

    if (state.bodyName == 'playlist') {
      return _buildPlaylistActions(context);
    }

    if (state.bodyName == 'web') {
      return _buildWebActions(context);
    }

    if (state.bodyName == 'song_enrichment') {
      return const SizedBox.shrink();
    }

    return const SizedBox.shrink();
  }

  Widget _buildWebActions(BuildContext context) {
    // Compile-time dead in the store build, so the source-site labels below do
    // not end up in the artifact — see plans/store-release-plan.md §10.
    if (!Features.webImport) return const SizedBox.shrink();

    final webNames = ['Velký zpěvník', 'Písničky-akordy', 'ProScholy', 'Worship Leader', 'Worship Chords'];
    final webIcons = [Icons.library_music, Icons.music_note, Icons.church, Icons.mic, Icons.queue_music];
    return BlocBuilder<WebBloc, WebState>(
      builder: (context, webState) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...List.generate(webNames.length, (index) {
              final isSelected = webState.searchWeb == index;
              return Padding(
                padding: const EdgeInsets.only(right: 4),
                child: RibbonButton(
                  text: webNames[index],
                  isEnabled: true,
                  isSelected: isSelected,
                  icon: Icon(webIcons[index]),
                  onPressed: () {
                    context.read<WebBloc>().add(ChangeSearchWeb(searchWeb: index));
                  },
                ),
              );
            }),
            const ToolbarDivider(),
            _buildWebZoomTransposeGroup(context, webState),
          ],
        );
      },
    );
  }

  /// Zoom and transpose for the song shown in the web tab — the same actions
  /// the preview offers, so a found song can be adjusted before it is saved.
  Widget _buildWebZoomTransposeGroup(BuildContext context, WebState webState) {
    final hasSong = (webState.currentSong?.lyric ?? '').isNotEmpty;
    final fontSize = webState.textStyle.fontSize ?? minPreviewFontSize;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RibbonButton(
          text: 'zoomIn'.tr(),
          isEnabled: hasSong && fontSize < maxPreviewFontSize,
          icon: const Icon(Icons.zoom_in, color: Colors.blue),
          onPressed: () {
            context.read<WebBloc>().add(const ChangeWebFontSize(isIncrease: true));
          },
        ),
        RibbonButton(
          text: 'zoomOut'.tr(),
          isEnabled: hasSong && fontSize > minPreviewFontSize,
          icon: const Icon(Icons.zoom_out, color: Colors.blue),
          onPressed: () {
            context.read<WebBloc>().add(const ChangeWebFontSize(isIncrease: false));
          },
        ),
        const SizedBox(width: 2),
        RibbonButton(
          text: '+1',
          isEnabled: hasSong,
          showText: false,
          icon: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 14, color: Colors.orange),
              Icon(Icons.music_note, size: 14, color: Colors.orange),
            ],
          ),
          onPressed: () {
            context.read<WebBloc>().add(const TransposeWebChord(increment: 1));
          },
        ),
        RibbonButton(
          text: '−1',
          isEnabled: hasSong,
          showText: false,
          icon: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.remove, size: 14, color: Colors.orange),
              Icon(Icons.music_note, size: 14, color: Colors.orange),
            ],
          ),
          onPressed: () {
            context.read<WebBloc>().add(const TransposeWebChord(increment: -1));
          },
        ),
      ],
    );
  }

  Widget _buildPreviewActions(BuildContext context, DesktopRibbonMenuState state) {
    final isSuperuser = context.read<SettingsBloc>().state.superuserMode;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.isSelectedSong) ...[
          _buildCurrentSongButton(context),
          const ToolbarDivider(),
          _buildZoomTransposeGroup(context),
          _buildOpenMediaGroup(context, state),
        ] else ...[
          if (isSuperuser) _buildNewSongButton(context),
          if (isSuperuser) const ToolbarDivider(),
          _buildCurrentSongButton(context),
        ],
        const ToolbarDivider(),
        _buildPresentationGroup(context),
      ],
    );
  }

  Widget _buildEditActions(BuildContext context, DesktopRibbonMenuState state) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNewSongButton(context),
        const ToolbarDivider(),
        _buildEditModeSelector(context, state),
        const ToolbarDivider(),
        _buildDeleteButton(context),
      ],
    );
  }

  Widget _buildPlaylistActions(BuildContext context) {
    return _buildPresentationGroup(context);
  }

  Widget _buildSettingsActions(BuildContext context, DesktopRibbonMenuState state) {
    final showServerAdmin = Features.serverAdminVisible(
      context.read<SettingsBloc>().settingsRepository.pocketBaseProvider.isConnected,
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildExportButton(context),
        _buildExportLyricsButton(context),
        const ToolbarDivider(),
        if (showServerAdmin) ...[
          _buildSettingsNavButton(
            context: context,
            text: 'groups'.tr(),
            icon: const Icon(Icons.group, color: Colors.teal),
            bodyName: 'groups',
            isSelected: state.bodyName == 'groups',
          ),
          _buildSettingsNavButton(
            context: context,
            text: 'users'.tr(),
            icon: const Icon(Icons.person, color: Colors.indigo),
            bodyName: 'users',
            isSelected: state.bodyName == 'users',
          ),
        ],
        _buildSettingsNavButton(
          context: context,
          text: 'presentationBtn'.tr(),
          icon: const Icon(Icons.present_to_all, color: Colors.deepPurple),
          bodyName: 'presentation_settings',
          isSelected: state.bodyName == 'presentation_settings',
        ),
        _buildSettingsNavButton(
          context: context,
          text: 'generalSettings'.tr(),
          icon: const Icon(Icons.settings, color: Colors.blueGrey),
          bodyName: 'general_settings',
          isSelected: state.bodyName == 'general_settings',
        ),
        const ToolbarDivider(),
        _buildQrCodeButton(context),
        const ToolbarDivider(),
        _buildBackupRestoreButton(context, state),
      ],
    );
  }

  Widget _buildNewSongButton(BuildContext context) {
    return RibbonButton(
      text: 'newSong'.tr(),
      icon: const Icon(Icons.new_label, color: Colors.green),
      isEnabled: true,
      onPressed: () {
        final nameController = TextEditingController();
        final artistController = TextEditingController();
        showDialog(
          context: context,
          builder: (dialogContext) {
            return EditDialog(
              width: 300,
              height: 300,
              title: 'newSong'.tr(),
              okBack: false,
              okClick: () {
                if (nameController.text.isEmpty) {
                  MyToast.showText(text: 'nameSongIsEmpty'.tr(), typeNotification: TypeNotification.error);
                  return;
                }
                final song = Song.empty()
                  ..title = nameController.text
                  ..interpret = artistController.text;
                context.read<EditSongBloc>().add(CreateNewSong(song: song));
                Navigator.pop(dialogContext);
                context.read<DesktopRibbonMenuBloc>().add(ChangeIsSelectedSong(song: song));
                context.read<DesktopRibbonMenuBloc>().add(const ChangeHomeBody(bodyName: 'edit'));
              },
              widgetContent: Column(
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'songName'.tr(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: artistController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'artist'.tr(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCurrentSongButton(BuildContext context) {
    return BlocBuilder<PreviewChordBloc, PreviewChordState>(
      builder: (context, previewState) {
        final song = previewState.data.song;
        if (song == null) return const SizedBox.shrink();
        return BlocBuilder<HomePageBloc, HomePageState>(
          builder: (context, homeState) {
            final isActive = homeState.selectedSongId == song.id && song.id.isNotEmpty;
            return RibbonButton(
              text: 'currentSong'.tr(),
              isEnabled: true,
              isSelected: isActive,
              icon: Icon(
                isActive ? Icons.cloud_done : Icons.cloud_upload,
                size: 16,
                color: isActive ? Colors.green : Colors.blueGrey,
              ),
              onPressed: () {
                context.read<HomePageBloc>().add(SelectSong(
                      selectedSongId: song.id,
                      title: song.title,
                      interpret: song.interpret ?? '',
                      lyricsWithoutChords: song.lyricsWithoutChords,
                      lyricsWithChords: song.lyrics,
                    ));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildZoomTransposeGroup(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        BlocBuilder<PreviewChordBloc, PreviewChordState>(
          builder: (context, state) {
            return RibbonButton(
              text: 'zoomIn'.tr(),
              isEnabled: state.data.song != null,
              icon: const Icon(Icons.zoom_in, color: Colors.blue),
              onPressed: () {
                context.read<PreviewChordBloc>().add(const ChangeFontSize(isIncrease: true));
              },
            );
          },
        ),
        BlocBuilder<PreviewChordBloc, PreviewChordState>(
          builder: (context, state) {
            return RibbonButton(
              text: 'zoomOut'.tr(),
              isEnabled: state.data.song != null,
              icon: const Icon(Icons.zoom_out, color: Colors.blue),
              onPressed: () {
                context.read<PreviewChordBloc>().add(const ChangeFontSize(isIncrease: false));
              },
            );
          },
        ),
        const SizedBox(width: 2),
        BlocBuilder<PreviewChordBloc, PreviewChordState>(
          builder: (context, state) {
            return RibbonButton(
              text: '+1',
              isEnabled: state.data.song != null,
              showText: false,
              icon: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: Colors.orange),
                  Icon(Icons.music_note, size: 14, color: Colors.orange),
                ],
              ),
              onPressed: () {
                context.read<PreviewChordBloc>().add(const TransposeChord(increment: 1));
              },
            );
          },
        ),
        BlocBuilder<PreviewChordBloc, PreviewChordState>(
          builder: (context, state) {
            return RibbonButton(
              text: '\u22121',
              isEnabled: state.data.song != null,
              showText: false,
              icon: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.remove, size: 14, color: Colors.orange),
                  Icon(Icons.music_note, size: 14, color: Colors.orange),
                ],
              ),
              onPressed: () {
                context.read<PreviewChordBloc>().add(const TransposeChord(increment: -1));
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildOpenMediaGroup(BuildContext context, DesktopRibbonMenuState state) {
    return BlocBuilder<PreviewChordBloc, PreviewChordState>(
      builder: (context, previewState) {
        final hasYoutube = previewState.data.song?.youtubeVideos?.isNotEmpty ?? false;
        final hasSheets = previewState.data.song?.sheets?.isNotEmpty ?? false;

        if (!hasYoutube && !hasSheets) return const SizedBox.shrink();

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasYoutube)
              RibbonButton(
                text: 'openVideos'.tr(),
                isEnabled: true,
                isSelected: state.bodyName == 'browse_youtube',
                icon: const Icon(Icons.play_circle_fill, color: Colors.red),
                onPressed: () {
                  final isActive = state.bodyName == 'browse_youtube';
                  context.read<DesktopRibbonMenuBloc>().add(
                        ChangeHomeBody(bodyName: isActive ? 'preview' : 'browse_youtube'),
                      );
                },
              ),
            if (hasSheets)
              RibbonButton(
                text: 'openSheet'.tr(),
                isEnabled: true,
                isSelected: state.bodyName == 'browse_sheets',
                icon: Icon(Icons.music_note, color: Colors.green.shade700),
                onPressed: () {
                  final isActive = state.bodyName == 'browse_sheets';
                  context.read<DesktopRibbonMenuBloc>().add(
                        ChangeHomeBody(bodyName: isActive ? 'preview' : 'browse_sheets'),
                      );
                },
              ),
            if (hasYoutube || hasSheets) const ToolbarDivider(),
          ],
        );
      },
    );
  }

  Widget _buildPresentationGroup(BuildContext context) {
    return BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
      builder: (context, ribbonState) {
        final isOpen = ribbonState.isPresentationWindowOpen;
        return BlocBuilder<PresentationPlaylistBloc, PresentationPlaylistState>(
          builder: (context, playlistState) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                RibbonButton(
                  text: isOpen ? 'closePresentationBtn'.tr() : 'presentationF5'.tr(),
                  isEnabled: isOpen || playlistState.isNotEmpty,
                  icon: Icon(
                    isOpen ? Icons.close_fullscreen : Icons.present_to_all,
                    size: 16,
                    color: (isOpen || playlistState.isNotEmpty) ? Colors.deepPurple : Colors.grey,
                  ),
                  onPressed: () async {
                    final manager = PresentationWindowManager();
                    if (isOpen) {
                      await manager.closePresentationWindow();
                    } else if (playlistState.isNotEmpty) {
                      _openPresentationFromPlaylist(context);
                    }
                  },
                ),
                RibbonButton(
                  text: 'addToPlaylist'.tr(),
                  isEnabled: true,
                  icon: const Icon(Icons.playlist_add, size: 16, color: Colors.teal),
                  onPressed: () {
                    _showAddSongsDialog(context);
                  },
                ),
                RibbonButton(
                  text: 'savePlaylist'.tr(),
                  isEnabled: playlistState.isNotEmpty,
                  icon: Icon(
                    Icons.save,
                    size: 16,
                    color: playlistState.isNotEmpty ? Colors.blue : Colors.grey,
                  ),
                  onPressed: () {
                    if (playlistState.isNotEmpty) {
                      _showSavePlaylistDialog(context);
                    }
                  },
                ),
                RibbonButton(
                  text: 'loadPlaylist'.tr(),
                  isEnabled: true,
                  icon: Icon(Icons.folder_open, size: 16, color: Colors.amber.shade800),
                  onPressed: () {
                    _showLoadPlaylistDialog(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildEditModeSelector(BuildContext context, DesktopRibbonMenuState state) {
    return ToolbarSegmentedControl<String>(
      selectedValue: state.bodyEditName,
      onChanged: (value) {
        context.read<DesktopRibbonMenuBloc>().add(ChangeEditBody(bodyName: value));
      },
      items: [
        ToolbarSegment(label: 'lyrics'.tr(), icon: const Icon(Icons.edit, color: Colors.blue), value: 'lyrics'),
        ToolbarSegment(label: 'chord'.tr(), icon: const Icon(Icons.piano, color: Colors.orange), value: 'chords'),
        ToolbarSegment(label: 'youtube'.tr(), icon: const Icon(Icons.videocam, color: Colors.red), value: 'youtube'),
        ToolbarSegment(label: 'sheets'.tr(), icon: Icon(Icons.music_note, color: Colors.green.shade700), value: 'sheets'),
        ToolbarSegment(label: 'otherSettings'.tr(), icon: Icon(Icons.settings, color: Colors.grey.shade700), value: 'settings'),
      ],
    );
  }

  Widget _buildDeleteButton(BuildContext context) {
    return RibbonButton(
      text: 'delete'.tr(),
      isEnabled: true,
      showText: false,
      icon: const Icon(Icons.delete, color: Colors.red),
      onPressed: () {
        showDialog(
          context: context,
          builder: (dialogContext) {
            return QuestionDialog(
              title: 'deleteSong'.tr(),
              okClick: () {
                context.read<EditSongBloc>().add(const DeleteCurrentSong());
              },
              question: 'deleteSongQuestion'.tr(),
            );
          },
        );
      },
    );
  }

  Widget _buildExportButton(BuildContext context) {
    return RibbonButton(
      text: 'exportAllSongs'.tr(),
      isEnabled: true,
      icon: const Icon(Icons.exit_to_app, color: Colors.blue),
      onPressed: () async {
        final listSong = context.read<HomePageBloc>().songsRepository.getListSongToJson();
        final outputFile = await FilePicker.platform.saveFile(
          dialogTitle: 'pleaseSelectPathToSaveFile'.tr(),
          fileName: 'list_songs.json',
        );
        if (outputFile == null) return;
        final returnedFile = File(outputFile);
        await returnedFile.writeAsString(listSong);
      },
    );
  }

  Widget _buildExportLyricsButton(BuildContext context) {
    return BlocBuilder<EditSongBloc, EditSongState>(
      builder: (context, state) {
        return Visibility(
          visible: state.currentEditSong.id.isNotEmpty,
          child: RibbonButton(
            text: 'exportLyricsToTxt'.tr(),
            isEnabled: true,
            icon: SizedBox(height: 20, child: Image.asset('assets/icons/txt.png')),
            onPressed: () async {
              String lyric = '';
              showDialog(
                context: context,
                builder: (dialogContext) {
                  return SelectDialog(
                    title: 'exportLyricsToTxt'.tr(),
                    selectQuestion: 'withOrWithoutChords'.tr(),
                    firstSelectTitle: 'withChords'.tr(),
                    firstSelectFunction: () async {
                      lyric = state.currentEditSong.lyricsWithChords;
                      final outputFile = await FilePicker.platform.saveFile(
                        dialogTitle: 'pleaseSelectPathToSaveFile'.tr(),
                        fileName: '${state.currentEditSong.title}.txt',
                      );
                      if (outputFile == null) return;
                      final returnedFile = File(outputFile);
                      await returnedFile.writeAsString(lyric);
                    },
                    secondSelectTitle: 'withoutChords'.tr(),
                    secondSelectFunction: () async {
                      lyric = state.currentEditSong.lyricsWithoutChordsWithLines;
                      final outputFile = await FilePicker.platform.saveFile(
                        dialogTitle: 'pleaseSelectPathToSaveFile'.tr(),
                        fileName: '${state.currentEditSong.title}.txt',
                      );
                      if (outputFile == null) return;
                      final returnedFile = File(outputFile);
                      await returnedFile.writeAsString(lyric);
                    },
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsNavButton({
    required BuildContext context,
    required String text,
    required Widget icon,
    required String bodyName,
    required bool isSelected,
  }) {
    return RibbonButton(
      text: text,
      icon: icon,
      isEnabled: true,
      isSelected: isSelected,
      onPressed: () {
        context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: bodyName));
      },
    );
  }

  Widget _buildQrCodeButton(BuildContext context) {
    return RibbonButton(
      text: 'qrCode'.tr(),
      isEnabled: true,
      icon: const Icon(Icons.qr_code, color: Colors.orange),
      onPressed: () {
        QrCodeDialog.show(context);
      },
    );
  }

  Widget _buildBackupRestoreButton(BuildContext context, DesktopRibbonMenuState state) {
    return RibbonButton(
      text: 'backupAndRestore'.tr(),
      isEnabled: true,
      isSelected: state.bodyName == 'backup_restore',
      icon: const Icon(Icons.backup, color: Colors.brown),
      onPressed: () {
        context.read<DesktopRibbonMenuBloc>().add(const ChangeHomeBody(bodyName: 'backup_restore'));
      },
    );
  }

  void _openPresentationFromPlaylist(BuildContext context) {
    final playlistBloc = context.read<PresentationPlaylistBloc>();
    final presentationBloc = context.read<PresentationBloc>();
    final settingsState = context.read<SettingsBloc>().state;
    final manager = PresentationWindowManager();

    if (playlistBloc.state.isEmpty) return;

    if (playlistBloc.state.currentSong == null) {
      playlistBloc.add(const SelectPresentationSong(index: 0));
    }

    presentationBloc.add(UpdatePresentationSettings(
      linesPerPage: settingsState.presentationLinesPerPage,
      fontSize: settingsState.presentationFontSize,
      textColor: settingsState.presentationFontColor,
      showChords: settingsState.presentationShowChords,
      screenIndex: settingsState.presentationScreenIndex,
    ));

    final currentSong = playlistBloc.state.currentSong ??
        (playlistBloc.state.isNotEmpty ? playlistBloc.state.playlist.songs.first : null);

    if (currentSong == null) return;

    presentationBloc.add(UpdatePresentationSong(song: currentSong));

    final result = PresentationBloc.computePageContent(
      song: currentSong,
      linesPerPage: settingsState.presentationLinesPerPage,
      showChords: settingsState.presentationShowChords,
      page: 0,
    );

    debugPrint('Opening presentation from playlist: ${currentSong.title}, '
        'pageContent length: ${result.pageContent.length}, '
        'totalPages: ${result.totalPages}, '
        'screenIndex: ${settingsState.presentationScreenIndex}');

    manager.openPresentationWindow(
      context,
      title: currentSong.title,
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

  void _showSavePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController(
      text: DateFormat('dd.MM.yyyy').format(DateTime.now()),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('savePresentationPlaylist'.tr()),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'playlistNameLabel'.tr(),
                    hintText: 'enterPlaylistNameHint'.tr(),
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<PresentationPlaylistBloc, PresentationPlaylistState>(
                  builder: (context, state) {
                    return Text(
                      'songCountN'.tr(args: [state.songCount.toString()]),
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  context.read<PresentationPlaylistBloc>().add(
                        SavePresentationPlaylist(name: name),
                      );
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('playlistNameSaved'.tr(args: [name])),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: Text('saveBtn'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showLoadPlaylistDialog(BuildContext context) {
    final playlistsBloc = context.read<PlaylistsBloc>();
    final allSongs = context.read<HomePageBloc>().songsRepository.songs;
    int? expandedIndex;

    List<Song> resolveSongs(List<String> songIds) {
      final songs = <Song>[];
      for (final id in songIds) {
        try {
          final song = allSongs.firstWhere((s) => s.id == id);
          songs.add(song);
        } catch (_) {}
      }
      return songs;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BlocBuilder<PlaylistsBloc, PlaylistsState>(
              builder: (context, playlistsState) {
                final playlists = playlistsState.playlists;

                return AlertDialog(
                  title: Text('loadPlaylist'.tr()),
                  content: SizedBox(
                    width: 500,
                    height: 500,
                    child: playlists.isEmpty
                        ? Center(
                            child: Text(
                              'noSavedPlaylists'.tr(),
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: playlists.length,
                            itemBuilder: (context, index) {
                              final playlist = playlists[index];
                              final isExpanded = expandedIndex == index;
                              final songs = isExpanded ? resolveSongs(playlist.listSongIds) : <Song>[];

                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        expandedIndex = isExpanded ? null : index;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isExpanded ? Colors.blue.withValues(alpha: 0.08) : null,
                                        border: const Border(bottom: BorderSide(color: Colors.black12)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isExpanded ? Icons.expand_less : Icons.expand_more,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.playlist_play, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(playlist.name,
                                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                                Text(
                                                  'nSongs'.tr(args: [playlist.listSongIds.length.toString()]),
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.download, size: 20),
                                            tooltip: 'loadToPresentation'.tr(),
                                            onPressed: () {
                                              context.read<PresentationPlaylistBloc>().add(
                                                    LoadPresentationPlaylist(playlist: playlist),
                                                  );
                                              Navigator.pop(dialogContext);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('playlistNameLoaded'.tr(args: [playlist.name])),
                                                  backgroundColor: Colors.green,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                            tooltip: 'deletePlaylistTooltip'.tr(),
                                            onPressed: () {
                                              playlistsBloc.add(DeletePlaylist(playlist: playlist));
                                              if (isExpanded) {
                                                setDialogState(() {
                                                  expandedIndex = null;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  if (isExpanded)
                                    Container(
                                      constraints: const BoxConstraints(maxHeight: 250),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withValues(alpha: 0.05),
                                        border: const Border(bottom: BorderSide(color: Colors.black12)),
                                      ),
                                      child: songs.isEmpty
                                          ? Padding(
                                              padding: const EdgeInsets.all(12),
                                              child: Text('noSongsInPlaylist'.tr(),
                                                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                            )
                                          : ReorderableListView.builder(
                                              shrinkWrap: true,
                                              itemCount: songs.length,
                                              // newIdx is already adjusted for
                                              // the removal — do not decrement.
                                              onReorderItem: (oldIdx, newIdx) {
                                                final ids = List<String>.from(playlist.listSongIds);
                                                final movedId = ids.removeAt(oldIdx);
                                                ids.insert(newIdx, movedId);
                                                final updatedPlaylist = Playlist(
                                                  id: playlist.id,
                                                  name: playlist.name,
                                                );
                                                updatedPlaylist.listSongIds = ids;
                                                playlistsBloc.add(UpdatePlaylistDirect(playlist: updatedPlaylist));
                                                setDialogState(() {});
                                              },
                                              itemBuilder: (context, songIndex) {
                                                final song = songs[songIndex];
                                                return ListTile(
                                                  key: ValueKey('${playlist.id}_${song.id}_$songIndex'),
                                                  dense: true,
                                                  leading: Text(
                                                    '${songIndex + 1}.',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                  title: Text(song.title, style: const TextStyle(fontSize: 13)),
                                                  subtitle: song.interpret != null && song.interpret!.isNotEmpty
                                                      ? Text(song.interpret!, style: const TextStyle(fontSize: 11, color: Colors.grey))
                                                      : null,
                                                  trailing: IconButton(
                                                    icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                                    tooltip: 'removeFromPlaylist'.tr(),
                                                    onPressed: () {
                                                      final ids = List<String>.from(playlist.listSongIds);
                                                      ids.removeAt(songIndex);
                                                      final updatedPlaylist = Playlist(
                                                        id: playlist.id,
                                                        name: playlist.name,
                                                      );
                                                      updatedPlaylist.listSongIds = ids;
                                                      playlistsBloc.add(UpdatePlaylistDirect(playlist: updatedPlaylist));
                                                      setDialogState(() {});
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text('closeBtn'.tr()),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddSongsDialog(BuildContext context) {
    final homePageBloc = context.read<HomePageBloc>();
    final allSongs = homePageBloc.state.listSong;
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filter = searchController.text.toLowerCase();
            final filteredSongs = filter.isEmpty
                ? allSongs
                : allSongs.where((s) => s.title.toLowerCase().contains(filter) || (s.interpret?.toLowerCase().contains(filter) ?? false)).toList();

            return AlertDialog(
              title: Text('addSongsToPlaylist'.tr()),
              content: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: 'searchHint'.tr(),
                        prefixIcon: const Icon(Icons.search),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          return ListTile(
                            dense: true,
                            title: Text(song.title, style: const TextStyle(fontSize: 13)),
                            subtitle: song.interpret != null && song.interpret!.isNotEmpty
                                ? Text(song.interpret!, style: const TextStyle(fontSize: 11))
                                : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                context.read<PresentationPlaylistBloc>().add(
                                      AddSongToPresentation(song: song),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('songAdded'.tr(args: [song.title])),
                                    duration: const Duration(milliseconds: 800),
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              context.read<PresentationPlaylistBloc>().add(
                                    AddSongToPresentation(song: song),
                                  );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('closeBtn'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Opens the pad window, then switches it between full size and minimized;
/// shows the playing key.
class _PadRibbonButton extends StatelessWidget {
  const _PadRibbonButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PadBloc, PadState>(
      buildWhen: (previous, current) =>
          previous.isWindowOpen != current.isWindowOpen || previous.isMinimized != current.isMinimized || previous.playingKey != current.playingKey,
      builder: (context, state) {
        final playing = state.playingKey;
        final isOpen = state.isWindowOpen && !state.isMinimized;
        return RibbonButton(
          text: playing == null ? 'pads'.tr() : '${'pads'.tr()} · ${SongKeyService.keyNames[playing]}',
          icon: Icon(Icons.graphic_eq, size: 16, color: isOpen ? AppColor.whiteColor : (playing != null ? AppColor.alertWarningColor : AppColor.grey1Color)),
          isEnabled: true,
          isSelected: isOpen,
          onPressed: () => context.read<PadBloc>().add(const TogglePadWindow()),
        );
      },
    );
  }
}

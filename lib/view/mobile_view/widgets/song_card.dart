// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/services/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../model/song/song.dart';
import '../../../model/user.dart';
import '../../../services/constants.dart';

class SongCard extends StatefulWidget {
  final Song song;
  final int index;
  final bool isSelectedSong;
  final bool isEditIconVisible;
  final bool isExpanded;

  const SongCard({Key? key, required this.song, required this.index, required this.isSelectedSong, required this.isEditIconVisible, required this.isExpanded}) : super(key: key);

  @override
  State<SongCard> createState() => _SongCardState();
}

class _SongCardState extends State<SongCard> {
  void _openPreview() {
    context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
    Navigator.pushNamed(context, '/previewPage');
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final settingsState = context.read<SettingsBloc>().state;
        TypeClickCard typeClickCard = settingsState.typeClickCard;
        switch (typeClickCard) {
          case TypeClickCard.none:
          case TypeClickCard.preview:
            _openPreview();
            break;
          case TypeClickCard.presentation:
            context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
            Navigator.pushNamed(context, '/presentationPage');
            break;
          case TypeClickCard.sheet:
            context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
            Navigator.pushNamed(context, '/sheetViewPage');
            break;
          case TypeClickCard.youtube:
            context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
            Navigator.pushNamed(context, '/youtubeVideoPage');
            break;
        }
      },
      child: Container(
          decoration: BoxDecoration(
            color: widget.isSelectedSong ? AppColor.defaultBackgroundColor : Colors.white,
            border: Border.all(color: AppColor.primaryColor),
            borderRadius: BorderRadius.circular(4),
          ),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.only(top: 8),
          width: MediaQuery.of(context).size.width,
          child: Padding(
            padding: const EdgeInsets.only(left: 12.0, right: 4.0, bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.song.title,
                        style: h5TextStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Text(
                            widget.song.indexSongBook != null ? '(${widget.song.indexSongBook})' : '',
                            style: labelTextStyle.copyWith(color: AppColor.primaryColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(
                            width: widget.song.indexSongBook != null ? 10 : 0,
                          ),
                          Expanded(
                            child: Text(
                              widget.song.interpret ?? '',
                              style: labelTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Select button
                IconButton(
                    icon: Icon(
                      MdiIcons.radioboxMarked,
                      color: widget.isSelectedSong ? Colors.green : AppColor.grey3Color,
                      size: 20,
                    ),
                    onPressed: () {
                      context.read<HomePageBloc>().add(SelectSong(
                          selectedSongId: widget.song.id,
                          title: widget.song.title,
                          interpret: widget.song.interpret ?? '',
                          lyricsWithoutChords: widget.song.lyricsWithoutChords,
                          lyricsWithChords: widget.song.lyrics));
                    }),
                // 3-dot menu
                BlocBuilder<UsersBloc, UsersState>(
                  builder: (context, userState) {
                    final isAdmin = userState.currentUser?.typeUser == TypeUser.admin || userState.currentUser?.typeUser == TypeUser.superuser;
                    return PopupMenuButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColor.grey3Color,
                      ),
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            value: 'preview',
                            child: Row(
                              children: [
                                Icon(MdiIcons.bookMusicOutline, color: AppColor.primaryDarkColor),
                                const SizedBox(width: 12),
                                Text('preview'.tr()),
                              ],
                            ),
                            onTap: () => _openPreview(),
                          ),
                          PopupMenuItem(
                            value: 'presentation',
                            child: Row(
                              children: [
                                Icon(MdiIcons.presentation, color: AppColor.primaryDarkestColor),
                                const SizedBox(width: 12),
                                Text('presentation'.tr()),
                              ],
                            ),
                            onTap: () {
                              context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
                              Navigator.pushNamed(context, '/presentationPage');
                            },
                          ),
                          if (widget.song.sheets != null && widget.song.sheets!.isNotEmpty)
                            PopupMenuItem(
                              value: 'sheet',
                              child: Row(
                                children: [
                                  Icon(MdiIcons.imageFrame, color: AppColor.primaryColor),
                                  const SizedBox(width: 12),
                                  Text('sheet'.tr()),
                                ],
                              ),
                              onTap: () {
                                context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
                                Navigator.pushNamed(context, '/sheetViewPage');
                              },
                            ),
                          if (widget.song.youtubeVideos != null && widget.song.youtubeVideos!.isNotEmpty)
                            PopupMenuItem(
                              value: 'youtube',
                              child: Row(
                                children: [
                                  Icon(MdiIcons.videoOutline, color: AppColor.primaryLightColor),
                                  const SizedBox(width: 12),
                                  Text('youtube'.tr()),
                                ],
                              ),
                              onTap: () {
                                context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
                                Navigator.pushNamed(context, '/youtubeVideoPage');
                              },
                            ),
                          if (isAdmin)
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(MdiIcons.pencil, color: AppColor.primaryLightestColor),
                                  const SizedBox(width: 12),
                                  Text('edit'.tr()),
                                ],
                              ),
                              onTap: () {
                                context.read<EditSongBloc>().add(ChangeEditSong(song: widget.song.copyWith(), isOriginalLyrics: false));
                                Navigator.pushNamed(context, '/editPage');
                              },
                            ),
                        ];
                      },
                    );
                  },
                ),
              ],
            ),
          )),
    );
  }
}

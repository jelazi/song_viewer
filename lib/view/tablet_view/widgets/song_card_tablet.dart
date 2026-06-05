// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/services/enums.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/question_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../../../model/song/song.dart';
import '../../../services/constants.dart';

class SongCardTablet extends StatefulWidget {
  final Song song;
  final int index;
  final bool isSelectedSong;

  final bool isEditIconVisible;
  final bool superuserMode;

  const SongCardTablet({
    Key? key,
    required this.song,
    required this.index,
    required this.isEditIconVisible,
    required this.superuserMode,
    required this.isSelectedSong,
  }) : super(key: key);

  @override
  State<SongCardTablet> createState() => _SongCardTabletState();
}

class _SongCardTabletState extends State<SongCardTablet> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final settingsState = context.read<SettingsBloc>().state;
        TypeClickCard typeClickCard = settingsState.typeClickCard;
        switch (typeClickCard) {
          case TypeClickCard.none:
            context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
            Navigator.pushNamed(context, '/previewPage');
            break;
          case TypeClickCard.preview:
            context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
            Navigator.pushNamed(context, '/previewPage');
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
      child: SizedBox(
        height: 60,
        child: Card(
            color: AppColor.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
              side: BorderSide(
                color: widget.isSelectedSong ? AppColor.primaryColor : AppColor.grey3Color,
                width: widget.isSelectedSong ? 2.0 : 1.0,
              ),
            ),
            surfaceTintColor: AppColor.primaryColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.song.title,
                            style: h5TextStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Visibility(
                          visible: widget.song.indexSongBook != null,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              widget.song.indexSongBook != null ? '(${widget.song.indexSongBook})' : '',
                              style: labelTextStyle.copyWith(color: AppColor.primaryColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        Visibility(
                          visible: widget.song.interpret != null,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Text(
                              widget.song.interpret ?? '',
                              style: labelTextStyle,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                    icon: Icon(
                      MdiIcons.radioboxMarked,
                      color: widget.isSelectedSong ? AppColor.primaryColor : AppColor.grey3Color,
                    ),
                    onPressed: () {
                      context.read<HomePageBloc>().add(SelectSong(
                          selectedSongId: widget.song.id,
                          title: widget.song.title,
                          interpret: widget.song.interpret ?? '',
                          lyricsWithoutChords: widget.song.lyricsWithoutChords,
                          lyricsWithChords: widget.song.lyrics));
                    }),
                Visibility(
                  visible: widget.isEditIconVisible,
                  child: PopupMenuButton(
                      icon: const Icon(
                        Icons.more_vert,
                        color: AppColor.grey3Color,
                      ),
                      itemBuilder: (context) {
                        return [
                          PopupMenuItem(
                            value: 'preview',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  MdiIcons.bookMusicOutline,
                                  color: AppColor.grey1Color,
                                ),
                                Text('preview'.tr()),
                              ],
                            ),
                            onTap: () {
                              context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
                              Navigator.pushNamed(context, '/previewPage');
                            },
                          ),
                          PopupMenuItem(
                            value: 'presentation',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Icon(
                                  MdiIcons.presentation,
                                  color: AppColor.grey1Color,
                                ),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    MdiIcons.imageFrame,
                                    color: AppColor.grey1Color,
                                  ),
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
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Icon(
                                    MdiIcons.videoOutline,
                                    color: AppColor.grey1Color,
                                  ),
                                  Text('youtube'.tr()),
                                ],
                              ),
                              onTap: () {
                                context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: widget.song));
                                Navigator.pushNamed(context, '/youtubeVideoPage');
                              },
                            ),
                          if (widget.isEditIconVisible && widget.superuserMode)
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Icon(
                                    Icons.edit,
                                    color: AppColor.grey1Color,
                                  ),
                                  Text('edit'.tr()),
                                ],
                              ),
                              onTap: () {
                                context.read<EditSongBloc>().add(ChangeEditSong(song: widget.song.copyWith(), isOriginalLyrics: false));
                                Navigator.pushNamed(context, '/editPage');
                              },
                            ),
                          if (widget.isEditIconVisible && widget.superuserMode)
                            PopupMenuItem(
                              value: 'delete',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Icon(
                                  Icons.delete,
                                  color: AppColor.grey1Color,
                                ),
                                Text('delete'.tr()),
                              ],
                            ),
                            onTap: () {
                              showDialog(
                                  context: context,
                                  builder: (context) => QuestionDialog(
                                        title: 'deleteSong'.tr(),
                                        okClick: () {
                                          context.read<HomePageBloc>().add(DeleteSong(song: widget.song));
                                        },
                                        question: '${'deleteSongQuestion'.tr()} ${widget.song.title}?',
                                      ));
                            },
                          ),
                        ];
                      }),
                ),
              ],
            )),
      ),
    );
  }
}

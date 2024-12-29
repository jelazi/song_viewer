import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/view/mobile_view/widgets/chords_lyric/flutter_chord.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:split_view/split_view.dart';

import '../../../../services/constants.dart';

class EditLyricPageMobile extends StatefulWidget {
  final bool isOriginalLyrics;

  const EditLyricPageMobile({super.key, required this.isOriginalLyrics});

  @override
  State<EditLyricPageMobile> createState() => _EditLyricPageMobileState();
}

class _EditLyricPageMobileState extends State<EditLyricPageMobile> {
  final TextEditingController editingController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditSongBloc, EditSongState>(
      builder: (context, state) {
        editingController.text = widget.isOriginalLyrics ? state.currentEditSong.originalLyrics ?? '' : state.currentEditSong.lyrics;
        return Scaffold(
          appBar: AppBar(
            title: Text(widget.isOriginalLyrics ? 'editOriginalLyricsLabel'.tr() : 'editLyricsLabel'.tr()),
          ),
          body: SplitView(
            viewMode: SplitViewMode.Vertical,
            indicator: Container(
              decoration: BoxDecoration(
                  border: const Border.symmetric(
                    horizontal: BorderSide(color: AppColor.primaryColor),
                  ),
                  color: AppColor.primaryLightestColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: const Offset(0, 3),
                    ),
                  ]),
            ),
            children: [
              SingleChildScrollView(
                  child: Container(
                padding: const EdgeInsets.only(left: 8),
                color: AppColor.defaultBackgroundColor,
                child: TextFormField(
                  initialValue: editingController.text,
                  style: state.textStyle,
                  maxLines: 200,
                  onChanged: (value) {
                    context.read<EditSongBloc>().add(ChangeSongValue(value: value, nameValue: widget.isOriginalLyrics ? 'originalLyrics' : 'lyrics', appVersion: 'mobile'));
                  },
                ),
              )),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: LyricsRenderer(
                  lyrics: widget.isOriginalLyrics ? state.currentEditSong.originalLyrics ?? '' : state.currentEditSong.lyrics,
                  textStyle: state.textStyle,
                  chordStyle: state.chordStyle,
                  onTapChord: () {},
                  isVisibleNote: true,
                  scrollController: scrollController,
                  baseFontSize: state.textStyle.fontSize ?? 20,
                  appBarStatus: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'package:song_viewer/blocs/export_blocs.dart';
import 'package:song_viewer/view/mobile_view/widgets/chords_lyric/flutter_chord.dart';
import 'package:song_viewer/view/mobile_view/widgets/dialogs/question_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:split_view/split_view.dart';

import '../../../../services/constants.dart';

class EditLyricPageTablet extends StatefulWidget {
  final bool isOriginalLyrics;

  const EditLyricPageTablet({
    super.key,
    required this.isOriginalLyrics,
  });

  @override
  State<EditLyricPageTablet> createState() => _EditLyricPageTabletState();
}

class _EditLyricPageTabletState extends State<EditLyricPageTablet> {
  final TextEditingController editingController = TextEditingController();

  final ScrollController scrollController = ScrollController();
  String currentText = '';

  @override
  void initState() {
    super.initState();
    currentText = editingController.text = context.read<EditSongBloc>().state.currentText;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditSongBloc, EditSongState>(
      builder: (context, state) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (pop, result) async {
            if (state.currentText == currentText) {
              Navigator.pushNamed(context, '/editPage');
            } else {
              showDialog(
                  context: context,
                  builder: (context) {
                    return QuestionDialog(
                      title: 'saveEditText'.tr(),
                      okClick: () {
                        context
                            .read<EditSongBloc>()
                            .add(ChangeSongValue(appVersion: 'tablet', nameValue: widget.isOriginalLyrics ? 'originalLyrics' : 'lyrics', value: currentText));
                        Navigator.pushNamed(context, '/editPage');
                      },
                      question: 'saveEditTextQuestion'.tr(),
                      cancelClick: () => Navigator.pushNamed(context, '/editPage'),
                    );
                  });
            }
          },
          child: Scaffold(
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
                        color: Colors.grey.withValues(alpha: 0.5),
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
                      setState(() {
                        currentText = value;
                      });
                    },
                  ),
                )),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: LyricsRenderer(
                    lyrics: currentText,
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
          ),
        );
      },
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../../blocs/export_blocs.dart';
import '../../../../../../services/constants.dart';

class EditLyricsBody extends StatefulWidget {
  const EditLyricsBody({super.key});

  @override
  State<EditLyricsBody> createState() => _EditLyricsBodyState();
}

class _EditLyricsBodyState extends State<EditLyricsBody> {
  final TextEditingController editingController = TextEditingController();
  TextSelection? previousSelection;

  @override
  void initState() {
    super.initState();
    editingController.text = context.read<EditSongBloc>().state.currentText;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EditSongBloc, EditSongState>(
      listener: (context, state) {},
      builder: (context, state) {
        editingController.text = context.read<EditSongBloc>().state.currentText;
        if (previousSelection != null && editingController.text.length >= previousSelection!.baseOffset) {
          editingController.selection = previousSelection!;
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
                width: MediaQuery.of(context).size.width - 300,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(state.currentEditSong.title, style: const TextStyle(fontSize: 15)),
                    SizedBox(
                      width: 320,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () {
                                  previousSelection = null;
                                  context.read<EditSongBloc>().add(ChangeEditSong(song: state.currentEditSong, isOriginalLyrics: !state.isOriginalLyrics));
                                },
                                child: Container(
                                    height: 30,
                                    width: 150,
                                    margin: const EdgeInsets.only(left: 5, right: 5),
                                    decoration: BoxDecoration(
                                      color: AppColor.defaultBackgroundColor,
                                      border: Border.all(color: AppColor.grey1Color),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(child: Text(state.isOriginalLyrics ? 'changeToTranslate'.tr() : 'changeToOriginal'.tr())))),
                          ),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                                onTap: () {
                                  previousSelection = null;
                                  context.read<EditSongBloc>().add(const SaveSong(typeApp: 'desktop'));
                                },
                                child: Container(
                                    height: 30,
                                    width: 150,
                                    margin: const EdgeInsets.only(left: 5, right: 5),
                                    decoration: BoxDecoration(
                                      color: state.isOriginalLyrics
                                          ? state.currentText == state.currentEditSong.originalLyrics
                                              ? AppColor.defaultBackgroundColor
                                              : AppColor.primaryColor
                                          : state.currentText == state.currentEditSong.lyrics
                                              ? AppColor.defaultBackgroundColor
                                              : AppColor.primaryColor,
                                      border: Border.all(color: AppColor.grey1Color),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Center(child: Text('save'.tr())))),
                          )
                        ],
                      ),
                    )
                  ],
                )),
            Expanded(
              child: SingleChildScrollView(
                  child: Container(
                padding: const EdgeInsets.only(left: 8),
                color: AppColor.defaultBackgroundColor,
                width: MediaQuery.of(context).size.width - 300,
                child: TextFormField(
                  controller: editingController,
                  style: TextStyle(fontSize: 13, color: state.textStyle.color),
                  maxLines: 200,
                  onChanged: (value) {
                    previousSelection = editingController.selection;
                    context.read<EditSongBloc>().add(ChangeSongValue(nameValue: 'lyrics', value: editingController.text, appVersion: 'desktop'));
                  },
                ),
              )),
            ),
          ],
        );
      },
    );
  }
}

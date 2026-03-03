import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../blocs/export_blocs.dart';
import '../../../../../../services/constants.dart';

class EditSettingsBody extends StatefulWidget {
  const EditSettingsBody({super.key});

  @override
  State<EditSettingsBody> createState() => _EditSettingsBodyState();
}

class _EditSettingsBodyState extends State<EditSettingsBody> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditSongBloc, EditSongState>(
      builder: (context, state) {
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                  height: 40,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 320,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                  onTap: () {
                                    context.read<EditSongBloc>().add(const SaveSong(typeApp: 'desktop'));
                                  },
                                  child: Container(
                                      height: 30,
                                      width: 30,
                                      margin: const EdgeInsets.only(left: 5, right: 5),
                                      decoration: BoxDecoration(
                                        color: state.isCurrentSongModified ? AppColor.primaryColor : AppColor.defaultBackgroundColor,
                                        border: Border.all(color: AppColor.grey1Color),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Center(child: Icon(Icons.save, size: 16, color: state.isCurrentSongModified ? Colors.white : Colors.black)))),
                            )
                          ],
                        ),
                      )
                    ],
                  )),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('title'.tr(), style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 30,
                    width: 300,
                    child: TextField(
                      controller: state.titleController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        context.read<EditSongBloc>().add(ChangeSongValue(nameValue: 'title', value: value, selection: state.titleController.selection, appVersion: 'desktop'));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('interpret'.tr(), style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 30,
                    width: 300,
                    child: TextField(
                      controller: state.interpretController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        context
                            .read<EditSongBloc>()
                            .add(ChangeSongValue(nameValue: 'interpret', value: value, selection: state.interpretController.selection, appVersion: 'desktop'));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text('indexSongBook'.tr(), style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 30,
                    width: 300,
                    child: TextField(
                      //only number insert
                      keyboardType: TextInputType.number,
                      inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                      controller: state.indexSongBookController,
                      style: const TextStyle(fontSize: 12),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        context
                            .read<EditSongBloc>()
                            .add(ChangeSongValue(nameValue: 'indexSongBook', value: value, selection: state.indexSongBookController.selection, appVersion: 'desktop'));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 500,
                width: 500,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('groups'.tr(), style: const TextStyle(fontSize: 15)),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 400,
                      height: 500,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            ...(state.listAllGroups).map((group) => MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      context.read<EditSongBloc>().add(ChangeGroupForCurrentSong(group: group));
                                    },
                                    child: Container(
                                      width: 100,
                                      margin: const EdgeInsets.only(right: 5),
                                      padding: const EdgeInsets.all(5),
                                      decoration: BoxDecoration(
                                        color: state.currentGroups.contains(group) ? AppColor.defaultBackgroundColor : Colors.white,
                                        border: Border.all(color: AppColor.grey1Color),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                      child: SingleChildScrollView(
                                        child: Row(
                                          children: [
                                            Text(group, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

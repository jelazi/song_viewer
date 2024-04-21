import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/services/constants.dart';
import 'package:default_project/services/enums.dart';
import 'package:default_project/view/desktop_view/widgets/my_dropdown_field.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/dialogs_export.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../model/song/song.dart';
import '../../../model/user.dart';

class HomeDrawer extends StatefulWidget {
  const HomeDrawer({
    super.key,
  });

  @override
  State<HomeDrawer> createState() => _HomeDrawerState();
}

class _HomeDrawerState extends State<HomeDrawer> {
  final List<String> items = [
    TypeClickCard.none.name,
    TypeClickCard.preview.name,
    TypeClickCard.presentation.name,
    TypeClickCard.sheet.name,
    TypeClickCard.youtube.name,
  ];
  String selectedItem = TypeClickCard.none.name;

  @override
  Widget build(BuildContext context) {
    selectedItem = context.read<HomePageBloc>().settingsRepository.typeClickCard.name;
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Drawer(
        width: MediaQuery.of(context).size.width * 0.7,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColor.primaryColor,
              ),
              child: Column(
                children: [
                  Text(
                    'songsViewer'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                  Text('${'version'.tr()} ${context.read<HomePageBloc>().settingsRepository.version}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      )),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('${context.read<HomePageBloc>().songsRepository.songs.length} ${'songs'.tr()}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        )),
                  )
                ],
              ),
            ),
            BlocBuilder<UsersBloc, UsersState>(
              builder: (context, state) {
                return Visibility(
                  visible: state.currentUser?.typeUser == TypeUser.admin || state.currentUser?.typeUser == TypeUser.superuser,
                  child: ListTile(
                    title: Row(children: [
                      const Icon(Icons.add),
                      const SizedBox(
                        width: 10,
                      ),
                      Text('addNewSong'.tr()),
                    ]),
                    onTap: () {
                      Navigator.pop(context);
                      context.read<EditSongBloc>().add(ChangeEditSong(song: Song.empty(), isOriginalLyrics: false));
                      Navigator.pushNamed(context, '/editPage');
                    },
                  ),
                );
              },
            ),
            ListTile(
              title: Row(children: [
                const Icon(Icons.settings),
                const SizedBox(
                  width: 10,
                ),
                Text('settings'.tr()),
              ]),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/settingsPage');
              },
            ),
            ListTile(
              title: Row(children: [
                const Icon(Icons.ads_click),
                const SizedBox(
                  width: 10,
                ),
                Text('typeClickCard'.tr()),
              ]),
              onTap: () {
                Navigator.of(context).pop();
                List<String> items = [
                  TypeClickCard.none.name,
                  TypeClickCard.preview.name,
                  TypeClickCard.presentation.name,
                  TypeClickCard.sheet.name,
                  TypeClickCard.youtube.name,
                ];
                String selectedItem = context.read<HomePageBloc>().settingsRepository.typeClickCard.name;
                showDialog(
                    barrierDismissible: false,
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(builder: (context, setState) {
                        return EditDialog(
                            title: 'typeClickCard'.tr(),
                            okClick: () {
                              context.read<HomePageBloc>().settingsRepository.changeTypeClickCard(TypeClickCard.values[items.indexOf(selectedItem)]);
                            },
                            widgetContent: MyDropDownField(
                              items: items,
                              selectedItem: selectedItem,
                              listener: (value) {
                                setState(() {
                                  selectedItem = value;
                                });
                              },
                            ));
                      });
                    });
              },
            ),
            // list tile select group
            BlocBuilder<HomePageBloc, HomePageState>(
              builder: (context, state) {
                List<String> selectedGroups = List.from(state.listSelectedGroups);
                return ListTile(
                  textColor: state.listAllGroups.length != selectedGroups.length ? AppColor.alertErrorColor : AppColor.grey1Color,
                  iconColor: state.listAllGroups.length != selectedGroups.length ? AppColor.alertErrorColor : AppColor.grey1Color,
                  title: Row(children: [
                    const Icon(Icons.group),
                    const SizedBox(
                      width: 10,
                    ),
                    Text('selectGroups'.tr()),
                  ]),
                  onTap: () {
                    Navigator.of(context).pop();

                    showDialog(
                      barrierDismissible: false,
                      context: context,
                      builder: (context) {
                        return StatefulBuilder(builder: (context, setState) {
                          return EditDialog(
                              height: 500,
                              title: 'selectGroups'.tr(),
                              okClick: () {
                                context.read<HomePageBloc>().add(SelectGroups(groups: selectedGroups));
                              },
                              widgetContent: SizedBox(
                                height: 350,
                                child: Wrap(
                                  children: state.listAllGroups
                                      .map((e) => ChoiceChip(
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
                                          selected: selectedGroups.contains(e)))
                                      .toList(),
                                ),
                              ));
                        });
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

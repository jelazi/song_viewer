import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/services/constants.dart';
import 'package:default_project/services/enums.dart';
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
            ExpansionTile(
                title: Text('typeClickCard'.tr()),
                children: items.map((String item) {
                  return ListTile(
                    selected: selectedItem == item,
                    selectedColor: Colors.blue,
                    title: Text(item),
                    onTap: () {
                      setState(() {
                        context.read<HomePageBloc>().settingsRepository.changeTypeClickCard(TypeClickCard.values[items.indexOf(item)]);
                        selectedItem = item;
                      });
                    },
                  );
                }).toList())
          ],
        ),
      ),
    );
  }
}

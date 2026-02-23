import 'package:default_project/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_chords_body.dart';
import 'package:default_project/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_lyrics_body.dart';
import 'package:default_project/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_settings_body.dart';
import 'package:default_project/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_sheets_body.dart';
import 'package:default_project/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_youtube_body.dart';
import 'package:flutter/material.dart';

import '../../../../../../blocs/export_blocs.dart';
import '../list_song.dart';

class EditBody extends StatefulWidget {
  const EditBody({super.key});

  @override
  State<EditBody> createState() => _EditBodyState();
}

class _EditBodyState extends State<EditBody> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePageBloc, HomePageState>(
      builder: (context, state) {
        return Row(
          children: [
            const ListSong(),
            BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
              builder: (context, state) {
                switch (state.bodyEditName) {
                  case 'lyrics':
                    return const EditLyricsBody();
                  case 'chords':
                    return const EditChordsBody();
                  case 'settings':
                    return const EditSettingsBody();
                  case 'youtube':
                    return const EditYoutubeBody();
                  case 'sheets':
                    return const EditSheetsBody();
                  default:
                    return Container();
                }
              },
            )
          ],
        );
      },
    );
  }
}

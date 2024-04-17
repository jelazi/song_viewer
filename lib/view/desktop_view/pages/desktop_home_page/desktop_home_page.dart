import 'package:default_project/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_body.dart';
import 'package:default_project/view/desktop_view/widgets/ribbon_menu.dart';
import 'package:flutter/material.dart';

import '../../../../blocs/export_blocs.dart';
import 'home_bodies/groups_body.dart';
import 'home_bodies/preview_body.dart';
import 'home_bodies/web_body.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
        builder: (context, state) {
          Widget homeBody = Container();
          switch (state.bodyName) {
            case 'preview':
              homeBody = const PreviewBody();
              break;
            case 'edit':
              homeBody = const EditBody();
              break;
            case 'web':
              homeBody = const WebBody();
              break;
            case 'groups':
              homeBody = const GroupsBody();
              break;
            default:
              return const PreviewBody();
          }
          return Column(
            children: [
              const RibbonMenu(),
              Expanded(child: homeBody),
            ],
          );
        },
      ),
    );
  }
}

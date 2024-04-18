import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/view/mobile_view/pages/home_page.dart';
import 'package:default_project/view/mobile_view/pages/login_page.dart';
import 'package:default_project/view/responsive_view/pages/page_responsive.dart';
import 'package:default_project/view/tablet_view/pages/home_page_tablet.dart';
import 'package:default_project/view/tablet_view/pages/login_page_tablet.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';
import '../../desktop_view/pages/desktop_home_page/desktop_home_page.dart';

class StateLogin extends StatelessWidget {
  SettingsRepository settingsRepository;
  StateLogin({super.key, required this.settingsRepository});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        return LayoutBuilder(builder: (context, constraints) {
          if (state.currentUser == null) {
            return PageResponsive(pageMobile: LoginPageMobile(), pageTablet: LoginPageTablet(), pageDesktop: const DesktopHomePage());
          } else {
            return PageResponsive(
                pageMobile: HomePageMobile(
                  settingsRepository: settingsRepository,
                ),
                pageTablet: HomePageTablet(
                  settingsRepository: settingsRepository,
                ),
                pageDesktop: const DesktopHomePage());
          }
        });
      },
    );
  }
}

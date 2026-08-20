import 'package:default_project/config/features.dart';
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
  final SettingsRepository settingsRepository;
  const StateLogin({super.key, required this.settingsRepository});

  @override
  Widget build(BuildContext context) {
    // Account login belongs to a build wired to a shared server. A local-first
    // build never authenticates, so `currentUser` would stay null forever and
    // this screen would park the user on a login form for a server that does
    // not exist. Because the condition is a compile-time constant, the branch
    // below is provably dead in a store build and the login pages are stripped
    // from the artifact with it — see plans/store-release-plan.md §10.
    if (!Features.sharedServer) return _buildHome(context);

    return BlocBuilder<UsersBloc, UsersState>(
      builder: (context, state) {
        return LayoutBuilder(builder: (context, constraints) {
          if (state.currentUser == null) {
            return PageResponsive(pageMobile: LoginPageMobile(), pageTablet: LoginPageTablet(), pageDesktop: const DesktopHomePage());
          } else {
            return _buildHome(context);
          }
        });
      },
    );
  }

  Widget _buildHome(BuildContext context) {
    return PageResponsive(
        pageMobile: HomePageMobile(
          settingsRepository: settingsRepository,
        ),
        pageTablet: HomePageTablet(
          settingsRepository: settingsRepository,
        ),
        pageDesktop: const DesktopHomePage());
  }
}

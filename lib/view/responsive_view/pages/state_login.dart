import 'package:song_viewer/config/features.dart';
import 'package:song_viewer/repositories/settings_repository.dart';
import 'package:song_viewer/view/mobile_view/pages/home_page.dart';
import 'package:song_viewer/view/mobile_view/pages/login_page.dart';
import 'package:song_viewer/view/responsive_view/pages/page_responsive.dart';
import 'package:song_viewer/view/tablet_view/pages/home_page_tablet.dart';
import 'package:song_viewer/view/tablet_view/pages/login_page_tablet.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';
import '../../desktop_view/pages/desktop_home_page/desktop_home_page.dart';

class StateLogin extends StatelessWidget {
  final SettingsRepository settingsRepository;
  const StateLogin({super.key, required this.settingsRepository});

  @override
  Widget build(BuildContext context) {
    // Must stay a compile-time constant: this is what keeps the login pages
    // out of a store artifact. A runtime check would ship them (§10).
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

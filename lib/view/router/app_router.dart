import 'package:default_project/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart';
import 'package:default_project/view/responsive_view/pages/page_responsive.dart';
import 'package:default_project/view/responsive_view/pages/state_login.dart';
import 'package:default_project/view/tablet_view/pages/presentation_page_tablet.dart';
import 'package:default_project/view/tablet_view/pages/preview_page_tablet.dart';
import 'package:default_project/view/tablet_view/pages/settings_page_tablet.dart';
import 'package:default_project/view/tablet_view/pages/sheet_view_page_tablet.dart';
import 'package:default_project/view/tablet_view/pages/tablet_edit_pages/edit_chords_tablet.dart';
import 'package:default_project/view/tablet_view/pages/tablet_edit_pages/edit_lyrics_tablet.dart';
import 'package:default_project/view/tablet_view/pages/tablet_edit_pages/edit_page_tablet.dart';
import 'package:default_project/view/tablet_view/pages/youtube_video_page_tablet.dart';
import 'package:flutter/material.dart';

import '../../blocs/export_blocs.dart';
import '../../repositories/settings_repository.dart';
import '../mobile_view/pages/edit_pages/edit_chords.dart';
import '../mobile_view/pages/edit_pages/edit_lyrics.dart';
import '../mobile_view/pages/edit_pages/edit_page.dart';
import '../mobile_view/pages/home_page.dart';
import '../mobile_view/pages/login_page.dart';
import '../mobile_view/pages/presentation_page.dart';
import '../mobile_view/pages/preview_page.dart';
import '../mobile_view/pages/settings_page.dart';
import '../mobile_view/pages/sheet_view_page.dart';
import '../mobile_view/pages/youtube_video_page.dart';
import '../tablet_view/pages/home_page_tablet.dart';



class AppRouter {
  SettingsRepository settingsRepository;
  AppRouter({
    required this.settingsRepository,
  });
  Route onGenerateRoute(
    RouteSettings routeSettings,
  ) {
    switch (routeSettings.name) {
      case '/':
        return MaterialPageRoute(
          builder: (_) => BlocListener<NotificationBloc, NotificationState>(
            listener: (context, state) {
              if (state.message.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message.last)));
              }
            },
            child: PageResponsive(
                pageDesktop: const DesktopHomePage(),
                pageMobile: HomePageMobile(settingsRepository: settingsRepository),
                pageTablet: HomePageTablet(settingsRepository: settingsRepository)),
          ),
        );
      case '/settingsPage':
        return MaterialPageRoute(builder: (_) => PageResponsive(pageMobile: const SettingsPageMobile(), pageTablet: const SettingsPageTablet(), pageDesktop: Container()));
      case '/editPage':
        return MaterialPageRoute(builder: (_) => PageResponsive(pageMobile: const EditPageMobile(), pageTablet: const EditPageTablet(), pageDesktop: Container()));
      case '/previewPage':
        return MaterialPageRoute(builder: (_) => PageResponsive(pageMobile: const PreviewPageMobile(), pageTablet: const PreviewPageTablet(), pageDesktop: Container()));

      case '/presentationPage':
        return MaterialPageRoute(builder: (_) => PageResponsive(pageMobile: const PresentationPageMobile(), pageTablet: const PresentationPageTablet(), pageDesktop: Container()));
      case '/sheetViewPage':
        return MaterialPageRoute(builder: (_) => PageResponsive(pageMobile: const SheetViewPageMobile(), pageTablet: const SheetViewPageTablet(), pageDesktop: Container()));
      case '/youtubeVideoPage':
        return MaterialPageRoute(builder: (_) => PageResponsive(pageMobile: const YoutubeVideoPageMobile(), pageTablet: const YoutubeVideoPageTablet(), pageDesktop: Container()));
      case '/editLyricPage':
        return MaterialPageRoute(
            builder: (_) => PageResponsive(
                pageMobile: const EditLyricPageMobile(isOriginalLyrics: false), pageTablet: const EditLyricPageTablet(isOriginalLyrics: false), pageDesktop: Container()));
      case '/editOriginalLyricPage':
        return MaterialPageRoute(
            builder: (_) => PageResponsive(
                pageMobile: const EditLyricPageMobile(isOriginalLyrics: true), pageTablet: const EditLyricPageTablet(isOriginalLyrics: true), pageDesktop: Container()));
      case '/editChordsPage':
        return MaterialPageRoute(
            builder: (_) => PageResponsive(
                pageMobile: const EditChordsPageMobile(isOriginalLyrics: false), pageTablet: const EditChordsPageTablet(isOriginalLyrics: false), pageDesktop: Container()));
      case '/editOriginalChordsPage':
        return MaterialPageRoute(
            builder: (_) => PageResponsive(
                pageMobile: const EditChordsPageMobile(isOriginalLyrics: true), pageTablet: const EditChordsPageTablet(isOriginalLyrics: true), pageDesktop: Container()));
      case '/loginPage':
        if (settingsRepository.currentUser.name == '') {
          return MaterialPageRoute(builder: (_) => LoginPageMobile());
        } else {
          return MaterialPageRoute(
            builder: (_) => BlocListener<NotificationBloc, NotificationState>(
              listener: (context, state) {
                if (state.message.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message.last)));
                }
              },
              child: PageResponsive(
                  pageDesktop: const DesktopHomePage(),
                  pageMobile: HomePageMobile(settingsRepository: settingsRepository),
                  pageTablet: HomePageTablet(settingsRepository: settingsRepository)),
            ),
          );
        }
      case '/stateLogin':
        return MaterialPageRoute(builder: (_) => StateLogin(settingsRepository: settingsRepository));
      default:
        return MaterialPageRoute(builder: (_) => Container());
    }
  }
}

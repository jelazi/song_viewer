// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:default_project/model/web_item.dart';
import 'package:default_project/providers/web_provider.dart';
import 'package:default_project/repositories/playlist_repository.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:default_project/repositories/user_repository.dart';
import 'package:default_project/services/constants.dart';
import 'package:default_project/services/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:window_manager/window_manager.dart';

import 'blocs/export_blocs.dart';
import 'firebase_options.dart';
import 'model/user.dart';
import 'model/web_interpret.dart';
import 'model/web_song.dart';
import 'providers/firebase_provider.dart';
import 'providers/hive_provider.dart';
import 'repositories/web_repository.dart';
import 'view/desktop_view/widgets/my_toast.dart';
import 'view/router/app_router.dart';

part 'main.part.dart';

class AppRepositories {
  final SettingsRepository settingsRepository;
  final PlaylistRepository playlistRepository;
  final UsersRepository usersRepository;
  final SongsRepository songsRepository;
  final WebRepository webRepository;
  final HiveProvider hiveProvider;

  AppRepositories({
    required this.settingsRepository,
    required this.playlistRepository,
    required this.usersRepository,
    required this.songsRepository,
    required this.webRepository,
    required this.hiveProvider,
  });
}

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Main started with args: $args');

  // Zjistit, jestli jsme v hlavním okně (ID 0) nebo v sub-okně
  if (args.firstOrNull == 'multi_window') {
    // Toto je sub-okno
    debugPrint('Starting presentation window...');
    runApp(const PresentationApp());
    return;
  }

  // Hlavní okno aplikace
  debugPrint('Starting main window...');
  logger = MyLogger(
    debug: true,
    saveToFile: false,
    level: 2,
    isDebugConsole: true,
  );
  logger.v('Start app');
  await EasyLocalization.ensureInitialized();
  await initHiveFunction();

  // Initialize providers and repositories locally
  final repositories = await initProvidersRepositories();

  if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
    await windowManager.ensureInitialized();
    WindowManager.instance.setMinimumSize(const Size(1024, 800));
    WindowManager.instance.setMaximumSize(const Size(2048, 1600));
    WindowManager.instance.setSize(const Size(1024, 800));
  } else if (Platform.isAndroid || Platform.isIOS) {}

  runApp(EasyLocalization(
    startLocale: const Locale('cs'),
    supportedLocales: const [Locale('cs'), Locale('en')],
    path: 'assets/lang',
    fallbackLocale: const Locale('cs'),
    child: MyApp(repositories: repositories),
  ));
} // Minimální prezentační aplikace BEZ pluginů

class PresentationApp extends StatelessWidget {
  const PresentationApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('PresentationApp building...');
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.music_note, color: Colors.white, size: 100),
              SizedBox(height: 20),
              Text(
                'Prezentační okno',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Čeká na zprávy...',
                style: TextStyle(color: Colors.white70, fontSize: 24),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final AppRepositories repositories;
  late final AppRouter _appRouter;

  MyApp({
    Key? key,
    required this.repositories,
  }) : super(key: key) {
    _appRouter = AppRouter(settingsRepository: repositories.settingsRepository);
  }

  @override
  Widget build(BuildContext context) {
    if ((Platform.isAndroid || Platform.isIOS) && MediaQuery.of(context).size.width < 600) {
      myToastWidth = MediaQuery.of(context).size.width - 40;
    } else if (Platform.isAndroid || Platform.isIOS) {
      myToastWidth = 400;
    } else {
      myToastWidth = 400;
    }
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => NotificationBloc(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => HomePageBloc(
              songsRepository: repositories.songsRepository,
              settingsRepository: repositories.settingsRepository,
              usersRepository: repositories.usersRepository,
            ),
          ),
          BlocProvider(
              create: (context) => PreviewChordBloc(
                    settingsRepository: repositories.settingsRepository,
                    songsRepository: repositories.songsRepository,
                    webRepository: repositories.webRepository,
                    hiveProvider: repositories.hiveProvider,
                  )),
          BlocProvider(
              create: ((context) => SettingsBloc(
                    settingsRepository: repositories.settingsRepository,
                    songsRepository: repositories.songsRepository,
                  ))),
          BlocProvider(
            create: (context) => EditSongBloc(
              songsRepository: repositories.songsRepository,
              settingsRepository: repositories.settingsRepository,
            ),
          ),
          BlocProvider(
            create: (context) => DesktopRibbonMenuBloc(),
          ),
          BlocProvider(
            create: ((context) => WebBloc(webRepository: repositories.webRepository, settingsRepository: repositories.settingsRepository, hiveProvider: repositories.hiveProvider)),
          ),
          BlocProvider(
            create: ((context) => UsersBloc(usersRepository: repositories.usersRepository)),
          ),
          BlocProvider(
            create: ((context) => PlaylistsBloc(
                playlistRepository: repositories.playlistRepository, songsRepository: repositories.songsRepository, settingsRepository: repositories.settingsRepository)),
          ),
          BlocProvider(
            create: (context) => PresentationBloc(),
          ),
        ],
        child: MaterialApp(
          title: 'Songs viewer',
          theme: ThemeData(
            primarySwatch: getMaterialColor(AppColor.primaryColor),
            iconTheme: const IconThemeData(color: AppColor.whiteColor),
          ),
          builder: BotToastInit(),
          navigatorObservers: [BotToastNavigatorObserver()],
          debugShowCheckedModeBanner: false,
          supportedLocales: context.supportedLocales,
          localizationsDelegates: context.localizationDelegates,
          locale: context.locale,
          onGenerateRoute: _appRouter.onGenerateRoute,
          initialRoute: "/",
        ),
      ),
    );
  }
}

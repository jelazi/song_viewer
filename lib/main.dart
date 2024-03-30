// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:default_project/providers/web_provider.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/services/constants.dart';
import 'package:default_project/services/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger_pkg/logger_pkg.dart';

import 'package:path_provider/path_provider.dart' as pathProvider;

import 'package:default_project/repositories/playlist_repository.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:default_project/repositories/user_repository.dart';
import 'package:window_manager/window_manager.dart';

import 'blocs/export_blocs.dart';
import 'firebase_options.dart';
import 'model/user.dart';
import 'providers/firebase_provider.dart';
import 'providers/hive_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import 'repositories/web_repository.dart';
import 'view/router/app_router.dart';

part 'main.part.dart';

void main() async {
  logger = MyLogger(
    debug: true,
    saveToFile: true,
    level: 4,
    isDebugConsole: true,
  );
  logger.v('Start app');
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await initHiveFunction();
  await initProvidersRepositories();
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
    child: MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  final AppRouter _appRouter = AppRouter(settingsRepository: settingsRepository);
  MyApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
              songsRepository: songsRepository,
              settingsRepository: settingsRepository,
              usersRepository: usersRepository,
            ),
          ),
          BlocProvider(
              create: (context) => PreviewChordBloc(
                    settingsRepository: settingsRepository,
                  )),
          BlocProvider(create: ((context) => SettingsBloc(settingsRepository: settingsRepository))),
          BlocProvider(
            create: (context) => EditSongBloc(
              songsRepository: songsRepository,
              settingsRepository: settingsRepository,
            ),
          ),
          BlocProvider(
            create: (context) => LoginBloc(
              usersRepository: usersRepository,
            ),
          ),
          BlocProvider(
            create: (context) => DesktopRibbonMenuBloc(),
          ),
          BlocProvider(
            create: ((context) => WebBloc(webRepository: webRepository)),
          )
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
          initialRoute: "/loginPage",
        ),
      ),
    );
  }
}

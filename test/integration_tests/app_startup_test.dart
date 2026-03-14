import 'dart:io';

import 'package:default_project/main.dart';
// Import adapters
import 'package:default_project/model/user.dart';
import 'package:default_project/model/web_interpret.dart';
import 'package:default_project/model/web_item.dart';
import 'package:default_project/model/web_song.dart';
import 'package:default_project/services/enums.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:path_provider/path_provider.dart' as pathProvider;
import 'package:patrol/patrol.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  patrolTest(
    'Launch full Songs Viewer application',
    ($) async {
      // Initialize logger
      logger = MyLogger(
        debug: true,
        saveToFile: false,
        level: 2,
        isDebugConsole: true,
      );
      logger.v('Start test app');

      // EasyLocalization init
      await EasyLocalization.ensureInitialized();

      // Initialize Hive - same as in main.dart
      Directory directory = await pathProvider.getApplicationDocumentsDirectory();
      Hive.init(directory.path);
      Hive.registerAdapter(TypeUserAdapter());
      Hive.registerAdapter(UserAdapter());
      Hive.registerAdapter(TypeClickCardAdapter());
      Hive.registerAdapter(WebItemAdapter());
      Hive.registerAdapter(WebSongAdapter());
      Hive.registerAdapter(WebInterpretAdapter());

      // Initialize providers and repositories using existing function from main.part.dart
      final result = await initProvidersAndCheckSync();
      final repositories = result.repositories;
      final syncInfo = result.syncInfo;

      // Window manager for desktop
      if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
        await windowManager.ensureInitialized();
        WindowManager.instance.setMinimumSize(const Size(1024, 800));
        WindowManager.instance.setMaximumSize(const Size(2048, 1600));
        WindowManager.instance.setSize(const Size(1024, 800));
      }

      print('🚀 Launching application...');

      // Launch app
      await $.pumpWidget(
        EasyLocalization(
          startLocale: const Locale('cs'),
          supportedLocales: const [Locale('cs'), Locale('en')],
          path: 'assets/lang',
          fallbackLocale: const Locale('cs'),
          child: MyApp(repositories: repositories, syncInfo: syncInfo),
        ),
      );

      print('⏳ Waiting for application to load...');

      // Wait for loading
      await $.pumpAndSettle(timeout: const Duration(seconds: 60));

      print('✅ Application launched successfully!');
      print('📱 Songs Viewer BLoC with Patrol');

      // Verify app is running
      expect(find.byType(MaterialApp), findsOneWidget);

      // Let app run for visual verification
      print('👀 Letting app run for 5 seconds...');
      await Future.delayed(const Duration(seconds: 5));

      print('✅ Test completed - app running correctly!');
    },
  );
}

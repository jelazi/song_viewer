// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
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
import 'package:default_project/services/presentation_window_manager.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
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
import 'model/song/song.dart';
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

  // SPRÁVNÝ ZPŮSOB podle dokumentace: použít WindowController.fromCurrentEngine()
  if (args.isNotEmpty && args.first == 'multi_window') {
    debugPrint('This is a sub-window, getting WindowController from current engine');

    try {
      final windowController = await WindowController.fromCurrentEngine();
      debugPrint('WindowController arguments: ${windowController.arguments}');

      // Sub-okno - spusť presentation app
      debugPrint('Starting presentation window...');
      runApp(const PresentationApp());
      return;
    } catch (e) {
      debugPrint('Error getting WindowController: $e');
      // Fallback - spusť presentation app i bez WindowController
      runApp(const PresentationApp());
      return;
    }
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

class PresentationApp extends StatefulWidget {
  const PresentationApp({super.key});

  @override
  State<PresentationApp> createState() => _PresentationAppState();
}

class _PresentationAppState extends State<PresentationApp> {
  String _displayText = 'Čeká na zprávy...';
  Song? _currentSong;

  @override
  void initState() {
    super.initState();
    _loadInitialSongData();
    _setupMessageHandler();

    // Force window to show after first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        debugPrint('First frame rendered, ensuring window is visible');
        final controller = await WindowController.fromCurrentEngine();
        await controller.show();
        debugPrint('Window show() called after first frame');
      } catch (e) {
        debugPrint('Error showing window after frame: $e');
      }
    });
  }

  void _loadInitialSongData() async {
    try {
      final controller = await WindowController.fromCurrentEngine();
      final arguments = controller.arguments;

      debugPrint('Window arguments type: ${arguments.runtimeType}');
      debugPrint('Window arguments: $arguments');

      if (arguments.isNotEmpty) {
        try {
          final payload = jsonDecode(arguments) as Map<String, dynamic>;
          
          // Check if this is new format with window_position
          if (payload.containsKey('song')) {
            // New format with position data
            final songJson = payload['song'] as Map<String, dynamic>;
            final song = Song.fromJson(songJson);
            debugPrint('Loaded song from arguments: ${song.title}');
            
            // Set window to fullscreen
            try {
              await WindowManager.instance.setFullScreen(true);
              debugPrint('Window set to fullscreen');
            } catch (e) {
              debugPrint('Error setting fullscreen: $e');
            }
            
            if (mounted) {
              setState(() {
                _currentSong = song;
                _displayText = _extractLyrics(song);
              });
            }
          } else {
            // Old format - just song data
            final song = Song.fromJson(payload);
            debugPrint('Loaded song from arguments (old format): ${song.title}');

            if (mounted) {
              setState(() {
                _currentSong = song;
                _displayText = _extractLyrics(song);
              });
            }
          }
        } catch (e) {
          debugPrint('Error parsing song from arguments: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading initial song data: $e');
    }
  }

  void _setupMessageHandler() async {
    try {
      final controller = await WindowController.fromCurrentEngine();
      await controller.setWindowMethodHandler((call) async {
        debugPrint('PresentationApp received method: ${call.method}');

        switch (call.method) {
          case 'update_song':
            try {
              debugPrint('Received arguments type: ${call.arguments.runtimeType}');
              // Convert from Map<Object?, Object?> to Map<String, dynamic>
              final rawMap = call.arguments as Map;
              final songJson = Map<String, dynamic>.from(rawMap);
              debugPrint('Converted to Map<String, dynamic>, parsing Song...');
              final song = Song.fromJson(songJson);
              debugPrint('Song parsed successfully: ${song.title}');
              if (mounted) {
                setState(() {
                  _currentSong = song;
                  _displayText = _extractLyrics(song);
                });
              }
              return 'ok';
            } catch (e, stackTrace) {
              debugPrint('Error processing song data: $e');
              debugPrint('Stack trace: $stackTrace');
              return 'error: $e';
            }
          case 'show_text':
            final text = call.arguments as String;
            if (mounted) {
              setState(() {
                _displayText = text;
              });
            }
            return 'ok';
          default:
            debugPrint('Unknown method: ${call.method}');
            return null;
        }
      });
      debugPrint('Message handler setup complete and ready to receive messages');
    } catch (e) {
      debugPrint('Error setting up message handler: $e');
    }
  }

  String _extractLyrics(Song song) {
    // Remove chords in brackets [C], [Am], etc.
    final lines = song.lyrics.split('\n');
    final lyricsWithoutChords = StringBuffer();

    for (final line in lines) {
      String cleanLine = line.replaceAll(RegExp(r'\[.*?\]'), '');
      if (cleanLine.trim().isNotEmpty) {
        lyricsWithoutChords.writeln(cleanLine);
      }
    }

    return lyricsWithoutChords.toString().trim();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('PresentationApp building...');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_note, color: Colors.white, size: 100),
                const SizedBox(height: 40),
                Text(
                  _currentSong?.title ?? 'Prezentační okno',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  _displayText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final AppRepositories repositories;

  const MyApp({
    Key? key,
    required this.repositories,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(settingsRepository: widget.repositories.settingsRepository);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    debugPrint('Main window closing, closing all child windows...');

    // Close presentation window using manager
    try {
      await PresentationWindowManager().closePresentationWindow();
    } catch (e) {
      debugPrint('Error closing presentation window: $e');
    }

    // Now destroy the main window
    await windowManager.destroy();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).size.width < 600) {
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
              songsRepository: widget.repositories.songsRepository,
              settingsRepository: widget.repositories.settingsRepository,
              usersRepository: widget.repositories.usersRepository,
            ),
          ),
          BlocProvider(
              create: (context) => PreviewChordBloc(
                    settingsRepository: widget.repositories.settingsRepository,
                    songsRepository: widget.repositories.songsRepository,
                    webRepository: widget.repositories.webRepository,
                    hiveProvider: widget.repositories.hiveProvider,
                  )),
          BlocProvider(
              create: ((context) => SettingsBloc(
                    settingsRepository: widget.repositories.settingsRepository,
                    songsRepository: widget.repositories.songsRepository,
                  ))),
          BlocProvider(
            create: (context) => EditSongBloc(
              songsRepository: widget.repositories.songsRepository,
              settingsRepository: widget.repositories.settingsRepository,
            ),
          ),
          BlocProvider(
            create: (context) => DesktopRibbonMenuBloc(),
          ),
          BlocProvider(
            create: ((context) => WebBloc(
                webRepository: widget.repositories.webRepository, settingsRepository: widget.repositories.settingsRepository, hiveProvider: widget.repositories.hiveProvider)),
          ),
          BlocProvider(
            create: ((context) => UsersBloc(usersRepository: widget.repositories.usersRepository)),
          ),
          BlocProvider(
            create: ((context) => PlaylistsBloc(
                playlistRepository: widget.repositories.playlistRepository,
                songsRepository: widget.repositories.songsRepository,
                settingsRepository: widget.repositories.settingsRepository)),
          ),
          BlocProvider(
            create: (context) => PresentationBloc(),
          ),
          BlocProvider(
            create: (context) => PresentationPlaylistBloc(),
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

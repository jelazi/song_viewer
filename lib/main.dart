// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:default_project/model/update_songlist_data.dart';
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
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger_pkg/logger_pkg.dart';
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

  // CORRECT WAY according to documentation: use WindowController.fromCurrentEngine()
  if (args.isNotEmpty && args.first == 'multi_window') {
    debugPrint('This is a sub-window, getting WindowController from current engine');

    try {
      final windowController = await WindowController.fromCurrentEngine();
      debugPrint('WindowController arguments: ${windowController.arguments}');

      // Sub-window - start presentation app
      debugPrint('Starting presentation window...');
      runApp(const PresentationApp());
      return;
    } catch (e) {
      debugPrint('Error getting WindowController: $e');
      // Fallback - start presentation app even without WindowController
      runApp(const PresentationApp());
      return;
    }
  }

  // Main application window
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
} // Minimal presentation app WITHOUT plugins

class PresentationApp extends StatefulWidget {
  const PresentationApp({super.key});

  @override
  State<PresentationApp> createState() => _PresentationAppState();
}

class _PresentationAppState extends State<PresentationApp> {
  String _title = 'Presentation Window';
  String _pageContent = 'Waiting for messages...';
  double _fontSize = 36.0;
  Color _textColor = Colors.white;
  bool _showChords = false;
  int _currentPage = 0;
  int _totalPages = 1;
  bool _showTitle = true;
  bool _showPageNumber = true;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
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

  void _loadInitialData() async {
    try {
      final controller = await WindowController.fromCurrentEngine();
      final arguments = controller.arguments;

      debugPrint('Window arguments type: ${arguments.runtimeType}');
      debugPrint('Window arguments: $arguments');

      if (arguments.isNotEmpty) {
        try {
          final data = jsonDecode(arguments) as Map<String, dynamic>;

          // Check if it's new page-based format or legacy song format
          if (data.containsKey('pageContent')) {
            if (mounted) {
              setState(() {
                _title = data['title'] ?? 'Presentation';
                _pageContent = data['pageContent'] ?? '';
                _fontSize = (data['fontSize'] ?? 36.0).toDouble();
                _textColor = Color.fromARGB(
                  (data['textColor'] ?? 0xFFFFFFFF) >> 24 & 0xFF,
                  (data['textColor'] ?? 0xFFFFFFFF) >> 16 & 0xFF,
                  (data['textColor'] ?? 0xFFFFFFFF) >> 8 & 0xFF,
                  (data['textColor'] ?? 0xFFFFFFFF) & 0xFF,
                );
                _showChords = data['showChords'] ?? false;
                _currentPage = data['currentPage'] ?? 0;
                _totalPages = data['totalPages'] ?? 1;
                _showTitle = data['showTitle'] ?? true;
                _showPageNumber = data['showPageNumber'] ?? true;
              });
            }
          } else {
            // Legacy format: full song JSON
            final song = Song.fromJson(data);
            debugPrint('Loaded song from arguments: ${song.title}');
            if (mounted) {
              setState(() {
                _title = song.title;
                _pageContent = _extractLyrics(song);
              });
            }
          }
        } catch (e) {
          debugPrint('Error parsing initial data: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
    }
  }

  void _setupMessageHandler() async {
    try {
      final controller = await WindowController.fromCurrentEngine();
      await controller.setWindowMethodHandler((call) async {
        debugPrint('PresentationApp received method: ${call.method}');

        switch (call.method) {
          case 'close_window_with_exit':
            debugPrint('Received close window with exit command');
            if (Platform.isMacOS) {
              try {
                final platform = const MethodChannel('com.songviewer/window');
                await platform.invokeMethod('closeWindowWithExit');
              } catch (e) {
                debugPrint('Error closing window: $e');
              }
            }
            return 'ok';

          case 'close_window_native':
            debugPrint('Received close window native command');
            if (Platform.isMacOS) {
              try {
                final platform = const MethodChannel('com.songviewer/window');
                await platform.invokeMethod('exitFullscreen');
                await Future.delayed(const Duration(milliseconds: 300));
                await platform.invokeMethod('closeWindow');
              } catch (e) {
                debugPrint('Error closing window: $e');
              }
            }
            return 'ok';

          case 'enter_fullscreen':
            debugPrint('Received enter fullscreen command');
            if (Platform.isMacOS) {
              try {
                final platform = const MethodChannel('com.songviewer/window');
                await platform.invokeMethod('enterFullscreen');
              } catch (e) {
                debugPrint('Error entering fullscreen: $e');
              }
            }
            return 'ok';

          case 'exit_fullscreen':
            debugPrint('Received exit fullscreen command');
            if (Platform.isMacOS) {
              try {
                final platform = const MethodChannel('com.songviewer/window');
                await platform.invokeMethod('exitFullscreen');
              } catch (e) {
                debugPrint('Error exiting fullscreen: $e');
              }
            }
            return 'ok';

          case 'close_window':
            debugPrint('Received close command');
            if (Platform.isMacOS) {
              try {
                final platform = const MethodChannel('com.songviewer/window');
                await platform.invokeMethod('closeWindow');
              } catch (e) {
                debugPrint('Error closing window: $e');
              }
            }
            return 'ok';

          case 'update_page':
            try {
              debugPrint('Received page update');
              final rawMap = call.arguments as Map;
              final data = Map<String, dynamic>.from(rawMap);
              if (mounted) {
                setState(() {
                  _title = data['title'] ?? _title;
                  _pageContent = data['pageContent'] ?? '';
                  _fontSize = (data['fontSize'] ?? _fontSize).toDouble();
                  _textColor = Color.fromARGB(
                    ((data['textColor'] ?? _textColor.toARGB32()) >> 24) & 0xFF,
                    ((data['textColor'] ?? _textColor.toARGB32()) >> 16) & 0xFF,
                    ((data['textColor'] ?? _textColor.toARGB32()) >> 8) & 0xFF,
                    (data['textColor'] ?? _textColor.toARGB32()) & 0xFF,
                  );
                  _showChords = data['showChords'] ?? _showChords;
                  _currentPage = data['currentPage'] ?? _currentPage;
                  _totalPages = data['totalPages'] ?? _totalPages;
                  _showTitle = data['showTitle'] ?? _showTitle;
                  _showPageNumber = data['showPageNumber'] ?? _showPageNumber;
                });
              }
              return 'ok';
            } catch (e, stackTrace) {
              debugPrint('Error processing page data: $e');
              debugPrint('Stack trace: $stackTrace');
              return 'error: $e';
            }

          case 'update_song':
            try {
              debugPrint('Received arguments type: ${call.arguments.runtimeType}');
              final rawMap = call.arguments as Map;
              final songJson = Map<String, dynamic>.from(rawMap);
              debugPrint('Converted to Map<String, dynamic>, parsing Song...');
              final song = Song.fromJson(songJson);
              debugPrint('Song parsed successfully: ${song.title}');
              if (mounted) {
                setState(() {
                  _title = song.title;
                  _pageContent = _extractLyrics(song);
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
                _pageContent = text;
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
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Page content - no scrolling, fixed lines
              Expanded(
                child: Center(
                  child: _pageContent.isEmpty
                      ? const SizedBox.shrink()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _pageContent.split('\n').map((line) {
                            // Check if line looks like a chord line (contains common chord patterns)
                            final isChordLine = _showChords && RegExp(r'\[.*?\]').hasMatch(line);
                            final displayLine = line.replaceAll(RegExp(r'[\[\]]'), '');
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                displayLine,
                                style: TextStyle(
                                  color: isChordLine ? _textColor.withValues(alpha: 0.7) : _textColor,
                                  fontSize: _fontSize,
                                  height: 1.4,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ),
              // Bottom bar: title (left) + page number (right)
              if (_showTitle || _showPageNumber)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_showTitle)
                      Flexible(
                        child: Text(
                          _title,
                          style: TextStyle(
                            color: _textColor.withValues(alpha: 0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_showPageNumber)
                      Text(
                        '${_currentPage + 1} / $_totalPages',
                        style: TextStyle(
                          color: _textColor.withValues(alpha: 0.4),
                          fontSize: 14,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                  ],
                ),
            ],
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
            create: (context) {
              final bloc = DesktopRibbonMenuBloc();
              // Set bloc reference in PresentationWindowManager
              PresentationWindowManager().setBloc(bloc);
              return bloc;
            },
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
            create: (context) => PresentationPlaylistBloc(
              playlistRepository: widget.repositories.playlistRepository,
              songsRepository: widget.repositories.songsRepository,
            ),
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

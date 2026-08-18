// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:default_project/config/features.dart';
import 'package:default_project/model/update_playlist_data.dart';
import 'package:default_project/model/update_songlist_data.dart';
import 'package:default_project/model/web_item.dart';
import 'package:default_project/providers/web_provider.dart';
import 'package:default_project/repositories/playlist_repository.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:default_project/repositories/user_repository.dart';
import 'package:default_project/services/chordpro_service.dart';
import 'package:default_project/services/constants.dart';
import 'package:default_project/services/enums.dart';
import 'package:default_project/services/presentation_bridge.dart';
import 'package:default_project/services/presentation_window_manager.dart';
import 'package:default_project/services/win32_fullscreen.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:window_manager/window_manager.dart';

import 'blocs/export_blocs.dart';
import 'model/song/song.dart';
import 'model/user.dart';
import 'model/web_interpret.dart';
import 'model/web_song.dart';
import 'providers/hive_provider.dart';
import 'providers/pocketbase_provider.dart';
import 'repositories/web_repository.dart';
import 'services/ai_search_service.dart';
import 'view/desktop_view/widgets/my_toast.dart';
import 'view/router/app_router.dart';
import 'view/sync_screen.dart';

part 'main.part.dart';

class AppRepositories {
  final SettingsRepository settingsRepository;
  final PlaylistRepository playlistRepository;
  final UsersRepository usersRepository;
  final SongsRepository songsRepository;

  /// Null in the store build — web import is compiled out entirely (§10).
  final WebRepository? webRepository;
  final HiveProvider hiveProvider;

  AppRepositories({
    required this.settingsRepository,
    required this.playlistRepository,
    required this.usersRepository,
    required this.songsRepository,
    required this.hiveProvider,
    this.webRepository,
  });
}

/// Shared application bootstrap.
///
/// Not an entrypoint itself — `main_personal.dart` and `main_store.dart` call
/// this. Which features are compiled in is decided by [Features], whose values
/// come from `--dart-define-from-file`. See plans/store-release-plan.md §10.
Future<void> bootstrap(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('Main started with args: $args (flavor: ${Features.flavorName})');

  // CORRECT WAY according to documentation: use WindowController.fromCurrentEngine()
  if (args.isNotEmpty && args.first == 'multi_window') {
    debugPrint('This is a sub-window, getting WindowController from current engine');

    try {
      final windowController = await WindowController.fromCurrentEngine();
      debugPrint('WindowController arguments: ${windowController.arguments}');

      // Cache arguments so _loadInitialData() doesn't need a second platform call
      PresentationApp.cachedArguments = windowController.arguments;

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

  // Phase 1: Initialize providers and check server state
  final result = await initProvidersAndCheckSync();
  final repositories = result.repositories;
  final syncInfo = result.syncInfo;

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
    child: MyApp(repositories: repositories, syncInfo: syncInfo),
  ));
} // Minimal presentation app WITHOUT plugins

class PresentationApp extends StatefulWidget {
  const PresentationApp({super.key});

  /// Cached window arguments from main() — avoids second platform channel call
  static String? cachedArguments;

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
  final FocusNode _presentationFocusNode = FocusNode();

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

        // On Windows: enter borderless fullscreen on the target screen
        if (Platform.isWindows) {
          // Small delay to ensure the window is fully rendered and foreground
          await Future.delayed(const Duration(milliseconds: 200));
          _enterFullscreenFromArgs();
        }
      } catch (e) {
        debugPrint('Error showing window after frame: $e');
      }
      // Re-request focus after fullscreen animation completes
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _presentationFocusNode.requestFocus();
          debugPrint('Focus re-requested after fullscreen delay');
        }
      });
    });
  }

  /// Enter borderless fullscreen using screen bounds from window arguments.
  void _enterFullscreenFromArgs() {
    try {
      final arguments = PresentationApp.cachedArguments ?? '';
      if (arguments.isEmpty) return;
      final data = jsonDecode(arguments) as Map<String, dynamic>;
      _applyFullscreen(data['screenBounds']);
    } catch (e) {
      debugPrint('Error entering fullscreen from args: $e');
    }
  }

  /// Apply borderless fullscreen with the given screen bounds map.
  void _applyFullscreen(dynamic screenBoundsData) {
    if (screenBoundsData == null || screenBoundsData is! Map) return;
    final bounds = Map<String, dynamic>.from(screenBoundsData);
    enterFullscreenWin32(
      left: (bounds['left'] as num).toInt(),
      top: (bounds['top'] as num).toInt(),
      width: (bounds['width'] as num).toInt(),
      height: (bounds['height'] as num).toInt(),
    );
  }

  void _loadInitialData() {
    // Use cached arguments from main() — avoids second platform channel call
    // which can fail intermittently and cause blank window
    final arguments = PresentationApp.cachedArguments ?? '';

    debugPrint('_loadInitialData using cached arguments: ${arguments.length} chars');

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
  }

  void _setupMessageHandler() {
    // On macOS: use native bridge MethodChannel (bypasses desktop_multi_window channel system)
    if (Platform.isMacOS) {
      const pageDataChannel = MethodChannel('com.songviewer/page_data');
      pageDataChannel.setMethodCallHandler((call) async {
        debugPrint('PresentationApp received method via native bridge: ${call.method}');
        return _handleIncomingMethod(call.method, call.arguments);
      });
      debugPrint('macOS page data handler setup complete');

      // Signal to native bridge that the Dart handler is now registered.
      // Swift will flush any messages that were buffered during engine startup.
      const navigateBridge = MethodChannel('com.songviewer/navigate_bridge');
      navigateBridge.invokeMethod('sub_window_ready').then((_) {
        debugPrint('Sub-window ready signal sent to native bridge');
      }).catchError((e) {
        debugPrint('Error sending sub_window_ready: $e');
      });
    }

    // On Windows: connect to TCP bridge for cross-window messaging
    if (Platform.isWindows) {
      _setupWindowsBridge();
    }
  }

  /// Set up TCP bridge connection on Windows (replaces broken WindowMethodChannel)
  Future<void> _setupWindowsBridge() async {
    try {
      final arguments = PresentationApp.cachedArguments ?? '';
      if (arguments.isEmpty) return;

      final data = jsonDecode(arguments) as Map<String, dynamic>;
      final bridgePort = data['bridgePort'] as int?;
      if (bridgePort == null) {
        debugPrint('No bridgePort in arguments, cannot connect to bridge');
        return;
      }

      final bridge = PresentationBridge();
      await bridge.connectToServer(bridgePort);
      bridge.onMessage = (method, msgData) {
        debugPrint('PresentationApp received via bridge: $method');
        if (method == 'enter_fullscreen') {
          // REUSE path: main window sends screen bounds for fullscreen re-entry
          _applyFullscreen(msgData);
          return;
        }
        _handleIncomingMethod(method, msgData);
      };
      debugPrint('Windows TCP bridge connected on port $bridgePort');
    } catch (e) {
      debugPrint('Error setting up Windows bridge: $e');
    }
  }

  /// Shared handler for incoming method calls (used by both macOS native bridge and Windows WindowController)
  dynamic _handleIncomingMethod(String method, dynamic arguments) {
    switch (method) {
      case 'close_window_with_exit':
        debugPrint('Received close window with exit command');
        if (Platform.isMacOS) {
          try {
            final platform = const MethodChannel('com.songviewer/window');
            platform.invokeMethod('closeWindowWithExit');
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
            platform.invokeMethod('exitFullscreen');
            Future.delayed(const Duration(milliseconds: 300), () {
              platform.invokeMethod('closeWindow');
            });
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
            platform.invokeMethod('enterFullscreen');
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
            platform.invokeMethod('exitFullscreen');
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
            platform.invokeMethod('closeWindow');
          } catch (e) {
            debugPrint('Error closing window: $e');
          }
        }
        return 'ok';

      case 'update_page':
        try {
          debugPrint('Received page update');
          final Map<String, dynamic> data;
          if (arguments is Map) {
            data = Map<String, dynamic>.from(arguments);
          } else {
            debugPrint('Unexpected arguments type: ${arguments.runtimeType}');
            return 'error: unexpected type';
          }
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
          debugPrint('Received arguments type: ${arguments.runtimeType}');
          final Map<String, dynamic> songJson;
          if (arguments is Map) {
            songJson = Map<String, dynamic>.from(arguments);
          } else {
            debugPrint('Unexpected arguments type: ${arguments.runtimeType}');
            return 'error: unexpected type';
          }
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
        final text = arguments as String;
        if (mounted) {
          setState(() {
            _pageContent = text;
          });
        }
        return 'ok';

      default:
        debugPrint('Unknown method: $method');
        return null;
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
  void dispose() {
    _presentationFocusNode.dispose();
    super.dispose();
  }

  /// Forward key events from presentation window to main window
  void _handlePresentationKeyEvent(KeyEvent event) async {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    String? command;

    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.space) {
      command = 'forward';
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.backspace) {
      command = 'backward';
    } else if (key == LogicalKeyboardKey.escape) {
      // Don't close the window natively — just tell the main window to hide it.
      // The window stays alive for instant reuse.
      command = 'escape';
    }

    if (command != null) {
      try {
        if (Platform.isMacOS) {
          // Use native bridge MethodChannel (bypasses desktop_multi_window channel system)
          const navigateBridge = MethodChannel('com.songviewer/navigate_bridge');
          await navigateBridge.invokeMethod('navigate', command);
        } else if (Platform.isWindows) {
          // Use TCP bridge to send navigation to main window
          PresentationBridge().send('navigate', command);
        }
      } catch (e) {
        debugPrint('Error forwarding key event to main window: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('PresentationApp building...');
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // Re-request focus when user taps anywhere on the presentation window
          _presentationFocusNode.requestFocus();
        },
        child: KeyboardListener(
          focusNode: _presentationFocusNode,
          autofocus: true,
          onKeyEvent: _handlePresentationKeyEvent,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: LayoutBuilder(
              builder: (context, constraints) {
                // Use the font size from settings directly — no auto-scaling
                final fontSize = _fontSize;
                final lineHeight = 1.4;

                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Page content — wraps long lines, no horizontal overflow
                      Expanded(
                        child: Center(
                          child: _pageContent.isEmpty
                              ? const SizedBox.shrink()
                              : SingleChildScrollView(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: _pageContent.split('\n').map((line) {
                                      final isChordLine = _showChords && RegExp(r'\[.*?\]').hasMatch(line);
                                      final displayLine = line.replaceAll(RegExp(r'[\[\]]'), '');
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 2),
                                        child: Text(
                                          displayLine,
                                          style: TextStyle(
                                            color: isChordLine ? _textColor.withValues(alpha: 0.7) : _textColor,
                                            fontSize: fontSize,
                                            height: lineHeight,
                                          ),
                                          softWrap: true,
                                          textAlign: TextAlign.center,
                                        ),
                                      );
                                    }).toList(),
                                  ),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  final AppRepositories repositories;
  final SyncInfo syncInfo;

  const MyApp({
    Key? key,
    required this.repositories,
    required this.syncInfo,
  }) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WindowListener {
  late final AppRouter _appRouter;
  bool _syncComplete = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _appRouter = AppRouter(settingsRepository: widget.repositories.settingsRepository);
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.addListener(this);
    }

    // If server has data and is authenticated, load data automatically
    if (widget.syncInfo.isAuthenticated && !widget.syncInfo.isServerEmpty) {
      _loadDataAndProceed();
    } else if (!widget.syncInfo.isAuthenticated) {
      // Not authenticated — skip sync, proceed with empty data
      _syncComplete = true;
    }
  }

  Future<void> _loadDataAndProceed() async {
    setState(() => _isLoading = true);
    try {
      await loadDataFromServer(widget.repositories);
    } catch (e) {
      logger.e('Error loading data from server: $e');
    }
    if (mounted) {
      setState(() {
        _syncComplete = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDownloadFromServer() async {
    await _loadDataAndProceed();
  }

  Future<void> _handleStartEmpty() async {
    setState(() {
      _syncComplete = true;
    });
  }

  @override
  void dispose() {
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  @override
  Future<void> onWindowClose() async {
    debugPrint('Main window closing, closing all child windows...');

    // Destroy presentation window (not just hide — app is quitting)
    try {
      await PresentationWindowManager().destroyPresentationWindow();
    } catch (e) {
      debugPrint('Error destroying presentation window: $e');
    }

    // Now destroy the main window
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      await windowManager.destroy();
    }
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

    // Show sync screen if server is empty and authenticated
    if (!_syncComplete && widget.syncInfo.isAuthenticated && widget.syncInfo.isServerEmpty) {
      return MaterialApp(
        title: 'Songs viewer',
        theme: ThemeData(
          primarySwatch: getMaterialColor(AppColor.primaryColor),
        ),
        debugShowCheckedModeBanner: false,
        supportedLocales: context.supportedLocales,
        localizationsDelegates: context.localizationDelegates,
        locale: context.locale,
        home: SyncScreen(
          syncInfo: widget.syncInfo,
          onDownloadFromServer: _handleDownloadFromServer,
          onStartEmpty: _handleStartEmpty,
          isLoading: _isLoading,
        ),
      );
    }

    // Show loading screen while data is being loaded
    if (!_syncComplete) {
      return MaterialApp(
        title: 'Songs viewer',
        theme: ThemeData(
          primarySwatch: getMaterialColor(AppColor.primaryColor),
        ),
        debugShowCheckedModeBanner: false,
        home: const Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Loading...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ),
      );
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
          // Available in every flavour: importing a file the user already owns
          // is not a content-distribution question, so no feature flag.
          BlocProvider(
            create: (context) => ChordProImportBloc(
              songsRepository: widget.repositories.songsRepository,
              // Section labels are resolved once here. Switching language later
              // does not re-translate them, which only affects songs imported
              // afterwards in the old language.
              chordProService: ChordProService(
                chorusLabel: 'chordProChorusLabel'.tr(),
                bridgeLabel: 'chordProBridgeLabel'.tr(),
              ),
            ),
          ),
          // Personal flavour only — the store build must not reference WebBloc
          // at all, so the scraping subtree stays out of the artifact (§10).
          if (Features.webImport)
            BlocProvider(
              create: ((context) => WebBloc(
                  webRepository: widget.repositories.webRepository!,
                  settingsRepository: widget.repositories.settingsRepository,
                  hiveProvider: widget.repositories.hiveProvider)),
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
          if (Features.aiEnrichment)
            BlocProvider(
              create: (context) => SongEnrichmentBloc(
                aiSearchService: AiSearchService(),
                settingsRepository: widget.repositories.settingsRepository,
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

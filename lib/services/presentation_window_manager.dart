import 'dart:convert';
import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:screen_retriever/screen_retriever.dart';

import '../blocs/desktop_ribbon_menu/desktop_ribbon_menu_bloc.dart';
import '../model/song/song.dart';
import 'presentation_bridge.dart';

/// Native bridge channel: main window Dart → native → sub-window Dart.
/// Used on macOS only. On Windows, DesktopMultiWindow cross-window messaging is used.
const _bridgeChannel = MethodChannel('com.songviewer/presentation_bridge');

/// Manager for presentation window operations.
/// Uses hide/show instead of destroy/recreate to avoid unreliable engine boot.
class PresentationWindowManager {
  // Singleton instance
  static final PresentationWindowManager _instance = PresentationWindowManager._internal();
  factory PresentationWindowManager() => _instance;
  PresentationWindowManager._internal();

  // Global reference to presentation window (kept alive even when hidden)
  WindowController? _presentationWindowController;

  // Whether the presentation is currently active (visible)
  bool _isPresenting = false;

  // Bloc reference for state updates
  DesktopRibbonMenuBloc? _ribbonMenuBloc;

  // TCP bridge for cross-window communication on Windows
  final PresentationBridge _bridge = PresentationBridge();

  /// Callback for navigation commands received from the presentation window (Windows).
  /// Set by the main window's home page to handle forward/backward/escape.
  void Function(String command)? onNavigationCommand;

  /// Set the bloc reference
  void setBloc(DesktopRibbonMenuBloc bloc) {
    _ribbonMenuBloc = bloc;
  }

  /// Open presentation window with page content
  Future<void> openPresentationWindow(
    BuildContext context, {
    required String title,
    required String pageContent,
    required double fontSize,
    required Color textColor,
    required bool showChords,
    required int currentPage,
    required int totalPages,
    int linesPerPage = 8,
    bool showTitle = true,
    bool showPageNumber = true,
    int screenIndex = 0,
  }) async {
    if (!context.mounted) return;

    try {
      // REUSE PATH: if we have a hidden window with a live engine, just show it
      if (_presentationWindowController != null) {
        debugPrint('Reusing existing hidden presentation window');

        // Show window and reposition on the correct screen
        try {
          if (Platform.isMacOS) {
            await _bridgeChannel.invokeMethod('show_reposition_window', screenIndex);
          } else if (Platform.isWindows) {
            await _presentationWindowController!.show();
            // Send fullscreen command with screen bounds via bridge
            final screenBounds = await _getScreenBounds(screenIndex);
            if (screenBounds != null) {
              _bridge.send('enter_fullscreen', screenBounds);
            }
          }
        } catch (e) {
          debugPrint('Error showing/repositioning window: $e');
          // Window might have been destroyed unexpectedly — fall through to create
          _presentationWindowController = null;
        }

        if (_presentationWindowController != null) {
          // Send the page data — engine is already ready, no buffering needed
          await sendPageToPresentation(
            context,
            title: title,
            pageContent: pageContent,
            fontSize: fontSize,
            textColor: textColor,
            showChords: showChords,
            currentPage: currentPage,
            totalPages: totalPages,
            showTitle: showTitle,
            showPageNumber: showPageNumber,
          );

          _isPresenting = true;
          _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: true));
          debugPrint('Presentation window reused and shown');
          return;
        }
      }

      // CREATE PATH: first-time creation of the sub-window
      debugPrint('Creating new presentation window... (screenIndex=$screenIndex)');

      // Send screenIndex to native BEFORE creating the window so macOS/Swift can position it
      if (Platform.isMacOS) {
        debugPrint('Sending setScreenIndex=$screenIndex to native bridge');
        await _bridgeChannel.invokeMethod('setScreenIndex', screenIndex);
      }

      // On Windows: start TCP bridge server, get screen bounds, include in window arguments
      int? bridgePort;
      Map<String, int>? screenBounds;
      if (Platform.isWindows) {
        bridgePort = await _bridge.startServer();
        debugPrint('TCP bridge server started on port $bridgePort');
        screenBounds = await _getScreenBounds(screenIndex);
        // Handle navigation commands from the sub-window
        _bridge.onMessage = (method, data) {
          if (method == 'navigate') {
            final command = data as String;
            debugPrint('Bridge received navigation: $command');
            onNavigationCommand?.call(command);
          }
        };
      }

      // Create new window with initial data (including screenIndex for Swift positioning)
      final initData = jsonEncode({
        'title': title,
        'pageContent': pageContent,
        'fontSize': fontSize,
        'textColor': textColor.toARGB32(),
        'showChords': showChords,
        'currentPage': currentPage,
        'totalPages': totalPages,
        'linesPerPage': linesPerPage,
        'screenIndex': screenIndex,
        if (bridgePort != null) 'bridgePort': bridgePort,
        if (screenBounds != null) 'screenBounds': screenBounds,
      });

      final window = await WindowController.create(WindowConfiguration(
        arguments: initData,
      ));

      _presentationWindowController = window;

      debugPrint('Window created: ${window.windowId}');
      await window.show();

      _isPresenting = true;
      _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: true));

      debugPrint('Window shown with page data');

      // Also send the initial page via the bridge as a backup (fire-and-forget).
      // Ensures data arrives even if WindowController.arguments parsing fails.
      debugPrint('Sending initial page via bridge as backup...');
      final backupPageData = {
        'title': title,
        'pageContent': pageContent,
        'fontSize': fontSize,
        'textColor': textColor.toARGB32(),
        'showChords': showChords,
        'currentPage': currentPage,
        'totalPages': totalPages,
        'linesPerPage': linesPerPage,
        'showTitle': showTitle,
        'showPageNumber': showPageNumber,
      };
      if (Platform.isMacOS) {
        // On macOS, the native bridge buffers until sub_window_ready
        _bridgeChannel.invokeMethod('update_page', backupPageData).then((_) {
          debugPrint('Backup initial page sent via bridge');
        }).catchError((e) {
          debugPrint('Error sending backup initial page: $e');
        });
      } else if (Platform.isWindows) {
        // On Windows, initial data is already delivered reliably via WindowConfiguration.arguments
        // (parsed by sub-window in _loadInitialData). No backup send needed.
        debugPrint('Windows: skipping backup send — initial data delivered via window arguments');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prezentační okno otevřeno'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error opening presentation window: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening window: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Send page content to existing presentation window
  Future<void> sendPageToPresentation(
    BuildContext context, {
    required String title,
    required String pageContent,
    required double fontSize,
    required Color textColor,
    required bool showChords,
    required int currentPage,
    required int totalPages,
    int linesPerPage = 8,
    bool showTitle = true,
    bool showPageNumber = true,
  }) async {
    if (_presentationWindowController == null || !_isPresenting) {
      debugPrint('No presentation window available or not presenting');
      return;
    }

    try {
      debugPrint('Sending page to presentation: $title (page ${currentPage + 1}/$totalPages)');
      final pageData = {
        'title': title,
        'pageContent': pageContent,
        'fontSize': fontSize,
        'textColor': textColor.toARGB32(),
        'showChords': showChords,
        'currentPage': currentPage,
        'totalPages': totalPages,
        'linesPerPage': linesPerPage,
        'showTitle': showTitle,
        'showPageNumber': showPageNumber,
      };
      if (Platform.isMacOS) {
        await _bridgeChannel.invokeMethod('update_page', pageData);
      } else if (Platform.isWindows) {
        _bridge.send('update_page', pageData);
      }
      debugPrint('Page sent successfully');
    } catch (e) {
      debugPrint('Error sending page: $e');
    }
  }

  /// Legacy: Send full song to existing presentation window
  Future<void> sendSongToPresentation(BuildContext context, Song song) async {
    if (_presentationWindowController == null) {
      debugPrint('No presentation window available');
      return;
    }

    try {
      debugPrint('Sending song to presentation: ${song.title}');
      if (Platform.isMacOS) {
        await _bridgeChannel.invokeMethod('update_song', song.toJson());
      } else if (Platform.isWindows) {
        _bridge.send('update_song', song.toJson());
      }
      debugPrint('Song sent successfully');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Song "${song.title}" sent'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error sending song: $e');
    }
  }

  /// Mark the presentation window as actually destroyed (e.g. by willCloseNotification).
  /// Cleans up all references — next open will create a new window.
  void markWindowClosed() {
    debugPrint('markWindowClosed: window was destroyed, clearing references');
    _presentationWindowController = null;
    _isPresenting = false;
    _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: false));
  }

  /// Hide the presentation window (keep engine alive for instant reuse).
  /// Uses native bridge on macOS, WindowController on Windows.
  Future<void> closePresentationWindow() async {
    if (!_isPresenting) return;

    try {
      debugPrint('Hiding presentation window...');
      if (Platform.isMacOS) {
        await _bridgeChannel.invokeMethod('hide_window');
        debugPrint('Window hidden via native bridge — engine kept alive for reuse');
      } else if (Platform.isWindows) {
        await _presentationWindowController?.hide();
        debugPrint('Window hidden via WindowController');
      }
    } catch (e) {
      debugPrint('Error hiding window: $e');
    }

    _isPresenting = false;
    _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: false));
  }

  /// Actually destroy the presentation window (kills the engine).
  /// Only used when the app is quitting or for error recovery.
  Future<void> destroyPresentationWindow() async {
    if (_presentationWindowController == null) return;

    try {
      debugPrint('Destroying presentation window...');
      if (Platform.isMacOS) {
        await _bridgeChannel.invokeMethod('close_window_with_exit');
        debugPrint('Window destroyed by native bridge');
      } else if (Platform.isWindows) {
        // Stop TCP bridge and hide the window
        await _bridge.stop();
        await _presentationWindowController?.hide();
        _presentationWindowController = null;
        debugPrint('Bridge stopped, window hidden and references cleared');
      }
    } catch (e) {
      debugPrint('Error destroying window: $e');
    }

    _presentationWindowController = null;
    _isPresenting = false;
    _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: false));
  }

  /// Check if presentation is currently active (visible)
  bool get isPresentationWindowOpen => _isPresenting;

  /// Check if the hidden window engine exists (for reuse)
  bool get hasHiddenWindow => _presentationWindowController != null && !_isPresenting;

  /// Get presentation window controller
  WindowController? get presentationWindow => _presentationWindowController;

  /// Get the screen bounds for the target screen index using screen_retriever.
  Future<Map<String, int>?> _getScreenBounds(int screenIndex) async {
    try {
      final displays = await screenRetriever.getAllDisplays();
      final target = screenIndex < displays.length ? displays[screenIndex] : displays.first;
      final pos = target.visiblePosition ?? const Offset(0, 0);
      final size = target.size;
      return {
        'left': pos.dx.toInt(),
        'top': pos.dy.toInt(),
        'width': size.width.toInt(),
        'height': size.height.toInt(),
      };
    } catch (e) {
      debugPrint('Error getting screen bounds: $e');
      return null;
    }
  }
}

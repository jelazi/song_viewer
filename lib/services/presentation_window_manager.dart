import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../blocs/desktop_ribbon_menu/desktop_ribbon_menu_bloc.dart';
import '../model/song/song.dart';

/// Native bridge channel: main window Dart → native → sub-window Dart.
/// Bypasses desktop_multi_window channel system entirely.
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

        // Show window and reposition on the correct screen via native bridge
        try {
          await _bridgeChannel.invokeMethod('show_reposition_window', screenIndex);
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

      // Send screenIndex to native BEFORE creating the window so Swift can position it
      debugPrint('Sending setScreenIndex=$screenIndex to native bridge');
      await _bridgeChannel.invokeMethod('setScreenIndex', screenIndex);

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
      // This gets buffered by Swift until sub_window_ready, then flushed.
      // Ensures data arrives even if WindowController.arguments parsing fails.
      debugPrint('Sending initial page via bridge as backup...');
      _bridgeChannel.invokeMethod('update_page', {
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
      }).then((_) {
        debugPrint('Backup initial page sent via bridge');
      }).catchError((e) {
        debugPrint('Error sending backup initial page: $e');
      });

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
      await _bridgeChannel.invokeMethod('update_page', {
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
      });
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
      await _bridgeChannel.invokeMethod('update_song', song.toJson());
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
  /// Uses native bridge to hide without destroying.
  Future<void> closePresentationWindow() async {
    if (!_isPresenting) return;

    try {
      debugPrint('Hiding presentation window via bridge...');
      await _bridgeChannel.invokeMethod('hide_window');
      debugPrint('Window hidden — engine kept alive for reuse');
    } catch (e) {
      debugPrint('Error hiding window via bridge: $e');
    }

    _isPresenting = false;
    _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: false));
  }

  /// Actually destroy the presentation window (kills the engine).
  /// Only used when the app is quitting or for error recovery.
  Future<void> destroyPresentationWindow() async {
    if (_presentationWindowController == null) return;

    try {
      debugPrint('Destroying presentation window via bridge...');
      await _bridgeChannel.invokeMethod('close_window_with_exit');
      debugPrint('Window destroyed by native');
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
}

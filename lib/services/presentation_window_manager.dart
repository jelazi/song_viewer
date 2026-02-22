import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

import '../blocs/desktop_ribbon_menu/desktop_ribbon_menu_bloc.dart';
import '../model/song/song.dart';

/// Manager for presentation window operations
class PresentationWindowManager {
  // Singleton instance
  static final PresentationWindowManager _instance = PresentationWindowManager._internal();
  factory PresentationWindowManager() => _instance;
  PresentationWindowManager._internal();

  // Global reference to presentation window
  WindowController? _presentationWindowController;

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
  }) async {
    if (!context.mounted) return;

    try {
      // Check if window controller exists and if the window is still alive
      if (_presentationWindowController != null) {
        try {
          final allWindows = await WindowController.getAll();
          final windowExists = allWindows.any((w) => w.windowId == _presentationWindowController!.windowId);

          if (windowExists) {
            await _presentationWindowController!.show();
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
            // Re-focus the main window so keyboard shortcuts work
            _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: true));
            return;
          } else {
            debugPrint('Window was closed externally, creating new one');
            _presentationWindowController = null;
          }
        } catch (e) {
          debugPrint('Failed to check window: $e');
          _presentationWindowController = null;
        }
      }

      debugPrint('Creating new presentation window...');

      // Create new window with initial data
      final initData = jsonEncode({
        'title': title,
        'pageContent': pageContent,
        'fontSize': fontSize,
        'textColor': textColor.toARGB32(),
        'showChords': showChords,
        'currentPage': currentPage,
        'totalPages': totalPages,
        'linesPerPage': linesPerPage,
      });

      final window = await WindowController.create(WindowConfiguration(
        arguments: initData,
      ));

      _presentationWindowController = window;

      debugPrint('Window created: ${window.windowId}');
      await window.show();

      _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: true));

      debugPrint('Window shown with page data');

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
    if (_presentationWindowController == null) {
      debugPrint('No presentation window available');
      return;
    }

    try {
      debugPrint('Sending page to presentation: $title (page ${currentPage + 1}/$totalPages)');
      await _invokeWithRetry('update_page', {
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
      await _invokeWithRetry('update_song', song.toJson());
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

  /// Invoke a method on the presentation window with retry logic.
  /// The sub-window needs time to boot its engine and register its handler.
  Future<dynamic> _invokeWithRetry(String method, [dynamic arguments]) async {
    if (_presentationWindowController == null) return;
    const maxRetries = 10;
    const retryDelay = Duration(milliseconds: 500);

    for (var attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await _presentationWindowController!.invokeMethod(method, arguments);
      } on WindowChannelException catch (e) {
        if (e.code == 'CHANNEL_UNREGISTERED' && attempt < maxRetries - 1) {
          debugPrint('Channel not ready yet, retrying in ${retryDelay.inMilliseconds}ms... (attempt ${attempt + 1}/$maxRetries)');
          await Future.delayed(retryDelay);
        } else {
          rethrow;
        }
      }
    }
  }

  /// Mark the presentation window as closed (called when the sub-window closed itself).
  /// Only updates internal state without sending any commands to the sub-window.
  void markWindowClosed() {
    _presentationWindowController = null;
    _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: false));
  }

  /// Close presentation window
  Future<void> closePresentationWindow() async {
    if (_presentationWindowController != null) {
      try {
        debugPrint('Closing presentation window...');
        await _invokeWithRetry('close_window_with_exit');
        debugPrint('Close command sent');
      } catch (e) {
        debugPrint('Error sending close via channel: $e');
        // Fallback: hide the window using the plugin API
        try {
          await _presentationWindowController!.hide();
          debugPrint('Window hidden via fallback');
        } catch (e2) {
          debugPrint('Error hiding window: $e2');
        }
      }

      _presentationWindowController = null;
      _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: false));
    }
  }

  /// Check if presentation window is open
  bool get isPresentationWindowOpen => _presentationWindowController != null;

  /// Get presentation window controller
  WindowController? get presentationWindow => _presentationWindowController;
}

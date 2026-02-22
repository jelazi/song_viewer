import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../blocs/desktop_ribbon_menu/desktop_ribbon_menu_bloc.dart';
import '../model/song/song.dart';

/// Native bridge channel: main window Dart → native → sub-window Dart.
/// Bypasses desktop_multi_window channel system entirely.
const _bridgeChannel = MethodChannel('com.songviewer/presentation_bridge');

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
    int screenIndex = 0,
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

  /// Mark the presentation window as closed (called when the sub-window closed itself).
  /// Only updates internal state without sending any commands to the sub-window.
  void markWindowClosed() {
    _presentationWindowController = null;
    _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: false));
  }

  /// Close presentation window via native bridge
  /// The bridge handles close_window_with_exit directly in Swift (no round-trip through sub-window Dart)
  Future<void> closePresentationWindow() async {
    if (_presentationWindowController != null) {
      try {
        debugPrint('Closing presentation window via bridge...');
        await _bridgeChannel.invokeMethod('close_window_with_exit');
        debugPrint('Close command sent — window closed by native');
      } catch (e) {
        debugPrint('Error sending close via bridge: $e');
        // Fallback: try to close via plugin API
        try {
          await _presentationWindowController!.hide();
          debugPrint('Window closed via plugin fallback');
        } catch (e2) {
          debugPrint('Error closing via plugin: $e2');
          try {
            await _presentationWindowController!.hide();
            debugPrint('Window hidden via fallback');
          } catch (e3) {
            debugPrint('Error hiding window: $e3');
          }
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

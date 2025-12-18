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

  /// Open presentation window with song data
  Future<void> openPresentationWindow(BuildContext context, Song song) async {
    if (!context.mounted) return;

    try {
      // Check if window controller exists and if the window is still alive
      if (_presentationWindowController != null) {
        try {
          // Try to check if window still exists by getting all windows
          final allWindows = await WindowController.getAll();
          final windowExists = allWindows.any((w) => w.windowId == _presentationWindowController!.windowId);

          if (windowExists) {
            // Window exists, just show it
            await _presentationWindowController!.show();
            await sendSongToPresentation(context, song);
            _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: true));
            return;
          } else {
            // Window was closed, clear the controller
            debugPrint('Window was closed externally, creating new one');
            _presentationWindowController = null;
          }
        } catch (e) {
          debugPrint('Failed to check window: $e');
          _presentationWindowController = null;
        }
      }

      debugPrint('Creating new presentation window...');

      // Create new window with song data in arguments as JSON string
      final songJsonString = jsonEncode(song.toJson());
      final window = await WindowController.create(WindowConfiguration(
        arguments: songJsonString,
      ));

      _presentationWindowController = window;

      debugPrint('Window created: ${window.windowId}');

      // Show the window (Swift callback will handle fullscreen)
      await window.show();

      // Notify bloc about state change
      _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: true));

      debugPrint('Window shown with song data in arguments');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Presentation window opened'),
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

  /// Send song to existing presentation window
  Future<void> sendSongToPresentation(BuildContext context, Song song) async {
    if (_presentationWindowController == null) {
      debugPrint('No presentation window available');
      return;
    }

    try {
      debugPrint('Sending song to presentation: ${song.title}');
      await _presentationWindowController!.invokeMethod('update_song', song.toJson());
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

  /// Close presentation window
  Future<void> closePresentationWindow() async {
    if (_presentationWindowController != null) {
      try {
        debugPrint('Closing presentation window...');

        // Send single command to exit fullscreen and close
        await _presentationWindowController!.invokeMethod('close_window_with_exit');
        debugPrint('Close command sent');
      } catch (e) {
        debugPrint('Error closing presentation window: $e');
      }

      _presentationWindowController = null;

      // Notify bloc about state change
      _ribbonMenuBloc?.add(const ChangePresentationWindowState(isOpen: false));
    }
  }

  /// Check if presentation window is open
  bool get isPresentationWindowOpen => _presentationWindowController != null;

  /// Get presentation window controller
  WindowController? get presentationWindow => _presentationWindowController;
}

import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';

import '../model/song/song.dart';

/// Manager for presentation window operations
class PresentationWindowManager {
  // Singleton instance
  static final PresentationWindowManager _instance = PresentationWindowManager._internal();
  factory PresentationWindowManager() => _instance;
  PresentationWindowManager._internal();

  // Global reference to presentation window
  WindowController? _presentationWindowController;

  /// Open presentation window with song data
  Future<void> openPresentationWindow(BuildContext context, Song song) async {
    if (!context.mounted) return;

    try {
      // Check if presentation window already exists
      if (_presentationWindowController != null) {
        debugPrint('Presentation window already exists, trying to show it');
        try {
          // Try to show existing window
          await _presentationWindowController!.show();
          debugPrint('Existing window shown (use Send button to update song)');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Prezentační okno zobrazeno'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 2),
              ),
            );
          }
          return;
        } catch (e) {
          debugPrint('Failed to show existing window, will create new one: $e');
          _presentationWindowController = null;
        }
      }

      // Also check all windows to see if presentation window exists
      final allWindows = await WindowController.getAll();
      for (var window in allWindows) {
        // Check if it's a presentation window (will have JSON string with song data)
        if (window.arguments.isNotEmpty) {
          try {
            // Try to parse as JSON to verify it's our presentation window
            jsonDecode(window.arguments);
            debugPrint('Found existing presentation window: ${window.windowId}');
            _presentationWindowController = window;
            await window.show();
            debugPrint('Existing window shown (use Send button to update song)');

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Prezentační okno zobrazeno'),
                  backgroundColor: Colors.blue,
                  duration: Duration(seconds: 2),
                ),
              );
            }
            return;
          } catch (e) {
            // Not a JSON string, skip this window
            continue;
          }
        }
      }

      debugPrint('Creating new presentation window...');

      // Create payload with song data
      final payload = {
        'song': song.toJson(),
      };
      
      // Create new window with payload as JSON string
      final payloadJsonString = jsonEncode(payload);
      final window = await WindowController.create(WindowConfiguration(
        arguments: payloadJsonString,
      ));

      _presentationWindowController = window;

      debugPrint('Window created: ${window.windowId}');

      // Show the window
      await window.show();

      debugPrint('Window shown - will be set to fullscreen automatically');

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
            content: Text('Chyba při otevírání okna: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Send song to existing presentation window
  Future<void> sendSongToPresentation(BuildContext context, Song song) async {
    if (!context.mounted) return;

    try {
      // Check if presentation window exists
      if (_presentationWindowController == null) {
        // Check all windows
        final allWindows = await WindowController.getAll();
        for (var window in allWindows) {
          if (window.arguments.isNotEmpty) {
            try {
              jsonDecode(window.arguments);
              _presentationWindowController = window;
              break;
            } catch (e) {
              continue;
            }
          }
        }
      }

      if (_presentationWindowController == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Prezentační okno nebylo nalezeno. Nejprve ho otevřete.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Send song data to presentation window
      debugPrint('Sending song to presentation window: ${song.title}');

      // Wait for message handler to be ready (needs time to initialize)
      debugPrint('Waiting for message handler to be ready...');
      await Future.delayed(const Duration(milliseconds: 1500));

      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          debugPrint('Send attempt $attempt/3');
          await _presentationWindowController!.invokeMethod('update_song', song.toJson());
          debugPrint('Song sent successfully on attempt $attempt');

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Píseň "${song.title}" odeslána do prezentace'),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          }
          return;
        } catch (e) {
          debugPrint('Error sending song on attempt $attempt: $e');
          if (attempt < 3) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }
      }

      // If all attempts failed
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nepodařilo se odeslat píseň. Zkuste to znovu.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error in sendSongToPresentation: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chyba: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Close presentation window
  Future<void> closePresentationWindow() async {
    if (_presentationWindowController != null) {
      try {
        await _presentationWindowController!.hide();
        debugPrint('Presentation window hidden');
      } catch (e) {
        debugPrint('Error hiding presentation window: $e');
      }
      _presentationWindowController = null;
    }
  }

  /// Get presentation window controller
  WindowController? get presentationWindow => _presentationWindowController;
}

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

extension WindowControllerExt on WindowController {
  /// Initialize window method handler
  Future<void> initializeWindowHandler() async {
    return await setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'window_set_title':
          final title = call.arguments as String;
          return await windowManager.setTitle(title);
        case 'window_set_frame':
          final args = call.arguments as Map;
          final rect = Rect.fromLTWH(
            args['x'] as double,
            args['y'] as double,
            args['width'] as double,
            args['height'] as double,
          );
          await windowManager.setBounds(rect);
          break;
        case 'window_center':
          return await windowManager.center();
        case 'window_close':
          return await windowManager.close();
        case 'window_set_fullscreen':
          final isFullscreen = call.arguments as bool;
          return await windowManager.setFullScreen(isFullscreen);
        default:
          throw MissingPluginException('Not implemented method: ${call.method}');
      }
    });
  }

  Future<void> setTitleExt(String title) {
    return invokeMethod('window_set_title', title);
  }

  Future<void> setFrameExt(Rect rect) {
    return invokeMethod('window_set_frame', {
      'x': rect.left,
      'y': rect.top,
      'width': rect.width,
      'height': rect.height,
    });
  }

  Future<void> centerExt() {
    return invokeMethod('window_center');
  }

  Future<void> closeExt() {
    return invokeMethod('window_close');
  }

  Future<void> setFullscreenExt(bool isFullscreen) {
    return invokeMethod('window_set_fullscreen', isFullscreen);
  }
}

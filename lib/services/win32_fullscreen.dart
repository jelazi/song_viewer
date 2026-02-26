import 'dart:ffi';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Win32 constants for window styling
const _gwlStyle = -16;
const _wsCaption = 0x00C00000;
const _wsThickframe = 0x00040000;
const _wsMinimize = 0x20000000;
const _wsMaximize = 0x01000000;
const _wsSysmenu = 0x00080000;
const _swpFramechanged = 0x0020;
const _swpShowwindow = 0x0040;

/// Enter borderless fullscreen on a specific screen area using Win32 APIs.
///
/// [left], [top], [width], [height] define the target screen rectangle
/// (usually obtained from `screen_retriever` in the main window).
///
/// Only works on Windows. No-op on other platforms.
void enterFullscreenWin32({
  required int left,
  required int top,
  required int width,
  required int height,
}) {
  if (!Platform.isWindows) return;

  try {
    final user32 = DynamicLibrary.open('user32.dll');

    final getForegroundWindow = user32.lookupFunction<
        IntPtr Function(),
        int Function()>('GetForegroundWindow');

    final getWindowLong = user32.lookupFunction<
        Int32 Function(IntPtr hWnd, Int32 nIndex),
        int Function(int hWnd, int nIndex)>('GetWindowLongW');

    final setWindowLong = user32.lookupFunction<
        Int32 Function(IntPtr hWnd, Int32 nIndex, Int32 dwNewLong),
        int Function(int hWnd, int nIndex, int dwNewLong)>('SetWindowLongW');

    final setWindowPos = user32.lookupFunction<
        Int32 Function(IntPtr hWnd, IntPtr hWndInsertAfter, Int32 x, Int32 y,
            Int32 cx, Int32 cy, Uint32 uFlags),
        int Function(int hWnd, int hWndInsertAfter, int x, int y, int cx,
            int cy, int uFlags)>('SetWindowPos');

    final hWnd = getForegroundWindow();
    if (hWnd == 0) {
      debugPrint('[Win32Fullscreen] GetForegroundWindow returned 0');
      return;
    }

    // Remove window decorations (title bar, borders, system menu)
    var style = getWindowLong(hWnd, _gwlStyle);
    style &= ~(_wsCaption | _wsThickframe | _wsMinimize | _wsMaximize | _wsSysmenu);
    setWindowLong(hWnd, _gwlStyle, style);

    // Position window to fill entire target screen
    setWindowPos(
      hWnd,
      0, // HWND_TOP
      left,
      top,
      width,
      height,
      _swpFramechanged | _swpShowwindow,
    );

    debugPrint('[Win32Fullscreen] Window set to fullscreen: ($left, $top) ${width}x$height');
  } catch (e) {
    debugPrint('[Win32Fullscreen] Error: $e');
  }
}

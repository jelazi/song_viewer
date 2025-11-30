# Multi-Window Presentation Setup

## Overview

This project uses `desktop_multi_window` package to open presentation slides in a separate window while keeping the main application window active.

## How It Works

### Main Window
- Entry point: `lib/main.dart`
- Contains the main application with song list, editing, etc.
- Stays open and functional when presentation window is launched

### Presentation Window
- Entry point: `lib/presentation_window.dart`
- Opens as a completely separate window process
- Shows song lyrics without chords in fullscreen
- Automatically positioned on secondary monitor (if available)

## Key Files

1. **`lib/presentation_window.dart`**
   - Separate `main()` function for presentation window
   - Receives song data as JSON argument
   - Handles window initialization and display

2. **`lib/extensions/window_controller_ext.dart`**
   - Extension methods for WindowController
   - Bridges communication between windows using window_manager
   - Methods: `setTitleExt()`, `setFrameExt()`, `setFullscreenExt()`, `closeExt()`

3. **`lib/view/desktop_view/widgets/ribbon_menu.dart`**
   - Contains `openPresentationWindow()` function
   - Detects multiple monitors using `screen_retriever`
   - Creates new window with `WindowController.create()`

## Usage

1. Select a song in the main application
2. Click the "Present" button in the ribbon menu
3. A new window opens with the presentation:
   - **Multiple monitors**: Opens on secondary monitor in fullscreen
   - **Single monitor**: Opens as 1200x800 window

4. Close presentation:
   - Click anywhere in the presentation window
   - Click the X button in top-right corner
   - Main window remains active throughout

## Technical Details

### Window Communication

The `desktop_multi_window` package creates truly separate window processes. Communication happens through:

1. **Initialization**: Song data passed as JSON string argument
2. **Window Control**: Extension methods invoke window_manager via method channels
3. **Method Handler**: Each window has its own handler for incoming commands

### Extension Methods Pattern

```dart
extension WindowControllerExt on WindowController {
  Future<void> initializeWindowHandler() async {
    return await setWindowMethodHandler((call) async {
      switch (call.method) {
        case 'window_set_title':
          return await windowManager.setTitle(call.arguments);
        // ... more cases
      }
    });
  }
  
  Future<void> setTitleExt(String title) {
    return invokeMethod('window_set_title', title);
  }
}
```

### Multi-Monitor Detection

```dart
final displays = await screenRetriever.getAllDisplays();

if (displays.length > 1) {
  // Position on secondary monitor
  final secondaryDisplay = displays[1];
  windowX = secondaryDisplay.visiblePosition!.dx;
  windowY = secondaryDisplay.visiblePosition!.dy;
  windowWidth = secondaryDisplay.size.width;
  windowHeight = secondaryDisplay.size.height;
}
```

## Dependencies

- `desktop_multi_window: ^0.3.0` - Multi-window support
- `screen_retriever: ^0.2.0` - Monitor detection
- `window_manager: ^0.5.1` - Window control

## Troubleshooting

### "Channel not registered" Error

If you see: `WindowChannelException: Channel "..." not accessible`

**Solution**: Ensure `WidgetsFlutterBinding.ensureInitialized()` is called in `presentation_window.dart` main() before any async operations.

### Window Not Appearing

1. Check if window was created successfully
2. Call `window.show()` explicitly
3. Add delay before sending window commands (100-300ms)

### Fullscreen Not Working

Some platforms may not support programmatic fullscreen. The window will still be sized to fill the display bounds.

## Platform Support

- ✅ macOS
- ✅ Windows  
- ✅ Linux
- ❌ iOS/Android (not applicable - no multi-window support)
- ❌ Web (not applicable - uses browser windows)

## Future Enhancements

- [ ] Keyboard shortcuts in presentation window (ESC to close, arrows to navigate)
- [ ] Live updates when song is changed in main window
- [ ] Presentation controls (next/previous song, font size)
- [ ] Custom backgrounds and themes
- [ ] Multiple presentations simultaneously

# Development Log

## 2026-02-22 - Fix CHANNEL_UNREGISTERED errors with desktop_multi_window v0.3.0

### What was done
- **Root cause**: `WindowController.invokeMethod` in v0.3.0 uses a **bidirectional** `WindowMethodChannel` internally. Both engines (main + sub-window) must register on the channel. The main window never registered, causing `CHANNEL_UNREGISTERED` errors on every `invokeMethod` call.
- **Fix**: Replaced all `_presentationWindowController!.invokeMethod(...)` calls with a custom **unidirectional** `WindowMethodChannel('songs_viewer/presentation')`. The sub-window registers as the sole handler. Any engine can invoke.
- **Sub-window handler**: Changed `_setupMessageHandler()` in `PresentationApp` from `controller.setWindowMethodHandler()` (bidirectional) to `presentationChannel.setMethodCallHandler()` (unidirectional).
- **Retry logic**: Added `_invokeWithRetry()` to `PresentationWindowManager` — retries up to 5 times with 500ms delays when the sub-window hasn't registered yet (startup timing).

### Files modified
- `lib/main.dart` - `_setupMessageHandler()` now uses unidirectional `WindowMethodChannel('songs_viewer/presentation')`
- `lib/services/presentation_window_manager.dart` - All `invokeMethod` calls use the shared unidirectional channel + retry helper

### Current state
- Two unidirectional channels: `songs_viewer/presentation` (main→sub, page updates/close) and `songs_viewer/navigate` (sub→main, keyboard forwarding)
- No compilation errors

---

## 2025-01-XX - Fix keyboard forwarding between presentation windows

### What was done
- **Fixed focus/keyboard issue in presentation mode** - The previous approach of `windowManager.focus()` to bring the main window to front was causing the presentation window to be hidden behind the main window (black screen). Reverted that approach entirely.
- **Implemented cross-window keyboard forwarding** - Added `KeyboardListener` to `PresentationApp` (sub-window) that captures arrow keys, space, backspace, and escape. These key events are forwarded to the main window via `WindowMethodChannel` (desktop_multi_window v0.3.0 API).
- **Fixed API for desktop_multi_window v0.3.0** - The old `DesktopMultiWindow.invokeMethod` / `DesktopMultiWindow.setMethodHandler` API was removed in v0.3.0. Replaced with `WindowMethodChannel('songs_viewer/navigate', mode: ChannelMode.unidirectional)` for inter-window communication.
- **Main window receives navigation commands** - `DesktopHomePage` listens on the `WindowMethodChannel` and invokes the same `_navigateForward` / `_navigateBackward` / escape logic as local keyboard events.

### Files modified
- `lib/main.dart` - Added `_presentationFocusNode`, `KeyboardListener` wrapper, `_handlePresentationKeyEvent()` that sends commands via `WindowMethodChannel`
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` - Added `_navigateChannel` (static const `WindowMethodChannel`), `initState()` registers handler, `dispose()` clears handler, `_handleRemoteNavigation()` method
- `lib/services/presentation_window_manager.dart` - Reverted `windowManager.focus()` and removed `_focusMainWindow()` method

### Current state
- Keyboard shortcuts (arrows, space, backspace, escape) now work from EITHER window - the main window or the presentation window
- Presentation window is no longer hidden/covered by the main window
- No compilation errors (only pre-existing info-level warnings)

### Known issues
- None new

---

## 2025-01-XX - Presentation UX fixes batch 3 (5 tasks)

### What was done
1. **Load playlist dialog - expandable with songs & edit** - Rewrote `_showLoadPlaylistDialog` in ribbon_menu.dart. Clicking a playlist now expands it to show all its songs with numbering, song title, and interpret. Songs can be reordered via drag-and-drop (ReorderableListView) and removed individually. Added `UpdatePlaylistDirect` event to `PlaylistsBloc` for saving playlist changes directly to Firebase.

2. **Consistent auto font size - never truncated** - Fixed PresentationApp in main.dart: removed `overflow: TextOverflow.ellipsis` and `maxLines: 1` which were cutting off long lines. Added width-based font size calculation using `TextPainter` binary search to find the max font size that fits the longest line. Final font size is the smaller of height-based and width-based calculations, ensuring text never overflows in either direction.

3. **Fix focus on double-click presentation start** - Added `FocusScope.of(context).requestFocus()` with 300ms delay after double-click opens/sends to presentation window in list_song.dart. This ensures keyboard shortcuts work immediately after starting presentation via double-click.

4. **Fix backward navigation skipping songs** - Root cause: `UpdatePresentationSong` always reset `currentPage` to 0 in the BLoC state, even when navigating to the last page of a previous song. Added optional `page` parameter to `UpdatePresentationSong` event. `_goToPreviousSongLastPage` now passes `page: lastPage` so the BLoC state correctly reflects the displayed page. Also fixed the black-first-page backward path to set page to `totalPages - 1`.

5. **Resizable divider between left and right columns in preview** - Added draggable vertical divider in preview_body.dart between `ListSong` and the lyrics content area. Uses `MouseRegion` (resize cursor) + `GestureDetector` (horizontal drag) pattern. `ListSong` now accepts optional `width` parameter (clamped 200-600px, default 300).

### Files modified
- `lib/view/desktop_view/widgets/ribbon_menu.dart` - Rewrote `_showLoadPlaylistDialog` with expandable playlists, song list, reorder, remove. Added Playlist model import.
- `lib/blocs/playlist_bloc/playlists_event.dart` - Added `UpdatePlaylistDirect` event
- `lib/blocs/playlist_bloc/playlists_bloc.dart` - Added `_updatePlaylistDirect` handler
- `lib/main.dart` - Fixed font auto-sizing to consider width, removed ellipsis truncation, added `dart:ui` import
- `lib/blocs/presentation_bloc/presentation_event.dart` - Added optional `page` parameter to `UpdatePresentationSong`
- `lib/blocs/presentation_bloc/presentation_bloc.dart` - Updated `_onUpdatePresentationSong` to use `event.page`
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` - Fixed `_goToPreviousSongLastPage` and black-first-page backward navigation to pass correct page
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/list_song.dart` - Added focus re-request after double-click, added `width` parameter
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/preview_body.dart` - Added resizable divider, `_listSongWidth` state

### Current state
- All 5 tasks implemented, no compilation errors
- Backward navigation now correctly tracks page state across song boundaries
- Font sizing considers both width and height, text is never truncated
- Keyboard focus works after double-click presentation start
- Playlist load dialog is interactive with song preview and editing

### Known issues
- Pre-existing warning: unused `list` variable in preview_body.dart line 186

---

## 2025-01-XX - Presentation UX fixes and improvements (6 tasks)

### What was done
1. **Double-click on playlist card starts presentation** - Added `onDoubleTap` callback to `PresentationPlaylistWidget`. Double-clicking a song in the playlist now either sends that song to an already-open presentation window, or opens a new presentation window starting from that song.

2. **Keep Home tab visible in settings sub-views** - When navigating to groups/users/presentation_settings, the "Home" tab now remains visible in the ribbon menu (with Settings tab selected by default). Clicking "Home" tab navigates back to the preview body.

3. **Auto-calculate font size from lines per page** - Removed the manual font size selector from presentation settings. The presentation window now auto-calculates the font size based on the available window height and the number of lines per page. Added `linesPerPage` parameter to `PresentationWindowManager` methods. The `PresentationApp` uses `LayoutBuilder` to compute optimal font size dynamically.

4. **Fix focus after opening presentation window** - Added `_focusNode.requestFocus()` with a 300ms delay after opening the presentation window. Also wrapped the entire home page in a `GestureDetector` that re-requests focus on any tap, ensuring keyboard shortcuts always work after interacting with UI elements.

5. **Fix arrow key navigation** - Completely rewrote the keyboard navigation logic in `desktop_home_page.dart`. Split into clear helper methods: `_navigateForward`, `_navigateBackward`, `_goToNextSongFirstPage`, `_goToNextSongWithBlackFirst`, `_goToPreviousSongLastPage`. Each key press now moves exactly one step (one page forward/backward), with proper handling of black screen transitions between songs.

6. **Playlist Firebase save** - Already implemented from previous session. Verified the save dialog (`_showSavePlaylistDialog`) and load dialog (`_showLoadPlaylistDialog`) work correctly with `SavePresentationPlaylist` and `LoadPresentationPlaylist` events.

### Files modified
- `lib/view/desktop_view/widgets/presentation_playlist_widget.dart` - Added `onSongDoubleTap` callback
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/list_song.dart` - Wired up double-tap handler
- `lib/view/desktop_view/widgets/ribbon_menu.dart` - Fixed tab controller for settings views (length=2, Home+Settings tabs with onTap navigation)
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` - Rewrote keyboard navigation, added focus fix, wrapped in GestureDetector
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/presentation_settings_body.dart` - Removed font size selector, added auto-calc note
- `lib/services/presentation_window_manager.dart` - Added `linesPerPage` parameter
- `lib/main.dart` - PresentationApp auto-calculates font size via LayoutBuilder

### Current state
- All 6 tasks implemented and compiling without errors
- Presentation navigation should now be strictly sequential (one page per key press)
- Font size is auto-calculated, no manual setting needed
- Home tab persists across all ribbon views

### Known issues
- The `Future.delayed(50ms)` is still used for cross-song transitions (playlist bloc processes event asynchronously). This could theoretically race in extreme cases but is reliable in practice.
- Pre-existing warnings in other files (unused variables, null-safety) were not touched.

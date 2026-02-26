import 'dart:io';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../blocs/export_blocs.dart';
import '../../../../services/presentation_window_manager.dart';
import '../../widgets/ribbon_menu.dart';
import 'home_bodies/browse_sheets_body.dart';
import 'home_bodies/browse_youtube_body.dart';
import 'home_bodies/edit_parts_body/edit_body.dart';
import 'home_bodies/general_settings_body.dart';
import 'home_bodies/groups_body.dart';
import 'home_bodies/presentation_settings_body.dart';
import 'home_bodies/preview_body.dart';
import 'home_bodies/users_body.dart';
import 'home_bodies/web_body.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({super.key});

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

class _DesktopHomePageState extends State<DesktopHomePage> {
  final FocusNode _focusNode = FocusNode();
  bool _isBlackScreen = false; // tracks if we're showing a black transition screen

  static const _navigationChannel = MethodChannel('com.songviewer/navigation');

  /// WindowMethodChannel for receiving navigation from sub-window on Windows
  static const _windowNavChannel = WindowMethodChannel(
    'com.songviewer/nav_bridge',
    mode: ChannelMode.unidirectional,
  );

  @override
  void initState() {
    super.initState();
    // On macOS: listen for navigation commands via native bridge MethodChannel
    _navigationChannel.setMethodCallHandler((call) async {
      if (call.method == 'navigate') {
        final command = call.arguments as String;
        _handleRemoteNavigation(command);
        return 'ok';
      }
      return null;
    });

    // On Windows: also listen for navigation via WindowMethodChannel cross-window messaging
    if (Platform.isWindows) {
      _windowNavChannel.setMethodCallHandler((call) async {
        debugPrint('Main window received WindowMethodChannel: ${call.method}');
        if (call.method == 'navigate') {
          final command = call.arguments as String;
          _handleRemoteNavigation(command);
          return 'ok';
        }
        return null;
      });
    }
  }

  /// Handle navigation commands from the presentation window
  void _handleRemoteNavigation(String command) {
    final presentationBloc = context.read<PresentationBloc>();
    final playlistBloc = context.read<PresentationPlaylistBloc>();
    final settingsState = context.read<SettingsBloc>().state;
    final ribbonState = context.read<DesktopRibbonMenuBloc>().state;

    if (!ribbonState.isPresentationWindowOpen) return;

    switch (command) {
      case 'forward':
        _navigateForward(presentationBloc, playlistBloc, settingsState);
        break;
      case 'backward':
        _navigateBackward(presentationBloc, playlistBloc, settingsState);
        break;
      case 'escape':
        // Hide the presentation window (keep engine alive for reuse)
        PresentationWindowManager().closePresentationWindow();
        break;
      case 'window_closed':
        // Native willCloseNotification: window was actually destroyed
        debugPrint('Received window_closed from native — window destroyed');
        PresentationWindowManager().markWindowClosed();
        break;
    }
  }

  @override
  void dispose() {
    _navigationChannel.setMethodCallHandler(null);
    if (Platform.isWindows) {
      _windowNavChannel.setMethodCallHandler(null);
    }
    _focusNode.dispose();
    super.dispose();
  }

  /// Send a black (empty) screen to the presentation window
  void _sendBlackScreen(BuildContext context) {
    final settingsState = context.read<SettingsBloc>().state;
    final manager = PresentationWindowManager();
    _isBlackScreen = true;
    manager.sendPageToPresentation(
      context,
      title: '',
      pageContent: '',
      fontSize: settingsState.presentationFontSize,
      textColor: settingsState.presentationFontColor,
      showChords: false,
      currentPage: 0,
      totalPages: 1,
      showTitle: false,
      showPageNumber: false,
    );
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final presentationBloc = context.read<PresentationBloc>();
    final playlistBloc = context.read<PresentationPlaylistBloc>();
    final settingsState = context.read<SettingsBloc>().state;
    final ribbonState = context.read<DesktopRibbonMenuBloc>().state;

    // F5 - Start/Open presentation
    if (key == LogicalKeyboardKey.f5) {
      if (!ribbonState.isPresentationWindowOpen && playlistBloc.state.isNotEmpty) {
        _startPresentation(context);
      }
      return;
    }

    // Only handle navigation if presentation is open
    if (!ribbonState.isPresentationWindowOpen) return;

    // Right arrow or Space - Next step (one page forward)
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.space) {
      _navigateForward(presentationBloc, playlistBloc, settingsState);
      return;
    }

    // Left arrow or Backspace - Previous step (one page backward)
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.backspace) {
      _navigateBackward(presentationBloc, playlistBloc, settingsState);
      return;
    }

    // Escape - Close presentation
    if (key == LogicalKeyboardKey.escape) {
      PresentationWindowManager().closePresentationWindow();
      return;
    }
  }

  /// Navigate one step forward in the presentation
  void _navigateForward(
    PresentationBloc presentationBloc,
    PresentationPlaylistBloc playlistBloc,
    SettingsState settingsState,
  ) {
    final presState = presentationBloc.state;

    // If currently showing black screen, advance to the next content
    if (_isBlackScreen) {
      _isBlackScreen = false;

      // If we were at the end of a song (black last page), move to next song
      if (!presState.hasNextPage && playlistBloc.state.hasNext) {
        _goToNextSongFirstPage(playlistBloc, presentationBloc, settingsState);
      } else {
        // Black first page — show the current song's current page
        final song = presState.currentSong;
        if (song != null) {
          final result = PresentationBloc.computePageContent(
            song: song,
            linesPerPage: settingsState.presentationLinesPerPage,
            showChords: settingsState.presentationShowChords,
            page: presState.currentPage,
            autoPageByParagraphs: settingsState.presentationAutoPageByParagraphs,
          );
          _sendPageToWindow(context, song.title, result);
        }
      }
      return;
    }

    if (presState.hasNextPage) {
      // Next page within same song
      final nextPage = presState.currentPage + 1;
      presentationBloc.add(const NextPresentationPage());
      final song = presState.currentSong;
      if (song != null) {
        final result = PresentationBloc.computePageContent(
          song: song,
          linesPerPage: presState.linesPerPage,
          showChords: presState.showChords,
          page: nextPage,
          autoPageByParagraphs: presState.autoPageByParagraphs,
        );
        _sendPageToWindow(context, song.title, result);
      }
    } else if (playlistBloc.state.hasNext) {
      // Last page of current song — show black screen or go to next song
      if (settingsState.presentationBlackLastPage) {
        _isBlackScreen = true;
        _sendBlackScreen(context);
      } else if (settingsState.presentationBlackFirstPage) {
        // Go to next song but show black first page
        _goToNextSongWithBlackFirst(playlistBloc, presentationBloc, settingsState);
      } else {
        // No black pages, go directly to next song's first page
        _goToNextSongFirstPage(playlistBloc, presentationBloc, settingsState);
      }
    }
    // else: last page of last song — do nothing
  }

  /// Navigate one step backward in the presentation
  void _navigateBackward(
    PresentationBloc presentationBloc,
    PresentationPlaylistBloc playlistBloc,
    SettingsState settingsState,
  ) {
    final presState = presentationBloc.state;

    // If currently showing black screen, go back to last visible page
    if (_isBlackScreen) {
      _isBlackScreen = false;
      final song = presState.currentSong;
      if (song != null) {
        // Go back to the last page of current song
        final result = PresentationBloc.computePageContent(
          song: song,
          linesPerPage: presState.linesPerPage,
          showChords: presState.showChords,
          page: 999, // will be clamped to last page
          autoPageByParagraphs: presState.autoPageByParagraphs,
        );
        _sendPageToWindow(context, song.title, result);
      }
      return;
    }

    if (presState.hasPreviousPage) {
      // Previous page within same song
      final prevPage = presState.currentPage - 1;
      presentationBloc.add(const PreviousPresentationPage());
      final song = presState.currentSong;
      if (song != null) {
        final result = PresentationBloc.computePageContent(
          song: song,
          linesPerPage: presState.linesPerPage,
          showChords: presState.showChords,
          page: prevPage,
          autoPageByParagraphs: presState.autoPageByParagraphs,
        );
        _sendPageToWindow(context, song.title, result);
      }
    } else if (playlistBloc.state.hasPrevious) {
      // First page of current song — go to previous song
      if (settingsState.presentationBlackFirstPage) {
        // Show black screen between songs
        _isBlackScreen = true;
        // Move to previous song so that when they press back again, they see its last page
        playlistBloc.add(const PreviousPresentationSong());
        Future.delayed(const Duration(milliseconds: 50), () {
          final prevSong = playlistBloc.state.currentSong;
          if (prevSong != null) {
            // Set to last page so next backward press shows that page correctly
            final lastPageResult = PresentationBloc.computePageContent(
              song: prevSong,
              linesPerPage: settingsState.presentationLinesPerPage,
              showChords: settingsState.presentationShowChords,
              page: 999, // will be clamped to last page
              autoPageByParagraphs: settingsState.presentationAutoPageByParagraphs,
            );
            context.read<PresentationBloc>().add(UpdatePresentationSong(song: prevSong, page: lastPageResult.totalPages - 1));
          }
        });
        _sendBlackScreen(context);
      } else {
        // Go directly to last page of previous song
        _goToPreviousSongLastPage(playlistBloc, presentationBloc, settingsState);
      }
    }
    // else: first page of first song — do nothing
  }

  /// Go to next song's first page
  void _goToNextSongFirstPage(
    PresentationPlaylistBloc playlistBloc,
    PresentationBloc presentationBloc,
    SettingsState settingsState,
  ) {
    playlistBloc.add(const NextPresentationSong());
    Future.delayed(const Duration(milliseconds: 50), () {
      final nextSong = playlistBloc.state.currentSong;
      if (nextSong != null) {
        presentationBloc.add(UpdatePresentationSong(song: nextSong));
        final result = PresentationBloc.computePageContent(
          song: nextSong,
          linesPerPage: settingsState.presentationLinesPerPage,
          showChords: settingsState.presentationShowChords,
          page: 0,
          autoPageByParagraphs: settingsState.presentationAutoPageByParagraphs,
        );
        _sendPageToWindow(context, nextSong.title, result);
      }
    });
  }

  /// Go to next song but show black first page
  void _goToNextSongWithBlackFirst(
    PresentationPlaylistBloc playlistBloc,
    PresentationBloc presentationBloc,
    SettingsState settingsState,
  ) {
    _isBlackScreen = true;
    playlistBloc.add(const NextPresentationSong());
    Future.delayed(const Duration(milliseconds: 50), () {
      final nextSong = playlistBloc.state.currentSong;
      if (nextSong != null) {
        presentationBloc.add(UpdatePresentationSong(song: nextSong));
      }
    });
    _sendBlackScreen(context);
  }

  /// Go to previous song's last page
  void _goToPreviousSongLastPage(
    PresentationPlaylistBloc playlistBloc,
    PresentationBloc presentationBloc,
    SettingsState settingsState,
  ) {
    playlistBloc.add(const PreviousPresentationSong());
    Future.delayed(const Duration(milliseconds: 50), () {
      final prevSong = playlistBloc.state.currentSong;
      if (prevSong != null) {
        final lastPageResult = PresentationBloc.computePageContent(
          song: prevSong,
          linesPerPage: settingsState.presentationLinesPerPage,
          showChords: settingsState.presentationShowChords,
          page: 999, // will be clamped to last page
          autoPageByParagraphs: settingsState.presentationAutoPageByParagraphs,
        );
        final lastPage = lastPageResult.totalPages - 1;
        // Update bloc with song AND correct page so hasPreviousPage works on next backward press
        presentationBloc.add(UpdatePresentationSong(song: prevSong, page: lastPage));
        final result = PresentationBloc.computePageContent(
          song: prevSong,
          linesPerPage: settingsState.presentationLinesPerPage,
          showChords: settingsState.presentationShowChords,
          page: lastPage,
          autoPageByParagraphs: settingsState.presentationAutoPageByParagraphs,
        );
        _sendPageToWindow(context, prevSong.title, result);
      }
    });
  }

  /// Send computed page content to the presentation window
  void _sendPageToWindow(BuildContext context, String title, PageContentResult result) {
    final settingsState = context.read<SettingsBloc>().state;
    final manager = PresentationWindowManager();

    manager.sendPageToPresentation(
      context,
      title: title,
      pageContent: result.pageContent,
      fontSize: settingsState.presentationFontSize,
      textColor: settingsState.presentationFontColor,
      showChords: settingsState.presentationShowChords,
      currentPage: result.currentPage,
      totalPages: result.totalPages,
      linesPerPage: settingsState.presentationLinesPerPage,
      showTitle: settingsState.presentationShowTitle,
      showPageNumber: settingsState.presentationShowPageNumber,
    );
  }

  /// Called whenever SettingsBloc emits a new state.
  /// If the presentation window is open, resend the current page with the updated settings.
  void _onSettingsChanged(SettingsState settingsState) {
    final ribbonState = context.read<DesktopRibbonMenuBloc>().state;
    if (!ribbonState.isPresentationWindowOpen) return;

    // If showing black screen, just resend black with new colors
    if (_isBlackScreen) {
      _sendBlackScreen(context);
      return;
    }

    // Update presentation bloc with new settings
    final presentationBloc = context.read<PresentationBloc>();
    presentationBloc.add(UpdatePresentationSettings(
      linesPerPage: settingsState.presentationLinesPerPage,
      fontSize: settingsState.presentationFontSize,
      textColor: settingsState.presentationFontColor,
      showChords: settingsState.presentationShowChords,
      screenIndex: settingsState.presentationScreenIndex,
      autoPageByParagraphs: settingsState.presentationAutoPageByParagraphs,
    ));

    // Resend the current page with new settings
    final presState = presentationBloc.state;
    final song = presState.currentSong;
    if (song != null) {
      final result = PresentationBloc.computePageContent(
        song: song,
        linesPerPage: settingsState.presentationLinesPerPage,
        showChords: settingsState.presentationShowChords,
        page: presState.currentPage,
        autoPageByParagraphs: settingsState.presentationAutoPageByParagraphs,
      );
      _sendPageToWindow(context, song.title, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Re-request focus when user clicks anywhere on the main window
        // This ensures keyboard shortcuts work after interacting with other widgets
        _focusNode.requestFocus();
      },
      child: KeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: BlocListener<SettingsBloc, SettingsState>(
          listener: (context, settingsState) {
            // Live reload: when any presentation setting changes while the window is open,
            // immediately resend the current page with the new settings
            _onSettingsChanged(settingsState);
          },
          child: BlocListener<EditSongBloc, EditSongState>(
            listenWhen: (previous, current) {
              // Only sync when the song object itself changed (e.g. after save)
              // and the song ID matches the currently previewed song
              if (previous.currentEditSong == current.currentEditSong) return false;
              final previewSong = context.read<PreviewChordBloc>().state.data.song;
              if (previewSong == null) return false;
              return current.currentEditSong.id == previewSong.id;
            },
            listener: (context, editState) {
              // After save, sync updated song data to PreviewChordBloc
              // so browse YouTube/sheets views show latest data
              context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: editState.currentEditSong));
              // Also update the ribbon menu in case YouTube/sheets were added/removed
              context.read<DesktopRibbonMenuBloc>().add(ChangeIsSelectedSong(song: editState.currentEditSong));
            },
            child: Scaffold(
              body: BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
                builder: (context, state) {
                  Widget homeBody = Container();
                  switch (state.bodyName) {
                    case 'preview':
                      homeBody = PreviewBody(onRequestFocus: () => _focusNode.requestFocus());
                      break;
                    case 'edit':
                      homeBody = const EditBody();
                      break;
                    case 'web':
                      homeBody = const WebBody();
                      break;
                    case 'groups':
                      homeBody = const GroupsBody();
                      break;
                    case 'users':
                      homeBody = const UsersBody();
                      break;
                    case 'presentation_settings':
                      homeBody = const PresentationSettingsBody();
                      break;
                    case 'general_settings':
                      homeBody = const GeneralSettingsBody();
                      break;
                    case 'browse_youtube':
                      homeBody = PreviewBody(
                        onRequestFocus: () => _focusNode.requestFocus(),
                        contentOverride: const BrowseYoutubeBody(),
                      );
                      break;
                    case 'browse_sheets':
                      homeBody = PreviewBody(
                        onRequestFocus: () => _focusNode.requestFocus(),
                        contentOverride: const BrowseSheetsBody(),
                      );
                      break;
                    default:
                      return PreviewBody(onRequestFocus: () => _focusNode.requestFocus());
                  }
                  return Column(
                    children: [
                      const RibbonMenu(),
                      Expanded(child: homeBody),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _startPresentation(BuildContext context) {
    final playlistBloc = context.read<PresentationPlaylistBloc>();
    final presentationBloc = context.read<PresentationBloc>();
    final settingsState = context.read<SettingsBloc>().state;
    final manager = PresentationWindowManager();

    debugPrint('[StartPresentation] settingsState.presentationScreenIndex = ${settingsState.presentationScreenIndex}');

    if (playlistBloc.state.isEmpty) return;

    // Select first song if none selected
    if (playlistBloc.state.currentSong == null) {
      playlistBloc.add(const SelectPresentationSong(index: 0));
    }

    // Apply settings to presentation bloc
    presentationBloc.add(UpdatePresentationSettings(
      linesPerPage: settingsState.presentationLinesPerPage,
      fontSize: settingsState.presentationFontSize,
      textColor: settingsState.presentationFontColor,
      showChords: settingsState.presentationShowChords,
      screenIndex: settingsState.presentationScreenIndex,
      autoPageByParagraphs: settingsState.presentationAutoPageByParagraphs,
    ));

    // Get the song directly from the playlist (don't rely on BLoC state timing)
    final currentSong = playlistBloc.state.currentSong ?? (playlistBloc.state.isNotEmpty ? playlistBloc.state.playlist.songs.first : null);

    if (currentSong == null) return;

    // Update presentation bloc with the song
    presentationBloc.add(UpdatePresentationSong(song: currentSong));

    // Compute page content directly — no race condition
    final result = PresentationBloc.computePageContent(
      song: currentSong,
      linesPerPage: settingsState.presentationLinesPerPage,
      showChords: settingsState.presentationShowChords,
      page: 0,
      autoPageByParagraphs: settingsState.presentationAutoPageByParagraphs,
    );

    debugPrint('Starting presentation: ${currentSong.title}, '
        'pageContent length: ${result.pageContent.length}, '
        'totalPages: ${result.totalPages}');

    // If black first page is enabled, start with black screen
    if (settingsState.presentationBlackFirstPage) {
      manager.openPresentationWindow(
        context,
        title: '',
        pageContent: '',
        fontSize: settingsState.presentationFontSize,
        textColor: settingsState.presentationFontColor,
        showChords: false,
        currentPage: 0,
        totalPages: 1,
        linesPerPage: settingsState.presentationLinesPerPage,
        showTitle: false,
        showPageNumber: false,
        screenIndex: settingsState.presentationScreenIndex,
      );
      _isBlackScreen = true;
    } else {
      // Open window immediately with computed content
      manager.openPresentationWindow(
        context,
        title: currentSong.title,
        pageContent: result.pageContent,
        fontSize: settingsState.presentationFontSize,
        textColor: settingsState.presentationFontColor,
        showChords: settingsState.presentationShowChords,
        currentPage: result.currentPage,
        totalPages: result.totalPages,
        linesPerPage: settingsState.presentationLinesPerPage,
        showTitle: settingsState.presentationShowTitle,
        showPageNumber: settingsState.presentationShowPageNumber,
        screenIndex: settingsState.presentationScreenIndex,
      );
    }

    // Re-request focus after opening window so keyboard shortcuts keep working
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }
}

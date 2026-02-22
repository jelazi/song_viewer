import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../blocs/export_blocs.dart';
import '../../../../services/presentation_window_manager.dart';
import '../../widgets/ribbon_menu.dart';
import 'home_bodies/edit_parts_body/edit_body.dart';
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

  @override
  void dispose() {
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

    // Right arrow or Space - Next page
    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.space) {
      final presState = presentationBloc.state;

      // If currently showing black screen, advance to next song's first page
      if (_isBlackScreen) {
        _isBlackScreen = false;
        if (playlistBloc.state.hasNext) {
          playlistBloc.add(const NextPresentationSong());
          Future.delayed(const Duration(milliseconds: 50), () {
            final nextSong = playlistBloc.state.currentSong;
            if (nextSong != null) {
              presentationBloc.add(UpdatePresentationSong(song: nextSong));
              if (settingsState.presentationBlackFirstPage) {
                // Show black first page, next press will show content
                _sendBlackScreen(context);
              } else {
                final result = PresentationBloc.computePageContent(
                  song: nextSong,
                  linesPerPage: settingsState.presentationLinesPerPage,
                  showChords: settingsState.presentationShowChords,
                  page: 0,
                );
                _sendPageToWindow(context, nextSong.title, result);
              }
            }
          });
        }
        return;
      }

      if (presState.hasNextPage) {
        // Next page within same song
        presentationBloc.add(const NextPresentationPage());
        // Compute content directly
        final song = presState.currentSong;
        if (song != null) {
          final result = PresentationBloc.computePageContent(
            song: song,
            linesPerPage: presState.linesPerPage,
            showChords: presState.showChords,
            page: presState.currentPage + 1,
          );
          _sendPageToWindow(context, song.title, result);
        }
      } else {
        // Last page of current song - check for black last page
        if (settingsState.presentationBlackLastPage && playlistBloc.state.hasNext) {
          _sendBlackScreen(context);
        } else if (playlistBloc.state.hasNext) {
          // No black page, go directly to next song
          playlistBloc.add(const NextPresentationSong());
          Future.delayed(const Duration(milliseconds: 50), () {
            final nextSong = playlistBloc.state.currentSong;
            if (nextSong != null) {
              presentationBloc.add(UpdatePresentationSong(song: nextSong));
              if (settingsState.presentationBlackFirstPage) {
                _sendBlackScreen(context);
              } else {
                final result = PresentationBloc.computePageContent(
                  song: nextSong,
                  linesPerPage: settingsState.presentationLinesPerPage,
                  showChords: settingsState.presentationShowChords,
                  page: 0,
                );
                _sendPageToWindow(context, nextSong.title, result);
              }
            }
          });
        }
      }
      return;
    }

    // Left arrow or Backspace - Previous page
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.backspace) {
      final presState = presentationBloc.state;

      // If currently showing black screen, go back to the last page of current/previous song
      if (_isBlackScreen) {
        _isBlackScreen = false;
        final song = presState.currentSong;
        if (song != null) {
          // Go back to the last page of current song
          final allLines = PresentationBloc.getLyricsLines(song, presState.showChords);
          final linesPerPage = presState.linesPerPage;
          final totalPages = (allLines.length / linesPerPage).ceil().clamp(1, 999);
          final result = PresentationBloc.computePageContent(
            song: song,
            linesPerPage: linesPerPage,
            showChords: presState.showChords,
            page: totalPages - 1,
          );
          _sendPageToWindow(context, song.title, result);
          presentationBloc.add(UpdatePresentationSettings(linesPerPage: linesPerPage));
        }
        return;
      }

      if (presState.hasPreviousPage) {
        // Previous page within same song
        presentationBloc.add(const PreviousPresentationPage());
        // Compute content directly
        final song = presState.currentSong;
        if (song != null) {
          final result = PresentationBloc.computePageContent(
            song: song,
            linesPerPage: presState.linesPerPage,
            showChords: presState.showChords,
            page: presState.currentPage - 1,
          );
          _sendPageToWindow(context, song.title, result);
        }
      } else {
        // First page of current song - go to previous song
        if (playlistBloc.state.hasPrevious) {
          if (settingsState.presentationBlackFirstPage) {
            // Show black screen before going back
            _sendBlackScreen(context);
          } else {
            playlistBloc.add(const PreviousPresentationSong());
            Future.delayed(const Duration(milliseconds: 50), () {
              final prevSong = playlistBloc.state.currentSong;
              if (prevSong != null) {
                presentationBloc.add(UpdatePresentationSong(song: prevSong));
                // Compute content for last page of previous song
                final allLines = PresentationBloc.getLyricsLines(prevSong, settingsState.presentationShowChords);
                final linesPerPage = settingsState.presentationLinesPerPage;
                final totalPages = (allLines.length / linesPerPage).ceil().clamp(1, 999);
                final result = PresentationBloc.computePageContent(
                  song: prevSong,
                  linesPerPage: linesPerPage,
                  showChords: settingsState.presentationShowChords,
                  page: totalPages - 1,
                );
                _sendPageToWindow(context, prevSong.title, result);
              }
            });
          }
        }
      }
      return;
    }

    // Escape - Close presentation
    if (key == LogicalKeyboardKey.escape) {
      PresentationWindowManager().closePresentationWindow();
      return;
    }
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
      showTitle: settingsState.presentationShowTitle,
      showPageNumber: settingsState.presentationShowPageNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        body: BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
          builder: (context, state) {
            Widget homeBody = Container();
            switch (state.bodyName) {
              case 'preview':
                homeBody = const PreviewBody();
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
              default:
                return const PreviewBody();
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
    );
  }

  void _startPresentation(BuildContext context) {
    final playlistBloc = context.read<PresentationPlaylistBloc>();
    final presentationBloc = context.read<PresentationBloc>();
    final settingsState = context.read<SettingsBloc>().state;
    final manager = PresentationWindowManager();

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
        showTitle: false,
        showPageNumber: false,
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
        showTitle: settingsState.presentationShowTitle,
        showPageNumber: settingsState.presentationShowPageNumber,
      );
    }
  }
}

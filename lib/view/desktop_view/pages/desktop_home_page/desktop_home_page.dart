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

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
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
        // Next song in playlist
        if (playlistBloc.state.hasNext) {
          playlistBloc.add(const NextPresentationSong());
          Future.delayed(const Duration(milliseconds: 50), () {
            final nextSong = playlistBloc.state.currentSong;
            if (nextSong != null) {
              presentationBloc.add(UpdatePresentationSong(song: nextSong));
              // Compute content directly for page 0 of new song
              final result = PresentationBloc.computePageContent(
                song: nextSong,
                linesPerPage: settingsState.presentationLinesPerPage,
                showChords: settingsState.presentationShowChords,
                page: 0,
              );
              _sendPageToWindow(context, nextSong.title, result);
            }
          });
        }
      }
      return;
    }

    // Left arrow or Backspace - Previous page
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.backspace) {
      final presState = presentationBloc.state;
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
        // Previous song in playlist
        if (playlistBloc.state.hasPrevious) {
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
    );
  }
}

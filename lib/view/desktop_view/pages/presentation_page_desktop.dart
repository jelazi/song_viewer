import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';

import '../../../blocs/export_blocs.dart';

class PresentationPageDesktop extends StatefulWidget {
  const PresentationPageDesktop({super.key});

  @override
  State<PresentationPageDesktop> createState() => _PresentationPageDesktopState();
}

class _PresentationPageDesktopState extends State<PresentationPageDesktop> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _checkAndOpenPresentation();
    });
  }

  Future<void> _checkAndOpenPresentation() async {
    final presentationState = context.read<PresentationBloc>().state;
    if (presentationState.currentSong == null) {
      // Try to open presentation from playlist
      context.read<PresentationBloc>().add(const OpenPresentation());
    }
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return;

    final bloc = context.read<PresentationBloc>();

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowRight:
      case LogicalKeyboardKey.space:
        bloc.add(const NextPresentationPage());
        break;
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.backspace:
        bloc.add(const PreviousPresentationPage());
        break;
      case LogicalKeyboardKey.escape:
        bloc.add(const ClosePresentation());
        if (mounted) {
          Navigator.of(context).pop();
        }
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: BlocBuilder<PresentationBloc, PresentationState>(
          builder: (context, state) {
            if (state.currentSong == null) {
              return const Center(
                child: Text(
                  'Žádná píseň není vybrána',
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              );
            }

            return _buildPresentationView(state);
          },
        ),
      ),
    );
  }

  Widget _buildPresentationView(PresentationState state) {
    final song = state.currentSong!;
    final pageContent = state.currentPageContent;
    final settingsState = context.read<SettingsBloc>().state;
    final showTitle = settingsState.presentationShowTitle;
    final showPageNumber = settingsState.presentationShowPageNumber;

    return Stack(
      children: [
        // Main presentation content
        GestureDetector(
          onTap: () {
            // Next page on tap, or close if last page
            if (state.hasNextPage) {
              context.read<PresentationBloc>().add(const NextPresentationPage());
            } else {
              context.read<PresentationBloc>().add(const ClosePresentation());
              if (mounted) {
                Navigator.of(context).pop();
              }
            }
          },
          child: Container(
            color: state.backgroundColor,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page content (no scrolling — fits in page)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: pageContent.split('\n').map((line) {
                        final isChordLine = state.showChords && RegExp(r'\[.*?\]').hasMatch(line);
                        final displayLine = line.replaceAll(RegExp(r'[\[\]]'), '');
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            displayLine,
                            style: TextStyle(
                              color: isChordLine ? state.textColor.withValues(alpha: 0.7) : state.textColor,
                              fontSize: state.fontSize,
                              height: 1.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Bottom bar: title (left) + page number (right)
                if (showTitle || showPageNumber)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (showTitle)
                        Flexible(
                          child: Text(
                            song.title,
                            style: TextStyle(
                              color: state.textColor.withValues(alpha: 0.4),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                      if (showPageNumber)
                        Text(
                          '${state.currentPage + 1} / ${state.totalPages}',
                          style: TextStyle(
                            color: state.textColor.withValues(alpha: 0.4),
                            fontSize: 14,
                          ),
                        )
                      else
                        const SizedBox.shrink(),
                    ],
                  ),
              ],
            ),
          ),
        ),

        // Exit button in top-right corner
        Positioned(
          top: 20,
          right: 20,
          child: IconButton(
            icon: Icon(Icons.close, color: state.textColor.withValues(alpha: 0.7), size: 32),
            onPressed: () {
              context.read<PresentationBloc>().add(const ClosePresentation());
              if (mounted) {
                Navigator.of(context).pop();
              }
            },
            tooltip: 'Zavřít prezentaci (ESC)',
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    // Restore window state when leaving presentation
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.setFullScreen(false);
    }
    super.dispose();
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../../../blocs/export_blocs.dart';

class PresentationPageDesktop extends StatefulWidget {
  const PresentationPageDesktop({super.key});

  @override
  State<PresentationPageDesktop> createState() => _PresentationPageDesktopState();
}

class _PresentationPageDesktopState extends State<PresentationPageDesktop> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndOpenPresentation();
    });
  }

  Future<void> _checkAndOpenPresentation() async {
    final song = context.read<PreviewChordBloc>().state.data.song;
    if (song != null) {
      context.read<PresentationBloc>().add(OpenPresentation(song: song));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocBuilder<PresentationBloc, PresentationState>(
        builder: (context, state) {
          if (state.currentSong == null) {
            return const Center(
              child: Text(
                'No song selected',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            );
          }

          return _buildPresentationView(state);
        },
      ),
    );
  }

  Widget _buildPresentationView(PresentationState state) {
    final song = state.currentSong!;
    final lyricsWithoutChords = song.lyricsWithoutChordsWithLines;

    return Stack(
      children: [
        // Main presentation content
        GestureDetector(
          onTap: () async {
            // Exit presentation
            context.read<PresentationBloc>().add(const ClosePresentation());
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
          child: Container(
            color: state.backgroundColor,
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
            // Song title
            if (song.title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: Text(
                  song.title,
                  style: TextStyle(
                    color: state.textColor,
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Interpret
            if (song.interpret != null && song.interpret!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 50),
                child: Text(
                  song.interpret!,
                  style: TextStyle(
                    color: state.textColor.withOpacity(0.7),
                    fontSize: 32,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Lyrics without chords
            Expanded(
              child: SingleChildScrollView(
                child: Center(
                  child: Text(
                    lyricsWithoutChords,
                    style: TextStyle(
                      color: state.textColor,
                      fontSize: state.fontSize,
                      height: 1.8,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: Text(
                'Tap anywhere to exit presentation',
                style: TextStyle(
                  color: state.textColor.withOpacity(0.5),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
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
        icon: Icon(Icons.close, color: state.textColor.withOpacity(0.7), size: 32),
        onPressed: () async {
          context.read<PresentationBloc>().add(const ClosePresentation());
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
        tooltip: 'Exit presentation (ESC)',
      ),
    ),
      ],
    );
  }

  @override
  void dispose() {
    // Restore window state when leaving presentation
    if (Platform.isLinux || Platform.isWindows || Platform.isMacOS) {
      windowManager.setFullScreen(false);
    }
    super.dispose();
  }
}

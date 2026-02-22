import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../../model/song/song.dart';

part 'presentation_event.dart';
part 'presentation_state.dart';

class PresentationBloc extends Bloc<PresentationEvent, PresentationState> {
  PresentationBloc() : super(const PresentationState()) {
    on<OpenPresentation>(_onOpenPresentation);
    on<ClosePresentation>(_onClosePresentation);
    on<UpdatePresentationSong>(_onUpdatePresentationSong);
    on<ToggleFullScreen>(_onToggleFullScreen);
    on<CheckMonitors>(_onCheckMonitors);
    on<SetBackgroundColor>(_onSetBackgroundColor);
    on<SetTextColor>(_onSetTextColor);
    on<SetFontSize>(_onSetFontSize);
    on<NextPresentationPage>(_onNextPage);
    on<PreviousPresentationPage>(_onPreviousPage);
    on<UpdatePresentationSettings>(_onUpdateSettings);
  }

  /// Split lyrics into lines based on showChords setting
  static List<String> getLyricsLines(Song song, bool showChords) {
    final lines = song.lyrics.split('\n');
    if (showChords) {
      // Return lyrics with chord brackets for display
      return lines.where((line) => line.trim().isNotEmpty).toList();
    } else {
      // Remove chords in brackets
      final result = <String>[];
      for (final line in lines) {
        String cleanLine = line.replaceAll(RegExp(r'\[.*?\]'), '');
        if (cleanLine.trim().isNotEmpty) {
          result.add(cleanLine);
        }
      }
      return result;
    }
  }

  /// Calculate pages and current page lines
  PresentationState _recalculatePages(PresentationState currentState, {Song? newSong, int? newPage}) {
    final song = newSong ?? currentState.currentSong;
    if (song == null) return currentState;

    final allLines = getLyricsLines(song, currentState.showChords);
    final linesPerPage = currentState.linesPerPage;
    final totalPages = (allLines.length / linesPerPage).ceil().clamp(1, 999);
    final page = (newPage ?? currentState.currentPage).clamp(0, totalPages - 1);

    final startIndex = page * linesPerPage;
    final endIndex = (startIndex + linesPerPage).clamp(0, allLines.length);
    final pageLines = allLines.sublist(startIndex, endIndex);

    return currentState.copyWith(
      currentSong: song,
      currentPage: page,
      totalPages: totalPages,
      pageLines: pageLines,
    );
  }

  Future<void> _onOpenPresentation(
    OpenPresentation event,
    Emitter<PresentationState> emit,
  ) async {
    if (!_isDesktopPlatform()) return;

    try {
      final displays = await screenRetriever.getAllDisplays();
      final hasMultiple = displays.length > 1;

      var newState = state.copyWith(
        isPresenting: true,
        hasMultipleMonitors: hasMultiple,
        monitorCount: displays.length,
        primaryDisplay: displays.isNotEmpty ? displays[0] : null,
        secondaryDisplay: displays.length > 1 ? displays[1] : null,
        currentPage: 0,
      );

      // Recalculate pages for current song
      newState = _recalculatePages(newState, newPage: 0);
      emit(newState);

      // Move to selected screen
      final screenIdx = state.screenIndex;
      if (screenIdx < displays.length && event.useSecondaryMonitor) {
        await _moveToMonitor(displays[screenIdx]);
        emit(state.copyWith(isFullScreen: true));
      }
    } catch (e) {
      debugPrint('Error opening presentation: $e');
    }
  }

  Future<void> _onClosePresentation(
    ClosePresentation event,
    Emitter<PresentationState> emit,
  ) async {
    if (!_isDesktopPlatform()) return;

    try {
      if (state.isFullScreen) {
        await windowManager.setFullScreen(false);
      }

      emit(state.copyWith(
        isPresenting: false,
        isFullScreen: false,
        currentPage: 0,
      ));
    } catch (e) {
      debugPrint('Error closing presentation: $e');
    }
  }

  void _onUpdatePresentationSong(
    UpdatePresentationSong event,
    Emitter<PresentationState> emit,
  ) {
    final newState = _recalculatePages(state, newSong: event.song, newPage: 0);
    emit(newState);
  }

  Future<void> _onToggleFullScreen(
    ToggleFullScreen event,
    Emitter<PresentationState> emit,
  ) async {
    if (!_isDesktopPlatform()) return;

    try {
      final newFullScreenState = !state.isFullScreen;
      await windowManager.setFullScreen(newFullScreenState);
      emit(state.copyWith(isFullScreen: newFullScreenState));
    } catch (e) {
      debugPrint('Error toggling fullscreen: $e');
    }
  }

  Future<void> _onCheckMonitors(
    CheckMonitors event,
    Emitter<PresentationState> emit,
  ) async {
    if (!_isDesktopPlatform()) return;

    try {
      final displays = await screenRetriever.getAllDisplays();
      emit(state.copyWith(
        hasMultipleMonitors: displays.length > 1,
        monitorCount: displays.length,
        primaryDisplay: displays.isNotEmpty ? displays[0] : null,
        secondaryDisplay: displays.length > 1 ? displays[1] : null,
      ));
    } catch (e) {
      debugPrint('Error checking monitors: $e');
    }
  }

  void _onSetBackgroundColor(
    SetBackgroundColor event,
    Emitter<PresentationState> emit,
  ) {
    emit(state.copyWith(backgroundColor: event.color));
  }

  void _onSetTextColor(
    SetTextColor event,
    Emitter<PresentationState> emit,
  ) {
    emit(state.copyWith(textColor: event.color));
  }

  void _onSetFontSize(
    SetFontSize event,
    Emitter<PresentationState> emit,
  ) {
    emit(state.copyWith(fontSize: event.fontSize));
  }

  void _onNextPage(
    NextPresentationPage event,
    Emitter<PresentationState> emit,
  ) {
    if (state.hasNextPage) {
      final newState = _recalculatePages(state, newPage: state.currentPage + 1);
      emit(newState);
    }
  }

  void _onPreviousPage(
    PreviousPresentationPage event,
    Emitter<PresentationState> emit,
  ) {
    if (state.hasPreviousPage) {
      final newState = _recalculatePages(state, newPage: state.currentPage - 1);
      emit(newState);
    }
  }

  void _onUpdateSettings(
    UpdatePresentationSettings event,
    Emitter<PresentationState> emit,
  ) {
    var newState = state;
    if (event.linesPerPage != null) {
      newState = newState.copyWith(linesPerPage: event.linesPerPage);
    }
    if (event.fontSize != null) {
      newState = newState.copyWith(fontSize: event.fontSize);
    }
    if (event.textColor != null) {
      newState = newState.copyWith(textColor: event.textColor);
    }
    if (event.showChords != null) {
      newState = newState.copyWith(showChords: event.showChords);
    }
    if (event.screenIndex != null) {
      newState = newState.copyWith(screenIndex: event.screenIndex);
    }
    // Recalculate pages with new settings
    newState = _recalculatePages(newState);
    emit(newState);
  }

  Future<void> _moveToMonitor(Display display) async {
    try {
      await windowManager.setPosition(
        Offset(
          display.visiblePosition!.dx,
          display.visiblePosition!.dy,
        ),
      );

      await windowManager.setSize(
        Size(
          display.size.width,
          display.size.height,
        ),
      );

      await windowManager.setFullScreen(true);
    } catch (e) {
      debugPrint('Error moving to monitor: $e');
    }
  }

  bool _isDesktopPlatform() {
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }

  /// Compute page content directly from song and settings (no BLoC state dependency)
  static PageContentResult computePageContent({
    required Song song,
    required int linesPerPage,
    required bool showChords,
    int page = 0,
  }) {
    final allLines = getLyricsLines(song, showChords);
    final totalPages = (allLines.length / linesPerPage).ceil().clamp(1, 999);
    final clampedPage = page.clamp(0, totalPages - 1);
    final startIndex = clampedPage * linesPerPage;
    final endIndex = (startIndex + linesPerPage).clamp(0, allLines.length);
    final pageLines = allLines.sublist(startIndex, endIndex);

    return PageContentResult(
      pageContent: pageLines.join('\n'),
      currentPage: clampedPage,
      totalPages: totalPages,
    );
  }
}

/// Result of computing page content directly
class PageContentResult {
  final String pageContent;
  final int currentPage;
  final int totalPages;

  const PageContentResult({
    required this.pageContent,
    required this.currentPage,
    required this.totalPages,
  });
}

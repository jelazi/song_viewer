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
  }

  Future<void> _onOpenPresentation(
    OpenPresentation event,
    Emitter<PresentationState> emit,
  ) async {
    if (!_isDesktopPlatform()) return;

    try {
      // Check for multiple monitors
      final displays = await screenRetriever.getAllDisplays();
      final hasMultiple = displays.length > 1;

      emit(state.copyWith(
        currentSong: event.song,
        isPresenting: true,
        hasMultipleMonitors: hasMultiple,
        monitorCount: displays.length,
        primaryDisplay: displays.isNotEmpty ? displays[0] : null,
        secondaryDisplay: displays.length > 1 ? displays[1] : null,
      ));

      // If multiple monitors and user wants to use secondary
      if (hasMultiple && event.useSecondaryMonitor && displays.length > 1) {
        await _moveToSecondaryMonitor(displays[1]);
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
      ));
    } catch (e) {
      debugPrint('Error closing presentation: $e');
    }
  }

  void _onUpdatePresentationSong(
    UpdatePresentationSong event,
    Emitter<PresentationState> emit,
  ) {
    emit(state.copyWith(currentSong: event.song));
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

  Future<void> _moveToSecondaryMonitor(Display display) async {
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
      debugPrint('Error moving to secondary monitor: $e');
    }
  }

  bool _isDesktopPlatform() {
    return Platform.isLinux || Platform.isWindows || Platform.isMacOS;
  }
}

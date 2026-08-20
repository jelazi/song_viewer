import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../../model/song/song.dart';

part 'desktop_ribbon_menu_event.dart';
part 'desktop_ribbon_menu_state.dart';

class DesktopRibbonMenuBloc extends Bloc<DesktopRibbonMenuEvent, DesktopRibbonMenuState> {
  DesktopRibbonMenuBloc()
      : super(const DesktopRibbonMenuInitial(
          bodyName: 'preview',
          bodyEditName: 'lyrics',
          isSelectedSong: false,
          isPresentationWindowOpen: false,
        )) {
    on<ChangeHomeBody>(_changeHomeBody);
    on<ChangeEditBody>(_changeEditBody);
    on<ChangeIsSelectedSong>(_changeIsSelectedSong);
    on<ChangePresentationWindowState>(_changePresentationWindowState);
  }

  void _changeHomeBody(ChangeHomeBody event, Emitter<DesktopRibbonMenuState> emit) {
    emit(state.copyWith(bodyName: event.bodyName));
  }

  void _changeEditBody(ChangeEditBody event, Emitter<DesktopRibbonMenuState> emit) {
    emit(state.copyWith(bodyEditName: event.bodyName));
  }

  void _changeIsSelectedSong(ChangeIsSelectedSong event, Emitter<DesktopRibbonMenuState> emit) {
    final song = event.song;
    String bodyName = state.bodyName;

    // Auto-switch back to preview if the new song doesn't have the required data
    if (song != null) {
      if (bodyName == 'browse_youtube' && (song.youtubeVideos?.isEmpty ?? true)) {
        bodyName = 'preview';
      } else if (bodyName == 'browse_sheets' && (song.sheets?.isEmpty ?? true)) {
        bodyName = 'preview';
      }
    } else {
      // No song selected — go back to preview
      if (bodyName == 'browse_youtube' || bodyName == 'browse_sheets') {
        bodyName = 'preview';
      }
    }

    emit(state.copyWith(isSelectedSong: song != null, bodyName: bodyName));
  }

  void _changePresentationWindowState(ChangePresentationWindowState event, Emitter<DesktopRibbonMenuState> emit) {
    emit(state.copyWith(isPresentationWindowOpen: event.isOpen));
  }
}

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import '../../model/song/song.dart';

part 'desktop_ribbon_menu_event.dart';
part 'desktop_ribbon_menu_state.dart';

class DesktopRibbonMenuBloc extends Bloc<DesktopRibbonMenuEvent, DesktopRibbonMenuState> {
  DesktopRibbonMenuBloc()
      : super(const DesktopRibbonMenuInitial(
          bodyName: 'preview',
          bodyEditName: 'lyrics',
          isSelectedSong: false,
        )) {
    on<ChangeHomeBody>(_changeHomeBody);
    on<ChangeEditBody>(_changeEditBody);
    on<ChangeIsSelectedSong>(_changeIsSelectedSong);
  }

  void _changeHomeBody(ChangeHomeBody event, Emitter<DesktopRibbonMenuState> emit) {
    emit(state.copyWith(bodyName: event.bodyName));
  }

  void _changeEditBody(ChangeEditBody event, Emitter<DesktopRibbonMenuState> emit) {
    emit(state.copyWith(bodyEditName: event.bodyName));
  }

  void _changeIsSelectedSong(ChangeIsSelectedSong event, Emitter<DesktopRibbonMenuState> emit) {
    emit(state.copyWith(isSelectedSong: event.song != null));
  }
}

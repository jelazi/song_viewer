// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:default_project/services/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsRepository settingsRepository;
  SongsRepository songsRepository;
  SettingsBloc({
    required this.settingsRepository,
    required this.songsRepository,
  }) : super(const SettingsInitial(
          previewFontTextSize: 20,
          previewFontChordSize: 20,
          editFontTextSize: 20,
          editFontChordSize: 20,
          previewColorText: Colors.black,
          previewColorChord: Colors.red,
          editColorText: Colors.black,
          editColorChord: Colors.red,
          isEditIconVisible: false,
          autoHideTopBar: false,
          typeClickCard: TypeClickCard.none,
          presentationScreenIndex: 0,
          presentationLinesPerPage: 8,
          presentationFontSize: 36.0,
          presentationFontColor: Colors.white,
          presentationShowChords: false,
          presentationBlackFirstPage: true,
          presentationBlackLastPage: true,
          presentationShowPageNumber: true,
          presentationShowTitle: true,
          presentationAutoPageByParagraphs: false,
          qrCurrentSongUrl: 'https://your-site.example/',
          qrWebAppUrl: 'https://songsviewerweb.web.app/',
        )) {
    on<_SettingsInitial>(_settingsInitial);
    on<ChangeSettingsValue>(_changeSettingsValue);

    add(_SettingsInitial());
  }

  void _settingsInitial(_SettingsInitial event, Emitter<SettingsState> emit) {
    final state = this.state;
    _emitAllValues(state, emit);
  }

  void _changeSettingsValue(ChangeSettingsValue event, Emitter<SettingsState> emit) {
    debugPrint('[SettingsBloc] changeSettingsValue: ${event.typeValue} = ${event.value}');
    final state = this.state;
    settingsRepository.changeSettingsValue(event.typeValue, event.value);
    debugPrint('[SettingsBloc] repo.presentationScreenIndex after change: ${settingsRepository.presentationScreenIndex}');
    _emitAllValues(state, emit);
  }

  void _emitAllValues(
    SettingsState state,
    Emitter<SettingsState> emit,
  ) {
    emit(state.copyWith(
      previewFontTextSize: settingsRepository.previewFontTextSize,
      previewFontChordSize: settingsRepository.previewFontChordSize,
      previewColorText: settingsRepository.previewColorText,
      previewColorChord: settingsRepository.previewColorChord,
      editFontTextSize: settingsRepository.editFontTextSize,
      editFontChordSize: settingsRepository.editFontChordSize,
      editColorText: settingsRepository.editColorText,
      editColorChord: settingsRepository.editColorChord,
      isEditIconVisible: settingsRepository.isEditIconVisible,
      autoHideTopBar: settingsRepository.autoHideTopBar,
      typeClickCard: settingsRepository.typeClickCard,
      presentationScreenIndex: settingsRepository.presentationScreenIndex,
      presentationLinesPerPage: settingsRepository.presentationLinesPerPage,
      presentationFontSize: settingsRepository.presentationFontSize,
      presentationFontColor: settingsRepository.presentationFontColor,
      presentationShowChords: settingsRepository.presentationShowChords,
      presentationBlackFirstPage: settingsRepository.presentationBlackFirstPage,
      presentationBlackLastPage: settingsRepository.presentationBlackLastPage,
      presentationShowPageNumber: settingsRepository.presentationShowPageNumber,
      presentationShowTitle: settingsRepository.presentationShowTitle,
      presentationAutoPageByParagraphs: settingsRepository.presentationAutoPageByParagraphs,
      qrCurrentSongUrl: settingsRepository.qrCurrentSongUrl,
      qrWebAppUrl: settingsRepository.qrWebAppUrl,
    ));
  }
}

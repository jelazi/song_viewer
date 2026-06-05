// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'dart:async';

import 'package:default_project/model/qr_link.dart';
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
          superuserMode: false,
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
          qrLinks: [
            QrLink(label: 'Current Song', url: 'https://your-site.example/'),
            QrLink(label: 'Web App', url: 'https://songsviewerweb.web.app/'),
            QrLink(label: 'Žižkovi', url: 'https://www.zizkovi.online/'),
          ],
          groqApiKey: '',
          youtubeApiKey: '',
          geminiApiKey: '',
        )) {
    on<_SettingsInitial>(_settingsInitial);
    on<ChangeSettingsValue>(_changeSettingsValue);
    on<AddQrLink>(_addQrLink);
    on<UpdateQrLink>(_updateQrLink);
    on<RemoveQrLink>(_removeQrLink);
    on<SyncQrLinksFromServer>(_syncQrLinksFromServer);

    add(_SettingsInitial());

    // Listen to PocketBase QR links changes
    _qrLinksSubscription = settingsRepository.pocketBaseProvider.qrLinksStream.listen((links) {
      add(SyncQrLinksFromServer(links));
    });
  }

  StreamSubscription<List<QrLink>>? _qrLinksSubscription;

  @override
  Future<void> close() {
    _qrLinksSubscription?.cancel();
    return super.close();
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

  void _addQrLink(AddQrLink event, Emitter<SettingsState> emit) {
    settingsRepository.addQrLink(QrLink(label: event.label, url: event.url));
    _emitAllValues(state, emit);
  }

  void _updateQrLink(UpdateQrLink event, Emitter<SettingsState> emit) {
    settingsRepository.updateQrLink(event.index, QrLink(label: event.label, url: event.url));
    _emitAllValues(state, emit);
  }

  void _removeQrLink(RemoveQrLink event, Emitter<SettingsState> emit) {
    settingsRepository.removeQrLink(event.index);
    _emitAllValues(state, emit);
  }

  void _syncQrLinksFromServer(SyncQrLinksFromServer event, Emitter<SettingsState> emit) {
    settingsRepository.setQrLinks(event.links);
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
      superuserMode: settingsRepository.superuserMode,
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
      qrLinks: settingsRepository.qrLinks,
      groqApiKey: settingsRepository.groqApiKey,
      youtubeApiKey: settingsRepository.youtubeApiKey,
      geminiApiKey: settingsRepository.geminiApiKey,
    ));
  }
}

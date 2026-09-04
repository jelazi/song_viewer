import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../../repositories/settings_repository.dart';
import '../../services/local_web/local_web_addresses.dart';
import '../../services/local_web/local_web_server.dart';

part 'local_web_event.dart';
part 'local_web_state.dart';

/// Drives the built-in web server that shows the current song to phones on the
/// same network.
class LocalWebBloc extends Bloc<LocalWebEvent, LocalWebState> {
  final LocalWebServer localWebServer;
  final SettingsRepository settingsRepository;

  LocalWebBloc({
    required this.localWebServer,
    required this.settingsRepository,
  }) : super(const LocalWebState()) {
    on<InitLocalWeb>(_init);
    on<StartLocalWeb>(_start);
    on<StopLocalWeb>(_stop);
    on<ChangeLocalWebPort>(_changePort);
    on<RefreshLocalWebAddresses>(_refreshAddresses);

    add(const InitLocalWeb());
  }

  Future<void> _init(InitLocalWeb event, Emitter<LocalWebState> emit) async {
    emit(state.copyWith(
      port: settingsRepository.localWebPort,
      addresses: await localWebServer.addresses(),
    ));

    if (settingsRepository.localWebEnabled) {
      await _startServer(emit);
    }
  }

  Future<void> _start(StartLocalWeb event, Emitter<LocalWebState> emit) async {
    if (state.isRunning || state.isBusy) return;
    await _startServer(emit);
    if (state.isRunning) {
      settingsRepository.changeSettingsValue('localWebEnabled', true);
    }
  }

  Future<void> _stop(StopLocalWeb event, Emitter<LocalWebState> emit) async {
    if (!state.isRunning) return;
    emit(state.copyWith(isBusy: true));
    await localWebServer.stop();
    settingsRepository.changeSettingsValue('localWebEnabled', false);
    emit(state.copyWith(isRunning: false, isBusy: false, errorKey: ''));
  }

  Future<void> _changePort(ChangeLocalWebPort event, Emitter<LocalWebState> emit) async {
    if (event.port < 1024 || event.port > 65535) {
      emit(state.copyWith(errorKey: 'localWebErrorPortRange'));
      return;
    }
    if (event.port == state.port) return;

    settingsRepository.changeSettingsValue('localWebPort', event.port);
    final wasRunning = state.isRunning;

    if (wasRunning) {
      emit(state.copyWith(isBusy: true));
      await localWebServer.stop();
      emit(state.copyWith(isRunning: false, isBusy: false));
    }

    emit(state.copyWith(port: event.port, errorKey: ''));

    if (wasRunning) {
      await _startServer(emit);
    }
  }

  Future<void> _refreshAddresses(RefreshLocalWebAddresses event, Emitter<LocalWebState> emit) async {
    emit(state.copyWith(addresses: await localWebServer.addresses()));
  }

  Future<void> _startServer(Emitter<LocalWebState> emit) async {
    emit(state.copyWith(isBusy: true, errorKey: ''));
    try {
      await localWebServer.start(port: state.port);
      emit(state.copyWith(
        isRunning: true,
        isBusy: false,
        addresses: await localWebServer.addresses(),
      ));
    } on SocketException catch (e) {
      logger.e('Local web server could not bind port ${state.port}: $e');
      emit(state.copyWith(isRunning: false, isBusy: false, errorKey: 'localWebErrorPortBusy'));
    } catch (e) {
      logger.e('Local web server failed to start: $e');
      emit(state.copyWith(isRunning: false, isBusy: false, errorKey: 'localWebErrorGeneric'));
    }
  }

  @override
  Future<void> close() async {
    await localWebServer.stop();
    return super.close();
  }
}

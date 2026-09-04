part of 'local_web_bloc.dart';

abstract class LocalWebEvent extends Equatable {
  const LocalWebEvent();

  @override
  List<Object?> get props => [];
}

/// Reads the stored settings and starts the server when it is enabled.
class InitLocalWeb extends LocalWebEvent {
  const InitLocalWeb();
}

class StartLocalWeb extends LocalWebEvent {
  const StartLocalWeb();
}

class StopLocalWeb extends LocalWebEvent {
  const StopLocalWeb();
}

class ChangeLocalWebPort extends LocalWebEvent {
  final int port;

  const ChangeLocalWebPort(this.port);

  @override
  List<Object?> get props => [port];
}

/// Re-reads the machine's addresses, which change when the Wi-Fi does.
class RefreshLocalWebAddresses extends LocalWebEvent {
  const RefreshLocalWebAddresses();
}

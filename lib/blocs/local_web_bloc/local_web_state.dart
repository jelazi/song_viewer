part of 'local_web_bloc.dart';

class LocalWebState extends Equatable {
  final bool isRunning;
  final bool isBusy;
  final int port;
  final List<LocalWebAddress> addresses;
  final String errorKey;

  const LocalWebState({
    this.isRunning = false,
    this.isBusy = false,
    this.port = LocalWebServer.defaultPort,
    this.addresses = const [],
    this.errorKey = '',
  });

  /// The address a QR code should carry — the first private IPv4 the machine
  /// has. Empty while the server is stopped or the machine is off any network.
  String get primaryUrl => isRunning && addresses.isNotEmpty ? addresses.first.url(port) : '';

  bool get hasError => errorKey.isNotEmpty;

  LocalWebState copyWith({
    bool? isRunning,
    bool? isBusy,
    int? port,
    List<LocalWebAddress>? addresses,
    String? errorKey,
  }) {
    return LocalWebState(
      isRunning: isRunning ?? this.isRunning,
      isBusy: isBusy ?? this.isBusy,
      port: port ?? this.port,
      addresses: addresses ?? this.addresses,
      errorKey: errorKey ?? this.errorKey,
    );
  }

  @override
  List<Object?> get props => [isRunning, isBusy, port, addresses, errorKey];
}

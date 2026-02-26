import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// TCP localhost bridge for main ↔ sub-window communication on Windows.
///
/// The `desktop_multi_window` v0.3.0 `WindowMethodChannel` / `WindowController.invokeMethod`
/// system does NOT work reliably on Windows (CHANNEL_UNREGISTERED error).
/// This bridge uses a localhost TCP socket with line-delimited JSON as a
/// reliable alternative for cross-window messaging.
///
/// Usage:
///   Main window: `startServer()` → pass port in window arguments → `send(method, data)`
///   Sub-window:  `connectToServer(port)` → listen via `onMessage` → `send(method, data)`
class PresentationBridge {
  // Singleton
  static final PresentationBridge _instance = PresentationBridge._();
  factory PresentationBridge() => _instance;
  PresentationBridge._();

  // ── Server side (main window) ──
  ServerSocket? _server;
  Socket? _clientSocket;

  // ── Client side (sub-window) ──
  Socket? _socket;

  // ── Subscriptions ──
  StreamSubscription? _serverSubscription;
  StreamSubscription? _socketSubscription;

  /// Called when a message arrives from the other window.
  void Function(String method, dynamic data)? onMessage;

  /// Start TCP server on localhost (main window).
  /// Returns the port number to pass to the sub-window via window arguments.
  Future<int> startServer() async {
    // Clean up any previous server
    await stop();

    _server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    debugPrint('[PresentationBridge] Server started on port ${_server!.port}');

    _serverSubscription = _server!.listen(
      (socket) {
        debugPrint('[PresentationBridge] Sub-window connected');
        _clientSocket = socket;
        _listenToSocket(socket);
      },
      onError: (e) {
        debugPrint('[PresentationBridge] Server error: $e');
      },
    );

    return _server!.port;
  }

  /// Connect to the TCP server (sub-window).
  /// [port] is the port received from window arguments.
  Future<void> connectToServer(int port) async {
    try {
      _socket = await Socket.connect(InternetAddress.loopbackIPv4, port);
      debugPrint('[PresentationBridge] Connected to server on port $port');
      _listenToSocket(_socket!);
    } catch (e) {
      debugPrint('[PresentationBridge] Failed to connect to port $port: $e');
      rethrow;
    }
  }

  void _listenToSocket(Socket socket) {
    _socketSubscription?.cancel();
    _socketSubscription = socket.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()).listen(
      (line) {
        try {
          final msg = jsonDecode(line) as Map<String, dynamic>;
          final method = msg['method'] as String;
          final data = msg['data'];
          debugPrint('[PresentationBridge] Received: $method');
          onMessage?.call(method, data);
        } catch (e) {
          debugPrint('[PresentationBridge] Error parsing message: $e');
        }
      },
      onDone: () {
        debugPrint('[PresentationBridge] Connection closed');
        _clientSocket = null;
        _socket = null;
      },
      onError: (e) {
        debugPrint('[PresentationBridge] Socket error: $e');
      },
    );
  }

  /// Send a message to the other window.
  /// Works from both main window (to sub) and sub-window (to main).
  void send(String method, [dynamic data]) {
    final socket = _clientSocket ?? _socket;
    if (socket == null) {
      debugPrint('[PresentationBridge] No connection, cannot send: $method');
      return;
    }
    try {
      final message = jsonEncode({'method': method, 'data': data});
      socket.writeln(message);
    } catch (e) {
      debugPrint('[PresentationBridge] Error sending $method: $e');
    }
  }

  /// Whether the bridge has an active connection.
  bool get isConnected => (_clientSocket ?? _socket) != null;

  /// Stop server and close all connections.
  Future<void> stop() async {
    _socketSubscription?.cancel();
    _socketSubscription = null;
    _serverSubscription?.cancel();
    _serverSubscription = null;

    try {
      await _clientSocket?.close();
    } catch (_) {}
    try {
      await _socket?.close();
    } catch (_) {}
    try {
      await _server?.close();
    } catch (_) {}

    _clientSocket = null;
    _socket = null;
    _server = null;
    onMessage = null;
    debugPrint('[PresentationBridge] Stopped');
  }
}

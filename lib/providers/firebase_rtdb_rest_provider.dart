import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:logger_pkg/logger_pkg.dart';

/// A REST/SSE client for Firebase Realtime Database.
/// Used on platforms where the native `firebase_database` package is not
/// supported (e.g. Windows).
///
/// REST API: https://firebase.google.com/docs/reference/rest/database
/// SSE: https://firebase.google.com/docs/database/rest/retrieve-data#section-rest-streaming
class FirebaseRtdbRestProvider {
  final String databaseUrl;
  final Future<String?> Function() getAuthToken;
  final Map<String, _SseSubscription> _sseSubscriptions = {};

  FirebaseRtdbRestProvider({
    required this.databaseUrl,
    required this.getAuthToken,
  });

  /// Build the full URL for a given RTDB path.
  String _buildUrl(String path) {
    final cleanPath = path.replaceAll(RegExp(r'^/+|/+$'), '');
    return '$databaseUrl/$cleanPath.json';
  }

  /// Build URL with auth query parameter.
  Future<String> _buildAuthUrl(String path) async {
    final token = await getAuthToken();
    final url = _buildUrl(path);
    return token != null ? '$url?auth=$token' : url;
  }

  // ---------------------------------------------------------------------------
  // REST operations
  // ---------------------------------------------------------------------------

  /// GET — Read data from a path.
  Future<dynamic> get(String path) async {
    try {
      final url = await _buildAuthUrl(path);
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final response = await request.close();
      final body = await response.transform(utf8.decoder).join();
      client.close();
      return jsonDecode(body);
    } catch (e) {
      logger.e('RTDB REST GET error ($path): $e');
      return null;
    }
  }

  /// PUT — Set (overwrite) data at a path.
  Future<void> set(String path, dynamic data) async {
    try {
      final url = await _buildAuthUrl(path);
      final client = HttpClient();
      final request = await client.putUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
      final response = await request.close();
      await response.drain();
      client.close();
      logger.d('RTDB REST PUT ($path) → ${response.statusCode}');
    } catch (e) {
      logger.e('RTDB REST PUT error ($path): $e');
    }
  }

  /// PATCH — Update specific fields at a path.
  Future<void> update(String path, Map<String, dynamic> data) async {
    try {
      final url = await _buildAuthUrl(path);
      final client = HttpClient();
      final request = await client.patchUrl(Uri.parse(url));
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(data));
      final response = await request.close();
      await response.drain();
      client.close();
      logger.d('RTDB REST PATCH ($path) → ${response.statusCode}');
    } catch (e) {
      logger.e('RTDB REST PATCH error ($path): $e');
    }
  }

  /// DELETE — Remove data at a path.
  Future<void> delete(String path) async {
    try {
      final url = await _buildAuthUrl(path);
      final client = HttpClient();
      final request = await client.deleteUrl(Uri.parse(url));
      final response = await request.close();
      await response.drain();
      client.close();
      logger.d('RTDB REST DELETE ($path) → ${response.statusCode}');
    } catch (e) {
      logger.e('RTDB REST DELETE error ($path): $e');
    }
  }

  // ---------------------------------------------------------------------------
  // SSE (Server-Sent Events) streaming
  // ---------------------------------------------------------------------------

  /// Listen to real-time changes at [path] via SSE.
  ///
  /// Returns a **broadcast** stream that emits the latest data map whenever the
  /// server pushes a `put` or `patch` event. The connection is automatically
  /// re-established on errors or disconnects (with exponential back-off).
  Stream<Map<String, dynamic>?> listen(String path) {
    if (_sseSubscriptions.containsKey(path)) {
      return _sseSubscriptions[path]!.stream;
    }

    final controller = StreamController<Map<String, dynamic>?>.broadcast(
      onCancel: () {
        // If all listeners are gone, optionally stop the SSE connection
        // For now we keep it alive — call stopListening() explicitly
      },
    );

    final sub = _SseSubscription(controller: controller, path: path);
    _sseSubscriptions[path] = sub;

    _startSseConnection(sub);

    return controller.stream;
  }

  Future<void> _startSseConnection(_SseSubscription sub) async {
    if (sub.controller.isClosed) return;

    try {
      final token = await getAuthToken();
      final url = _buildUrl(sub.path);
      final uri = Uri.parse(token != null ? '$url?auth=$token' : url);

      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();

      if (response.statusCode != 200) {
        final body = await response.transform(utf8.decoder).join();
        logger.e('SSE connection failed for ${sub.path}: HTTP ${response.statusCode} — $body');
        client.close();
        _scheduleReconnect(sub);
        return;
      }

      logger.i('SSE connected for ${sub.path}');
      sub.resetRetryDelay();
      sub.httpClient = client;

      String buffer = '';
      String currentEvent = '';
      String currentData = '';

      response.transform(utf8.decoder).listen(
        (chunk) {
          buffer += chunk;
          final lines = buffer.split('\n');
          // Keep the last potentially-incomplete line in the buffer
          buffer = lines.removeLast();

          for (final line in lines) {
            if (line.startsWith('event: ')) {
              currentEvent = line.substring(7).trim();
            } else if (line.startsWith('data: ')) {
              currentData += line.substring(6);
            } else if (line.isEmpty && currentEvent.isNotEmpty) {
              _handleSseEvent(sub, currentEvent, currentData.trim());
              currentEvent = '';
              currentData = '';
            }
          }
        },
        onError: (error) {
          logger.e('SSE stream error for ${sub.path}: $error');
          client.close();
          _scheduleReconnect(sub);
        },
        onDone: () {
          logger.i('SSE stream closed for ${sub.path}');
          client.close();
          _scheduleReconnect(sub);
        },
        cancelOnError: false,
      );
    } catch (e) {
      logger.e('SSE connection error for ${sub.path}: $e');
      _scheduleReconnect(sub);
    }
  }

  void _handleSseEvent(_SseSubscription sub, String event, String data) {
    if (sub.controller.isClosed) return;

    switch (event) {
      case 'put':
      case 'patch':
        if (data == 'null' || data.isEmpty) {
          sub.controller.add(null);
        } else {
          try {
            final json = jsonDecode(data);
            if (json is Map<String, dynamic>) {
              // Firebase SSE wraps data: {"path": "/", "data": { ... }}
              final innerData = json['data'];
              if (innerData is Map) {
                sub.controller.add(Map<String, dynamic>.from(innerData));
              } else if (innerData == null) {
                sub.controller.add(null);
              } else {
                // Scalar or list at path root
                sub.controller.add(<String, dynamic>{'_value': innerData});
              }
            }
          } catch (e) {
            logger.e('SSE parse error for ${sub.path}: $e (raw: $data)');
          }
        }
        break;
      case 'keep-alive':
        // Keep-alive signals — nothing to do
        break;
      case 'cancel':
        logger.w('SSE cancel event for ${sub.path}');
        break;
      case 'auth_revoked':
        logger.w('SSE auth_revoked for ${sub.path} — will reconnect with fresh token');
        _scheduleReconnect(sub, immediate: true);
        break;
      default:
        logger.d('SSE unknown event "$event" for ${sub.path}');
    }
  }

  void _scheduleReconnect(_SseSubscription sub, {bool immediate = false}) {
    if (sub.controller.isClosed) return;

    final delay = immediate ? Duration.zero : sub.nextRetryDelay();
    logger.i('SSE will reconnect ${sub.path} in ${delay.inSeconds}s');

    sub.reconnectTimer?.cancel();
    sub.reconnectTimer = Timer(delay, () => _startSseConnection(sub));
  }

  /// Stop listening to a specific path.
  void stopListening(String path) {
    final sub = _sseSubscriptions.remove(path);
    if (sub != null) {
      sub.reconnectTimer?.cancel();
      sub.httpClient?.close(force: true);
      if (!sub.controller.isClosed) sub.controller.close();
    }
  }

  /// Dispose all SSE connections and clean up.
  void dispose() {
    for (final sub in _sseSubscriptions.values) {
      sub.reconnectTimer?.cancel();
      sub.httpClient?.close(force: true);
      if (!sub.controller.isClosed) sub.controller.close();
    }
    _sseSubscriptions.clear();
  }
}

// -----------------------------------------------------------------------------
// Internal helpers
// -----------------------------------------------------------------------------

class _SseSubscription {
  final StreamController<Map<String, dynamic>?> controller;
  final String path;
  HttpClient? httpClient;
  Timer? reconnectTimer;
  int _retryCount = 0;

  _SseSubscription({required this.controller, required this.path});

  Stream<Map<String, dynamic>?> get stream => controller.stream;

  void resetRetryDelay() => _retryCount = 0;

  /// Exponential back-off: 1s → 2s → 4s → 8s → 16s → cap at 30s.
  Duration nextRetryDelay() {
    final seconds = (1 << _retryCount).clamp(1, 30);
    _retryCount++;
    return Duration(seconds: seconds);
  }
}

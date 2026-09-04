import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart' show rootBundle;
import 'package:logger_pkg/logger_pkg.dart';

import '../../model/chord/chords_positions.dart';
import '../../model/song/song.dart';
import '../../repositories/playlist_repository.dart';
import '../../repositories/songs_repository.dart';
import 'local_web_addresses.dart';
import 'local_web_payload.dart';

/// A web view of the library, served by the desktop app itself.
///
/// Everything comes out of the local Hive repositories — there is no
/// PocketBase, no cloud and no internet in this path, so it works on a church
/// Wi-Fi with no uplink. Visitors scan a QR code with a LAN address and follow
/// whatever song the desktop has marked as current; the page is pushed the
/// change over SSE, so it needs no polling.
class LocalWebServer {
  static const int defaultPort = 8080;

  /// Serving a page to other devices only makes sense from the machine running
  /// the service, so the server exists on desktop alone. The UI guards on the
  /// same value, which keeps the settings section and the server in step.
  static bool get isSupportedPlatform => !kIsWeb && (Platform.isMacOS || Platform.isWindows || Platform.isLinux);

  final SongsRepository songsRepository;
  final PlaylistRepository playlistRepository;

  HttpServer? _server;
  StreamSubscription<String>? _selectedSongSubscription;
  final _sseClients = <HttpResponse>[];
  final _assetCache = <String, String>{};

  LocalWebServer({required this.songsRepository, required this.playlistRepository});

  bool get isRunning => _server != null;
  int? get port => _server?.port;

  /// Binds to every interface so phones on the LAN can reach it.
  ///
  /// Throws [SocketException] when the port is taken — the caller surfaces that
  /// to the user rather than silently picking another port, because the port is
  /// part of the address printed into the QR code.
  Future<void> start({int port = defaultPort}) async {
    if (_server != null) return;

    final server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    _server = server;
    server.listen(_handle, onError: (Object e) => logger.e('Local web server error: $e'));

    _selectedSongSubscription = songsRepository.selectSongData.listen(_broadcastCurrentSong);

    logger.i('Local web server listening on port ${server.port}');
  }

  Future<void> stop() async {
    await _selectedSongSubscription?.cancel();
    _selectedSongSubscription = null;

    for (final client in List<HttpResponse>.from(_sseClients)) {
      try {
        await client.close();
      } catch (_) {
        // The client may already be gone; nothing to recover.
      }
    }
    _sseClients.clear();

    await _server?.close(force: true);
    _server = null;
    logger.i('Local web server stopped');
  }

  Future<List<LocalWebAddress>> addresses() => listLocalAddresses();

  // ---------------------------------------------------------------------------
  // Routing
  // ---------------------------------------------------------------------------

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;
    try {
      if (path == '/events') return await _handleEvents(request);
      if (path.startsWith('/api/')) return await _handleApi(request, path);
      return await _handleStatic(request, path);
    } catch (e) {
      logger.e('Local web server failed to serve $path: $e');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {
        // Response already committed.
      }
    }
  }

  Future<void> _handleApi(HttpRequest request, String path) async {
    final segments = request.uri.pathSegments;

    if (path == '/api/current-song') {
      return _json(request, LocalWebPayload.currentSong(songsRepository.selectedSongId));
    }

    if (path == '/api/songs') {
      return _json(request, songsRepository.songs.map(LocalWebPayload.songSummary).toList());
    }

    if (path == '/api/chord-diagrams') {
      return _json(request, _chordLibrary());
    }

    if (segments.length == 3 && segments[1] == 'song') {
      final song = songsRepository.getSongById(segments[2]);
      if (song == null) return _notFound(request);
      return _json(request, LocalWebPayload.songDetail(song));
    }

    if (path == '/api/playlists') {
      return _json(request, playlistRepository.playlists.map(LocalWebPayload.playlistSummary).toList());
    }

    if (segments.length == 3 && segments[1] == 'playlist') {
      final playlist = playlistRepository.playlists.where((p) => p.id == segments[2]).firstOrNull;
      if (playlist == null) return _notFound(request);
      final songs = playlist.listSongIds.map(songsRepository.getSongById).whereType<Song>().toList();
      return _json(request, LocalWebPayload.playlistDetail(playlist, songs));
    }

    return _notFound(request);
  }

  /// Every chord the app knows: the synced library plus the built-in grips,
  /// which is what the app's own fallback chain would resolve.
  Map<String, List<String>> _chordLibrary() {
    final chordService = songsRepository.chordService;
    final names = {...ChordsPositions.getAllChordNames(), ...chordService.pbChordCache.keys};
    return LocalWebPayload.chordLibrary(names, chordService.resolveChordPositions);
  }

  Future<void> _handleStatic(HttpRequest request, String path) async {
    final asset = switch (path) {
      '/styles.css' => ('assets/local_web/styles.css', 'text/css; charset=utf-8'),
      '/app.js' => ('assets/local_web/app.js', 'application/javascript; charset=utf-8'),
      _ => ('assets/local_web/index.html', 'text/html; charset=utf-8'),
    };

    final body = await _loadAsset(asset.$1);
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.parse(asset.$2)
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..write(body);
    await request.response.close();
  }

  Future<String> _loadAsset(String key) async {
    final cached = _assetCache[key];
    if (cached != null) return cached;
    final value = await rootBundle.loadString(key);
    _assetCache[key] = value;
    return value;
  }

  // ---------------------------------------------------------------------------
  // Server-sent events
  // ---------------------------------------------------------------------------

  Future<void> _handleEvents(HttpRequest request) async {
    final response = request.response;
    response
      ..statusCode = HttpStatus.ok
      ..headers.set(HttpHeaders.contentTypeHeader, 'text/event-stream; charset=utf-8')
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-cache')
      ..headers.set(HttpHeaders.connectionHeader, 'keep-alive')
      // Proxies and the Dart HTTP server both buffer by default, which delays
      // an event until the next one arrives — fatal for a live view.
      ..bufferOutput = false;

    _sseClients.add(response);
    response.done.whenComplete(() => _sseClients.remove(response));

    _write(response, 'currentSong', LocalWebPayload.currentSong(songsRepository.selectedSongId));
  }

  void _broadcastCurrentSong(String songId) {
    final payload = LocalWebPayload.currentSong(songId);
    for (final client in List<HttpResponse>.from(_sseClients)) {
      _write(client, 'currentSong', payload);
    }
  }

  void _write(HttpResponse response, String event, Object payload) {
    try {
      response.write('event: $event\ndata: ${jsonEncode(payload)}\n\n');
      response.flush();
    } catch (_) {
      _sseClients.remove(response);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _json(HttpRequest request, Object payload) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..write(jsonEncode(payload));
    await request.response.close();
  }

  Future<void> _notFound(HttpRequest request) async {
    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }
}

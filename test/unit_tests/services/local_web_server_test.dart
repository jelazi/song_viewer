import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:default_project/model/playlist.dart';
import 'package:default_project/model/song/song.dart';
import 'package:default_project/repositories/playlist_repository.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:default_project/services/chord_service.dart';
import 'package:default_project/services/local_web/local_web_server.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'local_web_server_test.mocks.dart';

@GenerateNiceMocks([MockSpec<SongsRepository>(), MockSpec<PlaylistRepository>(), MockSpec<ChordService>()])
void main() {
  // The binding is needed for rootBundle, which serves the page assets. It
  // also installs an HttpClient that answers every request with 400 so tests
  // cannot reach the network; this suite talks to a server it started itself,
  // so the real client has to be put back.
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  logger = MyLogger(debug: false, saveToFile: false, level: 0);

  late MockSongsRepository songsRepository;
  late MockPlaylistRepository playlistRepository;
  late MockChordService chordService;
  late StreamController<String> selectedSong;
  late LocalWebServer server;
  late HttpClient client;

  final song = Song(
    id: 'song-1',
    title: 'Svatý',
    lyrics: '[C]Svatý, [G]svatý',
    interpret: 'Hillsong',
    indexSongBook: 12,
  );

  Future<HttpClientResponse> get(String path) async {
    final request = await client.getUrl(Uri.parse('http://127.0.0.1:${server.port}$path'));
    return request.close();
  }

  Future<dynamic> getJson(String path) async {
    final response = await get(path);
    expect(response.statusCode, 200);
    return jsonDecode(await response.transform(utf8.decoder).join());
  }

  setUp(() async {
    songsRepository = MockSongsRepository();
    playlistRepository = MockPlaylistRepository();
    chordService = MockChordService();
    selectedSong = StreamController<String>.broadcast();
    client = HttpClient();

    when(songsRepository.selectSongData).thenAnswer((_) => selectedSong.stream);
    when(songsRepository.selectedSongId).thenReturn('song-1');
    when(songsRepository.songs).thenReturn([song]);
    when(songsRepository.getSongById('song-1')).thenReturn(song);
    when(songsRepository.getSongById('missing')).thenReturn(null);
    when(songsRepository.chordService).thenReturn(chordService);
    when(chordService.resolveChordPositions(any, song: anyNamed('song'))).thenReturn(['x 3 2 0 1 0']);

    final playlist = Playlist(id: 'p1', name: 'Nedělní chvály');
    playlist.listSongIds.add('song-1');
    when(playlistRepository.playlists).thenReturn([playlist]);

    server = LocalWebServer(songsRepository: songsRepository, playlistRepository: playlistRepository);
    // Port 0 lets the OS pick a free one, so the suite cannot collide with
    // whatever is already listening on the developer's machine.
    await server.start(port: 0);
  });

  tearDown(() async {
    client.close(force: true);
    await server.stop();
    await selectedSong.close();
  });

  group('lifecycle', () {
    test('reports the port it actually bound', () {
      expect(server.isRunning, isTrue);
      expect(server.port, greaterThan(0));
    });

    test('stop releases the port and start is idempotent', () async {
      await server.start(port: 0);
      final port = server.port;
      await server.stop();

      expect(server.isRunning, isFalse);
      expect(server.port, isNull);

      // Binding the same port again proves it was genuinely released.
      final probe = await ServerSocket.bind(InternetAddress.anyIPv4, port!);
      await probe.close();
    });
  });

  group('api', () {
    test('serves the current song id', () async {
      expect(await getJson('/api/current-song'), {'songId': 'song-1'});
    });

    test('serves the song list', () async {
      final songs = await getJson('/api/songs') as List;

      expect(songs, hasLength(1));
      expect(songs.first['title'], 'Svatý');
    });

    test('serves a song with its content and overrides', () async {
      final detail = await getJson('/api/song/song-1') as Map;

      expect(detail['content'], '[C]Svatý, [G]svatý');
      expect(detail['chordOverrides'], isEmpty);
    });

    test('serves the whole chord library, not just what the song uses', () async {
      final library = await getJson('/api/chord-diagrams') as Map;

      // Transposing on the phone asks for grips the song never contained, so
      // the library has to cover more than the song's own chords.
      expect(library.length, greaterThan(2));
      expect(library.values.first, ['x 3 2 0 1 0']);
    });

    test('an unknown song is a 404, not an empty song', () async {
      expect((await get('/api/song/missing')).statusCode, 404);
    });

    test('serves playlists and resolves their songs', () async {
      expect(await getJson('/api/playlists'), [
        {'id': 'p1', 'name': 'Nedělní chvály', 'songCount': 1},
      ]);

      final detail = await getJson('/api/playlist/p1') as Map;
      expect((detail['songs'] as List).first['id'], 'song-1');
    });

    test('an unknown api path is a 404 rather than the page', () async {
      expect((await get('/api/nope')).statusCode, 404);
    });
  });

  group('static assets', () {
    test('serves the page shell', () async {
      final response = await get('/');
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, 200);
      expect(body, contains('<title>Hudební archív</title>'));
    });

    test('serves the stylesheet and the script with their own content types', () async {
      final css = await get('/styles.css');
      expect(css.headers.contentType?.mimeType, 'text/css');

      final js = await get('/app.js');
      expect(js.headers.contentType?.mimeType, 'application/javascript');
    });

    test('an unknown page path falls back to the shell so client routing works', () async {
      final response = await get('/pisne/song-1');
      final body = await response.transform(utf8.decoder).join();

      expect(response.statusCode, 200);
      expect(body, contains('<title>Hudební archív</title>'));
    });
  });

  group('server-sent events', () {
    /// Collects [count] frames, then detaches. The subscription must be gone
    /// before the test ends: tearDown force-closes the client, and a live
    /// listener would surface that teardown as a test failure.
    Future<List<String>> collectFrames(HttpClientResponse response, int count) async {
      final frames = <String>[];
      final done = Completer<List<String>>();
      late StreamSubscription<String> subscription;

      subscription = response.transform(utf8.decoder).listen(
        (chunk) {
          frames.add(chunk);
          if (frames.length >= count && !done.isCompleted) done.complete(frames);
        },
        onError: (Object e) {
          if (!done.isCompleted) done.completeError(e);
        },
      );

      try {
        return await done.future.timeout(const Duration(seconds: 5));
      } finally {
        await subscription.cancel();
      }
    }

    test('sends the current song immediately, then every change', () async {
      final response = await get('/events');
      expect(response.headers.contentType?.mimeType, 'text/event-stream');

      final collected = collectFrames(response, 2);
      await pumpEventQueue();

      when(songsRepository.selectedSongId).thenReturn('song-2');
      selectedSong.add('song-2');

      final frames = await collected;

      expect(frames.first, contains('event: currentSong'));
      expect(frames.first, contains('"songId":"song-1"'));
      expect(frames.last, contains('"songId":"song-2"'));
    });

    test('deselecting broadcasts an empty id', () async {
      final response = await get('/events');

      final collected = collectFrames(response, 2);
      await pumpEventQueue();

      selectedSong.add('');

      final frames = await collected;

      expect(frames.last, contains('"songId":""'));
    });
  });
}

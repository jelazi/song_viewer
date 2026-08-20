import 'dart:async';

import 'package:default_project/model/playlist.dart';
import 'package:default_project/model/song/song.dart';
import 'package:default_project/providers/hive_provider.dart';
import 'package:default_project/providers/pocketbase_provider.dart';
import 'package:default_project/repositories/playlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import '../../test_helpers/test_logger.dart';

@GenerateMocks([PocketBaseProvider, HiveProvider])
import 'playlist_repository_test.mocks.dart';

void main() {
  group('PlaylistRepository', () {
    late PlaylistRepository playlistRepository;
    late MockPocketBaseProvider mockPocketBaseProvider;
    late MockHiveProvider mockHiveProvider;
    late StreamController<RealtimeChangeEvent<Playlist>> playlistChangeController;

    /// Rebuilds the repository. [isConnected] is the whole point of most of
    /// these tests: the repository must behave differently with and without a
    /// server, and the default here is **connected**, so the tests that care
    /// about the local-first path say so explicitly.
    void buildRepository({bool isConnected = true}) {
      when(mockPocketBaseProvider.isConnected).thenReturn(isConnected);
      playlistRepository = PlaylistRepository(
        hiveProvider: mockHiveProvider,
        pocketBaseProvider: mockPocketBaseProvider,
      );
    }

    setUp(() {
      initTestLogger();
      mockPocketBaseProvider = MockPocketBaseProvider();
      mockHiveProvider = MockHiveProvider();
      playlistChangeController = StreamController<RealtimeChangeEvent<Playlist>>.broadcast();

      // Mock default behavior
      when(mockPocketBaseProvider.getListPlaylists()).thenAnswer((_) async => []);
      when(mockPocketBaseProvider.playlistChangeStream).thenAnswer((_) => playlistChangeController.stream);
      when(mockHiveProvider.loadPlaylistsCache()).thenReturn(null);

      buildRepository();
    });

    tearDown(() {
      playlistChangeController.close();
    });

    group('Initialization', () {
      test('should load playlists from server on init when connected', () async {
        final testPlaylists = [
          Playlist(id: '1', name: 'Playlist 1'),
          Playlist(id: '2', name: 'Playlist 2'),
        ];

        when(mockPocketBaseProvider.getListPlaylists()).thenAnswer((_) async => testPlaylists);

        buildRepository();
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockPocketBaseProvider.getListPlaylists()).called(greaterThanOrEqualTo(1));
        expect(playlistRepository.playlists.length, equals(2));
      });

      test('should not touch the server when there is none', () async {
        // The setUp instance is connected and shares this mock, so let its
        // async init finish and forget those calls before measuring.
        await Future.delayed(const Duration(milliseconds: 100));
        clearInteractions(mockPocketBaseProvider);

        buildRepository(isConnected: false);
        await Future.delayed(const Duration(milliseconds: 100));

        verifyNever(mockPocketBaseProvider.getListPlaylists());
      });

      test('should load playlists from the Hive cache', () async {
        when(mockHiveProvider.loadPlaylistsCache()).thenReturn([
          Playlist(id: '1', name: 'Cached Playlist').toJson(),
        ]);

        buildRepository(isConnected: false);
        await Future.delayed(const Duration(milliseconds: 100));

        expect(playlistRepository.playlists.length, equals(1));
        expect(playlistRepository.playlists.first.name, equals('Cached Playlist'));
      });
    });

    group('Get Playlists', () {
      test('should return copy of playlists list', () {
        final result1 = playlistRepository.playlists;
        final result2 = playlistRepository.playlists;

        // Should be different instances (copies)
        expect(identical(result1, result2), isFalse);
        expect(result1, equals(result2));
      });

      test('should return empty list on initialization', () {
        final result = playlistRepository.playlists;

        expect(result, isEmpty);
      });
    });

    group('Save Playlist', () {
      test('should successfully save new playlist', () async {
        final playlist = Playlist(id: '1', name: 'Test Playlist');

        when(mockPocketBaseProvider.addOrUpdatePlaylist(playlist)).thenAnswer((_) async => true);

        final result = await playlistRepository.savePlaylist(playlist);

        expect(result, isTrue);
        expect(playlistRepository.playlists, contains(playlist));
        verify(mockPocketBaseProvider.addOrUpdatePlaylist(playlist)).called(1);
      });

      test('should keep the playlist locally when the server rejects it', () async {
        final playlist = Playlist(id: '1', name: 'Test Playlist');

        when(mockPocketBaseProvider.addOrUpdatePlaylist(playlist)).thenAnswer((_) async => false);

        final result = await playlistRepository.savePlaylist(playlist);

        // The local write is what decides: dropping the user's edit because a
        // server refused it would be worse than the two sides disagreeing.
        expect(result, isTrue);
        expect(playlistRepository.playlists, contains(playlist));
      });

      test('should save with no server at all', () async {
        buildRepository(isConnected: false);
        final playlist = Playlist(id: '1', name: 'Offline Playlist');

        final result = await playlistRepository.savePlaylist(playlist);

        expect(result, isTrue);
        expect(playlistRepository.playlists, contains(playlist));
        verifyNever(mockPocketBaseProvider.addOrUpdatePlaylist(any));
      });

      test('should persist to the Hive cache on save', () async {
        buildRepository(isConnected: false);
        final playlist = Playlist(id: '1', name: 'Offline Playlist');

        await playlistRepository.savePlaylist(playlist);

        verify(mockHiveProvider.savePlaylistsCache(any)).called(greaterThanOrEqualTo(1));
      });

      test('should stamp updatedAt on save', () async {
        buildRepository(isConnected: false);
        final playlist = Playlist(id: '1', name: 'Test Playlist');
        expect(playlist.updatedAt, isNull);

        await playlistRepository.savePlaylist(playlist);

        expect(playlist.updatedAt, isNotNull);
        expect(playlist.updatedAt!.isUtc, isTrue);
      });

      test('should update existing playlist', () async {
        final playlist = Playlist(id: '1', name: 'Original Name');

        when(mockPocketBaseProvider.addOrUpdatePlaylist(any)).thenAnswer((_) async => true);

        // First add playlist
        await playlistRepository.savePlaylist(playlist);

        // Then update it
        playlist.name = 'Updated Name';
        final result = await playlistRepository.savePlaylist(playlist);

        expect(result, isTrue);
        expect(playlistRepository.playlists.length, equals(1));
        expect(playlistRepository.playlists.first.name, equals('Updated Name'));
      });

      test('should add songs to playlist', () async {
        final playlist = Playlist(id: '1', name: 'Test Playlist');
        final song = Song(id: 'song1', title: 'Test Song', lyrics: 'lyrics');

        when(mockPocketBaseProvider.addOrUpdatePlaylist(playlist)).thenAnswer((_) async => true);

        playlist.addSong(song);
        final result = await playlistRepository.savePlaylist(playlist);

        expect(result, isTrue);
        expect(playlist.listSongIds, contains('song1'));
      });
    });

    group('Delete Playlist', () {
      test('should successfully delete playlist', () async {
        final playlist = Playlist(id: '1', name: 'Test Playlist');

        when(mockPocketBaseProvider.addOrUpdatePlaylist(playlist)).thenAnswer((_) async => true);
        when(mockPocketBaseProvider.deletePlaylist(playlist)).thenAnswer((_) async => true);

        // First add playlist
        await playlistRepository.savePlaylist(playlist);
        expect(playlistRepository.playlists, contains(playlist));

        // Then delete it
        final result = await playlistRepository.deletePlaylist(playlist);

        expect(result, isTrue);
        expect(playlistRepository.playlists, isNot(contains(playlist)));
        verify(mockPocketBaseProvider.deletePlaylist(playlist)).called(1);
      });

      test('should return false when server delete fails', () async {
        final playlist = Playlist(id: '1', name: 'Test Playlist');

        when(mockPocketBaseProvider.addOrUpdatePlaylist(playlist)).thenAnswer((_) async => true);
        when(mockPocketBaseProvider.deletePlaylist(playlist)).thenAnswer((_) async => false);

        // First add playlist
        await playlistRepository.savePlaylist(playlist);

        // Try to delete it
        final result = await playlistRepository.deletePlaylist(playlist);

        expect(result, isFalse);
        expect(playlistRepository.playlists, contains(playlist));
      });

      test('should delete with no server at all', () async {
        buildRepository(isConnected: false);
        final playlist = Playlist(id: '1', name: 'Offline Playlist');
        await playlistRepository.savePlaylist(playlist);

        final result = await playlistRepository.deletePlaylist(playlist);

        expect(result, isTrue);
        expect(playlistRepository.playlists, isNot(contains(playlist)));
        verifyNever(mockPocketBaseProvider.deletePlaylist(any));
      });

      test('should handle deleting non-existent playlist', () async {
        final playlist = Playlist(id: '999', name: 'Non-existent');

        when(mockPocketBaseProvider.deletePlaylist(playlist)).thenAnswer((_) async => true);

        final result = await playlistRepository.deletePlaylist(playlist);

        expect(result, isTrue);
        expect(playlistRepository.playlists, isNot(contains(playlist)));
      });
    });
  });
}

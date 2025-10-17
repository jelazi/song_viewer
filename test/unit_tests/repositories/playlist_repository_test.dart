import 'package:default_project/model/playlist.dart';
import 'package:default_project/model/song/song.dart';
import 'package:default_project/providers/firebase_provider.dart';
import 'package:default_project/providers/hive_provider.dart';
import 'package:default_project/repositories/playlist_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseProvider, HiveProvider])
import 'playlist_repository_test.mocks.dart';

void main() {
  group('PlaylistRepository', () {
    late PlaylistRepository playlistRepository;
    late MockFirebaseProvider mockFirebaseProvider;
    late MockHiveProvider mockHiveProvider;

    setUp(() {
      mockFirebaseProvider = MockFirebaseProvider();
      mockHiveProvider = MockHiveProvider();

      // Mock default behavior
      when(mockFirebaseProvider.getListPlaylistsFromFirestore()).thenAnswer((_) async => []);

      playlistRepository = PlaylistRepository(
        hiveProvider: mockHiveProvider,
        firebaseProvider: mockFirebaseProvider,
      );
    });

    group('Initialization', () {
      test('should load playlists from Firebase on init', () async {
        final testPlaylists = [
          Playlist(id: '1', name: 'Playlist 1'),
          Playlist(id: '2', name: 'Playlist 2'),
        ];

        when(mockFirebaseProvider.getListPlaylistsFromFirestore()).thenAnswer((_) async => testPlaylists);

        playlistRepository = PlaylistRepository(
          hiveProvider: mockHiveProvider,
          firebaseProvider: mockFirebaseProvider,
        );

        // Wait for async init
        await Future.delayed(const Duration(milliseconds: 100));

        // Verify that getListPlaylistsFromFirestore was called at least once
        // (may be called in setUp as well)
        verify(mockFirebaseProvider.getListPlaylistsFromFirestore()).called(greaterThanOrEqualTo(1));
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

        when(mockFirebaseProvider.addPlaylistToFirebase(playlist)).thenAnswer((_) async => true);

        final result = await playlistRepository.savePlaylist(playlist);

        expect(result, isTrue);
        expect(playlistRepository.playlists, contains(playlist));
        verify(mockFirebaseProvider.addPlaylistToFirebase(playlist)).called(1);
      });

      test('should return false when Firebase fails', () async {
        final playlist = Playlist(id: '1', name: 'Test Playlist');

        when(mockFirebaseProvider.addPlaylistToFirebase(playlist)).thenAnswer((_) async => false);

        final result = await playlistRepository.savePlaylist(playlist);

        expect(result, isFalse);
        expect(playlistRepository.playlists, isNot(contains(playlist)));
      });

      test('should update existing playlist', () async {
        final playlist = Playlist(id: '1', name: 'Original Name');

        when(mockFirebaseProvider.addPlaylistToFirebase(any)).thenAnswer((_) async => true);

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

        when(mockFirebaseProvider.addPlaylistToFirebase(playlist)).thenAnswer((_) async => true);

        playlist.addSong(song);
        final result = await playlistRepository.savePlaylist(playlist);

        expect(result, isTrue);
        expect(playlist.listSongIds, contains('song1'));
      });
    });

    group('Delete Playlist', () {
      test('should successfully delete playlist', () async {
        final playlist = Playlist(id: '1', name: 'Test Playlist');

        when(mockFirebaseProvider.addPlaylistToFirebase(playlist)).thenAnswer((_) async => true);
        when(mockFirebaseProvider.deletePlaylist(playlist)).thenAnswer((_) async => true);

        // First add playlist
        await playlistRepository.savePlaylist(playlist);
        expect(playlistRepository.playlists, contains(playlist));

        // Then delete it
        final result = await playlistRepository.deletePlaylist(playlist);

        expect(result, isTrue);
        expect(playlistRepository.playlists, isNot(contains(playlist)));
        verify(mockFirebaseProvider.deletePlaylist(playlist)).called(1);
      });

      test('should return false when Firebase delete fails', () async {
        final playlist = Playlist(id: '1', name: 'Test Playlist');

        when(mockFirebaseProvider.addPlaylistToFirebase(playlist)).thenAnswer((_) async => true);
        when(mockFirebaseProvider.deletePlaylist(playlist)).thenAnswer((_) async => false);

        // First add playlist
        await playlistRepository.savePlaylist(playlist);

        // Try to delete it
        final result = await playlistRepository.deletePlaylist(playlist);

        expect(result, isFalse);
        expect(playlistRepository.playlists, contains(playlist));
      });

      test('should handle deleting non-existent playlist', () async {
        final playlist = Playlist(id: '999', name: 'Non-existent');

        when(mockFirebaseProvider.deletePlaylist(playlist)).thenAnswer((_) async => true);

        final result = await playlistRepository.deletePlaylist(playlist);

        expect(result, isTrue);
        expect(playlistRepository.playlists, isNot(contains(playlist)));
      });
    });
  });
}

import 'dart:async';
import 'dart:convert';

import 'package:default_project/model/song/song.dart';
import 'package:default_project/providers/hive_provider.dart';
import 'package:default_project/providers/pocketbase_provider.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([PocketBaseProvider, HiveProvider])
import 'songs_repository_test.mocks.dart';

void main() {
  group('SongsRepository', () {
    late SongsRepository songsRepository;
    late MockPocketBaseProvider mockPocketBaseProvider;
    late MockHiveProvider mockHiveProvider;
    late StreamController<Map<String, dynamic>?> selectedSongController;
    late StreamController<RealtimeChangeEvent<Song>> songChangeController;
    late StreamController<RealtimeChangeEvent<String>> groupChangeController;

    setUp(() {
      mockPocketBaseProvider = MockPocketBaseProvider();
      mockHiveProvider = MockHiveProvider();
      selectedSongController = StreamController<Map<String, dynamic>?>.broadcast();
      songChangeController = StreamController<RealtimeChangeEvent<Song>>.broadcast();
      groupChangeController = StreamController<RealtimeChangeEvent<String>>.broadcast();

      // Mock PocketBase streams
      when(mockPocketBaseProvider.selectedSongStream).thenAnswer((_) => selectedSongController.stream);
      when(mockPocketBaseProvider.songChangeStream).thenAnswer((_) => songChangeController.stream);
      when(mockPocketBaseProvider.groupChangeStream).thenAnswer((_) => groupChangeController.stream);

      // Mock default PocketBase responses
      when(mockPocketBaseProvider.getListSongs()).thenAnswer((_) async => []);
      when(mockPocketBaseProvider.getListGroups()).thenAnswer((_) async => []);
      when(mockPocketBaseProvider.addOrUpdateSong(any)).thenAnswer((_) async => true);

      songsRepository = SongsRepository(
        hiveProvider: mockHiveProvider,
        pocketBaseProvider: mockPocketBaseProvider,
      );
    });

    tearDown(() {
      selectedSongController.close();
      songChangeController.close();
      groupChangeController.close();
    });

    group('Initialization', () {
      test('should initialize with empty songs list', () {
        expect(songsRepository.songs, isEmpty);
      });

      test('should have empty selectedSongId initially', () {
        expect(songsRepository.selectedSongId, isEmpty);
      });

      test('should have empty listAllGroups initially', () {
        expect(songsRepository.listAllGroups, isEmpty);
      });
    });

    group('Load Songs', () {
      test('should load songs from server', () async {
        final testSongs = [
          Song(id: '1', title: 'Song 1', lyrics: 'Lyrics 1'),
          Song(id: '2', title: 'Song 2', lyrics: 'Lyrics 2'),
        ];

        when(mockPocketBaseProvider.getListSongs()).thenAnswer((_) async => testSongs);

        await songsRepository.loadSongsFromServer();

        expect(songsRepository.songs.length, equals(2));
        verify(mockPocketBaseProvider.getListSongs()).called(1);
      });

      test('should not add duplicate songs', () async {
        final song = Song(id: '1', title: 'Song 1', lyrics: 'Lyrics 1');

        when(mockPocketBaseProvider.getListSongs()).thenAnswer((_) async => [song]);

        await songsRepository.loadSongsFromServer();
        await songsRepository.loadSongsFromServer();

        expect(songsRepository.songs.length, equals(1));
      });
    });

    group('Delete Song', () {
      test('should delete song successfully', () async {
        final song = Song(id: '1', title: 'Song 1', lyrics: 'Lyrics 1');

        when(mockPocketBaseProvider.getListSongs()).thenAnswer((_) async => [song]);
        await songsRepository.loadSongsFromServer();

        when(mockPocketBaseProvider.deleteSong('1')).thenAnswer((_) async => true);

        final result = await songsRepository.deleteSong('1');

        expect(result, isTrue);
        expect(songsRepository.songs, isEmpty);
        verify(mockPocketBaseProvider.deleteSong('1')).called(1);
      });

      test('should return false when server delete fails', () async {
        when(mockPocketBaseProvider.deleteSong('1')).thenAnswer((_) async => false);

        final result = await songsRepository.deleteSong('1');

        expect(result, isFalse);
      });
    });

    group('Get Song', () {
      test('should get song by id', () async {
        final song = Song(id: '1', title: 'Song 1', lyrics: 'Lyrics 1');

        when(mockPocketBaseProvider.getListSongs()).thenAnswer((_) async => [song]);
        await songsRepository.loadSongsFromServer();

        final result = songsRepository.getSongById('1');

        expect(result, isNotNull);
        expect(result?.title, equals('Song 1'));
      });

      test('should return null for non-existent song', () {
        final result = songsRepository.getSongById('999');

        expect(result, isNull);
      });
    });

    group('Transpose', () {
      test('should change transpose for song', () {
        final song = Song(id: '1', title: 'Song 1', lyrics: 'Lyrics 1');

        songsRepository.changeTransposeChord(song, 2);

        verify(mockHiveProvider.setNewTransposeForSong('1', 2)).called(1);
      });

      test('should get transpose for song', () {
        final song = Song(id: '1', title: 'Song 1', lyrics: 'Lyrics 1');

        when(mockHiveProvider.getTransposeForSong('1')).thenReturn(3);

        final result = songsRepository.getTransposeForSong(song);

        expect(result, equals(3));
        verify(mockHiveProvider.getTransposeForSong('1')).called(1);
      });

      test('should return 0 for null song', () {
        final result = songsRepository.getTransposeForSong(null);

        expect(result, equals(0));
        verifyNever(mockHiveProvider.getTransposeForSong(any));
      });
    });

    group('JSON Export', () {
      test('should return valid JSON string for songs list', () async {
        final song1 = Song(id: '1', title: 'Test Song 1', lyrics: 'Lyrics 1');
        final song2 = Song(id: '2', title: 'Test Song 2', lyrics: 'Lyrics 2');

        when(mockPocketBaseProvider.getListSongs()).thenAnswer((_) async => [song1, song2]);

        await songsRepository.loadSongsFromServer();

        final result = songsRepository.getListSongToJson();

        expect(() => jsonDecode(result), returnsNormally);
        final decoded = jsonDecode(result) as List<dynamic>;
        expect(decoded.length, equals(2));
        expect(decoded[0]['id'], equals('1'));
        expect(decoded[0]['title'], equals('Test Song 1'));
        expect(decoded[1]['id'], equals('2'));
        expect(decoded[1]['title'], equals('Test Song 2'));
      });

      test('should return valid JSON for empty songs list', () {
        final result = songsRepository.getListSongToJson();

        expect(() => jsonDecode(result), returnsNormally);
        final decoded = jsonDecode(result) as List<dynamic>;
        expect(decoded, isEmpty);
      });
    });

    group('Groups', () {
      test('should load groups from server', () async {
        final testGroups = ['Group 1', 'Group 2', 'Group 3'];

        when(mockPocketBaseProvider.getListGroups()).thenAnswer((_) async => testGroups);

        await songsRepository.loadAllGroups();

        expect(songsRepository.listAllGroups.length, equals(3));
        verify(mockPocketBaseProvider.getListGroups()).called(1);
      });

      test('should create new group', () async {
        when(mockPocketBaseProvider.createGroup('New Group')).thenAnswer((_) async => true);
        when(mockPocketBaseProvider.getListGroups()).thenAnswer((_) async => ['New Group']);

        await songsRepository.createGroup('New Group');

        expect(songsRepository.listAllGroups, contains('New Group'));
        verify(mockPocketBaseProvider.createGroup('New Group')).called(1);
        verify(mockPocketBaseProvider.getListGroups()).called(1);
      });
    });
  });
}

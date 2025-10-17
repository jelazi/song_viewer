import 'dart:async';

import 'package:default_project/model/song/song.dart';
import 'package:default_project/providers/firebase_provider.dart';
import 'package:default_project/providers/hive_provider.dart';
import 'package:default_project/repositories/songs_repository.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([FirebaseProvider, HiveProvider, DatabaseReference])
import 'songs_repository_test.mocks.dart';

void main() {
  group('SongsRepository', () {
    late SongsRepository songsRepository;
    late MockFirebaseProvider mockFirebaseProvider;
    late MockHiveProvider mockHiveProvider;
    late MockDatabaseReference mockSelectedSong;
    late StreamController<DatabaseEvent> selectedSongController;

    setUp(() {
      mockFirebaseProvider = MockFirebaseProvider();
      mockHiveProvider = MockHiveProvider();
      mockSelectedSong = MockDatabaseReference();
      selectedSongController = StreamController<DatabaseEvent>.broadcast();

      // Mock selectedSong stream
      when(mockFirebaseProvider.selectedSong).thenReturn(mockSelectedSong);
      when(mockSelectedSong.onValue).thenAnswer((_) => selectedSongController.stream);

      // Mock default Firebase responses
      when(mockFirebaseProvider.getListSongsFromFirestore()).thenAnswer((_) async => []);
      when(mockFirebaseProvider.getListSongGroupFromFirestore()).thenAnswer((_) async => []);

      songsRepository = SongsRepository(
        hiveProvider: mockHiveProvider,
        firebaseProvider: mockFirebaseProvider,
      );
    });

    tearDown(() {
      selectedSongController.close();
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
      test('should load songs from Firebase', () async {
        final testSongs = [
          Song(id: '1', title: 'Song 1', lyrics: 'Lyrics 1'),
          Song(id: '2', title: 'Song 2', lyrics: 'Lyrics 2'),
        ];

        when(mockFirebaseProvider.getListSongsFromFirestore()).thenAnswer((_) async => testSongs);

        await songsRepository.loadSongsFromFirebase();

        expect(songsRepository.songs.length, equals(2));
        verify(mockFirebaseProvider.getListSongsFromFirestore()).called(1);
      });

      test('should not add duplicate songs', () async {
        final song = Song(id: '1', title: 'Song 1', lyrics: 'Lyrics 1');

        when(mockFirebaseProvider.getListSongsFromFirestore()).thenAnswer((_) async => [song]);

        await songsRepository.loadSongsFromFirebase();
        await songsRepository.loadSongsFromFirebase();

        expect(songsRepository.songs.length, equals(1));
      });
    });

    group('Delete Song', () {
      test('should delete song successfully', () async {
        final song = Song(id: '1', title: 'Song 1', lyrics: 'Lyrics 1');

        when(mockFirebaseProvider.getListSongsFromFirestore()).thenAnswer((_) async => [song]);
        await songsRepository.loadSongsFromFirebase();

        when(mockFirebaseProvider.deleteSong('1')).thenAnswer((_) async => true);

        final result = await songsRepository.deleteSong('1');

        expect(result, isTrue);
        expect(songsRepository.songs, isEmpty);
        verify(mockFirebaseProvider.deleteSong('1')).called(1);
      });

      test('should return false when Firebase delete fails', () async {
        when(mockFirebaseProvider.deleteSong('1')).thenAnswer((_) async => false);

        final result = await songsRepository.deleteSong('1');

        expect(result, isFalse);
      });
    });

    group('Get Song', () {
      test('should get song by id', () async {
        final song = Song(id: '1', title: 'Song 1', lyrics: 'Lyrics 1');

        when(mockFirebaseProvider.getListSongsFromFirestore()).thenAnswer((_) async => [song]);
        await songsRepository.loadSongsFromFirebase();

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

    group('Groups', () {
      test('should load groups from Firebase', () async {
        final testGroups = ['Group 1', 'Group 2', 'Group 3'];

        when(mockFirebaseProvider.getListSongGroupFromFirestore()).thenAnswer((_) async => testGroups);

        await songsRepository.loadAllGroups();

        expect(songsRepository.listAllGroups.length, equals(3));
        verify(mockFirebaseProvider.getListSongGroupFromFirestore()).called(1);
      });

      test('should create new group', () async {
        when(mockFirebaseProvider.createNewGroup('New Group')).thenAnswer((_) async => true);
        when(mockFirebaseProvider.getListSongGroupFromFirestore()).thenAnswer((_) async => ['New Group']);

        await songsRepository.createGroup('New Group');

        expect(songsRepository.listAllGroups, contains('New Group'));
        verify(mockFirebaseProvider.createNewGroup('New Group')).called(1);
        verify(mockFirebaseProvider.getListSongGroupFromFirestore()).called(1);
      });
    });
  });
}

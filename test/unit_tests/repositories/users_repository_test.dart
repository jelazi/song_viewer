import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:default_project/model/user.dart';
import 'package:default_project/providers/firebase_provider.dart';
import 'package:default_project/providers/hive_provider.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  FirebaseProvider,
  HiveProvider,
  SettingsRepository,
  CollectionReference,
  QuerySnapshot,
  QueryDocumentSnapshot,
  DocumentReference,
])
import 'users_repository_test.mocks.dart';

void main() {
  // Initialize logger for tests
  setUpAll(() {
    logger = MyLogger(
      debug: false,
      saveToFile: false,
      level: 0, // Only errors
    );
  });

  group('UsersRepository', () {
    late UsersRepository usersRepository;
    late MockFirebaseProvider mockFirebaseProvider;
    late MockHiveProvider mockHiveProvider;
    late MockSettingsRepository mockSettingsRepository;
    late MockCollectionReference<Map<String, dynamic>> mockUserCollection;
    late MockQuerySnapshot<Map<String, dynamic>> mockQuerySnapshot;
    late MockDocumentReference<Map<String, dynamic>> mockDocumentReference;

    setUp(() {
      mockFirebaseProvider = MockFirebaseProvider();
      mockHiveProvider = MockHiveProvider();
      mockSettingsRepository = MockSettingsRepository();
      mockUserCollection = MockCollectionReference<Map<String, dynamic>>();
      mockQuerySnapshot = MockQuerySnapshot<Map<String, dynamic>>();
      mockDocumentReference = MockDocumentReference<Map<String, dynamic>>();

      // Setup default mock for userCollection
      when(mockFirebaseProvider.userCollection).thenReturn(mockUserCollection);

      usersRepository = UsersRepository(
        hiveProvider: mockHiveProvider,
        firebaseProvider: mockFirebaseProvider,
        settingsRepository: mockSettingsRepository,
      );
    });

    tearDown(() {
      usersRepository.userController.close();
    });

    group('Initialization', () {
      test('should initialize with empty users list', () {
        expect(usersRepository.users, isEmpty);
      });

      test('should initialize with TypeUser.none', () {
        expect(usersRepository.currentTypeUser, equals(TypeUser.none));
      });

      test('should have userStream', () {
        expect(usersRepository.userStream, isA<Stream<TypeUser>>());
      });
    });

    group('loadUsersFromFirebase', () {
      test('should load users successfully', () async {
        final user1 = User('user1', 'pass1')..typeUser = TypeUser.viewer;
        final user2 = User('user2', 'pass2')..typeUser = TypeUser.admin;

        final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        final mockDoc2 = MockQueryDocumentSnapshot<Map<String, dynamic>>();

        when(mockDoc1.data()).thenReturn(user1.toJson());
        when(mockDoc2.data()).thenReturn(user2.toJson());

        when(mockQuerySnapshot.docs).thenReturn([mockDoc1, mockDoc2]);
        when(mockUserCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        await usersRepository.loadUsersFromFirebase();

        expect(usersRepository.users.length, equals(2));
        expect(usersRepository.users[0].name, equals('user1'));
        expect(usersRepository.users[1].name, equals('user2'));
      });

      test('should handle empty users list', () async {
        when(mockQuerySnapshot.docs).thenReturn([]);
        when(mockUserCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        await usersRepository.loadUsersFromFirebase();

        expect(usersRepository.users, isEmpty);
      });

      test('should handle errors gracefully', () async {
        when(mockUserCollection.get()).thenThrow(Exception('Firebase error'));

        // Should not throw
        await usersRepository.loadUsersFromFirebase();

        expect(usersRepository.users, isEmpty);
      });
    });

    group('updateListUsersFromFirebase', () {
      test('should update users list', () async {
        final user1 = User('user1', 'pass1')..typeUser = TypeUser.viewer;

        final mockDoc1 = MockQueryDocumentSnapshot<Map<String, dynamic>>();
        when(mockDoc1.data()).thenReturn(user1.toJson());

        when(mockQuerySnapshot.docs).thenReturn([mockDoc1]);
        when(mockUserCollection.get()).thenAnswer((_) async => mockQuerySnapshot);

        await usersRepository.updateListUsersFromFirebase();

        expect(usersRepository.users.length, equals(1));
        expect(usersRepository.users[0].name, equals('user1'));
      });
    });

    group('createUser', () {
      test('should create user successfully', () async {
        final newUser = User('newuser', 'password')..typeUser = TypeUser.viewer;

        when(mockUserCollection.doc(newUser.name)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.set(any)).thenAnswer((_) async => {});

        final result = await usersRepository.createUser(newUser);

        expect(result, isTrue);
        verify(mockUserCollection.doc(newUser.name)).called(1);
        verify(mockDocumentReference.set(newUser.toJson())).called(1);
      });

      test('should return false on error', () async {
        final newUser = User('newuser', 'password')..typeUser = TypeUser.viewer;

        when(mockUserCollection.doc(newUser.name)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.set(any)).thenThrow(Exception('Firebase error'));

        final result = await usersRepository.createUser(newUser);

        expect(result, isFalse);
      });
    });

    group('deleteUser', () {
      test('should delete user successfully', () async {
        final user = User('user1', 'pass1')..typeUser = TypeUser.viewer;

        when(mockUserCollection.doc(user.name)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.delete()).thenAnswer((_) async => {});

        final result = await usersRepository.deleteUser(user);

        expect(result, isTrue);
        verify(mockUserCollection.doc(user.name)).called(1);
        verify(mockDocumentReference.delete()).called(1);
      });

      test('should return false on error', () async {
        final user = User('user1', 'pass1')..typeUser = TypeUser.viewer;

        when(mockUserCollection.doc(user.name)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.delete()).thenThrow(Exception('Firebase error'));

        final result = await usersRepository.deleteUser(user);

        expect(result, isFalse);
      });
    });

    group('updateUser', () {
      test('should update user successfully', () async {
        final user = User('user1', 'newpass')..typeUser = TypeUser.admin;

        when(mockUserCollection.doc(user.name)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.update(any)).thenAnswer((_) async => {});

        final result = await usersRepository.updateUser(user);

        expect(result, isTrue);
        verify(mockUserCollection.doc(user.name)).called(1);
        verify(mockDocumentReference.update(user.toJson())).called(1);
      });

      test('should return false on error', () async {
        final user = User('user1', 'newpass')..typeUser = TypeUser.admin;

        when(mockUserCollection.doc(user.name)).thenReturn(mockDocumentReference);
        when(mockDocumentReference.update(any)).thenThrow(Exception('Firebase error'));

        final result = await usersRepository.updateUser(user);

        expect(result, isFalse);
      });
    });

    group('checkUser', () {
      test('should return User when credentials are correct', () {
        final user1 = User('user1', 'pass1')..typeUser = TypeUser.viewer;
        final user2 = User('user2', 'pass2')..typeUser = TypeUser.admin;
        usersRepository.users = [user1, user2];

        when(mockSettingsRepository.setCurrentUser(any)).thenReturn(null);
        when(mockHiveProvider.setCurrentUser(any)).thenReturn(null);

        final result = usersRepository.checkUser('user1', 'pass1');

        expect(result, isA<User>());
        expect((result as User).name, equals('user1'));
        verify(mockSettingsRepository.setCurrentUser(user1)).called(1);
        verify(mockHiveProvider.setCurrentUser(user1)).called(1);
      });

      test('should return "userName" when user does not exist', () {
        usersRepository.users = [
          User('user1', 'pass1')..typeUser = TypeUser.viewer,
        ];

        final result = usersRepository.checkUser('nonexistent', 'pass');

        expect(result, equals('userName'));
        verifyNever(mockSettingsRepository.setCurrentUser(any));
        verifyNever(mockHiveProvider.setCurrentUser(any));
      });

      test('should return "usersPassword" when password is wrong', () {
        final user1 = User('user1', 'correctpass')..typeUser = TypeUser.viewer;
        usersRepository.users = [user1];

        final result = usersRepository.checkUser('user1', 'wrongpass');

        expect(result, equals('usersPassword'));
        verifyNever(mockSettingsRepository.setCurrentUser(any));
        verifyNever(mockHiveProvider.setCurrentUser(any));
      });

      test('should not call setCurrentUser when isFromHive is true', () {
        final user1 = User('user1', 'pass1')..typeUser = TypeUser.viewer;
        usersRepository.users = [user1];

        when(mockHiveProvider.setCurrentUser(any)).thenReturn(null);

        final result = usersRepository.checkUser('user1', 'pass1', isFromHive: true);

        expect(result, isA<User>());
        verifyNever(mockSettingsRepository.setCurrentUser(any));
        verify(mockHiveProvider.setCurrentUser(user1)).called(1);
      });

      test('should update currentTypeUser and emit to stream', () async {
        final user1 = User('user1', 'pass1')..typeUser = TypeUser.admin;
        usersRepository.users = [user1];

        when(mockSettingsRepository.setCurrentUser(any)).thenReturn(null);
        when(mockHiveProvider.setCurrentUser(any)).thenReturn(null);

        // Listen to stream
        final streamFuture = usersRepository.userStream.first;

        usersRepository.checkUser('user1', 'pass1');

        final emittedType = await streamFuture;
        expect(emittedType, equals(TypeUser.admin));
        expect(usersRepository.currentTypeUser, equals(TypeUser.admin));
      });
    });

    group('logoutUser', () {
      test('should reset user and emit TypeUser.none', () async {
        when(mockHiveProvider.setCurrentUser(null)).thenReturn(null);

        // Listen to stream
        final streamFuture = usersRepository.userStream.first;

        await usersRepository.logoutUser();

        final emittedType = await streamFuture;
        expect(emittedType, equals(TypeUser.none));
        expect(usersRepository.currentTypeUser, equals(TypeUser.none));
        verify(mockHiveProvider.setCurrentUser(null)).called(1);
      });
    });

    group('loadCurrentUser', () {
      test('should load and check user from Hive', () async {
        final savedUser = User('user1', 'pass1')..typeUser = TypeUser.viewer;
        usersRepository.users = [savedUser];

        when(mockHiveProvider.getCurrentUser()).thenReturn(savedUser);
        when(mockHiveProvider.setCurrentUser(any)).thenReturn(null);

        await usersRepository.loadCurrentUser();

        verify(mockHiveProvider.getCurrentUser()).called(1);
        verify(mockHiveProvider.setCurrentUser(savedUser)).called(1);
      });

      test('should return early when no user in Hive', () async {
        when(mockHiveProvider.getCurrentUser()).thenReturn(null);

        await usersRepository.loadCurrentUser();

        verify(mockHiveProvider.getCurrentUser()).called(1);
        verifyNever(mockHiveProvider.setCurrentUser(any));
      });
    });

    group('getCurrentUser', () {
      test('should return current user from Hive', () {
        final savedUser = User('user1', 'pass1')..typeUser = TypeUser.viewer;
        when(mockHiveProvider.getCurrentUser()).thenReturn(savedUser);

        final result = usersRepository.getCurrentUser();

        expect(result, equals(savedUser));
        verify(mockHiveProvider.getCurrentUser()).called(1);
      });

      test('should return null when no user is saved', () {
        when(mockHiveProvider.getCurrentUser()).thenReturn(null);

        final result = usersRepository.getCurrentUser();

        expect(result, isNull);
      });
    });
  });
}

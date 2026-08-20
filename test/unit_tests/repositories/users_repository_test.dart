import 'dart:async';

import 'package:default_project/model/user.dart';
import 'package:default_project/providers/hive_provider.dart';
import 'package:default_project/providers/pocketbase_provider.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/repositories/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

@GenerateMocks([
  PocketBaseProvider,
  HiveProvider,
  SettingsRepository,
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
    late MockPocketBaseProvider mockPocketBaseProvider;
    late MockHiveProvider mockHiveProvider;
    late MockSettingsRepository mockSettingsRepository;
    late StreamController<RealtimeChangeEvent<User>> userChangeController;

    setUp(() {
      mockPocketBaseProvider = MockPocketBaseProvider();
      mockHiveProvider = MockHiveProvider();
      mockSettingsRepository = MockSettingsRepository();
      userChangeController = StreamController<RealtimeChangeEvent<User>>.broadcast();

      // Setup default mock for PocketBase
      when(mockPocketBaseProvider.getListAppUsers()).thenAnswer((_) async => []);
      when(mockPocketBaseProvider.userChangeStream).thenAnswer((_) => userChangeController.stream);

      usersRepository = UsersRepository(
        hiveProvider: mockHiveProvider,
        pocketBaseProvider: mockPocketBaseProvider,
        settingsRepository: mockSettingsRepository,
      );
    });

    tearDown(() {
      usersRepository.userController.close();
      userChangeController.close();
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

    group('loadUsersFromServer', () {
      test('should load users successfully', () async {
        final user1 = User('user1', 'pass1')..typeUser = TypeUser.viewer;
        final user2 = User('user2', 'pass2')..typeUser = TypeUser.admin;

        when(mockPocketBaseProvider.getListAppUsers()).thenAnswer((_) async => [user1, user2]);

        await usersRepository.loadUsersFromServer();

        expect(usersRepository.users.length, equals(2));
        expect(usersRepository.users[0].name, equals('user1'));
        expect(usersRepository.users[1].name, equals('user2'));
      });

      test('should handle empty users list', () async {
        when(mockPocketBaseProvider.getListAppUsers()).thenAnswer((_) async => []);

        await usersRepository.loadUsersFromServer();

        expect(usersRepository.users, isEmpty);
      });

      test('should handle errors gracefully', () async {
        when(mockPocketBaseProvider.getListAppUsers()).thenThrow(Exception('Server error'));

        // Should not throw
        await usersRepository.loadUsersFromServer();

        expect(usersRepository.users, isEmpty);
      });
    });

    group('updateListUsersFromServer', () {
      test('should update users list', () async {
        final user1 = User('user1', 'pass1')..typeUser = TypeUser.viewer;

        when(mockPocketBaseProvider.getListAppUsers()).thenAnswer((_) async => [user1]);

        await usersRepository.updateListUsersFromServer();

        expect(usersRepository.users.length, equals(1));
        expect(usersRepository.users[0].name, equals('user1'));
      });
    });

    group('createUser', () {
      test('should create user successfully', () async {
        final newUser = User('newuser', 'password')..typeUser = TypeUser.viewer;

        when(mockPocketBaseProvider.addOrUpdateAppUser(newUser)).thenAnswer((_) async => true);

        final result = await usersRepository.createUser(newUser);

        expect(result, isTrue);
        verify(mockPocketBaseProvider.addOrUpdateAppUser(newUser)).called(1);
      });

      test('should return false on error', () async {
        final newUser = User('newuser', 'password')..typeUser = TypeUser.viewer;

        when(mockPocketBaseProvider.addOrUpdateAppUser(newUser)).thenThrow(Exception('Server error'));

        final result = await usersRepository.createUser(newUser);

        expect(result, isFalse);
      });
    });

    group('deleteUser', () {
      test('should delete user successfully', () async {
        final user = User('user1', 'pass1')..typeUser = TypeUser.viewer;

        when(mockPocketBaseProvider.deleteAppUser(user)).thenAnswer((_) async => true);

        final result = await usersRepository.deleteUser(user);

        expect(result, isTrue);
        verify(mockPocketBaseProvider.deleteAppUser(user)).called(1);
      });

      test('should return false on error', () async {
        final user = User('user1', 'pass1')..typeUser = TypeUser.viewer;

        when(mockPocketBaseProvider.deleteAppUser(user)).thenThrow(Exception('Server error'));

        final result = await usersRepository.deleteUser(user);

        expect(result, isFalse);
      });
    });

    group('updateUser', () {
      test('should update user successfully', () async {
        final user = User('user1', 'newpass')..typeUser = TypeUser.admin;

        when(mockPocketBaseProvider.addOrUpdateAppUser(user)).thenAnswer((_) async => true);

        final result = await usersRepository.updateUser(user);

        expect(result, isTrue);
        verify(mockPocketBaseProvider.addOrUpdateAppUser(user)).called(1);
      });

      test('should return false on error', () async {
        final user = User('user1', 'newpass')..typeUser = TypeUser.admin;

        when(mockPocketBaseProvider.addOrUpdateAppUser(user)).thenThrow(Exception('Server error'));

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
        // A failed login clears the stored user rather than leaving the
        // previous one behind.
        verify(mockHiveProvider.setCurrentUser(null)).called(1);
      });

      test('should return "usersPassword" when password is wrong', () {
        final user1 = User('user1', 'correctpass')..typeUser = TypeUser.viewer;
        usersRepository.users = [user1];

        final result = usersRepository.checkUser('user1', 'wrongpass');

        expect(result, equals('usersPassword'));
        verifyNever(mockSettingsRepository.setCurrentUser(any));
        verify(mockHiveProvider.setCurrentUser(null)).called(1);
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

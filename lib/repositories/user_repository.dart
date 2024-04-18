import 'dart:async';

import 'package:collection/collection.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../model/user.dart';
import '../providers/firebase_provider.dart';
import '../providers/hive_provider.dart';

class UsersRepository {
  final HiveProvider _hiveProvider;
  final FirebaseProvider _firebaseProvider;
  final SettingsRepository settingsRepository;
  TypeUser currentTypeUser = TypeUser.none;

  final userController = StreamController<TypeUser>.broadcast();
  Stream<TypeUser> get userStream => userController.stream.asBroadcastStream();

  List<User> users = <User>[];

  UsersRepository({
    required HiveProvider hiveProvider,
    required FirebaseProvider firebaseProvider,
    required this.settingsRepository,
  })  : _hiveProvider = hiveProvider,
        _firebaseProvider = firebaseProvider;

  Future<void> loadUsersFromFirebase() async {
    try {
      final _users = await _firebaseProvider.userCollection.get();
      users = <User>[];
      for (var user in _users.docs) {
        final userObject = User.fromJson(user.data());
        users.add(userObject);
      }
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> logoutUser() async {
    _hiveProvider.setCurrentUser(null);
    currentTypeUser = TypeUser.none;
    userController.sink.add(TypeUser.none);
  }

  Future<void> updateListUsersFromFirebase() async {
    try {
      final _users = await _firebaseProvider.userCollection.get();
      users = <User>[];
      for (var user in _users.docs) {
        final userObject = User.fromJson(user.data());
        users.add(userObject);
      }
    } catch (e) {
      logger.e(e);
    }
  }

  Future<bool> createUser(User newUser) async {
    try {
      await _firebaseProvider.userCollection.doc(newUser.name).set(newUser.toJson());
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<bool> deleteUser(User user) async {
    try {
      await _firebaseProvider.userCollection.doc(user.name).delete();
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<bool> updateUser(User newUser) async {
    try {
      await _firebaseProvider.userCollection.doc(newUser.name).update(newUser.toJson());
      return true;
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<void> loadCurrentUser() async {
    User? user = _hiveProvider.getCurrentUser();
    if (user == null) {
      return;
    }
    if (checkUser(user.name, user.password, isFromHive: true) is User) {
      logger.d('User ${user.name} is logged in');
    } else {
      logger.d('User ${user.name} is not logged in');
    }
  }

  dynamic checkUser(String username, String password, {bool isFromHive = false}) {
    final user = users.firstWhereOrNull((element) => element.name == username);
    final userWithPassword = users.firstWhereOrNull((element) => element.name == username && element.password == password);

    if (user == null) {
      logger.w('User $username does not exist');
      return 'userName';
    }
    if (userWithPassword == null) {
      logger.w('User $username has wrong password');
      return 'usersPassword';
    }
    if (!isFromHive) {
      settingsRepository.setCurrentUser(user);
    }
    currentTypeUser = user.typeUser;
    _hiveProvider.setCurrentUser(user);
    userController.sink.add(user.typeUser);
    return user;
  }

  User? getCurrentUser() {
    return _hiveProvider.getCurrentUser();
  }
}

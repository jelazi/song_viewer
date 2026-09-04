import 'dart:async';

import 'package:collection/collection.dart';
import 'package:song_viewer/repositories/settings_repository.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../model/user.dart';
import '../providers/hive_provider.dart';
import '../providers/pocketbase_provider.dart';

class UsersRepository {
  final HiveProvider _hiveProvider;
  final PocketBaseProvider _pocketBaseProvider;
  final SettingsRepository settingsRepository;
  TypeUser currentTypeUser = TypeUser.none;

  final userController = StreamController<TypeUser>.broadcast();
  Stream<TypeUser> get userStream => userController.stream.asBroadcastStream();

  final isChangedUsersController = StreamController<int>.broadcast();
  Stream<int> get isChangedUsers => isChangedUsersController.stream.asBroadcastStream();
  int _isChangedUsersValue = 0;

  List<User> users = <User>[];

  UsersRepository({
    required HiveProvider hiveProvider,
    required PocketBaseProvider pocketBaseProvider,
    required this.settingsRepository,
  })  : _hiveProvider = hiveProvider,
        _pocketBaseProvider = pocketBaseProvider {
    _init();
  }

  void _init() {
    // Listen to granular user change events via PocketBase realtime
    _pocketBaseProvider.userChangeStream.listen((event) {
      _handleUserRealtimeEvent(event);
    });
  }

  void _handleUserRealtimeEvent(RealtimeChangeEvent<User> event) {
    if (event.isDelete) {
      users.removeWhere((u) => u.name == event.recordId);
      logger.i('Realtime: user deleted name=${event.recordId}');
    } else if (event.isCreate && event.record != null) {
      final existing = users.firstWhereOrNull((u) => u.name == event.record!.name);
      if (existing == null) {
        users.add(event.record!);
        logger.i('Realtime: user created name=${event.record!.name} updated=${event.serverUpdated}');
      }
    } else if (event.isUpdate && event.record != null) {
      final index = users.indexWhere((u) => u.name == event.record!.name);
      if (index >= 0) {
        users[index] = event.record!;
        logger.i('Realtime: user updated name=${event.record!.name} updated=${event.serverUpdated}');
      } else {
        users.add(event.record!);
        logger.i('Realtime: user updated (new) name=${event.record!.name} updated=${event.serverUpdated}');
      }
    }
    isChangedUsersController.sink.add(_isChangedUsersValue++);
  }

  Future<void> loadUsersFromServer() async {
    try {
      users = await _pocketBaseProvider.getListAppUsers();
    } catch (e) {
      logger.e(e);
    }
  }

  Future<void> logoutUser() async {
    _hiveProvider.setCurrentUser(null);
    currentTypeUser = TypeUser.none;
    userController.sink.add(TypeUser.none);
  }

  Future<void> updateListUsersFromServer() async {
    try {
      users = await _pocketBaseProvider.getListAppUsers();
    } catch (e) {
      logger.e(e);
    }
  }

  Future<bool> createUser(User newUser) async {
    try {
      return await _pocketBaseProvider.addOrUpdateAppUser(newUser);
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<bool> deleteUser(User user) async {
    try {
      return await _pocketBaseProvider.deleteAppUser(user);
    } catch (e) {
      logger.e(e);
      return false;
    }
  }

  Future<bool> updateUser(User newUser) async {
    try {
      return await _pocketBaseProvider.addOrUpdateAppUser(newUser);
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
      logger.v('User ${user.name} is logged in');
    } else {
      logger.v('User ${user.name} is not logged in');
    }
  }

  dynamic checkUser(String username, String password, {bool isFromHive = false}) {
    final user = users.firstWhereOrNull((element) => element.name == username);
    final userWithPassword = users.firstWhereOrNull((element) => element.name == username && element.password == password);

    if (user == null) {
      if (!isFromHive) {
        logger.w('User $username does not exist');
      }
      _hiveProvider.setCurrentUser(null);
      return 'userName';
    }
    if (userWithPassword == null) {
      if (!isFromHive) {
        logger.w('User $username has wrong password');
      }
      _hiveProvider.setCurrentUser(null);
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

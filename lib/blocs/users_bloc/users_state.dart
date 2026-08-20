// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'users_bloc.dart';

class UsersState extends Equatable {
  final List<User> users;
  final User? currentUser;

  const UsersState({required this.users, required this.currentUser});

  /// Whether the user may create and edit songs in the library.
  ///
  /// Without a shared server there is no `currentUser` and no server-issued
  /// role, so the owner of the device has full rights. Use this instead of
  /// reading [currentUser] directly — a raw role check is always false in a
  /// local-first build.
  bool get canManageLibrary {
    if (!Features.sharedServer) return true;
    final type = currentUser?.typeUser;
    return type == TypeUser.admin || type == TypeUser.superuser;
  }

  @override
  List<Object> get props => [users, currentUser ?? ''];

  UsersState copyWith({
    List<User>? users,
    User? currentUser,
  }) {
    return UsersState(
      users: users ?? this.users,
      currentUser: currentUser,
    );
  }
}

class UsersInitial extends UsersState {
  const UsersInitial({required super.users, required super.currentUser});
}

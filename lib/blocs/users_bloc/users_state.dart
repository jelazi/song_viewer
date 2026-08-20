// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'users_bloc.dart';

class UsersState extends Equatable {
  final List<User> users;
  final User? currentUser;

  const UsersState({required this.users, required this.currentUser});

  /// Whether the user may create and edit songs in the library.
  ///
  /// With a shared server the answer is the server-issued role. Without one it
  /// cannot be: a local-first build never authenticates, so `currentUser` stays
  /// null forever and every role check would fail closed — a fresh store
  /// install could not even create its first song. There is no server to hand
  /// out roles and nobody else to protect the library from, so the owner of the
  /// device is the owner of the library.
  ///
  /// See plans/store-release-plan.md §9 and §10.
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

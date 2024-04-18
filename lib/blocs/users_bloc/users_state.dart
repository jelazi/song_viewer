// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'users_bloc.dart';

class UsersState extends Equatable {
  final List<User> users;
  final User? currentUser;

  const UsersState({required this.users, required this.currentUser});

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

part of 'users_bloc.dart';

class UsersEvent extends Equatable {
  const UsersEvent();

  @override
  List<Object> get props => [];
}

class _InitializeUsers extends UsersEvent {}

class UpdateUsers extends UsersEvent {}

class LoginUser extends UsersEvent {
  final String nameUser;
  final String passwordUser;

  LoginUser({required this.nameUser, required this.passwordUser});

  @override
  List<Object> get props => [nameUser, passwordUser];
}

class LogoutUser extends UsersEvent {
  final User typeUser;

  LogoutUser({required this.typeUser});

  @override
  List<Object> get props => [typeUser];
}

class AddUser extends UsersEvent {
  final User user;

  AddUser({required this.user});

  @override
  List<Object> get props => [user];
}

class DeleteUser extends UsersEvent {
  final User user;

  DeleteUser({required this.user});

  @override
  List<Object> get props => [user];
}

class UpdateUser extends UsersEvent {
  final User user;

  UpdateUser({required this.user});

  @override
  List<Object> get props => [user];
}

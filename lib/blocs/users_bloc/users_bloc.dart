import 'package:bloc/bloc.dart';
import 'package:default_project/repositories/user_repository.dart';
import 'package:default_project/view/desktop_view/widgets/my_toast.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';

import '../../model/user.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersRepository usersRepository;
  UsersBloc({
    required this.usersRepository,
  }) : super(const UsersInitial(
          users: [],
          currentUser: null,
        )) {
    on<_InitializeUsers>(_initializeUsers);
    on<UpdateUsers>(_updateUsers);
    on<LoginUser>(_loginUser);
    on<LogoutUser>(_logoutUser);
    on<AddUser>(_addUser);
    on<DeleteUser>(_deleteUser);
    on<UpdateUser>(_updateUser);

    add(_InitializeUsers());

    usersRepository.userStream.listen((event) {
      add(UpdateUsers());
    });

    // Listen to realtime user changes from PocketBase
    usersRepository.isChangedUsers.listen((_) {
      add(UpdateUsers());
    });
  }

  void _initializeUsers(_InitializeUsers event, Emitter<UsersState> emit) async {
    final state = this.state;
    await usersRepository.loadUsersFromServer();
    User? currentUser = usersRepository.getCurrentUser();
    emit(state.copyWith(
      users: usersRepository.users,
      currentUser: currentUser,
    ));
  }

  void _updateUsers(UpdateUsers event, Emitter<UsersState> emit) async {
    final state = this.state;
    await usersRepository.updateListUsersFromServer();

    emit(state.copyWith(
      users: usersRepository.users,
    ));
  }

  void _loginUser(LoginUser event, Emitter<UsersState> emit) async {
    final state = this.state;
    final result = usersRepository.checkUser(event.nameUser, event.passwordUser);
    if (result is String) {
      if (result == 'userName') {
        MyToast.showText(text: 'wrongUserName'.tr(), typeNotification: TypeNotification.error);
      } else if (result == 'userPassword') {
        MyToast.showText(text: 'wrongPassword'.tr(), typeNotification: TypeNotification.error);
      }
    }
    if (result is User) {
      emit(state.copyWith(currentUser: result));
    }
  }

  void _logoutUser(LogoutUser event, Emitter<UsersState> emit) async {
    final state = this.state;
    usersRepository.logoutUser();
    emit(state.copyWith(currentUser: null));
  }

  void _addUser(AddUser event, Emitter<UsersState> emit) async {
    final state = this.state;
    await usersRepository.createUser(event.user);
    await usersRepository.updateListUsersFromServer();
    emit(state.copyWith(users: List.from(usersRepository.users)));
  }

  void _deleteUser(DeleteUser event, Emitter<UsersState> emit) async {
    final state = this.state;
    await usersRepository.deleteUser(event.user);
    await usersRepository.updateListUsersFromServer();
    emit(state.copyWith(users: List.from(usersRepository.users)));
  }

  void _updateUser(UpdateUser event, Emitter<UsersState> emit) async {
    final state = this.state;
    await usersRepository.updateUser(event.user);
    await usersRepository.updateListUsersFromServer();
    emit(state.copyWith(users: List.from(usersRepository.users)));
  }
}

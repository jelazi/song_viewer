import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
part 'notification_event.dart';
part 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  NotificationBloc() : super(NotificationInitial(message: [])) {
    on<CreateMessage>(_onCreateMessage);
    /* repository.errorMessage.listen((error) {
      add(CreateMessage(message: error));
    });*/
  }

  void _onCreateMessage(CreateMessage event, Emitter<NotificationState> emit) {
    final state = this.state;
    var listMessage = state.message;
    listMessage.add(event.message);
    if (listMessage.length > 100) {
      listMessage.remove(listMessage.first);
    }
    emit(this.state.copyWith(message: listMessage));
  }
}

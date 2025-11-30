part of 'desktop_ribbon_menu_bloc.dart';

class DesktopRibbonMenuEvent extends Equatable {
  const DesktopRibbonMenuEvent();

  @override
  List<Object> get props => [];
}

class ChangeHomeBody extends DesktopRibbonMenuEvent {
  final String bodyName;
  const ChangeHomeBody({required this.bodyName});
  @override
  List<Object> get props => [bodyName];
}

class ChangeEditBody extends DesktopRibbonMenuEvent {
  final String bodyName;
  const ChangeEditBody({required this.bodyName});
  @override
  List<Object> get props => [bodyName];
}

class ChangeIsSelectedSong extends DesktopRibbonMenuEvent {
  final Song? song;
  const ChangeIsSelectedSong({required this.song});
  @override
  List<Object> get props => [song ?? ''];
}

class ChangePresentationWindowState extends DesktopRibbonMenuEvent {
  final bool isOpen;
  const ChangePresentationWindowState({required this.isOpen});
  @override
  List<Object> get props => [isOpen];
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'desktop_ribbon_menu_bloc.dart';

class DesktopRibbonMenuState extends Equatable {
  final String bodyName;
  final String bodyEditName;
  final bool isSelectedSong;
  final bool isPresentationWindowOpen;
  const DesktopRibbonMenuState({
    required this.bodyName,
    required this.bodyEditName,
    required this.isSelectedSong,
    required this.isPresentationWindowOpen,
  });

  @override
  List<Object> get props => [bodyName, bodyEditName, isSelectedSong, isPresentationWindowOpen];

  DesktopRibbonMenuState copyWith({
    String? bodyName,
    String? bodyEditName,
    bool? isSelectedSong,
    bool? isPresentationWindowOpen,
  }) {
    return DesktopRibbonMenuState(
      bodyName: bodyName ?? this.bodyName,
      bodyEditName: bodyEditName ?? this.bodyEditName,
      isSelectedSong: isSelectedSong ?? this.isSelectedSong,
      isPresentationWindowOpen: isPresentationWindowOpen ?? this.isPresentationWindowOpen,
    );
  }
}

class DesktopRibbonMenuInitial extends DesktopRibbonMenuState {
  const DesktopRibbonMenuInitial({
    required super.bodyName,
    required super.bodyEditName,
    required super.isSelectedSong,
    required super.isPresentationWindowOpen,
  });
}

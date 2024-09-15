// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'home_page_bloc.dart';

class HomePageState extends Equatable {
  final String selectedSongId;
  final List<Song> listSong;
  final bool isEditIconVisible;
  final List<String> listExpandedSongs;
  final List<String> listAllGroups;
  final List<String> listSelectedGroups;
  final String selectedPage;

  const HomePageState({
    required this.selectedSongId,
    required this.listSong,
    required this.isEditIconVisible,
    required this.listExpandedSongs,
    required this.listAllGroups,
    required this.listSelectedGroups,
    required this.selectedPage,
  });

  @override
  List<Object> get props => [selectedSongId, listSong, listExpandedSongs, isEditIconVisible, listAllGroups, listSelectedGroups, selectedPage];

  HomePageState copyWith({
    String? selectedSongId,
    List<Song>? listSong,
    bool? isEditIconVisible,
    List<String>? listExpandedSongs,
    List<String>? listAllGroups,
    List<String>? listSelectedGroups,
    String? selectedPage,
  }) {
    return HomePageState(
      selectedSongId: selectedSongId ?? this.selectedSongId,
      listSong: listSong ?? this.listSong,
      isEditIconVisible: isEditIconVisible ?? this.isEditIconVisible,
      listExpandedSongs: listExpandedSongs ?? this.listExpandedSongs,
      listAllGroups: listAllGroups ?? this.listAllGroups,
      listSelectedGroups: listSelectedGroups ?? this.listSelectedGroups,
      selectedPage: selectedPage ?? this.selectedPage,
    );
  }
}

class HomePageInitial extends HomePageState {
  const HomePageInitial({
    required super.isEditIconVisible,
    required super.selectedSongId,
    required super.listSong,
    required super.listExpandedSongs,
    required super.listAllGroups,
    required super.listSelectedGroups,
    required super.selectedPage,
  });
}

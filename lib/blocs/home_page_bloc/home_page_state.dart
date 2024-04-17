// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'home_page_bloc.dart';

class HomePageState extends Equatable {
  final String selectedSongId;
  final List<Song> listSong;
  final bool isEditIconVisible;
  final List<String> listExpandedSongs;
  final TypeUser typeUser;
  final List<String> listAllGroups;

  const HomePageState({
    required this.selectedSongId,
    required this.listSong,
    required this.listExpandedSongs,
    required this.isEditIconVisible,
    required this.typeUser,
    required this.listAllGroups,
  });

  @override
  List<Object> get props => [selectedSongId, listSong, listExpandedSongs, isEditIconVisible, typeUser, listAllGroups];

  HomePageState copyWith({
    String? selectedSongId,
    List<Song>? listSong,
    bool? isEditIconVisible,
    List<String>? listExpandedSongs,
    TypeUser? typeUser,
    List<String>? listAllGroups,
  }) {
    return HomePageState(
      selectedSongId: selectedSongId ?? this.selectedSongId,
      listSong: listSong ?? this.listSong,
      isEditIconVisible: isEditIconVisible ?? this.isEditIconVisible,
      listExpandedSongs: listExpandedSongs ?? this.listExpandedSongs,
      typeUser: typeUser ?? this.typeUser,
      listAllGroups: listAllGroups ?? this.listAllGroups,
    );
  }
}

class HomePageInitial extends HomePageState {
  const HomePageInitial({
    required super.isEditIconVisible,
    required super.selectedSongId,
    required super.listSong,
    required super.listExpandedSongs,
    required super.typeUser,
    required super.listAllGroups,
  });
}

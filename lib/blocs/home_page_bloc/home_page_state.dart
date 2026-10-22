// ignore_for_file: public_member_api_docs, sort_constructors_first
part of 'home_page_bloc.dart';

class HomePageState extends Equatable {
  final String selectedSongId;
  final List<Song> listSong;
  final bool isEditIconVisible;
  final bool superuserMode;
  final List<String> listExpandedSongs;
  final List<String> listAllGroups;
  final List<String> listSelectedGroups;
  final String selectedPage;

  /// The currently applied song filter text. Kept in state so the filter field
  /// and the displayed list stay in sync even when the list widget is remounted.
  final String currentFilter;

  final bool isRefreshing;

  const HomePageState({
    required this.selectedSongId,
    required this.listSong,
    required this.isEditIconVisible,
    required this.superuserMode,
    required this.listExpandedSongs,
    required this.listAllGroups,
    required this.listSelectedGroups,
    required this.selectedPage,
    this.currentFilter = '',
    this.isRefreshing = false,
  });

  @override
  List<Object> get props =>
      [selectedSongId, listSong, listExpandedSongs, isEditIconVisible, superuserMode, listAllGroups, listSelectedGroups, selectedPage, currentFilter, isRefreshing];

  HomePageState copyWith({
    String? selectedSongId,
    List<Song>? listSong,
    bool? isEditIconVisible,
    bool? superuserMode,
    List<String>? listExpandedSongs,
    List<String>? listAllGroups,
    List<String>? listSelectedGroups,
    String? selectedPage,
    String? currentFilter,
    bool? isRefreshing,
  }) {
    return HomePageState(
      selectedSongId: selectedSongId ?? this.selectedSongId,
      listSong: listSong ?? this.listSong,
      isEditIconVisible: isEditIconVisible ?? this.isEditIconVisible,
      superuserMode: superuserMode ?? this.superuserMode,
      listExpandedSongs: listExpandedSongs ?? this.listExpandedSongs,
      listAllGroups: listAllGroups ?? this.listAllGroups,
      listSelectedGroups: listSelectedGroups ?? this.listSelectedGroups,
      selectedPage: selectedPage ?? this.selectedPage,
      currentFilter: currentFilter ?? this.currentFilter,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class HomePageInitial extends HomePageState {
  const HomePageInitial({
    required super.isEditIconVisible,
    required super.superuserMode,
    required super.selectedSongId,
    required super.listSong,
    required super.listExpandedSongs,
    required super.listAllGroups,
    required super.listSelectedGroups,
    required super.selectedPage,
  });
}

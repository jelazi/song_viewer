part of 'home_page_bloc.dart';

class HomePageEvent extends Equatable {
  const HomePageEvent();

  @override
  List<Object> get props => [];
}

class _Init extends HomePageEvent {
  const _Init();

  @override
  List<Object> get props => [];
}

class UpdateSongData extends HomePageEvent {
  final bool updateSongRepository;
  const UpdateSongData({this.updateSongRepository = true});

  @override
  List<Object> get props => [updateSongRepository];
}

class FilterSong extends HomePageEvent {
  final String filter;

  const FilterSong({
    required this.filter,
  });

  @override
  List<Object> get props => [filter];
}

class ChangeSelectedSong extends HomePageEvent {
  final String selectedSongId;

  const ChangeSelectedSong({
    required this.selectedSongId,
  });

  @override
  List<Object> get props => [selectedSongId];
}

class SelectSong extends HomePageEvent {
  final String selectedSongId;

  const SelectSong({
    required this.selectedSongId,
  });

  @override
  List<Object> get props => [selectedSongId];
}

class UpdateSettingsData extends HomePageEvent {
  const UpdateSettingsData();

  @override
  List<Object> get props => [];
}

class ChangeExpandedCard extends HomePageEvent {
  final String songId;

  const ChangeExpandedCard({
    required this.songId,
  });

  @override
  List<Object> get props => [songId];
}

class UpdateSong extends HomePageEvent {
  final Song song;

  const UpdateSong({
    required this.song,
  });

  @override
  List<Object> get props => [song];
}

class CreateGroup extends HomePageEvent {
  final String group;
  const CreateGroup({required this.group});

  @override
  List<Object> get props => [group];
}

class DeleteGroup extends HomePageEvent {
  final String group;
  const DeleteGroup({required this.group});

  @override
  List<Object> get props => [group];
}

class ChangeGroup extends HomePageEvent {
  final String group;
  final String newGroup;
  const ChangeGroup({required this.group, required this.newGroup});

  @override
  List<Object> get props => [group, newGroup];
}

class SelectGroups extends HomePageEvent {
  final List<String> groups;
  const SelectGroups({required this.groups});

  @override
  List<Object> get props => [groups];
}

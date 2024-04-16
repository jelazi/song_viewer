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
  const UpdateSongData();

  @override
  List<Object> get props => [];
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

class LoginUser extends HomePageEvent {
  final TypeUser typeUser;
  const LoginUser({
    required this.typeUser,
  });
  @override
  List<Object> get props => [typeUser];
}

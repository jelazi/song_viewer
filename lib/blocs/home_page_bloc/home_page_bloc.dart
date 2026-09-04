// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:song_viewer/repositories/settings_repository.dart';
import 'package:song_viewer/repositories/songs_repository.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/song/song.dart';
import '../../repositories/user_repository.dart';
import '../../view/desktop_view/widgets/my_toast.dart';

part 'home_page_event.dart';
part 'home_page_state.dart';

class HomePageBloc extends Bloc<HomePageEvent, HomePageState> {
  SongsRepository songsRepository;
  SettingsRepository settingsRepository;
  UsersRepository usersRepository;

  HomePageBloc({
    required this.songsRepository,
    required this.settingsRepository,
    required this.usersRepository,
  }) : super(const HomePageInitial(
          selectedSongId: '',
          isEditIconVisible: false,
          superuserMode: false,
          listSong: [],
          listExpandedSongs: [],
          listAllGroups: [],
          listSelectedGroups: [],
          selectedPage: 'preview',
        )) {
    on<_Init>(_init);
    on<UpdateSongData>(_updateSongData);
    on<FilterSong>(_filterSong);
    on<ChangeSelectedSong>(_changeSelectedSong);
    on<SelectSong>(_selectSong);
    on<UpdateSettingsData>(_updateSettingsData);
    on<ChangeExpandedCard>(_changeExpandedCard);
    on<UpdateSong>(_updateSong);
    on<CreateGroup>(_createGroup);
    on<DeleteGroup>(_deleteGroup);
    on<ChangeGroup>(_changeGroup);
    on<SelectGroups>(_selectGroups);
    on<SelectPage>(_selectPage);
    on<DeleteSong>(_deleteSong);
    songsRepository.selectSongData.listen((event) {
      add(ChangeSelectedSong(selectedSongId: event));
    });

    songsRepository.isChangedListSong.listen((event) {
      add(const UpdateSongData(updateSongRepository: false));
    });

    add(const _Init());
  }

  void _init(_Init event, Emitter<HomePageState> emit) {
    final state = this.state;

    emit(state.copyWith(
      isEditIconVisible: settingsRepository.isEditIconVisible,
      superuserMode: settingsRepository.superuserMode,
      listSong: List<Song>.from(songsRepository.songs),
      listAllGroups: songsRepository.listAllGroups,
      listSelectedGroups: List<String>.from(songsRepository.listAllGroups),
      selectedSongId: songsRepository.selectedSongId,
      listExpandedSongs: [],
    ));
  }

  void _updateSongData(UpdateSongData event, Emitter<HomePageState> emit) async {
    final state = this.state;
    if (event.updateSongRepository) {
      await songsRepository.updateSongsFromServer();
    }
    // Re-apply the active filter so a refresh (e.g. after a delete) keeps the
    // current view instead of resetting to the full list.
    emit(state.copyWith(
      listSong: songsRepository.getSongByFilter(state.currentFilter),
    ));
  }

  void _updateSettingsData(UpdateSettingsData event, Emitter<HomePageState> emit) {
    final state = this.state;
    emit(state.copyWith(
      isEditIconVisible: settingsRepository.isEditIconVisible,
      superuserMode: settingsRepository.superuserMode,
    ));
  }

  void _filterSong(FilterSong event, Emitter<HomePageState> emit) {
    final state = this.state;
    emit(state.copyWith(currentFilter: event.filter, listSong: songsRepository.getSongByFilter(event.filter)));
  }

  void _changeSelectedSong(ChangeSelectedSong event, Emitter<HomePageState> emit) {
    final state = this.state;
    emit(state.copyWith(selectedSongId: event.selectedSongId));
  }

  void _selectSong(SelectSong event, Emitter<HomePageState> emit) {
    songsRepository.selectSong(event.selectedSongId, event.title, event.interpret, event.lyricsWithoutChords, event.lyricsWithChords);
  }

  void _changeExpandedCard(ChangeExpandedCard event, Emitter<HomePageState> emit) {
    final state = this.state;
    final oldListExpandedSongs = List<String>.from(state.listExpandedSongs);
    var listExpandedSongs = <String>[];
    if (oldListExpandedSongs.contains(event.songId)) {
    } else {
      listExpandedSongs.add(event.songId);
    }
    emit(state.copyWith(listExpandedSongs: listExpandedSongs));
  }

  void _updateSong(UpdateSong event, Emitter<HomePageState> emit) async {
    final state = this.state;
    await songsRepository.updateSong(event.song);
    emit(state.copyWith(listSong: List<Song>.from(songsRepository.songs)));
  }

  void _createGroup(CreateGroup event, Emitter<HomePageState> emit) async {
    final state = this.state;
    await songsRepository.createGroup(event.group);
    emit(state.copyWith(listAllGroups: List<String>.from(songsRepository.listAllGroups)));
  }

  void _deleteGroup(DeleteGroup event, Emitter<HomePageState> emit) async {
    final state = this.state;
    await songsRepository.deleteGroup(event.group);
    emit(state.copyWith(listAllGroups: List<String>.from(songsRepository.listAllGroups)));
  }

  void _changeGroup(ChangeGroup event, Emitter<HomePageState> emit) async {
    final state = this.state;
    await songsRepository.updateGroup(event.group, event.newGroup);
    emit(state.copyWith(listAllGroups: List<String>.from(songsRepository.listAllGroups)));
  }

  void _selectGroups(SelectGroups event, Emitter<HomePageState> emit) {
    final state = this.state;
    final listAllSongs = List<Song>.from(songsRepository.songs);
    final listSelectedSongs = <Song>[];
    for (Song song in listAllSongs) {
      if (song.groups == null) {
        continue;
      }
      if (song.groups!.any((element) => event.groups.contains(element))) {
        listSelectedSongs.add(song);
      }
    }
    emit(state.copyWith(listSelectedGroups: List<String>.from(event.groups), listSong: listSelectedSongs));
  }

  void _selectPage(SelectPage event, Emitter<HomePageState> emit) {
    final state = this.state;
    emit(state.copyWith(selectedPage: event.page));
  }

  void _deleteSong(DeleteSong event, Emitter<HomePageState> emit) async {
    final state = this.state;
    final result = await songsRepository.deleteSong(event.song.id);

    if (result) {
      MyToast.showText(text: '${'songs'.tr()}: ${event.song.title} ${'deleted'.tr()}', typeNotification: TypeNotification.success);
      // Drop the deleted song from the currently shown list right away. We must
      // not refresh from the server here: deleteSong already updated the local
      // store/cache, and a failing/slow server fetch would throw before this
      // emit, leaving the deleted song visible until the next restart.
      emit(state.copyWith(listSong: state.listSong.where((song) => song.id != event.song.id).toList()));
    }
  }
}

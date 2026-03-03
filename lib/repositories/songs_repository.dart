// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../model/song/song.dart';
import '../model/update_songlist_data.dart';
import '../providers/firebase_provider.dart';
import '../providers/hive_provider.dart';
import '../services/auxiliary_functions.dart';

class SongsRepository {
  final HiveProvider _hiveProvider;
  final FirebaseProvider _firebaseProvider;

  final selectSongController = StreamController<String>.broadcast();
  Stream<String> get selectSongData => selectSongController.stream.asBroadcastStream();

  final isChangedListSongController = StreamController<int>.broadcast();
  Stream<int> get isChangedListSong => isChangedListSongController.stream.asBroadcastStream();
  int isChangedListSongValue = 0;
  late UpdateSongListData updateSongListData;

  final _songs = <Song>[];
  String selectedSongId = '';
  List<String> listAllGroups = [];

  List<Song> get songs {
    var songs = List<Song>.from(_songs);

    songs.sort((a, b) {
      return collStr(a.title).compareTo(collStr(b.title));
    });
    return songs;
  }

  SongsRepository({
    required HiveProvider hiveProvider,
    required FirebaseProvider firebaseProvider,
  })  : _hiveProvider = hiveProvider,
        _firebaseProvider = firebaseProvider {
    _init();
  }

  void _init() {
    updateSongListData = _hiveProvider.getUpdateSongListData('updateSongListData') ?? UpdateSongListData(DateTime(1900), {});

    // Listen to selected song changes (works on all platforms including Windows)
    _firebaseProvider.selectedSongStream.listen((data) {
      if (data != null && data['song'] != null) {
        selectSongController.sink.add(data['song'].toString());
        selectedSongId = data['song'].toString();
      }
    });

    // Listen to song list update notifications (works on all platforms including Windows)
    _firebaseProvider.updateSongListStream.listen((data) {
      if (data != null) {
        try {
          final castedData = Map<String, dynamic>.from(data);
          final newUpdateSongListData = UpdateSongListData.fromJson(castedData);
          if (newUpdateSongListData.lastUpdate.isAfter(updateSongListData.lastUpdate)) {
            updateDataByUpdateSongListData(newUpdateSongListData);
          }
        } catch (e) {
          logger.e('Error update song list from firebase: $e');
        }
      }
    });
  }

  void updateDataByUpdateSongListData(UpdateSongListData newUpdateSongListData) {
    updateSongListData = newUpdateSongListData;
    _hiveProvider.setUpdateSongListData('updateSongListData', updateSongListData);
    updateSongsFromFirebase();
  }

  Future<void> loadSongsFromFirebase() async {
    final newSongs = await _firebaseProvider.getListSongsFromFirestore();
    for (Song song in newSongs) {
      if (_songs.firstWhereOrNull((val) => val.id == song.id) == null) {
        _songs.add(song);
      } else {
        //TODO: update song from firebase;
      }
    }
  }

  Future<void> updateSongsFromFirebase() async {
    final newSongs = await _firebaseProvider.getListSongsFromFirestore();
    for (Song song in newSongs) {
      if (_songs.firstWhereOrNull((val) => val.id == song.id) == null) {
        _songs.add(song);
      } else {
        Song oldSong = _songs.firstWhere((val) => val.id == song.id);
        final listChanged = song.checkModifiedSong(oldSong, false);
        if (listChanged.isNotEmpty) {
          int index = _songs.indexWhere((element) => element.id == song.id);
          _songs.removeWhere((element) => element.id == song.id);
          _songs.insert(index, song);
        }
      }
    }
    isChangedListSongController.sink.add(isChangedListSongValue++);
  }

  Future<void> loadAllGroups() async {
    listAllGroups = await _firebaseProvider.getListSongGroupFromFirestore();
  }

  Future<bool> deleteSong(String id) async {
    try {
      final result = await _firebaseProvider.deleteSong(id);
      if (result == false) {
        return false;
      }
      _songs.removeWhere((element) => element.id == id);
      return true;
    } catch (e) {
      return false;
    }
  }

  void selectSong(String songId, String title, String interpret, String lyricsWithoutChords, String lyricsWithChords) {
    if (selectedSongId == songId) {
      selectedSongId = '';
      _firebaseProvider.removeSelectedSong();
      return;
    }
    selectedSongId = songId;
    // Saved song (has ID) → send only id, title, interpret (no lyrics)
    // Web/unsaved song (empty ID) → send full lyrics with and without chords
    if (songId.isNotEmpty) {
      _firebaseProvider.saveNewSelectedSong(songId, title, interpret, '', '');
    } else {
      _firebaseProvider.saveNewSelectedSong(songId, title, interpret, lyricsWithoutChords, lyricsWithChords);
    }
  }

  List<Song> getSongByFilter(String filterSong) {
    List<Song> listSong = [];

    for (Song song in _songs) {
      if (containsString(filterSong, song)) {
        listSong.add(song);
      }
    }
    return listSong;
  }

  Song? getSongById(String id) {
    return _songs.firstWhereOrNull((val) => val.id == id);
  }

  bool containsString(String filter, Song song) {
    String stringToLoverCase = removeDiacriticsAndWhitespace(filter.toLowerCase());
    String titleToLoverCase = removeDiacriticsAndWhitespace(song.title.toLowerCase());
    String lyricsToLoverCase = removeDiacriticsAndWhitespace(song.lyricsWithoutChords.toLowerCase());

    String interpretToLoverCase = removeDiacriticsAndWhitespace(song.interpret ?? ''.toLowerCase());

    if (titleToLoverCase.contains(stringToLoverCase) || lyricsToLoverCase.contains(stringToLoverCase) || interpretToLoverCase.contains(stringToLoverCase)) {
      return true;
    }
    for (String group in song.groups ?? []) {
      String groupToLoverCase = removeDiacriticsAndWhitespace(group.toLowerCase());
      if (groupToLoverCase.contains(stringToLoverCase)) {
        return true;
      }
    }
    for (String tag in song.tags ?? []) {
      String tagToLoverCase = removeDiacriticsAndWhitespace(tag.toLowerCase());
      if (tagToLoverCase.contains(stringToLoverCase)) {
        return true;
      }
    }
    if (filter.contains(song.indexSongBook.toString())) {
      return true;
    }

    return false;
  }

  UpdateSongListData removeUpdateDataOlderThanThreeDays(UpdateSongListData updateSongListData) {
    final newMapIdSongs = <String, DateTime>{};
    updateSongListData.mapIdSongs.forEach((key, value) {
      if (value.isAfter(DateTime.now().subtract(const Duration(days: 3)))) {
        newMapIdSongs[key] = value;
      }
    });
    return UpdateSongListData(updateSongListData.lastUpdate, newMapIdSongs);
  }

  Future<void> updateSong(Song song) async {
    await _firebaseProvider.addSongToFirebase(song);
    updateSongListData.lastUpdate = DateTime.now();
    updateSongListData.mapIdSongs[song.id] = DateTime.now();
    updateSongListData = removeUpdateDataOlderThanThreeDays(updateSongListData);
    _hiveProvider.setUpdateSongListData('updateSongListData', updateSongListData);
    await _firebaseProvider.setUpdateSongList(updateSongListData);
    _songs.removeWhere((element) => element.id == song.id);
    _songs.add(song.copyWith());
  }

  void changeTransposeChord(Song song, int transpose) {
    _hiveProvider.setNewTransposeForSong(song.id, transpose);
  }

  int getTransposeForSong(Song? song) {
    if (song == null) {
      return 0;
    }
    return _hiveProvider.getTransposeForSong(song.id);
  }

  String getListSongToJson() {
    return jsonEncode(_songs.map((e) => e.toJson()).toList());
  }

  Future<void> createGroup(String group) async {
    final result = await _firebaseProvider.createNewGroup(group);
    if (result) {
      listAllGroups = [];
      listAllGroups = await _firebaseProvider.getListSongGroupFromFirestore();
    } else {
      logger.e('Error create group');
    }
  }

  Future<void> deleteGroup(String group) async {
    final result = await _firebaseProvider.deleteGroup(group);
    if (result) {
      listAllGroups = [];
      listAllGroups = await _firebaseProvider.getListSongGroupFromFirestore();
    } else {
      logger.e('Error delete group');
    }
  }

  Future<void> updateGroup(String oldGroup, String newGroup) async {
    final result = await _firebaseProvider.updateGroup(oldGroup, newGroup);
    if (result) {
      listAllGroups = [];
      listAllGroups = await _firebaseProvider.getListSongGroupFromFirestore();
    } else {
      logger.e('Error update group');
    }
  }
}

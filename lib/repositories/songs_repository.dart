// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';

import '../model/song/song.dart';
import '../providers/firebase_provider.dart';
import '../providers/hive_provider.dart';
import 'package:collection/collection.dart';

import '../services/auxiliary_functions.dart';

class SongsRepository {
  final HiveProvider _hiveProvider;
  final FirebaseProvider _firebaseProvider;

  final selectSongController = StreamController<String>.broadcast();
  Stream<String> get selectSongData => selectSongController.stream.asBroadcastStream();

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
    _firebaseProvider.selectedSong.onValue.listen((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map && data['song'] != null) {
        selectSongController.sink.add(data['song']);
        selectedSongId = data['song'];
      }
    });
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

  void selectSong(String songId) {
    if (selectedSongId == songId) {
      selectedSongId = '';
      _firebaseProvider.removeSelectedSong();
      return;
    }
    selectedSongId = songId;
    _firebaseProvider.saveNewSelectedSong(songId);
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

  Future<void> updateSong(Song song) async {
    await _firebaseProvider.addSongToFirebase(song);
    _songs.removeWhere((element) => element.id == song.id);
    _songs.add(song.copyWith());
  }

  void changeTransposeChord(Song song, int transpose) {
    _hiveProvider.setNewTransposeForSong(song.id, transpose);
  }

  int getTransposeForSong(Song song) {
    return _hiveProvider.getTransposeForSong(song.id);
  }
}

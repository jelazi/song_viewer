// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../model/song/song.dart';
import '../providers/hive_provider.dart';
import '../providers/pocketbase_provider.dart';
import '../services/auxiliary_functions.dart';
import '../services/chord_service.dart';

class SongsRepository {
  final HiveProvider _hiveProvider;
  final PocketBaseProvider _pocketBaseProvider;
  late final ChordService chordService;

  final selectSongController = StreamController<String>.broadcast();
  Stream<String> get selectSongData => selectSongController.stream.asBroadcastStream();

  final isChangedListSongController = StreamController<int>.broadcast();
  Stream<int> get isChangedListSong => isChangedListSongController.stream.asBroadcastStream();
  int isChangedListSongValue = 0;

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
    required PocketBaseProvider pocketBaseProvider,
  })  : _hiveProvider = hiveProvider,
        _pocketBaseProvider = pocketBaseProvider {
    chordService = ChordService(pocketBaseProvider, hiveProvider);
    _init();
  }

  void _init() {
    // Listen to selected song changes via PocketBase realtime
    _pocketBaseProvider.selectedSongStream.listen((data) {
      if (data != null && data['song'] != null) {
        selectSongController.sink.add(data['song'].toString());
        selectedSongId = data['song'].toString();
      }
    });

    // Listen to song change events via realtime_state timestamp comparison
    _pocketBaseProvider.songChangeStream.listen((event) {
      _handleSongRealtimeEvent(event);
    });

    // Listen to group change events via realtime_state timestamp comparison
    _pocketBaseProvider.groupChangeStream.listen((event) {
      _handleGroupRealtimeEvent(event);
    });
  }

  void _handleSongRealtimeEvent(RealtimeChangeEvent<Song> event) {
    if (event.isDelete) {
      _songs.removeWhere((s) => s.id == event.recordId);
      logger.i('Realtime: song deleted id=${event.recordId}');
    } else if (event.isCreate && event.record != null) {
      final existing = _songs.firstWhereOrNull((s) => s.id == event.record!.id);
      if (existing == null) {
        _songs.add(event.record!);
        logger.i('Realtime: song created id=${event.record!.id} updated=${event.serverUpdated}');
      }
    } else if (event.isUpdate && event.record != null) {
      final index = _songs.indexWhere((s) => s.id == event.record!.id);
      if (index >= 0) {
        _songs[index] = event.record!;
        logger.i('Realtime: song updated id=${event.record!.id} updated=${event.serverUpdated}');
      } else {
        _songs.add(event.record!);
        logger.i('Realtime: song updated (new) id=${event.record!.id} updated=${event.serverUpdated}');
      }
    }
    _saveSongsToCache();
    isChangedListSongController.sink.add(isChangedListSongValue++);
  }

  void _handleGroupRealtimeEvent(RealtimeChangeEvent<String> event) {
    if (event.isDelete) {
      listAllGroups.remove(event.recordId);
      logger.i('Realtime: group deleted name=${event.recordId}');
    } else if (event.isCreate && event.record != null) {
      if (!listAllGroups.contains(event.record)) {
        listAllGroups.add(event.record!);
        listAllGroups.sort();
        logger.i('Realtime: group created name=${event.record}');
      }
    } else if (event.isUpdate && event.record != null) {
      // For groups, updates mean the name might have changed — handled by delete + create
      if (!listAllGroups.contains(event.record)) {
        listAllGroups.add(event.record!);
        listAllGroups.sort();
        logger.i('Realtime: group updated name=${event.record}');
      }
    }
    _hiveProvider.saveGroupsCache(listAllGroups);
    isChangedListSongController.sink.add(isChangedListSongValue++);
  }

  // ---------------------------------------------------------------------------
  // Hive cache-first loading
  // ---------------------------------------------------------------------------

  /// Load songs from Hive cache. Returns true if cache had data.
  bool loadSongsFromCache() {
    final cachedSongs = _hiveProvider.loadSongsCache();
    if (cachedSongs != null && cachedSongs.isNotEmpty) {
      _songs.clear();
      for (final json in cachedSongs) {
        try {
          _songs.add(Song.fromJson(json));
        } catch (e) {
          logger.w('Error parsing cached song: $e');
        }
      }
      logger.i('Loaded ${_songs.length} songs from Hive cache');
      return true;
    }
    return false;
  }

  /// Load groups from Hive cache. Returns true if cache had data.
  bool loadGroupsFromCache() {
    final cachedGroups = _hiveProvider.loadGroupsCache();
    if (cachedGroups != null && cachedGroups.isNotEmpty) {
      listAllGroups = cachedGroups;
      logger.i('Loaded ${listAllGroups.length} groups from Hive cache');
      return true;
    }
    return false;
  }

  /// Check if PocketBase has newer data than our cache.
  /// Returns true if sync from PB is needed.
  Future<bool> isServerDataNewer() async {
    final localTimestamp = _hiveProvider.getLastSyncTimestamp();
    if (localTimestamp == null || localTimestamp.isEmpty) {
      logger.i('No local sync timestamp — full sync needed');
      return true;
    }
    final serverTimestamp = await _pocketBaseProvider.getServerUpdatedTimestamp();
    if (serverTimestamp == null || serverTimestamp.isEmpty) {
      logger.i('Could not get server timestamp — skipping sync');
      return false;
    }
    final needsSync = localTimestamp != serverTimestamp;
    logger.i('Cache check: local=$localTimestamp, server=$serverTimestamp, needsSync=$needsSync');
    return needsSync;
  }

  /// Save current in-memory songs to Hive cache with the server timestamp.
  Future<void> _saveSongsToCache() async {
    try {
      final serverTimestamp = await _pocketBaseProvider.getServerUpdatedTimestamp();
      final timestamp = serverTimestamp ?? DateTime.now().toUtc().toIso8601String();
      final songsJson = _songs.map((s) => s.toJson()).toList();
      _hiveProvider.saveSongsCache(songsJson, timestamp);
      logger.i('Saved ${_songs.length} songs to Hive cache with timestamp=$timestamp');
    } catch (e) {
      logger.e('Error saving songs to cache: $e');
    }
  }

  Future<void> loadSongsFromServer() async {
    final newSongs = await _pocketBaseProvider.getListSongs();
    for (Song song in newSongs) {
      if (_songs.firstWhereOrNull((val) => val.id == song.id) == null) {
        _songs.add(song);
      } else {
        int index = _songs.indexWhere((element) => element.id == song.id);
        _songs.removeWhere((element) => element.id == song.id);
        _songs.insert(index, song);
      }
    }
    await _saveSongsToCache();
  }

  Future<void> updateSongsFromServer() async {
    final newSongs = await _pocketBaseProvider.getListSongs();
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
    await _saveSongsToCache();
    isChangedListSongController.sink.add(isChangedListSongValue++);
  }

  Future<void> loadAllGroups() async {
    listAllGroups = await _pocketBaseProvider.getListGroups();
    _hiveProvider.saveGroupsCache(listAllGroups);
  }

  Future<bool> deleteSong(String id) async {
    try {
      final result = await _pocketBaseProvider.deleteSong(id);
      if (result == false) {
        return false;
      }
      _songs.removeWhere((element) => element.id == id);
      await _saveSongsToCache();
      // Notify listeners (e.g. HomePageBloc) so the visible list refreshes
      // immediately, regardless of which screen triggered the delete.
      isChangedListSongController.sink.add(isChangedListSongValue++);
      return true;
    } catch (e) {
      return false;
    }
  }

  void selectSong(String songId, String title, String interpret, String lyricsWithoutChords, String lyricsWithChords) {
    if (selectedSongId == songId) {
      selectedSongId = '';
      _pocketBaseProvider.removeSelectedSong();
      return;
    }
    selectedSongId = songId;
    _pocketBaseProvider.saveNewSelectedSong(songId, title, interpret, lyricsWithoutChords, lyricsWithChords);
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
    await _pocketBaseProvider.addOrUpdateSong(song);
    _songs.removeWhere((element) => element.id == song.id);
    _songs.add(song.copyWith());
    await _saveSongsToCache();
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
    final result = await _pocketBaseProvider.createGroup(group);
    if (result) {
      listAllGroups = [];
      listAllGroups = await _pocketBaseProvider.getListGroups();
      _hiveProvider.saveGroupsCache(listAllGroups);
    } else {
      logger.e('Error create group');
    }
  }

  Future<void> deleteGroup(String group) async {
    final result = await _pocketBaseProvider.deleteGroup(group);
    if (result) {
      listAllGroups = [];
      listAllGroups = await _pocketBaseProvider.getListGroups();
      _hiveProvider.saveGroupsCache(listAllGroups);
    } else {
      logger.e('Error delete group');
    }
  }

  Future<void> updateGroup(String oldGroup, String newGroup) async {
    final result = await _pocketBaseProvider.updateGroup(oldGroup, newGroup);
    if (result) {
      listAllGroups = [];
      listAllGroups = await _pocketBaseProvider.getListGroups();
      _hiveProvider.saveGroupsCache(listAllGroups);
    } else {
      logger.e('Error update group');
    }
  }

  /// Upload a file (e.g., sheet music image) and return the public URL.
  Future<String?> uploadFile(String fileName, List<int> fileBytes) async {
    return _pocketBaseProvider.uploadFile(fileName, fileBytes);
  }
}

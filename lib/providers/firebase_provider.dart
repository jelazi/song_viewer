import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:default_project/model/update_songlist_data.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../model/playlist.dart';
import '../model/song/song.dart';
import '../model/user.dart';

class FirebaseProvider {
  CollectionReference<Map<String, dynamic>> songCollection = FirebaseFirestore.instance.collection('songs');
  CollectionReference<Map<String, dynamic>> userCollection = FirebaseFirestore.instance.collection('users');
  CollectionReference<Map<String, dynamic>> playlistCollection = FirebaseFirestore.instance.collection('playlists');
  CollectionReference<Map<String, dynamic>> groupCollection = FirebaseFirestore.instance.collection('groups');
  FirebaseFirestore inst = FirebaseFirestore.instance;
  final DatabaseReference selectedSong = FirebaseDatabase.instance.ref().child('currentSong');
  final DatabaseReference updateSongList = FirebaseDatabase.instance.ref().child('updateSongList');

  FirebaseProvider() {
    inst.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  Future<void> authenticateUser() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      await fb_auth.FirebaseAuth.instance.signInAnonymously();

      songCollection = inst.collection('songs');
      userCollection = inst.collection('users');
      playlistCollection = inst.collection('playlists');
      groupCollection = inst.collection('groups');
      selectedSong.onValue.listen((DatabaseEvent event) {
        final data = event.snapshot.value;
        if (data != null && data is Map) {
          //TODO: listener for current song on database
        }
      });
      try {
        updateSongList.onValue.listen((DatabaseEvent event) {
          final data = event.snapshot.value;
          if (data != null && data is Map) {
            //TODO: listener for update song list on database
          }
        });
      } catch (e) {
        logger.e('Error listening to updateSongList: $e');
      }
    } catch (e) {
      logger.e('$e');
    }
  }

  Future<void> setUpdateSongList(UpdateSongListData updateSongListData) async {
    try {
      await updateSongList.set(updateSongListData.toJson());
    } catch (e) {
      logger.e('$e');
    }
  }

  Future<bool> addUserToFirebase(User user) async {
    try {
      var snapshot = await userCollection.doc(user.name).get();
      if (snapshot.exists) {
        return await updateUser(user);
      } else {
        await userCollection.doc(user.name).set(user.toJson());
      }
      return true;
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  void saveNewSelectedSong(String id, String title, String interpret, String lyricsWithoutChords) {
    selectedSong.update({'song': id, 'title': title, 'interpret': interpret, 'lyricsWithoutChords': lyricsWithoutChords});
  }

  void removeSelectedSong() {
    selectedSong.update({'song': '', 'title': '', 'interpret': '', 'lyricsWithoutChords': ''});
  }

  Future<bool> updateUser(User user) async {
    try {
      await userCollection.doc(user.name).update(user.toJson());
      return true;
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<List<User>> getListUsersFromFirestore() async {
    List<User> listUsers = [];
    try {
      var querySnapshot = await userCollection.get();
      for (var doc in querySnapshot.docs) {
        listUsers.add(User.fromJson(doc.data()));
      }
    } catch (e) {
      logger.e('$e');
    }
    return listUsers;
  }

  Future<List<String>> getListSongGroupFromFirestore() async {
    List<String> listSongGroup = [];
    try {
      final snapshot = await groupCollection.doc('groups').get();
      if (snapshot.exists) {
        Map<String, dynamic>? map = snapshot.data();
        List<dynamic> groups = map?['groups'];
        listSongGroup = groups.map((e) => e.toString()).toList();
      }
    } catch (e) {
      logger.e('$e');
    }
    return listSongGroup;
  }

  Future<bool> createNewGroup(String groupName) async {
    try {
      final snapshot = await groupCollection.doc('groups').get();
      if (snapshot.exists) {
        Map<String, dynamic>? map = snapshot.data();
        List<dynamic> groups = map?['groups'];
        if (groups.contains(groupName)) {
          return false;
        }
        groups.add(groupName);
        await groupCollection.doc('groups').update({'groups': groups});
      } else {
        await groupCollection.doc('groups').set({
          'groups': [groupName]
        });
      }

      return true;
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<bool> deleteGroup(String groupName) async {
    try {
      final snapshot = await groupCollection.doc('groups').get();
      if (snapshot.exists) {
        Map<String, dynamic>? map = snapshot.data();
        List<dynamic> groups = map?['groups'];
        if (groups.contains(groupName)) {
          groups.remove(groupName);
          await groupCollection.doc('groups').update({'groups': groups});
          return true;
        }
      }
      return false;
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<bool> updateGroup(String oldGroupName, String newGroupName) async {
    try {
      final snapshot = await groupCollection.doc('groups').get();
      if (snapshot.exists) {
        Map<String, dynamic>? map = snapshot.data();
        List<dynamic> groups = map?['groups'];
        if (groups.contains(oldGroupName)) {
          groups.remove(oldGroupName);
          groups.add(newGroupName);
          await groupCollection.doc('groups').update({'groups': groups});
          return true;
        }
      }
      return false;
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<bool> deleteUser(User user) async {
    try {
      final snapshot = await userCollection.doc(user.name).get();
      if (snapshot.exists) {
        await userCollection.doc(user.name).delete();
        return true;
      } else {
        logger.e('User not found');
        return false;
      }
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<bool> addSongToFirebase(Song songData) async {
    try {
      final snapshot = await songCollection.doc(songData.id).get();
      if (snapshot.exists) {
        updateSong(songData);
      } else {
        await songCollection.doc(songData.id).set(songData.toJson());
      }
      return true;
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<bool> updateSong(Song songData) async {
    try {
      await songCollection.doc(songData.id).update(songData.toJson());
      return true;
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<List<Song>> getListSongsFromFirestore() async {
    List<Song> listSongs = [];
    try {
      final querySnapshot = await songCollection.get();
      for (var doc in querySnapshot.docs) {
        listSongs.add(Song.fromJson(doc.data()));
      }
    } catch (e) {
      logger.e('$e');
    }
    return listSongs;
  }

  Future<bool> deleteSong(String songId) async {
    try {
      var snapshot = await songCollection.doc(songId).get();
      if (snapshot.exists) {
        await songCollection.doc(songId).delete();
        return true;
      } else {
        logger.e('Song not found');
        return false;
      }
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<bool> addPlaylistToFirebase(Playlist playlist) async {
    try {
      final snapshot = await playlistCollection.doc(playlist.id).get();
      if (snapshot.exists) {
        final result = await updatePlaylist(playlist);
        return result;
      } else {
        await playlistCollection.doc(playlist.id).set(playlist.toJson());
        return true;
      }
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<bool> updatePlaylist(Playlist playlist) async {
    try {
      await playlistCollection.doc(playlist.id).update(playlist.toJson());
      return true;
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<bool> addGroupsToFirebase(List<String> listGroup) async {
    Map<String, Object> map = {'groups': listGroup};
    try {
      final snapshot = await groupCollection.doc('groups').get();
      if (snapshot.exists) {
        await groupCollection.doc('groups').update(map);
      } else {
        await groupCollection.doc('groups').set(map);
      }
      return true;
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }

  Future<List<Playlist>> getListPlaylistsFromFirestore() async {
    List<Playlist> listPlaylists = [];
    try {
      final querySnapshot = await playlistCollection.get();
      for (var doc in querySnapshot.docs) {
        listPlaylists.add(Playlist.fromJson(doc.data()));
      }
    } catch (e) {
      logger.e('$e');
    }
    return listPlaylists;
  }

  Future<bool> deletePlaylist(Playlist playlist) async {
    try {
      final snapshot = await playlistCollection.doc(playlist.id).get();
      if (snapshot.exists) {
        await playlistCollection.doc(playlist.id).delete();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      logger.e('$e');
      return false;
    }
  }
}

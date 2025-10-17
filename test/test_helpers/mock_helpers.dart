class MockSong {
  String title;
  String artist;

  MockSong({required this.title, required this.artist});
}

class MockPlaylist {
  String name;
  List<MockSong> songs;

  MockPlaylist({required this.name, required this.songs});
}

class MockUser {
  String username;
  List<MockPlaylist> playlists;

  MockUser({required this.username, required this.playlists});
}

class MockSongsRepository {
  List<MockSong> getSongs() {
    return [
      MockSong(title: 'Song 1', artist: 'Artist 1'),
      MockSong(title: 'Song 2', artist: 'Artist 2'),
    ];
  }
}

class MockPlaylistRepository {
  List<MockPlaylist> getPlaylists() {
    return [
      MockPlaylist(name: 'Playlist 1', songs: []),
      MockPlaylist(name: 'Playlist 2', songs: []),
    ];
  }
}

class MockUserRepository {
  MockUser getUser() {
    return MockUser(username: 'User1', playlists: []);
  }
}
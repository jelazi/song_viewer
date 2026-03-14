part of 'main.dart';

/// Information about PocketBase server state after authentication
class SyncInfo {
  final bool isAuthenticated;
  final int serverSongCount;
  final int serverPlaylistCount;
  final int serverUserCount;
  final int serverGroupCount;

  SyncInfo({
    required this.isAuthenticated,
    required this.serverSongCount,
    required this.serverPlaylistCount,
    required this.serverUserCount,
    required this.serverGroupCount,
  });

  bool get isServerEmpty => serverSongCount == 0 && serverPlaylistCount == 0 && serverUserCount == 0 && serverGroupCount == 0;

  int get totalServerItems => serverSongCount + serverPlaylistCount + serverUserCount + serverGroupCount;
}

/// Phase 1: Initialize providers & check server state (before showing UI)
Future<({AppRepositories repositories, SyncInfo syncInfo})> initProvidersAndCheckSync() async {
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    Directory directory = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(directory.path);
  }

  // Initialize PocketBase provider
  PocketBaseProvider pocketBaseProvider = PocketBaseProvider();
  await pocketBaseProvider.loadConfig();
  final isAuthenticated = await pocketBaseProvider.authenticate();

  HiveProvider hiveProvider = HiveProvider();
  await hiveProvider.initHiveBox();
  WebProvider webProvider = WebProvider();

  SettingsRepository settingsRepository = SettingsRepository(
    hiveProvider: hiveProvider,
    pocketBaseProvider: pocketBaseProvider,
  );

  await settingsRepository.loadLocalSettings();
  settingsRepository.getInfoApp();

  SongsRepository songsRepository = SongsRepository(
    pocketBaseProvider: pocketBaseProvider,
    hiveProvider: hiveProvider,
  );

  PlaylistRepository playlistRepository = PlaylistRepository(
    hiveProvider: hiveProvider,
    pocketBaseProvider: pocketBaseProvider,
  );

  UsersRepository usersRepository = UsersRepository(
    hiveProvider: hiveProvider,
    pocketBaseProvider: pocketBaseProvider,
    settingsRepository: settingsRepository,
  );

  WebRepository webRepository = WebRepository(
    webProvider: webProvider,
  );

  // Check server data counts
  int songCount = 0;
  int playlistCount = 0;
  int userCount = 0;
  int groupCount = 0;

  if (isAuthenticated) {
    songCount = await pocketBaseProvider.getServerSongCount();
    playlistCount = await pocketBaseProvider.getServerPlaylistCount();
    userCount = await pocketBaseProvider.getServerUserCount();
    groupCount = await pocketBaseProvider.getServerGroupCount();
  }

  final syncInfo = SyncInfo(
    isAuthenticated: isAuthenticated,
    serverSongCount: songCount,
    serverPlaylistCount: playlistCount,
    serverUserCount: userCount,
    serverGroupCount: groupCount,
  );

  final repositories = AppRepositories(
    settingsRepository: settingsRepository,
    playlistRepository: playlistRepository,
    usersRepository: usersRepository,
    songsRepository: songsRepository,
    webRepository: webRepository,
    hiveProvider: hiveProvider,
  );

  return (repositories: repositories, syncInfo: syncInfo);
}

/// Phase 2: Load data from server into repositories
Future<void> loadDataFromServer(AppRepositories repositories) async {
  await repositories.songsRepository.loadSongsFromServer();
  await repositories.songsRepository.loadAllGroups();
  await repositories.usersRepository.loadUsersFromServer();

  await repositories.webRepository.testGetSong();
  await repositories.usersRepository.loadUsersFromServer();
  await repositories.usersRepository.loadCurrentUser();
}

/// Upload local JSON data to the PocketBase server
Future<int> uploadJsonDataToServer(
  PocketBaseProvider pocketBaseProvider,
  String jsonData,
) async {
  try {
    final List<dynamic> items = jsonDecode(jsonData);
    final songs = items.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
    return await pocketBaseProvider.uploadAllSongs(songs);
  } catch (e) {
    logger.e('Error uploading JSON data: $e');
    return 0;
  }
}

Future<void> initHiveFunction() async {
  Directory directory = await path_provider.getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  //Hive.initFlutter(directory.path);
  Hive.registerAdapter(TypeUserAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(TypeClickCardAdapter());
  Hive.registerAdapter(WebItemAdapter());
  Hive.registerAdapter(WebSongAdapter());
  Hive.registerAdapter(WebInterpretAdapter());
  Hive.registerAdapter(UpdateSongListDataAdapter());
  Hive.registerAdapter(UpdatePlaylistDataAdapter());
}

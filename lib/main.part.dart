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

  // Initialize PocketBase provider.
  //
  // In a local-first build the app must be fully usable with no server and no
  // configuration, so startup never waits on the network — see
  // plans/store-release-plan.md §3.5 and §10.
  PocketBaseProvider pocketBaseProvider = PocketBaseProvider();
  bool isAuthenticated = false;
  if (Features.sharedServer) {
    await pocketBaseProvider.loadConfig();
    isAuthenticated = await pocketBaseProvider.authenticate();
  }

  HiveProvider hiveProvider = HiveProvider();
  await hiveProvider.initHiveBox();

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

  // Web import is built only in the personal flavour. The store build must not
  // merely disable it — the provider, the repository and their source URLs must
  // be absent from the artifact (blocker B1, §2). Because `Features.webImport`
  // is a compile-time constant, this whole branch is provably dead in the store
  // build and the AOT compiler strips the subtree with it.
  WebRepository? webRepository;
  if (Features.webImport) {
    webRepository = WebRepository(
      webProvider: WebProvider(),
    );
  }

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

/// Phase 2: Load data — cache-first with PocketBase sync when needed
Future<void> loadDataFromServer(AppRepositories repositories) async {
  // 1. Load songs & groups from Hive cache first (instant)
  final hasCachedSongs = repositories.songsRepository.loadSongsFromCache();
  final hasCachedGroups = repositories.songsRepository.loadGroupsFromCache();

  if (hasCachedSongs) {
    logger.i('Songs loaded from Hive cache');
  }
  if (hasCachedGroups) {
    logger.i('Groups loaded from Hive cache');
  }

  // 2. Check if PocketBase has newer data than our cache
  final needsSync = await repositories.songsRepository.isServerDataNewer();

  if (needsSync) {
    logger.i('Server data is newer — syncing from PocketBase');
    await repositories.songsRepository.loadSongsFromServer();
    await repositories.songsRepository.loadAllGroups();
  } else {
    logger.i('Cache is up-to-date — skipping PocketBase sync');
    // If there was no cache at all, we still need to fetch
    if (!hasCachedSongs) {
      await repositories.songsRepository.loadSongsFromServer();
    }
    if (!hasCachedGroups) {
      await repositories.songsRepository.loadAllGroups();
    }
  }

  // 3. Load users (not cached — typically small dataset)
  try {
    await repositories.usersRepository.loadUsersFromServer();
    await repositories.usersRepository.loadCurrentUser();
  } catch (e) {
    logger.e('Error loading users: $e');
  }

  // 4. Load chord diagrams — cache-first with PB sync
  try {
    final chordService = repositories.songsRepository.chordService;
    final hasCachedChords = chordService.loadFromCache();
    if (hasCachedChords) {
      logger.i('Chord diagrams loaded from Hive cache');
    }
    final needsChordSync = await chordService.isServerDataNewer();
    if (needsChordSync) {
      logger.i('Server chord data is newer — syncing from PocketBase');
      await chordService.syncFromServer();
    } else if (!hasCachedChords) {
      await chordService.syncFromServer();
    }
  } catch (e) {
    logger.e('Error loading chord diagrams: $e');
  }
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

part of 'main.dart';

Future<AppRepositories> initProvidersRepositories() async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (kIsWeb) {
    await Hive.initFlutter();
  } else {
    Directory directory = await path_provider.getApplicationDocumentsDirectory();
    Hive.init(directory.path);
  }

  FirebaseProvider firebaseProvider = FirebaseProvider();
  await firebaseProvider.authenticateUser();
  HiveProvider hiveProvider = HiveProvider();
  await hiveProvider.initHiveBox();
  WebProvider webProvider = WebProvider();

  SettingsRepository settingsRepository = SettingsRepository(
    hiveProvider: hiveProvider,
  );

  await settingsRepository.loadLocalSettings();
  settingsRepository.getInfoApp();

  SongsRepository songsRepository = SongsRepository(
    firebaseProvider: firebaseProvider,
    hiveProvider: hiveProvider,
  );
  await songsRepository.loadSongsFromFirebase();
  await songsRepository.loadAllGroups();

  PlaylistRepository playlistRepository = PlaylistRepository(
    hiveProvider: hiveProvider,
    firebaseProvider: firebaseProvider,
  );

  UsersRepository usersRepository = UsersRepository(
    hiveProvider: hiveProvider,
    firebaseProvider: firebaseProvider,
    settingsRepository: settingsRepository,
  );
  await usersRepository.loadUsersFromFirebase();

  WebRepository webRepository = WebRepository(
    webProvider: webProvider,
  );

  await webRepository.testGetSong();
  await usersRepository.loadUsersFromFirebase();
  await usersRepository.loadCurrentUser();

  return AppRepositories(
    settingsRepository: settingsRepository,
    playlistRepository: playlistRepository,
    usersRepository: usersRepository,
    songsRepository: songsRepository,
    webRepository: webRepository,
    hiveProvider: hiveProvider,
  );
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

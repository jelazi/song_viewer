part of 'main.dart';

late SettingsRepository settingsRepository;
late PlaylistRepository playlistRepository;
late UsersRepository usersRepository;
late SongsRepository songsRepository;
late WebRepository webRepository;
late HiveProvider hiveProvider;

Future<void> initProvidersRepositories() async {
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
  hiveProvider = HiveProvider();
  await hiveProvider.initHiveBox();
  WebProvider webProvider = WebProvider();

  settingsRepository = SettingsRepository(
    hiveProvider: hiveProvider,
  );

  await settingsRepository.loadLocalSettings();
  settingsRepository.getInfoApp();

  songsRepository = SongsRepository(
    firebaseProvider: firebaseProvider,
    hiveProvider: hiveProvider,
  );
  await songsRepository.loadSongsFromFirebase();
  await songsRepository.loadAllGroups();
  playlistRepository = PlaylistRepository(
    hiveProvider: hiveProvider,
    firebaseProvider: firebaseProvider,
  );
  usersRepository = UsersRepository(
    hiveProvider: hiveProvider,
    firebaseProvider: firebaseProvider,
    settingsRepository: settingsRepository,
  );
  await usersRepository.loadUsersFromFirebase();
  webRepository = WebRepository(
    webProvider: webProvider,
  );

  playlistRepository = PlaylistRepository(
    hiveProvider: hiveProvider,
    firebaseProvider: firebaseProvider,
  );

  await webRepository.testGetSong();
  await usersRepository.loadUsersFromFirebase();
  await usersRepository.loadCurrentUser();
}

Future<void> initHiveFunction() async {
  Directory directory = await pathProvider.getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  //Hive.initFlutter(directory.path);
  Hive.registerAdapter(TypeUserAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(TypeClickCardAdapter());
  Hive.registerAdapter(WebItemAdapter());
  Hive.registerAdapter(WebSongAdapter());
  Hive.registerAdapter(WebInterpretAdapter());
}

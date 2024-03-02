part of 'main.dart';

dynamic settingsRepository;
dynamic playlistRepository;
dynamic usersRepository;
dynamic songsRepository;

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
  HiveProvider hiveProvider = HiveProvider();
  await hiveProvider.initHiveBox();

  settingsRepository = SettingsRepository(
    hiveProvider: hiveProvider,
  );

  await settingsRepository.loadLocalSettings();

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
  await usersRepository.loadCurrentUser();
}

Future<void> initHiveFunction() async {
  Directory directory = await pathProvider.getApplicationDocumentsDirectory();
  Hive.init(directory.path);
  //Hive.initFlutter(directory.path);
  Hive.registerAdapter(TypeUserAdapter());
  Hive.registerAdapter(UserAdapter());
  Hive.registerAdapter(TypeClickCardAdapter());
}

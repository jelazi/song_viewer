# Unit Testy pro Songs Viewer BLoC

Tento adresář obsahuje unit testy pro všechny vrstvy aplikace Songs Viewer.

## 📁 Struktura

```
unit_tests/
├── providers/          # Testy pro poskytovatele dat
│   ├── hive_provider_test.dart
│   └── web_provider_test.dart
├── repositories/       # Testy pro repozitáře
│   ├── playlist_repository_test.dart
│   ├── settings_repository_test.dart
│   ├── songs_repository_test.dart
│   ├── user_repository_test.dart
│   └── web_repository_test.dart
├── models/            # Testy pro datové modely
│   └── song_test.dart
├── blocs/             # Testy pro BLoC komponenty
├── all_tests.dart     # Soubor pro spuštění všech testů
└── README.md          # Tento soubor
```

## 🚀 Spuštění testů

### Spuštění všech unit testů

```bash
flutter test test/unit_tests/all_tests.dart
```

### Spuštění konkrétní kategorie testů

```bash
# Pouze provider testy
flutter test test/unit_tests/providers/

# Pouze repository testy
flutter test test/unit_tests/repositories/

# Pouze model testy
flutter test test/unit_tests/models/

# Pouze BLoC testy
flutter test test/unit_tests/blocs/
```

### Spuštění konkrétního testovacího souboru

```bash
flutter test test/unit_tests/providers/hive_provider_test.dart
```

### Spuštění s coverage

```bash
flutter test --coverage test/unit_tests/all_tests.dart
```

Pro zobrazení coverage reportu:

```bash
# Vygenerování HTML reportu
genhtml coverage/lcov.info -o coverage/html

# Otevření v prohlížeči
open coverage/html/index.html
```

## 🛠️ Příprava testovacího prostředí

### 1. Instalace závislostí

```bash
flutter pub get
```

### 2. Generování mock souborů

Mock soubory jsou potřeba pro testování s Mockito:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 3. Kontrola testů

```bash
# Spuštění všech testů
flutter test

# Kontrola pouze unit testů
flutter test test/unit_tests/
```

## 📝 Testovací frameworky a nástroje

### Použité balíčky

- **flutter_test**: Základní testovací framework pro Flutter
- **mockito**: Knihovna pro vytváření mock objektů
- **build_runner**: Generování kódu pro mockito
- **pocketbase**: PocketBase SDK pro komunikaci se serverem

### Testovací vzory

#### 1. Provider testy
- Testují přímou interakci s datovými zdroji (PocketBase, Hive, Web API)
- Používají mock objekty pro izolaci závislostí
- Kontrolují správné volání API a zpracování odpovědí

#### 2. Repository testy
- Testují business logiku a orchestraci mezi providery
- Mockují všechny závislosti (providery)
- Ověřují správné volání providerů a zpracování dat

#### 3. Model testy
- Testují serializaci/deserializaci JSON
- Kontrolují validaci dat
- Ověřují správnost copyWith metod a transformací

#### 4. BLoC testy
- Testují stavový management
- Ověřují správné reakce na eventy
- Kontrolují emitované stavy

## 📊 Pokrytí kódem (Coverage)

Cílem je dosáhnout minimálně 80% pokrytí kódu testy.

### Aktuální pokrytí

Pro zobrazení aktuálního pokrytí spusťte:

```bash
flutter test --coverage
lcov --summary coverage/lcov.info
```

## ✅ Kontrolní seznam pro nové testy

Při přidávání nových testů se ujistěte, že:

- [ ] Test má popisný název vystihující testovanou funkcionalitu
- [ ] Test je nezávislý na ostatních testech
- [ ] Test používá `setUp()` a `tearDown()` pro inicializaci a cleanup
- [ ] Všechny mock objekty jsou správně nastaveny
- [ ] Test kontroluje očekávané chování i edge cases
- [ ] Test je rychlý (jednotky až desítky milisekund)
- [ ] Test nepoužívá reálné síťové volání nebo databáze

## 🐛 Řešení problémů

### Mock soubory nejsou vygenerovány

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Testy padají kvůli chybějícím závislostem

```bash
flutter pub get
flutter clean
flutter pub get
```

### Chyby při inicializaci PocketBase v testech

Ujistěte se, že používáte `TestWidgetsFlutterBinding.ensureInitialized()` v `setUp()`.

### Hive testy selhávají

```dart
setUpAll(() async {
  await Hive.initFlutter();
  // Registrace adaptérů
});

tearDownAll(() async {
  await Hive.close();
  await Hive.deleteFromDisk();
});
```

## 📚 Další zdroje

- [Flutter Testing Documentation](https://docs.flutter.dev/testing)
- [Mockito Documentation](https://pub.dev/packages/mockito)
- [BLoC Testing](https://bloclibrary.dev/#/testing)
- [Effective Dart: Testing](https://dart.dev/guides/language/effective-dart/testing)

## 🤝 Přispívání

Při přidávání nových funkcí do aplikace, vždy vytvořte odpovídající unit testy:

1. Vytvořte testovací soubor ve správné složce
2. Napište testy pokrývající happy path i edge cases
3. Spusťte všechny testy a ujistěte se, že procházejí
4. Zkontrolujte code coverage

## 📞 Kontakt

Pro otázky týkající se testů kontaktujte tým nebo vytvořte issue v repozitáři.

---

**Poslední aktualizace:** Říjen 2025

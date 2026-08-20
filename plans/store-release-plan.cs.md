# Plán: vydání Songs Viewer jako placené aplikace na App Store a Google Play

> Stav: NÁVRH — pouze analýza, v kódu zatím nic změněno.
> Vytvořeno: 2026-08-17
> Rozsah: placené vydání pro iOS + Android. Desktop (Windows/macOS/Linux) zatím zůstává beze změny.
>
> Toto je český překlad souboru `store-release-plan.md`. Při změnách aktualizuj obě verze.

---

## 0. Shrnutí

Aplikace je funkčně bohatá a technicky zdravá (`flutter analyze`: 0 errors, 0 warnings,
195 infos), ale **v současné podobě ji vydat nelze**. Existují tři tvrdé blokátory a několik
menších mezer v přípravě releasu.

| # | Blokátor | Závažnost | Proč blokuje |
|---|---------|----------|---------------|
| B1 | Stahování obsahu ze šesti cizích webů s texty a akordy, včetně natvrdo zapsaného API tokenu | **Kritická** | App Store 5.2 (duševní vlastnictví) / Play „Intellectual Property" — téměř jisté zamítnutí nebo pozdější stažení, plus reálná autorskoprávní odpovědnost ve chvíli, kdy jde o peníze |
| B2 | ~~Přihlašovací údaje k PocketBase zabalené jako asset~~ → **z části opraveno 2026-08-17**; heslo *nebylo* změněno a sdílená databáze zůstává | **Kritická** | Údaj se sice už nedistribuuje, ale byl v každém dosud vydaném buildu, takže se musí považovat za veřejný. Placená aplikace navíc nemůže mít všechny kupující v jedné sdílené databázi |
| B3 | Release buildy pro Android se podepisují **debug** klíčem | **Kritická** | Play debug-podepsaný AAB odmítne |
| B4 | Placeholder metadata (název aplikace, bundle ID, purpose strings, pubspec name/description) | Vysoká | Zaručené potíže při review; bundle ID jsou po vydání trvalé |
| B5 | Chybí zásady ochrany osobních údajů, cesta ke smazání účtu, materiály pro obchody | Vysoká | Vyžadují to formuláře obou obchodů před odesláním |

Reálný odhad do prvního vydání: **6–10 týdnů**, přičemž většinu času zabere (a) vyřešení otázky
obsahu a licencí a (b) povinný 14denní uzavřený test u nových osobních vývojářských účtů na Google.

---

## 1. Jak aplikace vypadá dnes (zjištění)

**Technologie.** Flutter 3.44.3, BLoC, Hive (lokálně), PocketBase (vzdálená synchronizace),
`easy_localization` (cs/en), 182 Dart souborů, oddělené stromy pohledů mobile / tablet / desktop.

**Platformy.** Přítomné jsou `android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/`.
Pluginy určené jen pro desktop (`window_manager`, `desktop_multi_window`, `screen_retriever`) se
importují bezpodmínečně v `lib/main.dart`, ale za běhu jsou ošetřené kontrolami `Platform.is*`
(`lib/main.dart:101-107`).

**Hlavní funkce.** Editace písní (texty + akordy + transpozice), diagramy akordů, playlisty,
vykreslování PDF/not, odkazy na YouTube playbacky, prezentační režim (na desktopu druhé okno),
sdílení přes QR, záloha a obnova, synchronizace přes PocketBase s uživatelskými rolemi,
AI obohacení písní (Gemini) a import z šesti webů s akordy.

**Zdraví kódu.** `flutter analyze` → 195 nálezů, všechny úrovně `info` (převážně
`use_super_parameters`, `use_build_context_synchronously`, `avoid_print` v testech). Unit testy
existují pro modely, repozitáře a jeden BLoC; integrační testy přes Patrol, jeden je `.disabled`.

---

## 2. Blokátory podrobně

### B1 — stahování obsahu z cizích webů (ten rozhodující)

`lib/providers/web_provider.dart:9-14` má natvrdo zapsaných šest zdrojů:

```
velkyzpevnik.cz, supermusic.cz, zpevnik.proscholy.cz,
pisnicky-akordy.cz, songs.worshipleaderapp.com, worshipchords.com
```

Aplikace stahuje a parsuje jejich stránky a API (`beautiful_soup_dart`, GraphQL a Elasticsearch
dotazy na ProScholy v `web_provider.dart:41-110`, WorshipLeader `/api/grid` a `/api/get` na
`:218-230`, HTML WorshipChords na `:251-270`) a **stažené texty a akordy ukládá do lokální
knihovny uživatele i na PocketBase server**.

`lib/providers/web_provider.dart:15` navíc obsahuje natvrdo zapsaný API token pro pisnicky-akordy.cz,
posílaný jako bearer hlavička na `:207`.

Proč to blokuje právě **placené** vydání:

- Texty písní jsou chráněná autorská díla. Ani ty, ani stahované weby je nemohou dál licencovat.
- Apple guideline 5.2.1/5.2.3 i pravidla Play pro duševní vlastnictví míří přesně na aplikace,
  které reprodukují cizí obsah bez oprávnění. Recenzenti to u aplikací typu „akordy/texty" aktivně
  hledají.
- Zpoplatnění odstraňuje jakoukoli obhajobu ve smyslu osobního užití a dělá z tebe komerčního
  porušovatele.
- Natvrdo zapsaný token je neoprávněný přístup k cizímu API — nezávisle na autorském právu.
- I kdyby aplikace review prošla, jediné oznámení od provozovatele webu nebo vydavatele
  (OSA/Intergram v ČR, CCLI/Hal Leonard v zahraničí) ji stáhne a může poškodit vývojářský účet.

**Varianty (je nutné jednu zvolit — viz §7, rozhodnutí 1):**

| Varianta | Co znamená | Riziko v obchodech | Náročnost |
|---|---|---|---|
| **A. Odstranit import z mobilních buildů** *(doporučeno)* | Mobilní aplikace = osobní zpěvník: uživatel si píše/importuje **vlastní** písně, synchronizuje, prezentuje. Web import zůstane jen na desktopu, nebo se zruší úplně. | Nejnižší | Nízká–střední |
| **B. Místo stahování odkazovat** | Import nahradit tlačítkem „otevřít v prohlížeči / ve vestavěném prohlížeči" na zdrojový web. Uživatel si to přečte tam, do aplikace se nic nekopíruje. | Nízké | Střední |
| **C. Získat písemný souhlas** | Oslovit všech šest webů kvůli písemnému svolení s importem; ponechat jen ty, které souhlasí; token zrušit. | Střední (může být potřeba doložit Applu) | Vysoká, závislá na cizí straně |
| **D. Vydat jak to je** | — | **Nepřijatelné** | — |

Doporučení: **varianta A pro v1.0**, případně B jako pozdější doplněk. Kód pro stahování ponechat
za přepínačem při kompilaci, aby desktopový build (který se přes obchody nedistribuuje) zůstal
nedotčený.

Bez ohledu na zvolenou variantu: **odstranit natvrdo zapsaný token** (`web_provider.dart:15`)
a nechat ho zneplatnit.

### B2 — tajemství a víceuživatelský provoz

> **Aktualizováno 2026-08-17.** *Distribuční* polovina tohoto blokátoru byla opravena zvlášť
> v průběhu psaní tohoto plánu (DEVLOG část 8–9): `pocketbase_config.json` už není
> v `flutter: assets:`, záložní `rootBundle` je z `pocketbase_provider.dart` pryč, konfigurace je
> jen v `~/.songviewer/` a historie gitu byla vyčištěna. Níže je to, co zbývá.

Původně byl `pocketbase_config.json` (URL serveru + e-mail účtu + heslo v čitelné podobě) uvedený
v `flutter: assets:` a načítal se přes `rootBundle`, takže se kompiloval do každého distribuovaného
balíčku a šel přečíst libovolným archivačním nástrojem.

Druhý problém, nedotčený: je to jeden sdílený účet na jednom serveru. Placená aplikace prodávaná
cizím lidem znamená, že by všichni kupující zapisovali do stejné databáze. Současný model je
„privátní server naší kapely", ne produkt.

Náprava:
1. ~~Odebrat `pocketbase_config.json` z assetů v `pubspec.yaml` a zrušit záložní načítání přes
   `rootBundle`.~~ **Hotovo 2026-08-17.**
2. **Změnit heslo k PocketBase** — stále otevřené (odloženo rozhodnutím). Bylo zabalené v každém
   dosud vydaném buildu, takže se musí považovat za veřejné; vyčištění historie gitu neodvolá už
   distribuované buildy. Změna hesla znehodnotí stávající instalace, což je přesně důvod, proč se má
   udělat *dřív*, než si aplikaci koupí cizí lidé, ne potom.
3. **Dostat tři API klíče z čitelného úložiště** — `groqApiKey`, `youtubeApiKey`, `geminiApiKey` jsou
   v čitelné podobě v Hive (`settings_repository.dart:50-52`, načítají se na `:208-210`) a obrazovka
   nastavení kopíruje klíče k YouTube a Gemini nešifrovaně do schránky
   (`general_settings_body.dart:290-294`). Použít `flutter_secure_storage`, odstranit je z jakéhokoli
   exportu či diagnostiky, nebo klíče zadávané uživatelem z mobilního buildu vypustit.
   **Pro store vyřešeno 2026-08-18** volbou „vypustit": celá sekce klíčů v nastavení (včetně
   tlačítka „Export all API keys" do schránky) je za `Features.aiEnrichment`, takže ve store buildu
   ji nelze zobrazit ani vyplnit — `FEATURE_AI` je `false` v `store_mobile.json`
   i `store_desktop.json`. **Personal build zůstává beze změny**: klíče se zadávají dál a leží dál
   v čitelném Hive. Zbývá tedy jen pro personal, a je to o řád menší riziko (jedno zařízení,
   vlastní klíče). `backup_service.dart:197-199` / `:386-388` klíče pořád zapisuje do zálohy
   nastavení a zpět načítá — ve store buildu jsou vždy prázdné, v personal ne.
4. Zpřísnit pravidla kolekcí v PocketBase tak, aby běžný uživatel četl a zapisoval jen vlastní
   záznamy. Projít podle toho `pocketbase_collections.json`.
5. Rozhodnout model synchronizace — **celý rozbor je v §9.** Ve zkratce: lokálně first jako výchozí
   stav, PocketBase přesunutý do pokročilého nastavení „mám vlastní server". Hostované účty
   provozované tebou se pro jednorázově placenou aplikaci nedoporučují.
   **V UI implementováno 20. 8. 2026.** `Features.sharedServer` dřív hlídal jen start
   (`main.part.dart:40`), takže store build sice nastartoval lokálně, ale pořád zobrazoval celou
   serverovou vrstvu. Nyní: přihlašování k účtu se odkompiluje pryč (`state_login.dart`,
   `app_router.dart` — stránky mizí z artefaktu), správa uživatelů a skupin se objeví, jen když je
   server skutečně připojený (`Features.serverAdminVisible`), a nastavení PocketBase je ve všech
   třech rozvrženích sníženo na sbalenou sekci „vlastní server (pokročilé)". Server tedy zůstává
   zachovaný, jen není výchozí cesta — přesně jak žádá §9. Zároveň to opravilo díru, kterou ten flag
   otevřel: kontrola práv ke zpěvníku četla roli vydanou serverem, kterou lokálně-first build nikdy
   nemá, takže čerstvá store instalace nemohla vytvořit první píseň (`UsersState.canManageLibrary`).
6. Tajemství, která se musí distribuovat, přesunout do `--dart-define` / `String.fromEnvironment`,
   nikdy do assetů.
7. **Repozitář na GitHubu je veřejný.** Není to blokátor pro obchody, ale obchodní rozhodnutí, které
   stojí za vědomé zvážení: kdokoli si aplikaci může naklonovat a sestavit zdarma a zdrojový kód
   dokumentuje adresu tvého serveru. Buď to přijmout (placená verze konkuruje pohodlím, ne
   utajením — u open-source aplikací prodávaných v obchodech běžná volba), nebo repozitář před
   vydáním přepnout na soukromý.

### B3 — podepisování Android release buildu

`android/app/build.gradle:56-60`:

```gradle
release {
    // TODO: Add your own signing config for the release build.
    signingConfig signingConfigs.debug
}
```

`android/key.properties` už existuje (storePassword / keyPassword / keyAlias / storeFile) — jen
není zapojený. Je potřeba standardní blok `signingConfigs.release` načítající `key.properties`,
plus `minifyEnabled`/`shrinkResources` a soubor ProGuard. Keystore někam trvale zazálohovat, nebo
se přihlásit do Play App Signing (doporučeno — hlavní klíč drží Google).

### B4 — identita a metadata

| Položka | Současný stav | Problém |
|---|---|---|
| Android `applicationId` | `com.lzizka.songsviewer.songs_viewer_bloc` (`build.gradle:45`) | Obsahuje surový název projektu; neshoduje se s iOS. **Po prvním vydání je trvalé.** |
| iOS bundle ID | `com.lzizka.songviewer` (`project.pbxproj:504`) | V pořádku — buď k němu srovnat Android, nebo teď zvolit nový pár |
| Název aplikace na Androidu | `songs_viewer_bloc` (`AndroidManifest.xml:5`) | Tohle uživatel uvidí na ploše |
| pubspec `name` / `description` | `default_project` / „A new Flutter project." | Kosmetické, ale nedbalé; změna `name` znamená upravit všechny importy `package:default_project/...` |
| iOS `NSPhotoLibraryUsageDescription` | „Photo Library Access Warning" (`Info.plist`) | Placeholder purpose strings znamenají automatické zamítnutí; musí srozumitelně vysvětlit *proč* |
| Verze | `1.2.3+43` | Jako výchozí bod v pořádku |

Navíc: `android:label`, `CFBundleName` (`songs_viewer`) a `CFBundleDisplayName` (`Songs Viewer`)
si vzájemně neodpovídají.

### B5 — materiály pro obchody (zatím žádné)

- Veřejně dostupná adresa se zásadami ochrany osobních údajů — **vyžadují oba obchody**, a je
  nutná, protože aplikace komunikuje po síti a (volitelně) ukládá obsah uživatele.
- Podmínky užití / EULA (standardní EULA od Applu stačí, pokud nepotřebuješ vlastní podmínky).
- Adresa podpory + kontaktní e-mail.
- Formulář **Data safety** (Play) a **Privacy Nutrition Labels** (Apple) — musí odpovídat
  skutečnosti (přístup k síti, uživatelský obsah, volitelná volání na Google Gemini).
- Dotazník pro hodnocení obsahu (Play) / věkové hodnocení (Apple).
- Cesta ke smazání účtu — Play ji vyžaduje, pokud aplikace pracuje s účty; potřebuješ jak cestu
  přímo v aplikaci, tak veřejně přístupnou webovou stránku.
- Exportní compliance: `ITSAppUsesNonExemptEncryption = false` je už nastaveno a pro použití jen
  přes HTTPS je to správně.

---

## 3. Vedlejší technické mezery

1. **Android `targetSdk`** se dědí z Flutter nástrojů (`build.gradle:47-48`). Nastavit ho explicitně
   a před odesláním ověřit, že splňuje aktuální minimum Play.
2. **`<queries>` pro `url_launcher`** — manifest deklaruje jen `PROCESS_TEXT`
   (`AndroidManifest.xml:43-48`). Na Androidu 11+ vrátí `canLaunchUrl` pro `https:` false, dokud
   nepřibude explicitní `<intent> ... VIEW / https`. Závisí na tom odkazy na YouTube, odkazy na noty
   i dialog s QR kódem (`youtube_video_page.dart`, `qr_code_dialog.dart`, `edit_page.dart`).
3. **Mobilní release buildy nejsou ověřené.** V repozitáři nic nedokládá úspěšné
   `flutter build appbundle --release` / `flutter build ipa`. Desktopové pluginy se importují na
   začátku `main.dart`; za běhu jsou sice ošetřené, ale release buildy je potřeba prokázat.
4. **Jazyk je natvrdo čeština** — `startLocale: const Locale('cs')` v `lib/main.dart:110`.
   Pro mezinárodní nabídku by měla aplikace respektovat jazyk zařízení a `cs` nechat jen jako
   záložní variantu.
5. **Start dělá síťovou práci ještě před vykreslením UI** — `initProvidersAndCheckSync()`
   (`lib/main.part.dart:25-81`) se přihlašuje k PocketBase a posílá čtyři počítací dotazy ještě
   před `runApp`. Na nespolehlivé síti to znamená pomalý nebo prázdný první start; recenzent
   v omezené síti může vidět rozbitou aplikaci. Musí to být neblokující a s tvrdým timeoutem.
6. **Žádné hlášení pádů, žádná analytika.** U placené aplikace před vydáním přidat Sentry nebo
   Crashlytics.
7. **Chybí onboarding.** První spuštění teď vede na přihlášení a synchronizaci — pojmy, ke kterým
   platící cizí člověk nemá žádný kontext.
8. **195 nálezů analyzátoru.** Neblokuje, ale stojí za pročištění (`/simplify` nebo cílené
   `dart fix --apply`).
9. **`app.log` / `test.log` v kořeni repozitáře** a jeden `.disabled` Patrol test — úklid.

---

## 4. Obchodní stránka a účty

**Apple.** Apple Developer Program — 99 USD/rok. Pro placené aplikace navíc potřebuješ podepsanou
smlouvu Paid Applications a vyplněné bankovní a daňové údaje (jako vývojář mimo USA formulář
W-8BEN, česká daňová rezidence). Účet fyzické osoby = tvoje občanské jméno je veřejné, pokud se
nezaregistruješ jako firma.

**Google.** Play Console — 25 USD jednorázově. Dvě podstatná omezení pro nový **osobní** účet:
- Vyžaduje se ověření totožnosti (doklad).
- Nový osobní účet musí projít **uzavřeným testem s nejméně 12 testery po 14 po sobě jdoucích dní**,
  než může požádat o produkční přístup. **Začni s tím brzy** — je to nejdelší položka harmonogramu
  a na tvém kódu nezávisí.

**Cena.** Oba obchody si berou 15 % (pásmo pro malé firmy / první 1 M USD — měl bys požádat
o Apple Small Business Program a sníženou sazbu u Googlu) nebo 30 %. Oba obchody za tebe ve většině
zemí odvádějí DPH. Zvaž stejnou cenu v obou obchodech a cenovou hladinu pro český trh
(např. 99–199 Kč) oproti mezinárodním pásmům.

**Placené předem vs. freemium** (viz §7, rozhodnutí 3):
- **Placené předem** — nejjednodušší: žádný kód pro nákupy v aplikaci, žádná validace účtenek,
  žádné obnovování nákupu. Nevýhoda: žádná zkušební verze, výrazně nižší konverze, žádný příjem od
  stávajících uživatelů zdarma.
- **Zdarma + jednorázové odemčení (IAP)** — lepší konverze, ale vyžaduje `in_app_purchase`,
  ukládání oprávnění, obnovovací tok a testování v sandboxu na obou platformách (~1–2 týdny).
- **Předplatné** — dává smysl jen při provozování hostované synchronizace, jinak neobhajitelné.

Doporučení pro v1: **placené předem**, přehodnotit podle skutečných dat o stahování.

---

## 5. Plán po fázích

### Fáze 0 — rozhodnutí a účty (1. týden, převážně bez programování)
- [ ] Rozhodnout body 1–5 v §7.
- [ ] Změnit uniklé heslo k PocketBase a klíč ke Gemini. *(udělat hned, bez ohledu na ostatní)*
- [ ] Zaregistrovat/ověřit účty Apple Developer + Google Play Console.
- [ ] **Jakmile bude existovat sestavitelný AAB, spustit 14denní uzavřený test na Googlu**, sehnat
      12 testerů. Běží paralelně se všemi dalšími fázemi.
- [ ] Zvolit finální název aplikace (ověřit kolize v obchodech), bundle ID a cenu.

### Fáze 1 — právní a bezpečnostní náprava (1.–3. týden) — *blokuje všechno ostatní*
- [ ] Zavést zvolenou variantu pro web import (§2 B1). U varianty A: skrýt
      `WebProvider`/`WebBloc`/webové části UI za přepínač buildu, aby se na mobil nedostaly.
- [ ] Smazat natvrdo zapsaný token pro pisnicky-akordy.
- [x] ~~Odebrat `pocketbase_config.json` z assetů v `pubspec.yaml` a zrušit záložní `rootBundle`
      v `pocketbase_provider.dart`.~~ Hotovo 2026-08-17.
- [ ] Změnit heslo k PocketBase (stále otevřené) a přesunout tři API klíče do zabezpečeného úložiště.
- [ ] Zavést zvolený model synchronizace (§9): pro v1.0 to znamená přesunout PocketBase do
      pokročilého nastavení „mám vlastní server" a udělat z lokálního režimu výchozí cestu. Zpřísnit
      pravidla kolekcí v PocketBase.
- [x] ~~Přidat časové razítko `updatedAt` ke každé písni a playlistu už teď, ještě než bude existovat
      jakýkoli cloudový sync — last-write-wins po jednotlivých záznamech (§9) nejde zpětně dodělat
      nad daty, která razítko nemají.~~ **Hotovo 20. 8. 2026.** `DateTime? updatedAt` na `Song` a
      `Playlist`, razítkuje se při každém lokálním zápisu. **Zatím jen lokálně**: kolekce
      `songs`/`playlists` v PocketBase takové pole nemají, takže záznam, který projde přes server, o
      razítko přijde. Než bude moci řídit synchronizaci, je potřeba migrace schématu.
- [x] ~~Zprovoznit zápisové cesty bez serveru.~~ **Hotovo 20. 8. 2026** a ukázalo se, že to není
      drobnost, ale blokátor: každý zápis šel nejdřív na PocketBase a neúspěšné kolečko po síti bral
      jako neúspěch operace. Ve store buildu tedy nešlo smazat píseň, nešlo vytvořit, uložit ani
      smazat playlist a obnova zálohy neudělala vůbec nic. Všechno teď zapisuje nejdřív lokálně a na
      server sahá, jen když je připojený. `PlaylistRepository` navíc dostal Hive cache, kterou nikdy
      neměl — playlisty se dřív po restartu ztratily.
- [ ] Přesunout klíč ke Gemini do zabezpečeného úložiště a odstranit ho z exportu nastavení.
- [ ] Udělat `initProvidersAndCheckSync()` neblokující a s timeoutem; aplikace musí být při prvním
      spuštění plně použitelná offline.
- [ ] Ověřit: čistá instalace, režim letadlo, žádný nastavený server → aplikace funguje od začátku
      do konce.

### Fáze 2 — příprava releasu (3.–4. týden)
- [ ] Zapojit `signingConfigs.release` z `android/key.properties`; zapnout Play App Signing.
- [ ] Zapnout R8 (`minifyEnabled`, `shrinkResources`) + pravidla ProGuard; ověřit, že se nerozbije
      reflexe (adaptéry Hive, `json_serializable`).
- [ ] Sjednotit bundle ID; nastavit název aplikace viditelný uživateli na obou platformách; opravit
      `name`/`description` v pubspec.
- [ ] Explicitně nastavit `compileSdk`/`targetSdk`/`minSdk`; ověřit proti aktuálnímu požadavku Play.
- [ ] Přidat `<queries>` pro `https` VIEW intenty.
- [ ] Přepsat `NSPhotoLibraryUsageDescription`; projít, jestli file_picker/share_plus nepotřebují
      další purpose strings na cestách, které mobil skutečně používá.
- [ ] Přegenerovat ikony pro obě platformy; přidat adaptivní ikonu pro Android.
- [ ] Prokázat, že `flutter build appbundle --release` a `flutter build ipa` projdou; nainstalovat
      a odzkoušet release artefakty na skutečných zařízeních.
- [ ] Nastavit CI (adresář `.github/` už existuje) pro sestavení obou artefaktů.

### Fáze 3 — připravenost produktu pro platící uživatele (4.–6. týden)
- [ ] Onboarding při prvním spuštění vysvětlující, co aplikace umí bez serveru.
- [ ] Lokalizace podle jazyka zařízení; doplnit cs/en řetězce pro vše nově přidané.
- [ ] Hlášení pádů (Sentry/Crashlytics) s možností odhlášení.
- [ ] Tok „Smazat moje data / účet" v aplikaci (povinné, pokud účty zůstanou) + veřejná webová
      stránka.
- [ ] Nastavení: O aplikaci / verze / licence (`showLicensePage`) / kontakt na podporu / odkaz na
      zásady ochrany osobních údajů.
- [ ] Pročištění nálezů analyzátoru; znovu zapnout nebo smazat vypnutý Patrol test; rozšířit testy
      BLoC.
- [ ] Matice ručního testování: telefon + tablet, iOS + Android, tmavý/světlý režim, malá obrazovka,
      velké písmo.

### Fáze 4 — materiály pro obchody a odeslání (6.–8. týden)
- [ ] Zásady ochrany osobních údajů + podmínky na stabilní adrese.
- [ ] Snímky obrazovky: iPhone 6,9"/6,5", iPad 13" (pokud bude iPad podporovaný — Info.plist
      deklaruje orientace pro iPad, takže snímky pro iPad budou vyžadované), telefon s Androidem
      + tablet 7"/10".
- [ ] Feature graphic pro Play (1024×500), ikona v obchodě, krátký a dlouhý popis v češtině
      a angličtině.
- [ ] Pravdivě vyplnit Data Safety (Play) a Privacy Nutrition Labels (Apple).
- [ ] Dotazníky pro hodnocení obsahu a věkovou kategorii.
- [ ] Nahrát do TestFlightu (interní → externí) a do uzavřeného tracku Play.
- [ ] Odeslat k posouzení. Počítat s 1–2 koly zamítnutí; připravit si písemné vysvětlení, odkud
      obsah písní pochází — recenzenti se na to zeptají.

### Fáze 5 — po vydání
- [ ] Sledovat podíl relací bez pádu a recenze; mít připravenou cestu pro rychlou opravu.
- [ ] Podle skutečných dat o konverzi rozhodnout o nákupech v aplikaci / zkušební verzi.
- [ ] Distribuci pro desktop držet oddělenou od buildů pro obchody.
- [ ] **v1.1** — synchronizace přes vlastní cloudové úložiště uživatele (Google Drive + iCloud)
      podle §9. Ověření OAuth aplikace u Googlu pro scope `drive.appdata` začít řešit brzy — je to
      čekání, ne práce.
- [ ] **v1.2** — LAN sync pro kapelu (objevování přes mDNS/Bonjour + přenos stavu přes WebSocket)
      podle §9. Tohle je odlišující funkce; prezentační režim na desktopu už je stejný vzor, jen
      napříč okny místo napříč sítí.

---

## 6. Odhad náročnosti

| Fáze | Vývojářská práce | Kalendářní čas |
|---|---|---|
| 0 Rozhodnutí + účty | 0,5 dne | 1 týden (čekání na ověření) |
| 1 Právo + bezpečnost | 5–10 dnů | 2 týdny |
| 2 Příprava releasu | 3–5 dnů | 1 týden |
| 3 Připravenost produktu | 5–8 dnů | 2 týdny |
| 4 Materiály + review | 3–5 dnů | 2–3 týdny (vč. 14denního testu Play a review) |
| **Celkem** | **~17–29 člověkodnů** | **6–10 týdnů** |

14denní uzavřený test na Play a review u Applu je čekání, ne práce — překryj je s fázemi 3 a 4.

---

## 7. Otevřená rozhodnutí (nutná před začátkem fáze 1)

1. **Web import** — varianta A (odstranit z mobilu, doporučeno), B (jen odkazovat), nebo C (usilovat
   o písemný souhlas)? Určuje, kolik z `web_bloc`, `web_repository`, `web_provider` a webových částí
   UI se dostane na mobil.
2. **Model synchronizace** — celý rozbor je v **§9**. Není to už volba ano/ne; doporučení je
   postupná škála: lokálně first ve v1.0, sync přes vlastní cloud uživatele ve v1.1, LAN sync pro
   kapelu ve v1.2, vlastní PocketBase zůstává jako pokročilá volba. Hostované účty provozované tebou
   se pro jednorázově placenou aplikaci vědomě *nedoporučují*.
3. **Zpoplatnění** — placené předem (doporučeno pro v1), nebo zdarma s jednorázovým odemčením
   přes IAP?
4. **Rozsah v1** — jen telefon, nebo telefon + tablet? Deklarování podpory iPadu znamená sadu
   snímků navíc a další kolo testování; tabletové UI už existuje (`lib/view/tablet_view/`), takže
   jde hlavně o náklad na QA.
5. **Identita** — vydávat jako fyzická osoba (tvoje občanské jméno bude veřejné v obou obchodech),
   nebo založit firmu/IČO?

---

## 8. Okamžité kroky (nezávislé na všech rozhodnutích výše)

1. **Změnit heslo k PocketBase.** Bylo zabalené v každém dosud vydaném buildu, takže je fakticky
   veřejné. Stále otevřené (odloženo rozhodnutím) a je to jediná položka, která je tím *těžší*, čím
   déle se odkládá — každá nová instalace zvětšuje škodu ze změny hesla.
2. Vyměnit tři API klíče (`groqApiKey`, `youtubeApiKey`, `geminiApiKey`) a dostat je z čitelného
   úložiště v Hive i z exportu do schránky.
3. Smazat `web_provider.dart:15` (token k cizímu API, používaný na `:207`) a nechat ho zneplatnit
   u provozovatele webu, pokud byl vydaný na tebe.
4. Rozhodnout, jestli veřejný repozitář na GitHubu zůstane veřejný i po vydání (§2 B2, bod 7).

---

## 9. Architektura synchronizace bez vlastní databáze

Rozvádí rozhodnutí 2 z §7. Klíčové zjištění: **jsou to dva různé problémy** a každý má jinou
odpověď. Kód dnes dělá obojí — kolekce `realtime_state` (aktuální píseň, QR odkazy) a role
`viewer/editor/admin/superuser` v `app_users` ukazují, že jde o nástroj pro kapelu, ne jen o osobní
zpěvník.

### Problém A — osobní synchronizace mezi vlastními zařízeními

Telefon + tablet + desktop jednoho člověka. Řešitelné **úplně bez serveru**: synchronizace přes
cloudové úložiště, které uživatel už má.

**Doporučení: soubor ve vlastním cloudu uživatele.** Aplikace zapisuje snapshot/žurnál do složky na
Google Drive, iCloud Drive, Dropboxu nebo přes WebDAV (Nextcloud). Dat se nikdy nedotkneš, neplatíš
hosting a nejsi správce osobních údajů podle GDPR.

| Varianta | Napříč platformami | Háček |
|---|---|---|
| **Google Drive** (složka `drive.appdata`) | iOS + Android + desktop | Scope je klasifikovaný jako *sensitive* → OAuth aplikace potřebuje ověření u Googlu; počítej pár týdnů navíc |
| **iCloud / CloudKit** | jen Apple | Zdarma a nativní, ale Androidí tablet data neuvidí |
| **Dropbox** | všude | OAuth aplikace; schválení jednodušší než u Googlu |
| **WebDAV / Nextcloud** | všude | Žádné schvalování, ale má to jen technický uživatel |

Rozumná kombinace: **Google Drive + iCloud** pokryje ~95 % uživatelů, WebDAV jako bonus pro
techničtější. Ověření OAuth u Googlu je čekání, ne práce — ale musí se začít včas.

**Řešení konfliktů se musí vyřešit bez ohledu na zvolené úložiště.** Když uživatel upraví píseň na
telefonu i na tabletu, zatímco jsou obě zařízení offline, co vyhraje? Nejjednodušší udržitelná
odpověď je last-write-wins **po jednotlivých písních** (ne nad celou databází), s razítkem
`updatedAt` u každého záznamu. Model už je rozdělený na písně/playlisty, takže to sedí na stávající
strukturu.

### Problém B — kapela: společné playlisty a realtime „všichni na stejné písni"

Soubory v cloudu tohle neřeší. Při zkoušce nebo na chválách potřebují všichni sledovat, na čem je
zrovna kapelník.

**Odpověď bez serveru: lokální síť.** Jedno zařízení dělá hostitele (kapelník), ostatní se připojí
přes Wi-Fi — mDNS/Bonjour pro objevování, WebSocket pro přenos stavu. Žádný server, žádné účty,
žádné provozní náklady.

Pro tenhle konkrétní případ užití je LAN spíš **lepší** než cloud, ne horší: všichni jsou stejně ve
stejné místnosti, funguje to i když v kostele nechytá signál, a je to okamžité bez latence.
Prezentační režim na desktopu už je přesně tenhle vzor, jen napříč okny místo napříč sítí.

Sdílení playlistu s kapelou *před* zkouškou pokryje export souboru přes share sheet nebo QR kód —
`backup_service.dart`, `share_plus` i `qr_flutter` už v projektu jsou, takže jde spíš o doladění než
o novou práci.

### Vlastní PocketBase jako „pro" varianta

To, co existuje dnes, nezahazovat — jen to přeznačit na pokročilé nastavení: *„mám vlastní server,
tady je URL a přihlášení."* Pro kapelníka, který si server sám provozuje, je to plnohodnotná varianta
a tebe nestojí nic. Jen to nesmí být výchozí cesta, kterou uvidí běžný kupující.

### Varování k byznys modelu

Kdyby hostovaný sync někdy provozoval ty: **jednorázově placená aplikace s doživotním hostovaným
syncem je prodělečný model.** Náklady na server běží dál, příjem přišel jednou. Hostovaný sync
funguje jen jako předplatné. Proto by v1 měla být postavená tak, aby server nepotřebovala vůbec —
když se poptávka po hostovaném syncu později ukáže jako reálná, přidá se jako placený doplněk nad
architekturu, která už funguje.

### Doporučené fázování

| Verze | Schopnost | Poznámka |
|---|---|---|
| **v1.0** | Lokálně first; plně použitelné offline bez jakéhokoli nastavování | Kvůli review v obchodech to stejně musí být (§3.5) |
| **v1.0** | Export/import + QR / share sheet | Z velké části existuje; nejlevnější způsob, jak přenést písně mezi zařízeními |
| **v1.1** | Synchronizace přes vlastní cloud uživatele (Drive + iCloud) | Neblokuje vydání |
| **v1.2** | LAN sync pro kapelu | Tohle je skutečná odlišující funkce |
| — | Vlastní PocketBase | Zůstává, skryté v pokročilém nastavení |

---

## 10. Rozdělení na dva produkty: osobní build vs. store build

Odpovídá na otázku „jak si můžu dál vyvíjet všechno pro sebe a zároveň vydávat omezenou,
prodejnou verzi" — a nahrazuje rámování „buď–anebo" u rozhodnutí 1 a 3 v §7.

### Nepoužívat dvě dlouhoběžící gitové větve

Nasnadě je nápad mít větev `personal` a větev `deploy` — je to špatný nástroj. Každá oprava
a každá funkce by se musela cherry-pickovat nebo mergovat přes obě, s každým týdnem přibývá
konfliktů a po půl roce máš dva projekty místo jednoho. Dělá to *přesně* z toho, co je zadáním
(„jednoduše přidávat funkce do obou částí"), tu nejtěžší věc.

**Použij jednu větev a dva build flavory s příznaky vyhodnocenými při kompilaci.**

### Proč při kompilaci, ne přepínačem za běhu

Ve store buildu musí zakázaný kód **v artefaktu chybět**, ne být jen vypnutý. Kdokoli si rozbalí
APK/IPA a přečte řetězce; recenzent, který v placené aplikaci najde `velkyzpevnik.cz`, je přesně
problém B1 (§2). Runtime `if (settings.enableWebImport)` nechá v binárce všechny URL i API token.
`const` příznak umožní AOT kompilátoru dokázat, že je větev mrtvá, a odstranit ji.

### Tři vrstvy — jistotu dávají jen všechny tři dohromady

**Vrstva 1 — kompoziční kořen. Tady vzniká skutečné odstranění.** Projekt už má správný šev:
`AppRepositories` v `lib/main.dart:43`. Rozděl vstupní body:

```
lib/
  config/features.dart      # const příznaky
  main_personal.dart        # vstupní bod: plná sada funkcí
  main_store.dart           # vstupní bod: bezpečné pro obchody
  main.dart                 # sdílený bootstrap + MyApp (role beze změny)
```

Store vstupní bod nikdy nezpůsobí vytvoření `web_provider.dart`. Celý podstrom
(provider → repository → bloc) se stane nedosažitelným a odstraní se i s řetězci URL.

**Vrstva 2 — const příznaky pro UI**, aby se záložky a tlačítka vůbec nepřeložily:

```dart
class Features {
  static const bool webImport    = bool.fromEnvironment('FEATURE_WEB_IMPORT');
  static const bool aiEnrichment = bool.fromEnvironment('FEATURE_AI');
  static const bool sharedServer = bool.fromEnvironment('FEATURE_SHARED_SERVER');
}
```

`bool.fromEnvironment` má výchozí hodnotu `false`. Je to záměr, který stojí za udržení: **když
zapomeneš cokoli předat, dostaneš bezpečný store build, ne ten osobní.** Fail-closed.

**Vrstva 3 — ověřit artefakt.** Tohle dělá rozdíl mezi „myslím, že to tam není" a „ověřil jsem,
že to tam není", a je to obhajitelné i před recenzentem:

```bash
unzip -p build/app/outputs/bundle/storeRelease/*.aab | strings \
  | grep -iE "velkyzpevnik|supermusic|proscholy|pisnicky-akordy|worshipleader|worshipchords" \
  && { echo "FAIL: zdrojové weby jsou ve store buildu"; exit 1; }
```

Zapojit do CI jako krok, který build shodí. Bez toho ti první nepozorná změna importu tiše protáhne
scraping zpět do placené aplikace.

### Konfigurace buildu

Použij `--dart-define-from-file` (Flutter 3.7+) místo dlouhých příkazových řádků:

Tři konfigurace, protože omezení se řídí tím, **jak se build distribuuje**, ne
tím, jak se flavor jmenuje:

| Build | Konfigurace | Web import |
|---|---|---|
| personal, jakákoli platforma | `config/personal.json` | zapnuto |
| store, Android / iOS | `config/store_mobile.json` | **vypnuto** — tyhle artefakty jdou na Google Play a App Store, kde platí B1 |
| store, macOS / Windows / Linux / web | `config/store_desktop.json` | zapnuto — distribuuje se přímo, pravidla obchodů neplatí |

```bash
flutter run   --flavor personal -t lib/main_personal.dart --dart-define-from-file=config/personal.json
flutter build appbundle --flavor store -t lib/main_store.dart --dart-define-from-file=config/store_mobile.json
```

V praxi používej `./build.sh <platforma> <flavor> <mode>`, který konfiguraci vybere
sám a sken B1 pouští jen na artefakty, které skutečně jdou do obchodu — skenovat
desktopové buildy by ze své podstaty selhávalo vždycky a brána, která selhává
pořád, se přestane brát vážně.

Zabalit do `Makefile`, ať je denní příkaz `make store-android`.

### Flavory na platformách

**Android** — `productFlavors` s odlišnými application ID:
`com.lzizka.songviewer.personal` a `com.lzizka.songviewer`. Užitečný vedlejší efekt: **oba buildy
jdou nainstalovat na jeden telefon vedle sebe**, takže se store verze dá testovat vedle osobní.
Ikony a názvy specifické pro flavor patří do `android/app/src/personal/res` a `src/store/res`;
Gradle je slévá automaticky.

**iOS** — dvě schémata plus dva `.xcconfig` soubory s odlišným `PRODUCT_BUNDLE_IDENTIFIER`
a `PRODUCT_NAME`. Vytvoření schémat je ruční práce v Xcode, ale jednorázová.

### Strategie v gitu

Zůstat u současného modelu, jen bez dlouhoběžících větví: `master` = to, co je vydané,
`develop` = integrace, krátké feature větve. Dva produkty odděl **tagy, ne větvemi** —
`store/v1.0.0` a `personal/v1.2.4`. Z jednoho commitu se dá vydat obojí, nebo jen jedna strana.
Čísla verzí přebij při buildu přes `--build-name` / `--build-number`, ať `pubspec.yaml` nemusí
držet dvě.

### Co se tím zároveň vyřeší

| Příznak | Personal | Store — Android / iOS | Store — desktop a web |
|---|---|---|---|
| `FEATURE_WEB_IMPORT` | zapnuto | **vypnuto** — řeší blokátor B1 (§2) | zapnuto |
| `FEATURE_SHARED_SERVER` | stávající PocketBase | lokálně first; server jen při ručním zadání | stejné jako mobil |
| `FEATURE_AI` | zapnuto | zvážit (klíče, náklady) | stejné jako mobil |

Podstatný je ten první řádek: **B1 je problém pravidel obchodů, ne problém kódu.**
Do Google Play a App Store se nahrávají jen artefakty pro Android a iOS, takže jen
ty se té funkce musí vzdát. Desktopové buildy téhož store produktu se distribuují
přímo a web import si nechávají.

Rozhodnutí 1 („co s web importem") a rozhodnutí 2 („model synchronizace") přestávají být
„buď–anebo" a stávají se z nich „obojí, jen v jiném flavoru" — v osobním buildu si nemusíš nic
odepírat.

### Náročnost

~2–3 dny: refaktor bootstrapu a vstupních bodů (½ dne), Gradle flavory (½ dne), iOS schémata
(1 den — Xcode je pomalý), skripty a kontrola v CI (½ dne). Nejvíc práce je rozplést UI: místa,
která odkazují na `WebBloc` (`web_body.dart`, `list_web_song.dart`, `web_page_mobile.dart`,
`song_card_tablet_web.dart`, `ribbon_menu.dart`, `home_page_tablet.dart`,
`web_search_history_menu.dart`), nesmí store build vůbec zmínit.

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
| B2 | Přihlašovací údaje admina k PocketBase zabalené jako asset (`pocketbase_config.json`) | **Kritická** | Každý kupující si je vytáhne z IPA/APK; navíc jedna sdílená databáze pro všechny uživatele |
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

`lib/providers/web_provider.dart:9-15` má natvrdo zapsaných šest zdrojů:

```
velkyzpevnik.cz, supermusic.cz, zpevnik.proscholy.cz,
pisnicky-akordy.cz, songs.worshipleaderapp.com, worshipchords.com
```

Aplikace stahuje a parsuje jejich stránky a API (`beautiful_soup_dart`, GraphQL a Elasticsearch
dotazy na ProScholy v `web_provider.dart:41-110`, WorshipLeader `/api/grid` a `/api/get` na
`:218-230`, HTML WorshipChords na `:251-270`) a **stažené texty a akordy ukládá do lokální
knihovny uživatele i na PocketBase server**.

`lib/providers/web_provider.dart:16` navíc obsahuje natvrdo zapsaný API token pro pisnicky-akordy.cz.

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

Bez ohledu na zvolenou variantu: **odstranit natvrdo zapsaný token** (`web_provider.dart:16`)
a nechat ho zneplatnit.

### B2 — tajemství a víceuživatelský provoz

`pubspec.yaml` uvádí `pocketbase_config.json` v sekci `flutter: assets:` a soubor na disku obsahuje:

```
pocketbaseUrl: https://your-pocketbase-url.example
email:        <e-mail admina>
password:     <heslo v čitelné podobě>
```

`lib/providers/pocketbase_provider.dart:127` ho načítá přes `rootBundle.loadString(...)` a na `:172`
se s ním přihlašuje. Soubor je sice v `.gitignore` (`.gitignore:121`) — to je tu ale bezpředmětné,
protože **se kompiluje přímo do distribuovaného balíčku aplikace**. Kdokoli si APK/IPA rozbalí.

Druhý problém: je to jeden sdílený účet na jednom serveru. Placená aplikace prodávaná cizím lidem
znamená, že by všichni kupující zapisovali do stejné databáze. Současný model je „privátní server
naší kapely", ne produkt.

Náprava:
1. Odebrat `pocketbase_config.json` z assetů v `pubspec.yaml` a zrušit záložní načítání přes
   `rootBundle` v `pocketbase_provider.dart:127`.
2. **Okamžitě změnit heslo admina k PocketBase a klíč ke Gemini** — obojí považuj za uniklé.
3. Zpřísnit pravidla kolekcí v PocketBase tak, aby běžný uživatel četl a zapisoval jen vlastní
   záznamy. Projít podle toho `pocketbase_collections.json`.
4. Rozhodnout model synchronizace (viz §7, rozhodnutí 2):
   - **Lokálně first + volitelně vlastní server** *(doporučeno pro v1)*: aplikace je plně použitelná
     offline bez jakéhokoli nastavování; synchronizace je pokročilé nastavení, kde si uživatel zadá
     *vlastní* PocketBase URL a přihlašovací údaje. Žádná sdílená infrastruktura, žádné náklady na
     hosting, žádná role správce osobních údajů podle GDPR.
   - **Hostované účty**: server provozuješ ty, uživatelé se registrují. Lepší produkt, ale děláš
     tím ze sebe správce osobních údajů (GDPR), přidává to náklady na hosting, vyžaduje mazání účtu
     (v aplikaci **a zároveň** na veřejné webové adrese — požadavek Play) a skutečné zásady ochrany
     osobních údajů pokrývající uložený obsah uživatelů.
5. Tajemství, která se musí distribuovat, přesunout do `--dart-define` / `String.fromEnvironment`,
   nikdy do assetů.
6. Klíč ke Gemini: teď je v čitelné podobě v Hive (`settings_repository.dart:210`) a vypisuje se do
   exportu nastavení (`general_settings_body.dart:294`). Odstranit ho z jakéhokoli exportu či
   diagnostiky; uložit přes `flutter_secure_storage`; nebo klíče zadávané uživatelem z mobilního
   buildu vypustit.

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
- [ ] Odebrat `pocketbase_config.json` z assetů v `pubspec.yaml` a zrušit záložní `rootBundle`
      v `pocketbase_provider.dart`.
- [ ] Zavést zvolený model synchronizace; zpřísnit pravidla kolekcí v PocketBase.
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
2. **Model synchronizace** — lokálně first s volitelným vlastním PocketBase serverem uživatele
   (doporučeno), nebo hostované účty, které provozuješ ty? Druhá varianta přidává GDPR, hosting
   a mazání účtů.
3. **Zpoplatnění** — placené předem (doporučeno pro v1), nebo zdarma s jednorázovým odemčením
   přes IAP?
4. **Rozsah v1** — jen telefon, nebo telefon + tablet? Deklarování podpory iPadu znamená sadu
   snímků navíc a další kolo testování; tabletové UI už existuje (`lib/view/tablet_view/`), takže
   jde hlavně o náklad na QA.
5. **Identita** — vydávat jako fyzická osoba (tvoje občanské jméno bude veřejné v obou obchodech),
   nebo založit firmu/IČO?

---

## 8. Okamžité kroky (nezávislé na všech rozhodnutích výše)

1. Změnit heslo admina k PocketBase — je v čitelném souboru, který se balí do buildů.
2. Ze stejného důvodu vyměnit API klíč ke Gemini.
3. Ověřit, že žádný distribuovaný build s `pocketbase_config.json` se nikdy nedostal ven.
4. Smazat `web_provider.dart:16` (token k cizímu API) a nechat ho zneplatnit u provozovatele webu,
   pokud byl vydaný na tebe.

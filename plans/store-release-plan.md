# Plan: Publishing Songs Viewer as a paid app on the App Store and Google Play

> Status: DRAFT — analysis only, no code changed yet.
> Created: 2026-08-17
> Scope: iOS + Android paid release. Desktop (Windows/macOS/Linux) stays as-is for now.

---

## 0. Executive summary

The app is functionally rich and technically healthy (`flutter analyze`: 0 errors, 0 warnings,
195 infos), but **it cannot be published in its current form**. There are three hard blockers
and a set of smaller release-engineering gaps.

| # | Blocker | Severity | Why it blocks |
|---|---------|----------|---------------|
| B1 | Scraping of 6 third-party lyrics/chord sites, incl. a hardcoded third-party API token | **Critical** | App Store 5.2 (IP) / Play "Intellectual Property" — near-certain rejection or later takedown, plus real copyright liability once money is involved |
| B2 | ~~PocketBase credentials shipped as a bundled asset~~ → **partly fixed 2026-08-17**; the password was *not* rotated and the single shared DB remains | **Critical** | The credential no longer ships, but it shipped in every build released so far, so it must be treated as public. A paid app also cannot put all buyers in one shared database |
| B3 | Android release builds are signed with the **debug** key | **Critical** | Play refuses debug-signed AABs |
| B4 | Placeholder metadata (app name, bundle IDs, purpose strings, pubspec name/description) | High | Guaranteed review friction; bundle IDs are permanent once published |
| B5 | No privacy policy, no account deletion path, no store assets | High | Required by both stores' forms before submission |

Realistic timeline to first release: **6–10 weeks**, dominated by (a) resolving the content/licensing
question and (b) Google's mandatory 14-day closed test for new personal developer accounts.

---

## 1. What the app is today (findings)

**Stack.** Flutter 3.44.3, BLoC, Hive (local), PocketBase (remote sync), `easy_localization`
(cs/en), 182 Dart files, separate mobile / tablet / desktop view trees.

**Platforms.** `android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/` all present.
Desktop-only plugins (`window_manager`, `desktop_multi_window`, `screen_retriever`) are imported
unconditionally in `lib/main.dart` but guarded at runtime by `Platform.is*` checks
(`lib/main.dart:101-107`).

**Core features.** Song editing (lyrics + chords + transposition), chord diagrams, playlists,
PDF/sheet rendering, YouTube playback links, presentation mode (secondary window on desktop),
QR sharing, backup/restore, PocketBase sync with user roles, AI-assisted song enrichment
(Gemini), and web import from six chord sites.

**Health.** `flutter analyze` → 195 issues, all `info` (mostly `use_super_parameters`,
`use_build_context_synchronously`, `avoid_print` in tests). Unit tests exist for models,
repositories and one BLoC; integration tests via Patrol, one is `.disabled`.

---

## 2. Blockers in detail

### B1 — Third-party content scraping (the decisive one)

`lib/providers/web_provider.dart:9-14` hardcodes six sources:

```
velkyzpevnik.cz, supermusic.cz, zpevnik.proscholy.cz,
pisnicky-akordy.cz, songs.worshipleaderapp.com, worshipchords.com
```

The app fetches and parses their pages/APIs (`beautiful_soup_dart`, GraphQL and Elasticsearch
queries against ProScholy at `web_provider.dart:41-110`, WorshipLeader `/api/grid` and `/api/get`
at `:218-230`, WorshipChords HTML at `:251-270`) and **stores the imported lyrics and chords into
the user's local library and the PocketBase server**.

`lib/providers/web_provider.dart:15` also contains a hardcoded API token for pisnicky-akordy.cz,
sent as a bearer header at `:207`.

Why this blocks a **paid** release specifically:

- Song lyrics are copyrighted works. Neither you nor the scraped sites can license them onward.
- Apple Guideline 5.2.1/5.2.3 and Play's IP policy both target apps that reproduce third-party
  content without authorization. Reviewers actively look for this in "chords/lyrics" apps.
- Charging money removes any fair-use-ish defence and makes you a commercial infringer.
- The hardcoded token is unauthorized access to someone else's API — independent of copyright.
- Even if it passes review, a single DMCA/takedown from a site owner or publisher (OSA/Intergram
  in CZ, CCLI/Hal Leonard internationally) removes the app and can strike the developer account.

**Options (must pick one — see §7 Decision 1):**

| Option | What it means | Store risk | Effort |
|---|---|---|---|
| **A. Remove import from mobile builds** *(recommended)* | Mobile app = personal songbook: user writes/imports **their own** songs, syncs, presents. Web import stays desktop-only, or is dropped entirely. | Lowest | Low–Medium |
| **B. Link-out instead of scrape** | Replace import with "open in browser / in-app browser" to the source site. User reads it there; nothing is copied into the app. | Low | Medium |
| **C. Get written permission** | Contact each of the six sites for written consent to import; keep only those who agree; drop the token. | Medium (needs paperwork you may have to show Apple) | High, external dependency |
| **D. Ship as-is** | — | **Unacceptable** | — |

Recommendation: **A for v1.0**, with B as an optional follow-up. Keep the scraping code behind a
compile-time flag so the desktop build (not distributed via stores) is unaffected.

Regardless of the option: **remove the hardcoded token** (`web_provider.dart:15`) and rotate it.

### B2 — Secrets and multi-tenancy

> **Updated 2026-08-17.** The *shipping* half of this blocker was fixed separately while this plan
> was being written (DEVLOG parts 8–9): `pocketbase_config.json` is no longer in
> `flutter: assets:`, the `rootBundle` fallback is gone from `pocketbase_provider.dart`, the config
> lives only in `~/.songviewer/`, and git history was purged. The items below are what remains.

Originally, `pocketbase_config.json` (server URL + account e-mail + plain-text password) was listed
under `flutter: assets:` and loaded via `rootBundle`, so it was compiled into every shipped bundle
and readable with any archive tool.

Second problem, untouched: this is one shared account on one server. A paid app sold to strangers
means every buyer would write into the same database. The current model is "my band's private
server", not "a product".

Fix:
1. ~~Remove `pocketbase_config.json` from `pubspec.yaml` assets and delete the `rootBundle`
   fallback path.~~ **Done 2026-08-17.**
2. **Rotate the PocketBase password** — still open (deferred by decision). It was embedded in every
   build released so far, so it must be treated as public; purging git history does not un-ship
   builds already distributed. Rotation invalidates existing installations, which is exactly why it
   should happen *before* strangers buy the app rather than after.
3. **Move the three API keys out of plain storage** — `groqApiKey`, `youtubeApiKey`, `geminiApiKey`
   are held as plain text in Hive (`settings_repository.dart:50-52`, loaded at `:208-210`), and the
   settings screen copies the YouTube and Gemini keys to the clipboard in the clear
   (`general_settings_body.dart:290-294`). Use `flutter_secure_storage`, strip them from any
   export/diagnostic output, or drop user-supplied keys from the mobile build.
   **Settled for the store build on 2026-08-18** by taking the "drop them" option: the whole API-key
   settings section — including the "Export all API keys" clipboard button — sits behind
   `Features.aiEnrichment`, so a store build cannot display or accept the keys (`FEATURE_AI` is
   `false` in both `store_mobile.json` and `store_desktop.json`). **The personal build is
   unchanged**: keys are still entered there and still live in plain Hive. What remains is therefore
   a personal-build-only concern and a much smaller one (one device, own keys).
   `backup_service.dart:197-199` / `:386-388` still writes the keys into the settings backup and
   reads them back — always empty in a store build, not in personal.
4. Lock the PocketBase collection rules so a non-admin user can only read/write their own records.
   Review `pocketbase_collections.json` against this.
5. Decide the sync model — **see §9 for the full analysis.** In short: local-first by default, with
   PocketBase demoted to an advanced "I run my own server" setting. Hosted accounts operated by you
   are not recommended for a one-time-purchase app.
   **Implemented in the UI on 2026-08-20.** `Features.sharedServer` previously gated only startup
   (`main.part.dart:40`), so a store build started local-first but still showed the whole server
   layer. Now: account login compiles out (`state_login.dart`, `app_router.dart` — the pages leave
   the artifact), user and group administration appears only when a server is actually connected
   (`Features.serverAdminVisible`), and the PocketBase settings are demoted to a collapsed
   "own server (advanced)" section in all three layouts. The server is kept, not removed, exactly as
   §9 requires. This also fixed a hole the flag had opened: the library-permission check read a
   server-issued role, which a local-first build never has, so a fresh store install could not
   create its first song (`UsersState.canManageLibrary`).
6. Move any secrets that must ship to `--dart-define` / `String.fromEnvironment`, never assets.
7. **The GitHub repository is public.** Not a store blocker, but a commercial decision worth making
   consciously: anyone can clone and build the app for free, and the source documents your server
   endpoint. Either accept it (a paid version competes on convenience, not secrecy — a normal choice
   for open-source apps sold on stores) or make the repo private before launch.

### B3 — Android release signing

`android/app/build.gradle:56-60`:

```gradle
release {
    // TODO: Add your own signing config for the release build.
    signingConfig signingConfigs.debug
}
```

`android/key.properties` already exists (storePassword / keyPassword / keyAlias / storeFile) —
it is simply not wired in. Needs the standard `signingConfigs.release` block reading
`key.properties`, plus `minifyEnabled`/`shrinkResources` and a ProGuard file. Back up the keystore
somewhere durable, or enroll in Play App Signing (recommended — Google keeps the master key).

### B4 — Identity and metadata

| Item | Current | Problem |
|---|---|---|
| Android `applicationId` | `com.lzizka.songsviewer.songs_viewer_bloc` (`build.gradle:45`) | Contains the raw project name; inconsistent with iOS. **Permanent after first publish.** |
| iOS bundle ID | `com.lzizka.songviewer` (`project.pbxproj:504`) | Fine — align Android to this or pick a new pair now |
| Android app label | `songs_viewer_bloc` (`AndroidManifest.xml:5`) | This is what users see on the home screen |
| pubspec `name` / `description` | `default_project` / "A new Flutter project." | Cosmetic but sloppy; `name` change means updating every `package:default_project/...` import |
| iOS `NSPhotoLibraryUsageDescription` | "Photo Library Access Warning" (`Info.plist`) | Placeholder purpose strings are an automatic rejection; must explain *why* in user language |
| Version | `1.2.3+43` | Fine as a starting point |

Also: `android:label`, `CFBundleName` (`songs_viewer`) and `CFBundleDisplayName` (`Songs Viewer`)
disagree with each other.

### B5 — Store compliance artifacts (none exist yet)

- Privacy policy URL (public, reachable) — **required by both stores**, and mandatory because the
  app makes network calls and (optionally) stores user content.
- Terms of use / EULA (Apple's standard EULA is acceptable if you don't need custom terms).
- Support URL + support e-mail.
- Play **Data safety** form and Apple **Privacy Nutrition Labels** — must match reality
  (network access, user-generated content, optional third-party AI calls to Google Gemini).
- Content rating questionnaire (Play) / age rating (Apple).
- Account deletion route — required by Play if the app has accounts; needs both an in-app path
  and a publicly accessible web page.
- Export compliance: `ITSAppUsesNonExemptEncryption = false` is already set and is correct for
  HTTPS-only usage.

---

## 3. Secondary technical gaps

1. **Android `targetSdk`** is inherited from the Flutter tool (`build.gradle:47-48`). Pin it
   explicitly and verify it satisfies Play's current minimum before submitting.
2. **`<queries>` for `url_launcher`** — the manifest only declares `PROCESS_TEXT`
   (`AndroidManifest.xml:43-48`). On Android 11+ `canLaunchUrl` for `https:` will return false
   without an explicit `<intent> ... VIEW / https` query. YouTube links, sheet links and the QR
   dialog all depend on this (`youtube_video_page.dart`, `qr_code_dialog.dart`, `edit_page.dart`).
3. **Mobile release builds are unverified.** Nothing in the repo shows a successful
   `flutter build appbundle --release` / `flutter build ipa`. Desktop plugins are imported at the
   top of `main.dart`; they are runtime-guarded but the release builds must be proven.
4. **Locale is forced to Czech** — `startLocale: const Locale('cs')` in `lib/main.dart:110`.
   For an international listing, follow the device locale and keep `cs` only as fallback.
5. **Startup does network work before UI** — `initProvidersAndCheckSync()`
   (`lib/main.part.dart:25-81`) authenticates against PocketBase and issues four count queries
   before `runApp`. On a flaky network this is a slow/blank first launch; reviewers on a
   restricted network may see a broken app. Must be non-blocking with a hard timeout.
6. **No crash reporting / no analytics.** For a paid app, add Sentry or Crashlytics before launch.
7. **No onboarding.** First run currently lands on login/sync concepts that a paying stranger has
   no context for.
8. **195 analyzer infos.** Not blocking, but worth a cleanup pass (`/simplify` or a focused
   `dart fix --apply`).
9. **`app.log` / `test.log` in the repo root** and a `.disabled` Patrol test — housekeeping.

---

## 4. Business / account setup

**Apple.** Apple Developer Program — 99 USD/year. For paid apps you additionally need the Paid
Applications agreement signed, plus banking and tax details (W-8BEN as a non-US developer, Czech
tax residency). Individual account = your legal name is public unless you register as a company.

**Google.** Play Console — 25 USD one-time. Two important constraints for a **new personal**
account:
- Identity verification (ID document) is required.
- A new personal account must run a **closed test with at least 12 testers for 14 continuous days**
  before it can apply for production access. **Start this early** — it is the longest pole in the
  schedule and is independent of your code.

**Pricing.** Both stores take 15% (small-business / first 1M USD tier — you should apply for
Apple's Small Business Program and Google's reduced rate) or 30%. Note both stores handle VAT/sales
tax collection for you in most territories. Consider price parity across stores, and a Czech-market
price point (e.g. 99–199 CZK) versus international tiers.

**Paid-upfront vs freemium** (see §7 Decision 3):
- **Paid upfront** — simplest: zero IAP code, no receipt validation, no restore-purchase flow.
  Downside: no trial, much lower conversion, no revenue from existing free users.
- **Free + one-time unlock (IAP)** — better conversion, but requires `in_app_purchase`,
  entitlement storage, restore flow, and sandbox testing on both platforms (~1–2 weeks).
- **Subscription** — only if you run hosted sync; otherwise not justifiable.

Recommendation for v1: **paid upfront**, revisit after real download data.

---

## 5. Phased plan

### Phase 0 — Decisions and accounts (week 1, mostly non-coding)
- [ ] Resolve Decisions 1–4 in §7.
- [ ] Rotate the leaked PocketBase password and Gemini key. *(do this today, regardless)*
- [ ] Register/verify Apple Developer + Google Play Console accounts.
- [ ] **Start the Google 14-day closed test track as soon as any buildable AAB exists**, recruit
      12 testers. This runs in parallel with all later phases.
- [ ] Choose final app name (check store name collisions), bundle IDs, price.

### Phase 1 — Legal and security remediation (weeks 1–3) — *blocks everything*
- [ ] Implement the chosen option for web import (§2 B1). If Option A: gate
      `WebProvider`/`WebBloc`/web UI bodies behind a build flag so mobile ships without them.
- [ ] Delete the hardcoded pisnicky-akordy token.
- [x] ~~Remove `pocketbase_config.json` from `pubspec.yaml` assets and remove the `rootBundle`
      fallback in `pocketbase_provider.dart`.~~ Done 2026-08-17.
- [ ] Rotate the PocketBase password (still open) and move the three API keys to secure storage.
- [ ] Implement the chosen sync model (§9): for v1.0 that means demoting PocketBase to an advanced
      "I run my own server" setting and making local-first the default path. Harden PocketBase
      collection rules.
- [x] ~~Add an `updatedAt` timestamp to every song/playlist record now, even before any cloud sync
      exists — per-record last-write-wins (§9) is impossible to retrofit onto data written without it.~~
      **Done 2026-08-20.** `DateTime? updatedAt` on `Song` and `Playlist`, stamped on every local
      write. **Local-only for now**: the PocketBase `songs`/`playlists` collections have no such
      field, so a record that round-trips through the server loses it. A schema migration is needed
      before the timestamp can drive sync.
- [x] ~~Make the write paths work with no server.~~ **Done 2026-08-20**, and it turned out to be a
      blocker rather than a nicety: every write went to PocketBase first and treated a failed
      round-trip as a failed operation, so in a store build songs could not be deleted, playlists
      could not be created, saved or deleted, and restoring a backup did nothing. All now write
      locally first and contact the server only when connected. `PlaylistRepository` also gained the
      Hive cache it never had — playlists used to be lost on restart.
- [ ] Move the Gemini key to secure storage and strip it from settings export.
- [ ] Make `initProvidersAndCheckSync()` non-blocking with a timeout; app must be fully usable
      offline on first launch.
- [ ] Verify: fresh install, airplane mode, no server configured → app works end to end.

### Phase 2 — Release engineering (week 3–4)
- [ ] Wire `signingConfigs.release` from `android/key.properties`; enable Play App Signing.
- [ ] Enable R8 (`minifyEnabled`, `shrinkResources`) + ProGuard rules; verify no reflection breaks
      (Hive adapters, `json_serializable`).
- [ ] Align bundle IDs; set the user-visible app name on both platforms; fix pubspec
      `name`/`description`.
- [ ] Pin `compileSdk`/`targetSdk`/`minSdk` explicitly; confirm against Play's current requirement.
- [ ] Add `<queries>` for `https` VIEW intents.
- [ ] Rewrite `NSPhotoLibraryUsageDescription`; audit whether file_picker/share_plus need more
      purpose strings on the paths mobile actually uses.
- [ ] Regenerate launcher icons for both platforms; add adaptive icon for Android.
- [ ] Prove `flutter build appbundle --release` and `flutter build ipa` succeed; install and smoke
      test the release artifacts on real devices.
- [ ] Set up CI (there is already a `.github/` directory) to build both artifacts.

### Phase 3 — Product readiness for paying users (weeks 4–6)
- [ ] First-run onboarding explaining what the app does without a server.
- [ ] Device-locale-aware localization; complete cs/en strings for anything newly added.
- [ ] Crash reporting (Sentry/Crashlytics) with an opt-out.
- [ ] In-app "Delete my data / account" flow (mandatory if accounts stay) + a public web page.
- [ ] Settings: About / version / licences (`showLicensePage`) / support contact / privacy link.
- [ ] Analyzer cleanup pass; re-enable or delete the disabled Patrol test; broaden BLoC tests.
- [ ] Manual QA matrix: phone + tablet, iOS + Android, dark/light, small screen, large font.

### Phase 4 — Store assets and submission (weeks 6–8)
- [ ] Privacy policy + terms hosted at a stable URL.
- [ ] Screenshots: iPhone 6.9"/6.5", iPad 13" (if iPad is supported — the Info.plist declares iPad
      orientations, so iPad screenshots will be required), Android phone + 7"/10" tablet.
- [ ] Play feature graphic (1024×500), store icon, short + long description in cs and en.
- [ ] Fill Data Safety (Play) and Privacy Nutrition Labels (Apple) truthfully.
- [ ] Content/age rating questionnaires.
- [ ] Upload to TestFlight (internal → external) and the Play closed track.
- [ ] Submit for review. Budget for 1–2 rejection cycles; prepare a written explanation of where
      song content comes from — reviewers will ask.

### Phase 5 — Post-launch
- [ ] Monitor crash-free rate and reviews; hotfix path ready.
- [ ] Decide on IAP/trial based on real conversion data.
- [ ] Keep the desktop distribution channel separate from the store builds.
- [ ] **v1.1** — sync via the user's own cloud storage (Google Drive + iCloud), per §9. Start the
      Google OAuth verification for the `drive.appdata` scope early; it is calendar time, not work.
- [ ] **v1.2** — LAN sync for bands (mDNS/Bonjour discovery + WebSocket state transport), per §9.
      This is the differentiating feature; the desktop presentation mode is already the same pattern
      across windows.

---

## 6. Effort estimate

| Phase | Engineering effort | Wall-clock |
|---|---|---|
| 0 Decisions + accounts | 0.5 day | 1 week (verification latency) |
| 1 Legal + security | 5–10 days | 2 weeks |
| 2 Release engineering | 3–5 days | 1 week |
| 3 Product readiness | 5–8 days | 2 weeks |
| 4 Store assets + review | 3–5 days | 2–3 weeks (incl. Play 14-day test + review) |
| **Total** | **~17–29 dev-days** | **6–10 weeks** |

The Play 14-day closed test and Apple review are calendar time, not work — overlap them with
Phases 3–4.

---

## 7. Open decisions (needed before Phase 1 starts)

1. **Web import** — Option A (remove from mobile, recommended), B (link-out only), or C (seek
   written permission)? This determines how much of `web_bloc`, `web_repository`, `web_provider`
   and the web UI bodies ships to mobile.
2. **Sync model** — see **§9** for the full analysis. This is no longer a binary choice; the
   recommendation is a staged scale: local-first in v1.0, BYO-cloud file sync in v1.1, LAN sync for
   bands in v1.2, self-hosted PocketBase kept as an advanced option. Hosted accounts operated by
   you are deliberately *not* recommended for a one-time-purchase app.
3. **Monetization** — paid upfront (recommended for v1), or free with a one-time IAP unlock?
4. **Scope of v1** — phone-only, or phone + tablet? Declaring iPad support means an extra
   screenshot set and an extra QA pass; the tablet UI already exists (`lib/view/tablet_view/`),
   so this is mostly a QA cost.
5. **Identity** — publish as an individual (your legal name becomes public on both stores) or
   register a company/IČO?

---

## 8. Immediate actions (independent of every decision above)

1. **Rotate the PocketBase password.** It shipped inside every build released so far, so it is
   effectively public. This is still open (deferred by decision) and it is the one item that gets
   *harder* the longer it waits — every new installation increases the breakage from rotating.
2. Rotate the three API keys (`groqApiKey`, `youtubeApiKey`, `geminiApiKey`) and move them out of
   plain Hive storage and out of the clipboard export.
3. Delete `web_provider.dart:15` (third-party API token, used at `:207`) and have it invalidated by
   the site operator if it was issued to you.
4. Decide whether the public GitHub repository stays public before launch (§2 B2, item 7).

---

## 9. Sync architecture without running your own database

Expands Decision 2 in §7. The key insight: **this is two different problems**, and they have
different answers. The codebase does both today — the `realtime_state` collection (current song,
QR links) and the `viewer/editor/admin/superuser` roles in `app_users` show this is a band tool,
not only a personal songbook.

### Problem A — personal sync across my own devices

Phone + tablet + desktop belonging to one person. Solvable **with no server at all**: sync through
cloud storage the user already owns.

**Recommendation: a file in the user's own cloud.** The app writes a snapshot/journal into a folder
on Google Drive, iCloud Drive, Dropbox, or via WebDAV (Nextcloud). You never touch the data, pay no
hosting, and are not a GDPR data controller.

| Option | Cross-platform | Catch |
|---|---|---|
| **Google Drive** (`drive.appdata` folder) | iOS + Android + desktop | The scope is classed as *sensitive* → the OAuth app needs Google verification; budget a few extra weeks |
| **iCloud / CloudKit** | Apple only | Free and native, but an Android tablet will not see the data |
| **Dropbox** | everywhere | OAuth app; approval is simpler than Google's |
| **WebDAV / Nextcloud** | everywhere | No approval process at all, but only technical users have it |

Sensible combination: **Google Drive + iCloud** covers ~95 % of users, with WebDAV as a bonus for
the technical crowd. The Google OAuth verification is calendar time, not work — but it must be
started early.

**Conflict resolution has to be solved regardless of which storage is chosen.** If the user edits a
song on the phone and on the tablet while both are offline, which one wins? The simplest
sustainable answer is last-write-wins **per song** (not per whole database), with an `updatedAt`
timestamp on every record. The model is already split into songs/playlists, so this fits the
existing structure.

### Problem B — band: shared playlists and realtime "everyone on the same song"

Cloud files do not solve this. At a rehearsal or a service, everyone needs to follow whatever the
band leader is currently on.

**Server-free answer: the local network.** One device acts as host (the band leader), the others
connect over Wi-Fi — mDNS/Bonjour for discovery, WebSocket for state transport. No server, no
accounts, no running cost.

For this specific use case LAN is arguably **better** than cloud, not worse: everyone is in the same
room anyway, it works when the church has no mobile signal, and it is instant with no latency. The
desktop presentation mode is already this pattern, just across windows instead of across the
network.

Sharing a playlist with the band *ahead of* the rehearsal is covered by file export via the share
sheet, or by QR code — `backup_service.dart`, `share_plus` and `qr_flutter` are already in the
project, so this is refinement rather than new work.

### Self-hosted PocketBase as the "pro" option

Do not throw away what exists today — just relabel it as an advanced setting: *"I run my own server,
here is the URL and login."* For a band leader who already hosts one it is a full-featured option
and costs you nothing. It simply must not be the default path a regular buyer sees.

### Business-model warning

If hosted sync is ever operated by you: **a one-time-purchase app with lifetime hosted sync is a
loss-making model.** Server costs keep running; the revenue arrived once. Hosted sync only works as
a subscription. This is why v1 should be built to need no server at all — if demand for hosted sync
later proves real, it can be added as a paid add-on on top of an architecture that already works.

### Recommended staging

| Version | Capability | Note |
|---|---|---|
| **v1.0** | Local-first; fully usable offline with zero configuration | Required for store review anyway (§3.5) |
| **v1.0** | Export/import + QR / share sheet | Largely exists; cheapest way to move songs between devices |
| **v1.1** | Sync via the user's own cloud (Drive + iCloud) | Not a release blocker |
| **v1.2** | LAN sync for bands | This is the actual differentiating feature |
| — | Self-hosted PocketBase | Stays, hidden in advanced settings |

---

## 10. Splitting into two products: personal build vs store build

Answers "how do I keep developing everything for myself while shipping a restricted, sellable
version" — and supersedes the either/or framing of Decisions 1 and 3 in §7.

### Do not use two long-lived git branches

The obvious idea — a `personal` branch and a `deploy` branch — is the wrong tool. Every fix and
every feature would have to be cherry-picked or merged across, conflicts accumulate with every
week, and after six months there are two projects instead of one. It makes *exactly* the thing the
requirement asks for ("easily add features to both parts") the hardest thing to do.

**Use one branch and two build flavors with compile-time feature flags.**

### Why compile-time, not a runtime setting

For the store build the forbidden code must be **absent from the artifact**, not merely disabled.
Anyone can unpack an APK/IPA and read the strings; a reviewer finding `velkyzpevnik.cz` inside a
paid app is exactly the B1 problem (§2). A runtime `if (settings.enableWebImport)` leaves every URL
and the API token in the binary. A `const` flag lets the AOT compiler prove the branch is dead and
strip it.

### Three layers — only all three together give the guarantee

**Layer 1 — composition root. This is where real removal happens.** The project already has the
right seam: `AppRepositories` in `lib/main.dart:43`. Split the entrypoints:

```
lib/
  config/features.dart      # const flags
  main_personal.dart        # entrypoint: full feature set
  main_store.dart           # entrypoint: store-safe
  main.dart                 # shared bootstrap + MyApp (unchanged role)
```

The store entrypoint never causes `web_provider.dart` to be constructed. The whole subtree
(provider → repository → bloc) becomes unreachable and is stripped with its URL strings.

**Layer 2 — const flags for the UI**, so tabs and buttons compile out:

```dart
class Features {
  static const bool webImport    = bool.fromEnvironment('FEATURE_WEB_IMPORT');
  static const bool aiEnrichment = bool.fromEnvironment('FEATURE_AI');
  static const bool sharedServer = bool.fromEnvironment('FEATURE_SHARED_SERVER');
}
```

`bool.fromEnvironment` defaults to `false`. That is deliberate and worth keeping: **forgetting to
pass anything yields the safe store build, not the personal one.** Fail-closed.

**Layer 3 — verify the artifact.** This is what turns "I think it is excluded" into "I verified it
is excluded", and it is what makes the claim defensible to a reviewer:

```bash
unzip -p build/app/outputs/bundle/storeRelease/*.aab | strings \
  | grep -iE "velkyzpevnik|supermusic|proscholy|pisnicky-akordy|worshipleader|worshipchords" \
  && { echo "FAIL: source sites present in store build"; exit 1; }
```

Wire it into CI as a build-failing step. Without it, one careless import silently drags the
scraping back into the paid app.

### Build configuration

Use `--dart-define-from-file` (Flutter 3.7+) rather than long command lines:

Three configs, because the restriction follows **how a build is distributed**,
not what the flavour is called:

| Build | Config | Web import |
|---|---|---|
| personal, any platform | `config/personal.json` | on |
| store, Android / iOS | `config/store_mobile.json` | **off** — these are the artifacts uploaded to Google Play and the App Store, where B1 applies |
| store, macOS / Windows / Linux / web | `config/store_desktop.json` | on — distributed directly, no store policy applies |

```bash
flutter run   --flavor personal -t lib/main_personal.dart --dart-define-from-file=config/personal.json
flutter build appbundle --flavor store -t lib/main_store.dart --dart-define-from-file=config/store_mobile.json
```

In practice use `./build.sh <platform> <flavor> <mode>`, which selects the config
and only runs the B1 scan on the artifacts that actually ship to a store —
scanning desktop builds would always fail by design, and a gate that always fails
gets ignored.

Wrap in a `Makefile` so the daily command is `make store-android`.

### Flavors per platform

**Android** — `productFlavors` with distinct application IDs:
`com.lzizka.songviewer.personal` and `com.lzizka.songviewer`. Useful side effect: **both builds
install side by side on one phone**, so the store build can be tested next to the personal one.
Flavor-specific icons and labels live in `android/app/src/personal/res` and `src/store/res`;
Gradle merges them automatically.

**iOS** — two schemes plus two `.xcconfig` files with different `PRODUCT_BUNDLE_IDENTIFIER` and
`PRODUCT_NAME`. Scheme creation is manual work in Xcode, but it is one-off.

### Git strategy

Keep the current model, minus the long-lived branches: `master` = what is released, `develop` =
integration, short-lived feature branches. Separate the two products by **tags, not branches** —
`store/v1.0.0` and `personal/v1.2.4`. Both can be released from the same commit, or only one side.
Override version numbers at build time with `--build-name` / `--build-number` so `pubspec.yaml`
does not have to carry two.

### What this also resolves

| Flag | Personal | Store — Android / iOS | Store — desktop & web |
|---|---|---|---|
| `FEATURE_WEB_IMPORT` | on | **off** — resolves blocker B1 (§2) | on |
| `FEATURE_SHARED_SERVER` | the existing PocketBase | local-first; server only if entered manually | same as mobile |
| `FEATURE_AI` | on | evaluate (keys, cost) | same as mobile |

The web-import column is the important one: **B1 is a store-policy problem, not a
code problem.** Only the Android and iOS artifacts are uploaded to Google Play and
the App Store, so only they have to drop the feature. Desktop builds of the same
store product are distributed directly and keep it.

Decision 1 ("what to do about web import") and Decision 2 ("sync model") stop being either/or and
become "both, in different flavors" — nothing has to be given up in the personal build.

### Effort

~2–3 days: bootstrap/entrypoint refactor (½ day), Gradle flavors (½ day), iOS schemes (1 day —
Xcode is slow), scripts and the CI check (½ day). The bulk of the work is untangling the UI: the
places that reference `WebBloc` (`web_body.dart`, `list_web_song.dart`, `web_page_mobile.dart`,
`song_card_tablet_web.dart`, `ribbon_menu.dart`, `home_page_tablet.dart`,
`web_search_history_menu.dart`) must not be mentioned at all by the store build.

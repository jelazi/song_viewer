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
| B2 | PocketBase admin credentials shipped as a bundled asset (`pocketbase_config.json`) | **Critical** | Every buyer can extract the server login from the IPA/APK; also single shared DB for all users |
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

`lib/providers/web_provider.dart:9-15` hardcodes six sources:

```
velkyzpevnik.cz, supermusic.cz, zpevnik.proscholy.cz,
pisnicky-akordy.cz, songs.worshipleaderapp.com, worshipchords.com
```

The app fetches and parses their pages/APIs (`beautiful_soup_dart`, GraphQL and Elasticsearch
queries against ProScholy at `web_provider.dart:41-110`, WorshipLeader `/api/grid` and `/api/get`
at `:218-230`, WorshipChords HTML at `:251-270`) and **stores the imported lyrics and chords into
the user's local library and the PocketBase server**.

`lib/providers/web_provider.dart:16` also contains a hardcoded API token for pisnicky-akordy.cz.

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

Regardless of the option: **remove the hardcoded token** (`web_provider.dart:16`) and rotate it.

### B2 — Secrets and multi-tenancy

`pubspec.yaml` lists `pocketbase_config.json` in `flutter: assets:`, and the file on disk contains:

```
pocketbaseUrl: https://your-pocketbase-url.example
email:        <admin e-mail>
password:     <plaintext password>
```

`lib/providers/pocketbase_provider.dart:127` loads it via `rootBundle.loadString(...)` and
`:172` authenticates with it. The file is git-ignored (`.gitignore:121`) — but git-ignored is
irrelevant here, **it is compiled into the shipped app bundle**. Anyone can `unzip` the APK/IPA.

Second problem: this is one shared account on one server. A paid app sold to strangers means
every buyer would write into the same database. The current model is "my band's private server",
not "a product".

Fix:
1. Remove `pocketbase_config.json` from `pubspec.yaml` assets and delete the `rootBundle`
   fallback path in `pocketbase_provider.dart:127`.
2. **Rotate the PocketBase admin password and the Gemini key immediately** — treat both as leaked.
3. Lock the PocketBase collection rules so a non-admin user can only read/write their own records.
   Review `pocketbase_collections.json` against this.
4. Decide the sync model (see §7 Decision 2):
   - **Local-first + optional own server** *(recommended for v1)*: app is fully usable offline
     with zero configuration; sync is an advanced setting where the user enters *their own*
     PocketBase URL and credentials. No shared infrastructure, no per-user hosting cost, no GDPR
     data-controller burden for you.
   - **Hosted accounts**: you run the server, users register. Better product, but it makes you a
     data controller (GDPR), adds hosting cost, requires account deletion (in-app **and** a public
     web URL — Play requirement), and a real privacy policy covering stored user content.
5. Move any secrets that must ship to `--dart-define` / `String.fromEnvironment`, never assets.
6. Gemini API key: currently plain in Hive (`settings_repository.dart:210`) and printed into a
   settings-export buffer (`general_settings_body.dart:294`). Remove it from any export/diagnostic
   output; store via `flutter_secure_storage`; or drop user-supplied AI keys from the mobile build.

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
- [ ] Remove `pocketbase_config.json` from `pubspec.yaml` assets and remove the `rootBundle`
      fallback in `pocketbase_provider.dart`.
- [ ] Implement the chosen sync model; harden PocketBase collection rules.
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
2. **Sync model** — local-first with the user's own optional PocketBase server (recommended), or
   hosted accounts you operate? The second one adds GDPR, hosting and account-deletion work.
3. **Monetization** — paid upfront (recommended for v1), or free with a one-time IAP unlock?
4. **Scope of v1** — phone-only, or phone + tablet? Declaring iPad support means an extra
   screenshot set and an extra QA pass; the tablet UI already exists (`lib/view/tablet_view/`),
   so this is mostly a QA cost.
5. **Identity** — publish as an individual (your legal name becomes public on both stores) or
   register a company/IČO?

---

## 8. Immediate actions (independent of every decision above)

1. Rotate the PocketBase admin password — it is in a plaintext file that is bundled into builds.
2. Rotate the Gemini API key for the same reason.
3. Confirm no build artifact containing `pocketbase_config.json` has ever been distributed.
4. Delete `web_provider.dart:16` (third-party API token) and rotate it with the site owner if it
   was issued to you.

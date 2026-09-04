# Song Viewer

A songbook for musicians. Write songs as lyrics with inline chords, attach sheet music and
playback links, transpose on the spot, and project the lyrics on a second screen while you play.
Everything syncs through your own PocketBase server, and the whole band can read the current set
list from a phone browser over the local network.

[![CI](https://github.com/jelazi/song_viewer/actions/workflows/ci.yml/badge.svg)](https://github.com/jelazi/song_viewer/actions/workflows/ci.yml)
![Flutter](https://img.shields.io/badge/Flutter-3.44-blue.svg)
![Platform](https://img.shields.io/badge/iOS%20·%20Android%20·%20macOS%20·%20Windows%20·%20Linux%20·%20Web-lightgrey.svg)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

One codebase for iOS, Android, macOS, Windows, Linux and the web, with separate mobile, tablet
and desktop layouts rather than one stretched layout.

## The songbook

- **Lyrics with inline chords** — `[Am]` markup in the text, rendered above the syllable it
  belongs to
- **Transposition** — shift a song to another key without touching the source text
- **Chord notation** — convert foreign spelling to Czech notation, so `B` and `Bb` mean what the
  player expects
- **Sheet music and images** — attach PDFs or scans to a song
- **Playback links** — keep a YouTube link next to the song
- **Notes** — `{...}` blocks for arrangement notes that are not lyrics
- **Playlists** — named set lists with ordered song references
- **Groups** — categorise the songbook

## Presentation

- **Second window** on desktop through `desktop_multi_window`: the operator keeps the editor,
  the audience sees only the lyrics
- **Presentation playlists** — walk a set list front to back without leaving the projection
- **Live state** — the current song is shared through the PocketBase `realtime_state`
  collection, so another device can follow along

## Sharing over the local network

A built-in HTTP server publishes the songbook to any browser on the same Wi-Fi. Open the address
the app shows, or scan its QR code, and the band reads the set list on their own phones — no
account, no installation, nothing leaving the network.

## Import

- **ChordPro** — import songs in the [ChordPro](https://www.chordpro.org/) format, available in
  every build. The app's own markup already uses inline `[Chord]` the same way, so the
  conversion is mostly about the one place the formats disagree: ChordPro spends `{...}` on
  directives, the app spends it on notes.
- **Web import** — pull a song from the web and clean it up. Compile-time optional; see
  *Build flavours*.

## Sync

PocketBase is the backend for songs, playlists, users, groups, uploads and live state. Users
have roles (viewer, editor, admin, superuser), and write paths are local-first with per-record
timestamps, so the app stays usable offline and reconciles afterwards.

Credentials never live in the repository or in the app bundle. They are read from
`~/.songviewer/pocketbase_config.json`, an owner-only file outside the project, or typed into
the app's settings — which writes that same file.

## Architecture

- **BLoC/Cubit** — fifteen feature blocs (`home_page`, `playlist`, `presentation`,
  `presentation_playlist`, `preview`, `settings`, `users`, `web`, `local_web`,
  `chordpro_import`, `song_enrichment`, `notification`, `desktop_ribbon_menu` and the edit blocs)
- **Repositories** over PocketBase and local Hive storage
- **Responsive views** — `mobile_view`, `tablet_view` and `desktop_view` are separate widget
  trees behind one router, not breakpoints on a shared layout
- **Hive** for offline storage, **easy_localization** for English and Czech

```
lib/
├── blocs/          # one directory per feature
├── config/         # compile-time feature flags
├── core/
├── model/          # song, chord, playlist, web_song, ...
├── providers/      # pocketbase_provider
├── repositories/   # songs, playlists, users, settings, web
├── services/       # chordpro, presentation_bridge, local_web, enums
├── view/           # mobile_view | tablet_view | desktop_view | router
└── main.dart       # plus main_personal.dart / main_store.dart
packages/
└── logger_pkg/     # small logging package used across the app
```

## Build flavours

The app ships in two flavours, and the difference is compiled in rather than switched at runtime:

| Build | Config | Web import |
|---|---|---|
| personal, any platform | `config/personal.json` | on |
| store, Android / iOS | `config/store_mobile.json` | **off** |
| store, macOS / Windows / Linux / web | `config/store_desktop.json` | on |

Every flag in `lib/config/features.dart` is a `const` read from the compilation environment, so
the AOT compiler can prove a disabled branch is dead and strip it, together with the string
literals it reaches. That is the point: in the store build the excluded code must be *absent
from the artifact*, not merely switched off — anyone can unpack an APK and read the strings
inside. `bool.fromEnvironment` defaults to `false`, so forgetting to pass a config yields the
safe store build rather than the permissive one.

`build.sh` picks the entrypoint, config file and flavour for each target:

```bash
./build.sh                        # interactive menu
./build.sh macos personal debug
./build.sh android-aab store release
```

## Getting started

### 1. Install dependencies

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

The generated `.g.dart` and `.mocks.dart` files are not committed, so `build_runner` has to run
before analyzing, testing or building.

### 2. Set up a PocketBase server

See [PocketBase setup](#pocketbase-setup) below.

### 3. Configure the connection

```bash
mkdir -p ~/.songviewer && chmod 700 ~/.songviewer
cp pocketbase_config.example.json ~/.songviewer/pocketbase_config.json
chmod 600 ~/.songviewer/pocketbase_config.json
```

```json
{
  "pocketbaseUrl": "https://your-pocketbase-url.example",
  "email": "your-user@example.com",
  "password": "your-password"
}
```

The credentials live **only** in that file. It is never committed and deliberately not bundled as
an app asset, so no build ships it. You can also skip the file entirely and enter the server and
credentials under **Settings → PocketBase**, which writes the same file.

### 4. Run

```bash
flutter run -d macos
```

## PocketBase setup

### Option A — local development

1. Download PocketBase v0.36+ from [pocketbase.io](https://pocketbase.io/docs/)
2. Run `./pocketbase serve`
3. Open the Admin UI at `http://127.0.0.1:8090/_/`
4. Create an admin account

### Option B — self-hosted with Coolify

1. Create a new **Docker** service with the image `ghcr.io/muchobien/pocketbase:latest`
2. Map port `8090:8090`
3. Mount a persistent volume to `/pb_data`, so data survives container restarts
4. Point a subdomain at it and let Coolify handle Let's Encrypt
5. Open `https://your-pb-url/_/` and create the first admin account

### Import the collections

In the Admin UI go to **Settings → Import collections** and paste the contents of
`pocketbase_collections.json` from this repository. That creates:

| Collection | Holds |
|---|---|
| `songs` | lyrics, chords, metadata |
| `playlists` | named set lists with song references |
| `app_users` | application users and their roles |
| `groups` | song groups and categories |
| `realtime_state` | current song and QR links |
| `uploads` | sheet music (PDF / images) |

### Create a user

The app authenticates against the PocketBase `users` collection, not `app_users`. In the Admin
UI open **Collections → users**, create a record with an e-mail and password, and use those in
`~/.songviewer/pocketbase_config.json` or in the app settings.

## Development

```bash
flutter analyze
flutter test
```

Both run in CI on every push and pull request against `main`, alongside an Android build of the
store flavour. The Patrol tests in `integration_test/` need a device and run separately with
`patrol test`.

## Requirements

- Flutter SDK ≥ 3.10
- PocketBase 0.36+ for sync
- App icons are regenerated with
  `dart run flutter_launcher_icons -f flutter_launcher_icons.yaml`

## License

Released under the [MIT License](LICENSE).

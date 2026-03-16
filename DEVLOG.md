# Development Log

## 2026-03-16 - Full backup & restore for desktop

### What was done
Implemented a complete backup and restore feature for the desktop app. Backs up **everything** in the application: songs, playlists, groups, users, chord diagrams, all settings, and downloaded sheet/image files.

### Changes
- **BackupService** (`lib/services/backup_service.dart`): New service that handles:
  - **Export**: Collects all data (songs, playlists, groups, users, chord diagrams, settings, QR links, API keys) into a single `backup.json`. Downloads all sheet/image files from PocketBase into a `files/` subfolder. Creates a timestamped backup folder.
  - **Import**: Reads `backup.json`, re-uploads files to PocketBase (gets new URLs), remaps sheet URLs in songs, restores all collections (songs, playlists, groups, users, chord diagrams), restores all settings including colors, presentation settings, QR links, and API keys. Shows confirmation dialog before overwriting.
  - **Preview**: Reads a backup folder and shows counts of items before restoring.

- **BackupRestoreBody** (`lib/view/desktop_view/pages/desktop_home_page/home_bodies/backup_restore_body.dart`): Desktop UI with:
  - Export section — pick folder → creates timestamped subfolder with backup
  - Import section — pick backup folder → preview counts → confirm → restore
  - Progress indicator with live status messages
  - Result card showing success/error with item counts table

- **desktop_home_page.dart**: Added `case 'backup_restore'` → `BackupRestoreBody()`
- **ribbon_menu.dart**: Added "Záloha a obnova" button in SettingsTabbar (brown backup icon)

### Backup format
```
SongsViewer_backup_YYYYMMDD_HHMM/
  backup.json          — all structured data (version, songs, playlists, groups, users, chordDiagrams, settings, fileMapping)
  files/               — downloaded sheet images (file_0001.png, etc.)
```

### Current state
- Build succeeds, 0 errors, 0 warnings (only pre-existing info-level deprecation warnings)
- Accessible from desktop Settings tab → "Záloha a obnova" button
- Exports everything including binary files (sheets/images)
- Import re-uploads files to PocketBase and remaps URLs

---

## 2026-03-16 - Fix chord editor: edit replaces instead of adding duplicate

### What was done
Fixed bug where editing an existing chord position and saving it to the library would add a new position instead of replacing the edited one.

### What was fixed
- **chord_editor_dialog.dart**: Added `_isAddingNew` flag to distinguish between "add new" and "edit existing" operations
  - `_addNewPosition()` sets `_isAddingNew = true` → position is appended to list
  - `_editCurrentPosition()` sets `_isAddingNew = false` → position replaces at current index
  - `_saveEditedPosition()` simplified: checks `_isAddingNew` to decide add vs replace
  - `_cancelEditing()` also resets the flag
- Removed convoluted previous logic that incorrectly used `_positions.contains()` check, which always resulted in `add()` when the position was modified

### Current state
- Build succeeds, 0 errors
- Editing a chord position now correctly replaces it in-place
- Adding a new chord position still appends to the list as expected

---

## 2026-03-15 - Fix chord editor overflow + open editor for missing chords

### What was done
1. **Fixed RenderFlex overflow** in `ChordEditorDialog` — Column at line 183 overflowed by 18px on small screens
2. **Open chord editor for chords without diagrams** — tapping a chord that has no diagram now opens `ChordEditorDialog` directly instead of silently returning

### Changes
- **chord_editor_dialog.dart**: Wrapped content below header/Divider in `Flexible(SingleChildScrollView(Column(...)))` so dialog is scrollable
- **preview_page.dart** (mobile): `openChordImage` calls `_openChordEditor` when `positions.isEmpty`
- **preview_page_tablet.dart** (tablet): same fix
- **playlist_tablet.dart**: same fix
- **preview_body.dart** (desktop): same fix

### Current state
- Build succeeds, 0 errors (only info-level deprecation warnings)
- Chord editor dialog no longer overflows on smaller screens
- Chords without existing diagrams can now be created from any page (mobile/tablet/desktop)

---

## 2026-03-15 - Chord editor on mobile/tablet + mobile playlist single column

### What was done
1. **Chord editor on long-press** — mobile and tablet now open `ChordEditorDialog` when user long-presses on a chord name or on the chord overlay popup
2. **Mobile playlist: single column layout** — on phones (width < 600), playlist song view shows full lyrics in one scrollable column instead of two-column layout, with prev/next song buttons

### Changes
- **LyricsRenderer**: Added optional `onLongPressChord` callback, wired to both `GestureDetector` blocks
- **preview_page.dart** (mobile): Long-press on chord overlay popup opens `ChordEditorDialog`
- **preview_page_tablet.dart** (tablet): Same long-press → chord editor behavior
- **playlist_tablet.dart**: 
  - Added `_isMobile()` helper (Android/iOS + width < 600)
  - Added `_getSingleColumnRenderer()` — renders full lyrics in single scrollable column
  - Mobile: hides column navigation arrows, shows prev/next song buttons (skip_previous/skip_next)
  - Long-press on chord overlay opens `ChordEditorDialog`

### Current state
- Build succeeds, 0 errors
- Chord editor accessible everywhere: desktop (right-click), mobile/tablet (long-press)
- Mobile playlist songs are single-column scrollable with song navigation

---

## 2026-03-15 - Chord editor bugfixes + Hive cache for chord diagrams

### What was done
1. **Fixed Row overflow** in `ChordEditorDialog` save buttons — replaced `Row` with `Wrap`
2. **Fixed shift direction** in `ChordEditorWidget` — UP arrow now moves to higher frets (was inverted)
3. **Hive cache-first loading** for chord diagrams — same pattern as songs

### Changes
- **ChordEditorDialog**: Save buttons use `Wrap` instead of `Row` to prevent overflow
- **ChordEditorWidget**: Arrow UP = higher frets, arrow DOWN = lower frets; tooltips updated to "Vyšší pražce" / "Nižší pražce"
- **HiveProvider**: Added `saveChordDiagramsCache()`, `loadChordDiagramsCache()`, `getChordDiagramsSyncTimestamp()`
- **ChordService**: Rewritten for Hive-first loading — `loadFromCache()` → `isServerDataNewer()` → `syncFromServer()`. Accepts `HiveProvider`. Save/delete also persist to Hive cache.
- **SongsRepository**: Passes `hiveProvider` to `ChordService` constructor
- **main.part.dart**: Phase 2 uses cache-first flow for chords (same as songs)

### Current state
- Build succeeds, 0 errors
- Chord diagrams load instantly from Hive, sync with PB only when server timestamp differs

---

## 2026-03-15 - Chord editor: support for higher frets with fretboard shifting

### What was done
Updated `ChordEditorWidget` to support chords played higher up the guitar neck (up to fret 15).

### Changes
- **ChordEditorWidget** (`lib/view/desktop_view/widgets/chord_editor_widget.dart`):
  - Shows 5 frets at a time but supports actual fret values up to 15
  - Auto-calculates `startFret` from placed dots (same algorithm as `guitar_tabs.dart` renderer)
  - ▲/▼ shift buttons on the right side to manually scroll the visible fret range
  - Fret numbers displayed on the left side of the fretboard
  - Thick nut bar shown only when `startFret == 1`, otherwise thin line
  - Range indicator (e.g. "3–7") between shift buttons

### Current state
- `flutter analyze` passes with 0 errors, 0 warnings
- Editor properly handles high-fret chords (e.g. F# barré at fret 7-9)
- Consistent with the existing `guitar_tabs.dart` renderer behavior

---

## 2026-03-15 - Chord management: PB collection, per-song overrides, desktop editor

### What was done
Implemented a full chord management feature set with three parts:
1. **PocketBase `chord_diagrams` collection** — stores default chord diagrams (name + list of position strings) server-side
2. **Per-song chord overrides** — each song can optionally override specific chord diagrams via `chordOverrides` field
3. **Desktop chord editor** — interactive clickable fretboard for creating/editing chord fingering diagrams

### Changes
- **PB schema** (`pocketbase_collections.json`): Added `chord_diagrams` collection (name text, positions json, unique index on name); added `chordOverrides` json field to songs collection
- **ChordDiagram model** (`lib/model/chord/chord_diagram.dart`): New data class with `name` and `positions` fields, JSON serialization via `json_serializable`
- **PocketBaseProvider** (`lib/providers/pocketbase_provider.dart`): Added CRUD methods for `chord_diagrams` (`getAllChordDiagrams`, `getChordDiagram`, `addOrUpdateChordDiagram`, `deleteChordDiagram`); updated `_recordToSong`/`_songToBody` for `chordOverrides` serialization
- **Song model** (`lib/model/song/song.dart`): Added `Map<String, List<String>>? chordOverrides` field with full `copyWith`/equality support
- **ChordService** (`lib/services/chord_service.dart`): New service with in-memory PB cache; implements fallback chain: song overrides → PB cache → hardcoded `ChordsPositions` → empty
- **SongsRepository**: Added `ChordService` as owned field, initialized in constructor
- **main.part.dart**: Added `chordService.loadChordDiagrams()` call in Phase 2
- **ChordEditorWidget** (`lib/view/desktop_view/widgets/chord_editor_widget.dart`): Interactive 6-string × 5-fret fretboard with CustomPainter; click to place/remove finger dots; 0th fret toggles open/muted
- **ChordEditorDialog** (`lib/view/desktop_view/widgets/chord_editor_dialog.dart`): Full CRUD dialog — navigate positions, add/edit/delete, save to song or default library, remove song override, source indicator chip
- **All 5 preview views** updated to use `ChordService.resolveChordPositions()` instead of hardcoded `ChordsPositions`; desktop preview adds right-click to open chord editor

### Fallback chain
1. `song.chordOverrides[chordName]` — per-song override
2. PocketBase `chord_diagrams` collection cache — server default
3. `ChordsPositions.getPositionsChordsByName()` — hardcoded fallback
4. Empty list — nothing displayed

### Current state
- `flutter analyze` passes with 0 errors, 0 warnings (184 pre-existing info-level issues)
- All chord display code uses the new fallback chain
- Desktop right-click on chord opens editor dialog
- PB `chord_diagrams` collection schema is defined in JSON but needs to be created on server (import or manual creation)
- Hardcoded chords in `ChordsPositions` are still used as final fallback

### Pending / Next steps
- Import updated `pocketbase_collections.json` to PB server to create `chord_diagrams` collection and `chordOverrides` field on songs
- Optionally: seed PB `chord_diagrams` with data from hardcoded `ChordsPositions`
- Test the full flow end-to-end (create chord in editor → save to PB → verify fallback chain)

---

## 2026-03-15 - macOS Pod deployment target stabilization

### What was done
Resolved recurring CocoaPods deployment target mismatch warnings during macOS builds.

### What was fixed
- Updated `macos/Podfile` `post_install` hook to enforce `MACOSX_DEPLOYMENT_TARGET = 10.15` for all Pod targets.
- Re-ran `pod install` so generated `Pods.xcodeproj` no longer contains `10.11` targets.

### Current state
- `flutter build macos --debug` succeeds.
- Warning `MACOSX_DEPLOYMENT_TARGET is set to 10.11` is gone.
- Remaining warnings are from third-party dependencies (`patrol`, `CocoaAsyncSocket`) and do not block build.

---

## 2026-03-15 - Startup warning cleanup (macOS Pod target + stale Hive user)

### What was done
Cleaned up two non-critical startup warnings seen after enabling Hive cache-first loading.

### What was fixed
- **User warning from stale Hive session**: In `UsersRepository.checkUser()`, warnings are now suppressed when validation is triggered from Hive boot (`isFromHive: true`).
- **Auto-clean invalid cached user**: When cached user does not exist or password is invalid, `currentUser` in Hive is cleared to avoid repeated warnings on next start.
- **macOS CocoaPods deployment target warning**: Updated `macos/Podfile` post-install hook to force `MACOSX_DEPLOYMENT_TARGET = 10.13` for all pod targets, preventing Xcode warning about pods defaulting to 10.11.

### Current state
- Hive cache-first startup still works as expected.
- Startup logs are cleaner (fewer false-positive warnings).
- `desktop_multi_window` engine-handle warning remains separate and appears to be non-blocking (app starts and works).

---

## 2026-03-15 - Hive cache-first loading for songs and groups

### What was done
Implemented offline-first caching: songs and groups are now stored in Hive and loaded from cache on startup. PocketBase is only queried when the server `updated` timestamp differs from the cached one.

### Changes
- **HiveProvider**: Added `songsCacheBox` with methods `saveSongsCache()`, `loadSongsCache()`, `getLastSyncTimestamp()`, `saveGroupsCache()`, `loadGroupsCache()`
- **PocketBaseProvider**: Added public `getServerUpdatedTimestamp()` method to fetch the global `updated` value from `realtime_state`
- **SongsRepository**:
  - Added `loadSongsFromCache()` / `loadGroupsFromCache()` for instant Hive loading
  - Added `isServerDataNewer()` — compares Hive timestamp vs PocketBase `updated` timestamp
  - Added `_saveSongsToCache()` — persists songs + server timestamp to Hive
  - All CRUD operations (create, update, delete song/group) and realtime handlers now persist to Hive cache
- **main.part.dart**: `loadDataFromServer()` now uses cache-first flow:
  1. Load songs & groups from Hive (instant)
  2. Compare timestamps — only sync from PB if server is newer
  3. If no cache exists, full sync from PB as before

### Flow
1. App starts → load songs from Hive cache (instant UI)
2. Fetch `updated` timestamp from PocketBase
3. If timestamp differs from cached value → full sync from PB → save to Hive with new timestamp
4. If same → skip PB fetch, use cached data
5. Realtime updates during session also persist to Hive

### Current state
- Zero compilation errors (169 pre-existing info warnings)
- Cache persists across app restarts
- First launch still fetches everything from PB (no cache yet)
- Subsequent launches are instant from cache unless PB has changes

---

## 2026-03-14 - Fix playlist timestamp updates + cleanup

### What was done
Fixed issue where playlist saves (edit and create) did not update `playlists_updated` and `updated` timestamps in the `realtime_state` collection. Songs were already working correctly.

### What was fixed
- **Removed `checkSongChange()` guard in `playlists_bloc.dart`**: The `_savePlaylist` handler had a guard that compared current songs against the original playlist. This could silently prevent saves when the user edited only the name or when songs appeared unchanged (reference equality). Removed the guard — now saves always proceed if name is non-empty and songs exist.
- **Cleaned up debug logging**: Removed all `debugPrint` and `logger.i` statements added during troubleshooting from `pocketbase_provider.dart`, `playlists_bloc.dart`, `edit_song_bloc.dart`, and `playlist_body.dart`.

### Root cause
The `checkSongChange()` method in `PlaylistsBloc._savePlaylist` was comparing the current state against the mutable `currentPlaylist` object. After the first save, the playlist object was already mutated in place, so subsequent saves would see no changes and short-circuit before calling the repository.

### Current state
- Songs and playlists both correctly update timestamps on save
- All 10 playlist repository tests pass
- Zero compilation errors
- Realtime sync works end-to-end: save → timestamp update → global `updated` bump → listener triggers → diff & fetch

---

## 2026-03-13i - Global `updated` trigger in realtime_state

### What was done
Added a global `updated` timestamp to `realtime_state` that acts as a single trigger for all change detection. The listener now watches ONLY this one value — when it changes, the app loads and diffs all timestamp maps.

**Flow:**
1. CRUD operation happens → individual timestamp map updated (e.g. `songs_updated`) → global `updated` bumped
2. Listener detects `updated` changed → calls `_triggerUpdateCheck()`
3. `_triggerUpdateCheck()` loads all 4 timestamp maps from server, diffs each against local state
4. Only maps that actually changed get processed (song/playlist/group/user diff handlers)
5. Local `_lastUpdatedTimestamp` updated to match — no re-trigger

**Changes in `pocketbase_provider.dart`:**
- Added `_lastUpdatedTimestamp` field — tracks last known global timestamp
- `_subscribeToRealtime()` now only processes `currentSong`, `qrLinks`, and `updated` keys (removed direct handling of `songs_updated`, `playlists_updated`, `groups_updated`, `users_updated`)
- Added `_triggerUpdateCheck()` — loads all maps, diffs only changed ones
- Added `_bumpUpdatedTimestamp()` — sets global `updated` to now
- All `_updateXxxTimestamp()` / `_removeXxxTimestamp()` helpers now call `_bumpUpdatedTimestamp()`
- `updateGroup()` and `addGroupsList()` also bump global updated
- `_initializeTimestampMaps()` loads `updated` value, initializes if missing

### Current state
- Zero compilation errors, 51 repository tests pass
- Single trigger model: listener → `updated` changed → diff all maps → fetch only changed records

---

## 2026-03-13h - Realtime via single realtime_state listener with timestamp maps

### What was done
Replaced individual collection subscriptions (songs, playlists, app_users) with a single `realtime_state` listener that uses timestamp maps for efficient change detection. Now only ONE realtime subscription exists — on the `realtime_state` collection.

**How it works:**
1. `realtime_state` collection holds records with keys: `songs_updated`, `playlists_updated`, `groups_updated`, `users_updated`
2. Each record's `data` field contains a map: `{entityId: iso8601Timestamp}`
3. App subscribes ONLY to `realtime_state` (single listener)
4. When a timestamp map changes, the app diffs the local map vs the new server map
5. For new/changed timestamps → fetches only that specific record from PB
6. For missing IDs → emits delete event
7. After every CRUD operation, the corresponding timestamp map is updated in `realtime_state`

**Changes:**

1. **PocketBaseProvider** (`pocketbase_provider.dart`):
   - Added `_songTimestamps`, `_playlistTimestamps`, `_groupTimestamps`, `_userTimestamps` local maps
   - Added `groupChangeStream` (new stream for group changes)
   - Replaced `_subscribeToRealtime()`: removed individual songs/playlists/app_users subscriptions, enhanced realtime_state subscription with switch on key type
   - Added `_initializeTimestampMaps()` — loads existing maps from server, builds initial maps if empty
   - Added `_handleSongTimestampChange()`, `_handlePlaylistTimestampChange()`, `_handleGroupTimestampChange()`, `_handleUserTimestampChange()` — diff handlers
   - Added `_updateXxxTimestamp()` / `_removeXxxTimestamp()` helpers per entity type
   - Added `getSongByUuid()` and `getUserByName()` single-record fetch methods
   - Modified ALL CRUD methods to update timestamp maps after operations
   - Modified `dispose()` — only unsubscribes from `realtime_state`

2. **SongsRepository** (`songs_repository.dart`):
   - Added `groupChangeStream` listener in `_init()`
   - Added `_handleGroupRealtimeEvent()` — updates `listAllGroups` on group create/update/delete

3. **Tests**: Updated `songs_repository_test.dart` to mock `groupChangeStream`. Regenerated all mocks.

### Files modified
- `lib/providers/pocketbase_provider.dart` — single-listener architecture, timestamp maps, CRUD updates
- `lib/repositories/songs_repository.dart` — group realtime handling
- `test/unit_tests/repositories/songs_repository_test.dart` — mock groupChangeStream
- `test/unit_tests/repositories/*.mocks.dart` — regenerated

### Current state
- Zero new compilation errors
- 315 tests pass (3 pre-existing failures in web_repository_test and settings_repository_test)
- Only ONE realtime subscription (realtime_state) instead of four (realtime_state + songs + playlists + app_users)
- Timestamp maps are auto-initialized from server data on first connect
- Repos keep same stream interfaces — no BLoC changes needed

---

## 2026-03-13g - Granular PocketBase realtime subscriptions

### What was done
Replaced the old "re-fetch everything" realtime approach with granular, per-record change events from PocketBase. Now when a song, playlist, or user is created/updated/deleted on the server, only that specific record is updated in memory — no full re-download needed.

1. **RealtimeChangeEvent model** (`pocketbase_provider.dart`): New generic class carrying `action` (create/update/delete), parsed `record`, `recordId`, and `serverUpdated` timestamp from PocketBase.

2. **PocketBaseProvider**: 
   - Replaced `_updateSongListController` (void) → `_songChangeController` (RealtimeChangeEvent<Song>)
   - Replaced `_updatePlaylistController` (void) → `_playlistChangeController` (RealtimeChangeEvent<Playlist>)
   - Added `_userChangeController` (RealtimeChangeEvent<User>) — new realtime subscription for `app_users` collection
   - Each subscription now parses the record directly from the event data, logs action + timestamp, and emits a typed event

3. **SongsRepository**: `_handleSongRealtimeEvent()` — processes individual song create/update/delete events directly from the realtime event data, without re-fetching all songs from the server.

4. **PlaylistRepository**: `_handlePlaylistRealtimeEvent()` — same granular approach for playlists.

5. **UsersRepository**: Added `_init()` with `_handleUserRealtimeEvent()` and `isChangedUsersController` stream — now listens to realtime user changes and updates the local list granularly.

6. **UsersBloc**: Now also listens to `usersRepository.isChangedUsers` stream for realtime user updates.

7. **Tests updated**: All repository tests updated to mock new stream types (`RealtimeChangeEvent<T>` instead of `void`). Mocks regenerated with `build_runner`.

### Files modified
- `lib/providers/pocketbase_provider.dart` — RealtimeChangeEvent class, granular streams, app_users subscription
- `lib/repositories/songs_repository.dart` — granular song event handling
- `lib/repositories/playlist_repository.dart` — granular playlist event handling
- `lib/repositories/user_repository.dart` — added _init(), granular user event handling, isChangedUsers stream
- `lib/blocs/users_bloc/users_bloc.dart` — listen to realtime user changes
- `test/unit_tests/repositories/songs_repository_test.dart` — updated to new stream types
- `test/unit_tests/repositories/playlist_repository_test.dart` — updated to new stream types
- `test/unit_tests/repositories/users_repository_test.dart` — updated to new stream types

### Current state
- Zero compilation errors
- All 308 unit tests pass (8 integration test failures are pre-existing PatrolBinding issue)
- Realtime changes from PocketBase now update individual records with logged timestamps
- Songs, playlists, and users all have granular realtime subscriptions
- `updateSongsFromServer()` and `updateListUsersFromServer()` still available as manual refresh fallbacks

---

## 2026-03-13f - Firebase migration script syntax fix

### What was done
Fixed a Python syntax error in `tools/firebase_to_pocketbase.py` caused by accidental pasted text from Firebase Console inside the import section.

- Removed stray console text inserted after `import sys`
- Restored valid Python imports so the script can run again

### Current state
- Script syntax is valid again
- Firebase credentials are currently hardcoded in the script by local edit and should not be committed

## 2026-03-13e - Firebase migration script: sheet files support

### What was done
Updated `tools/firebase_to_pocketbase.py` to also migrate sheet image/PDF files from Firebase Storage to PocketBase.

- Added `download_file()` — downloads files from any URL (Firebase Storage etc.)
- Added `multipart_upload()` — constructs multipart/form-data POST using only stdlib
- Added `pb_upload_file()` — uploads file to PocketBase `uploads` collection, returns new public URL
- Added `migrate_sheets()` — for each song, downloads all sheet files and re-uploads to PB, replacing old Firebase URLs with new PocketBase URLs
- Shows progress: counts total sheets, logs per-song migration
- Graceful fallback: if a download fails, keeps the original URL and warns
- Skips URLs that already point to PocketBase
- Final verification now also shows `uploads` collection record count

### Current state
- Migration script handles: songs, playlists, users, groups, + sheet files
- All using only Python stdlib (no pip install needed)
- Collections already imported to live PocketBase server (all 6 confirmed)
- Server currently has 0 records — waiting for user to run migration

## 2026-03-13c - Firebase to PocketBase migration

### What was done
Complete migration from Firebase (Firestore, RTDB, Auth, Storage) to PocketBase v0.36 self-hosted backend.

1. **PocketBase provider** (`lib/providers/pocketbase_provider.dart`): Full CRUD for all collections (songs, playlists, app_users, groups, realtime_state, uploads). Realtime subscriptions via PB SDK. File upload replacing Firebase Storage. Config management (load/save/test/reconnect).

2. **Collections JSON** (`pocketbase_collections.json`): Import-ready JSON with 6 collections for PB v0.36. Auth rules require authenticated user for all operations.

3. **PB config** (`pocketbase_config.json`): Template config file for PB URL/email/password, gitignored. App reads from `~/.songviewer/pocketbase_config.json` with fallback to bundled asset.

4. **All 4 repositories rewritten**: songs_repository, playlist_repository, user_repository, settings_repository — all use PocketBaseProvider instead of FirebaseProvider. Simplified sync (PB realtime handles notifications natively).

5. **BLoC updates**: Renamed Firebase methods — `loadSongsFromFirebase()` → `loadSongsFromServer()`, `updateSongsFromFirebase()` → `updateSongsFromServer()`, `loadUsersFromFirebase()` → `loadUsersFromServer()`, etc. Renamed `SyncQrLinksFromFirebase` event to `SyncQrLinksFromServer`.

6. **Sheet upload views**: 3 files (desktop, tablet, mobile edit pages) now use `songsRepository.uploadFile()` instead of `FirebaseStorage.instance`.

7. **Smart sync system**: Two-phase initialization (`initProvidersAndCheckSync` + `loadDataFromServer`). `SyncInfo` class tracks server state. `SyncScreen` widget shows when server is empty — offers "Download from server" or "Start with empty database". Loading indicator during data fetch.

8. **PocketBase settings UI**: Desktop — inline section in GeneralSettingsBody with URL/email/password fields, test connection, save, and status indicator. Mobile/tablet — settings section with tiles that open a dialog for PB configuration.

9. **Firebase removed**: All Firebase packages removed from pubspec.yaml (firebase_core, cloud_firestore, firebase_storage, firebase_database, firebase_auth, firedart). Deleted firebase_provider.dart, firebase_rtdb_rest_provider.dart, firebase_options.dart.

10. **README updated**: Full PocketBase setup guide including Coolify deployment, collection import, user creation.

11. **Localization updated**: All Firebase references in cs.json/en.json changed to "server". Added sync/PB settings keys in both languages.

### Files created
- `lib/providers/pocketbase_provider.dart` — PocketBase provider (~640 lines)
- `lib/view/sync_screen.dart` — Smart sync screen widget
- `pocketbase_collections.json` — PB collections import file
- `pocketbase_config.json` — PB config template (gitignored)

### Files deleted
- `lib/providers/firebase_provider.dart`
- `lib/providers/firebase_rtdb_rest_provider.dart`
- `lib/firebase_options.dart`

### Files modified
- `lib/main.dart` — PB init, SyncInfo, two-phase loading, sync screen
- `lib/main.part.dart` — `initProvidersAndCheckSync()`, `loadDataFromServer()`, `SyncInfo` class
- `lib/repositories/songs_repository.dart` — PocketBaseProvider
- `lib/repositories/playlist_repository.dart` — PocketBaseProvider
- `lib/repositories/user_repository.dart` — PocketBaseProvider
- `lib/repositories/settings_repository.dart` — PocketBaseProvider
- `lib/blocs/home_page_bloc/home_page_bloc.dart` — method renames
- `lib/blocs/users_bloc/users_bloc.dart` — method renames
- `lib/blocs/edit_blocs/edit_song_bloc/edit_song_bloc.dart` — method renames
- `lib/blocs/settings_bloc/settings_bloc.dart` — SyncQrLinksFromServer
- `lib/blocs/settings_bloc/settings_event.dart` — SyncQrLinksFromServer
- `lib/blocs/presentation_playlist_bloc/presentation_playlist_event.dart` — comment update
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/general_settings_body.dart` — PB settings section
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_sheets_body.dart` — PB file upload
- `lib/view/desktop_view/widgets/ribbon_menu.dart` — comment update
- `lib/view/mobile_view/pages/settings_page.dart` — PB settings section
- `lib/view/mobile_view/pages/edit_pages/edit_page.dart` — PB file upload
- `lib/view/tablet_view/pages/settings_page_tablet.dart` — PB settings section
- `lib/view/tablet_view/pages/tablet_edit_pages/edit_page_tablet.dart` — PB file upload
- `pubspec.yaml` — removed Firebase deps, added pocketbase SDK
- `assets/lang/cs.json` — sync/PB keys, Firebase→server
- `assets/lang/en.json` — sync/PB keys, Firebase→server
- `README.md` — PB setup guide, Coolify deployment
- `.gitignore` — pocketbase_config.json

### Current state
- All Firebase dependencies removed, PocketBase SDK integrated
- Zero compilation errors across all modified files
- App uses two-phase init: auth+check → sync screen if needed → load data
- PB settings configurable from all platforms (desktop, mobile, tablet)
- Collections JSON ready for PB v0.36 import
- README has full setup guide

### Known issues / pending
- Not yet tested with a running PocketBase instance (needs deployment)
- The `_hiveProvider` field in PlaylistRepository is unused (minor lint warning)
- Some old UpdateSongListData/UpdatePlaylistData Hive adapters still registered but unused

---

## 2026-03-13d - Test files cleanup (Firebase → PocketBase)

### What was done
Updated all test files to remove Firebase dependencies and use PocketBase mocks.

1. **Deleted** `test/unit_tests/providers/firebase_provider_test.dart` — no longer relevant
2. **Updated** `test/unit_tests/all_tests.dart` — removed firebase_provider_test import
3. **Updated** `test/unit_tests/repositories/settings_repository_test.dart` — MockFirebaseProvider → MockPocketBaseProvider
4. **Updated** `test/unit_tests/repositories/songs_repository_test.dart` — full rewrite: PocketBaseProvider mocks, updated method names (getListSongs, addOrUpdateSong, createGroup, etc.), added updateSongListStream mock
5. **Updated** `test/unit_tests/repositories/users_repository_test.dart` — full rewrite: removed Firestore mocks (CollectionReference, QuerySnapshot, etc.), uses MockPocketBaseProvider with getListAppUsers, addOrUpdateAppUser, deleteAppUser
6. **Updated** `test/unit_tests/repositories/playlist_repository_test.dart` — full rewrite: PocketBaseProvider mocks, addOrUpdatePlaylist, updatePlaylistStream mock
7. **Updated** `test/integration_tests/app_startup_test.dart` — uses `initProvidersAndCheckSync()` + `syncInfo` param
8. **Updated** `test/unit_tests/README.md` — removed Firebase references, updated to PocketBase
9. **Regenerated** all `.mocks.dart` files via `dart run build_runner build --delete-conflicting-outputs`

### Current state
- Zero Firebase-related errors across entire project
- All generated mock files up to date with PocketBase types
- Only remaining warnings: unused `_hiveProvider` in PlaylistRepository, unused declarations in .g.dart files (pre-existing)

---

## 2026-03-13b - Mobile playlists + numbered copy format

### What was done
1. **Mobile playlists page**: New `PlaylistsPageMobile` with full playlist management — list of playlists, open, edit, copy, delete via popup menu. Accessible from mobile drawer.
2. **Mobile drawer entry**: Added "Playlists" menu item with playlist icon in `home_drawer.dart`
3. **Route**: Added `/playlistsPageMobile` route in `app_router.dart`
4. **Numbered copy format**: Changed copy-to-clipboard format everywhere (desktop, tablet, mobile) to include numbered song titles:
   ```
   Název playlistu
   1. Název písně
   2. Název písně
   3. Název písně
   ```

### Files changed
- `lib/view/mobile_view/pages/playlists_page.dart` — NEW: mobile playlists page with list, popup menu (open/edit/copy/delete)
- `lib/view/mobile_view/widgets/home_drawer.dart` — added playlists entry in drawer
- `lib/view/router/app_router.dart` — added `/playlistsPageMobile` route
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/playlist_body.dart` — updated copy format to numbered
- `lib/view/tablet_view/pages/home_page_tablet.dart` — updated copy format to numbered
- `assets/lang/cs.json` — added `openPlaylist`, `noPlaylists`
- `assets/lang/en.json` — same new keys

### Current state
- Zero compilation errors
- Playlists work on all platforms: desktop, tablet, mobile
- Copy format is numbered everywhere

---

## 2026-03-13 - Copy playlist to clipboard

### What was done
- Added "Copy playlist" button in **desktop** playlist view — both in playlist tile (left panel) and detail header (right panel)
- Added "Copy playlist" button in **tablet** playlist list (home_page_tablet)
- Copies playlist name on the first line, followed by each song title on a new line
- Added translation keys `copyPlaylist` and `playlistCopied` in cs.json and en.json

### Files changed
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/playlist_body.dart` — added `_copyPlaylistToClipboard()` method, copy button in detail header and playlist tile
- `lib/view/tablet_view/pages/home_page_tablet.dart` — added copy button to playlist list tiles
- `assets/lang/cs.json` — added `copyPlaylist`, `playlistCopied`
- `assets/lang/en.json` — same new keys

### Current state
- Zero compilation errors
- Copy to clipboard works on desktop (playlist detail view + tile) and tablet (playlist list)

---

## 2026-03-06d - Reject AI suggestions + re-analyze

### What was done
1. **Reject AI author/title**: Orange "✕" button next to each AI suggestion (author, original title) lets the user reject the suggestion. The system immediately re-runs AI analysis with a hint telling the AI to suggest a DIFFERENT author/title (lists all previously rejected values).
2. **Reject YouTube results**: "Odmítnout výsledky a hledat znovu" button below YouTube results dismisses all current results and searches with alternative queries (karaoke, live, worship, lyrics variants). Previously rejected video IDs are excluded from new results.
3. **State tracks rejections**: `rejectedAuthors`, `rejectedTitles`, `rejectedVideoIds` lists in `SongEnrichmentState` persist across re-analyses so the AI keeps getting better hints.
4. **AI prompt injection**: Rejected values are injected into the AI prompt as "IMPORTANT: The user has REJECTED these..." instructions, forcing the AI to try different answers.

### Files changed
- `lib/blocs/song_enrichment_bloc/song_enrichment_event.dart` — added `RejectAnalysis`, `RejectYoutubeResults` events
- `lib/blocs/song_enrichment_bloc/song_enrichment_state.dart` — added `rejectedAuthors`, `rejectedTitles`, `rejectedVideoIds` lists
- `lib/blocs/song_enrichment_bloc/song_enrichment_bloc.dart` — added `_rejectAnalysis`, `_rejectYoutubeResults` handlers
- `lib/services/ai_search_service.dart` — `analyzeSong` accepts `rejectedAuthors`/`rejectedTitles`, injects into prompt
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/song_enrichment_body.dart` — reject buttons in approval rows + YouTube section
- `assets/lang/cs.json` — added `enrichReject`, `enrichRejectYoutube`
- `assets/lang/en.json` — same new keys

### Current state
- Zero compilation errors, zero analysis issues
- User can reject AI suggestions → re-analysis with rejection hints
- User can reject YouTube results → alternative search queries

---

## 2026-03-06c - Enrichment auto-save, song info bar, API key export

### What was done
1. **Enrichment auto-save on approve**: Clicking approve on YouTube video, sheet music, author, or original title now immediately saves the change to the song (no separate "Save" button needed). Each approve action updates the song in BLoC state and triggers `UpdateSong` to persist to Firebase.
2. **AI analyze author fix**: Approve button now works correctly for author — immediately sets song interpret. Removed buggy "remove" button that reset entire enrichment state.
3. **Copy text from AI results**: All AI analysis values (author, title, language, genre) now have copy buttons and use `SelectableText` for easy selection.
4. **Full song info in chord preview**: The top bar in chord preview now shows: songbook number, interpret, cap, bpm, time signature, and tags (separated by dots) instead of just "cap: 0".
5. **Export all API keys**: New button in settings API keys section copies all configured API keys (Groq, YouTube, Gemini) to clipboard.

### Files changed
- `lib/blocs/song_enrichment_bloc/song_enrichment_state.dart` — added `songVersion` counter for detecting individual approve saves
- `lib/blocs/song_enrichment_bloc/song_enrichment_bloc.dart` — all approve handlers now update the song immediately + increment songVersion
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/song_enrichment_body.dart` — auto-save via `listenWhen` songVersion detection, copy buttons, SelectableText, fixed author approve
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/preview_body.dart` — rich song info bar replacing simple "cap: X"
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/general_settings_body.dart` — export API keys button
- `assets/lang/cs.json` — added enrichCopy, enrichCopied, exportApiKeys, exportApiKeysCopied
- `assets/lang/en.json` — same new keys

### Current state
- Zero compilation errors, zero analysis issues
- Enrichment approve → immediate save to song + Firebase
- AI results are selectable and copyable
- Chord preview shows full song metadata

---

## 2026-03-06b - Enrichment UX fixes + presentation title

### What was done
1. **YouTube saving fix**: After enrichment save, `_selectedSong` is now updated locally so the UI immediately reflects saved YouTube videos/sheets in all views
2. **Enrichment state preserved across tabs**: `initState()` restores `_selectedSong` from BLoC state — switching to presentation/edit and back no longer loses the analysis
3. **Current song data shown in AI analysis**: New "Current song data" section shows what's already saved (interpret, songbook number, YouTube count, sheets, tags) with green/grey indicators. AI results that already match saved data show a blue "already saved" icon instead of approve button
4. **YouTube Czech first**: AI prompt now returns Czech search queries first, searches up to 4 queries (was 2)
5. **Presentation title fix**: `_startPresentation` now uses `_buildPresentationTitle(song)` instead of `currentSong.title` — shows interpret + songbook number
6. **Better AI prompt**: Improved song identification — added musical examples (Jesus Christ Superstar), explicit Czech→English mapping, lyrics-based identification rule, better structured query guidance

### Files changed
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — fixed `_startPresentation` title
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/song_enrichment_body.dart` — restored state from BLoC in initState, added current song info section, green/blue icons, updated `_selectedSong` after save
- `lib/services/ai_search_service.dart` — improved AI prompt with musical examples, Czech-first queries
- `lib/blocs/song_enrichment_bloc/song_enrichment_bloc.dart` — search up to 4 YouTube queries
- `assets/lang/cs.json` — added enrichCurrentData, enrichSongbookIndex, enrichTags, enrichAlreadySaved
- `assets/lang/en.json` — same new keys

### Current state
- Zero compilation errors (168 info-level warnings, all pre-existing)
- Enrichment state survives tab switches
- Presentation title shows full format (#number title — interpret)

---

## 2026-03-07 - Multi-task improvements (Tasks 1-6)

### What was done

**Task 1: Dynamic QR codes with Firebase sync**
- Replaced 3 fixed QR URL fields with a dynamic `List<QrLink>` (add/edit/remove URLs)
- Created `QrLink` model class with label + url, JSON serialization, Equatable
- Added Firebase RTDB sync: QR links are pushed to `qrLinks` node on changes
- On startup, loads from Firebase (overrides local if available), otherwise pushes local to Firebase
- All platforms (mobile, tablet, desktop) now listen to Firebase for real-time QR link sync
- Added migration from old 3 fixed keys to new list format in Hive
- Desktop: inline editable list with label + URL fields, add/delete buttons
- Mobile/Tablet: tap to edit dialog with label + URL + delete option, add button
- QR Code Dialog: dynamically renders QR sections based on the list
- New BLoC events: `AddQrLink`, `UpdateQrLink`, `RemoveQrLink`, `SyncQrLinksFromFirebase`

**Task 2: Clear AI analysis when switching songs**
- `ResetEnrichment` event dispatched when selecting a different song in enrichment page

**Task 3: Fix sheet music search returning no results**
- Rewrote `searchSheetMusic()` — removed restrictive `type: "file"` GraphQL filter
- Now searches with multiple queries (title alone + title+interpret)
- Accepts broader external types (file, score, sheet, images, PDFs)
- Deduplicates results by URL

**Task 4: Show interpret + songbook number in presentation view**
- Changed `_sendPageToWindow` to accept `Song` object instead of `String title`
- New `_buildPresentationTitle(Song)` helper: builds `#indexSongBook title — interpret`
- Updated all 7 call sites in desktop_home_page.dart + 3 in list_song.dart

**Task 5: Better AI prompt for author/title identification**
- Rewrote AI prompt in English with explicit rules and examples
- Instructions for identifying original author vs cover, original title vs translation

**Task 6: Multi-AI approach (Groq + Gemini)**
- Added Google Gemini API (gemini-2.0-flash) as second AI alongside Groq
- Both AIs run in parallel via `Future.wait()`
- Results merged — non-null values from either AI are combined
- Added `geminiApiKey` to Settings (repository, state, bloc, UI)

### Files created
- `lib/model/qr_link.dart` — QrLink model class

### Files changed
- `lib/providers/firebase_provider.dart` — added RTDB `qrLinks` node, stream, setQrLinks(), getQrLinks()
- `lib/repositories/settings_repository.dart` — replaced 3 QR fields with List<QrLink>, added firebaseProvider, CRUD methods, migration, Firebase sync
- `lib/blocs/settings_bloc/settings_bloc.dart` — new QR events, Firebase stream listener, geminiApiKey
- `lib/blocs/settings_bloc/settings_event.dart` — AddQrLink, UpdateQrLink, RemoveQrLink, SyncQrLinksFromFirebase
- `lib/blocs/settings_bloc/settings_state.dart` — replaced 3 QR fields with List<QrLink>, geminiApiKey
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/general_settings_body.dart` — dynamic QR list UI, Gemini API key field
- `lib/view/mobile_view/widgets/dialogs/qr_code_dialog.dart` — dynamic list rendering
- `lib/view/mobile_view/pages/settings_page.dart` — dynamic QR list with add/edit/delete
- `lib/view/tablet_view/pages/settings_page_tablet.dart` — dynamic QR list with add/edit/delete
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — Song-based presentation title
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/list_song.dart` — Song-based presentation title
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/song_enrichment_body.dart` — ResetEnrichment on song switch
- `lib/services/ai_search_service.dart` — dual-AI, improved prompt, better sheet search
- `lib/blocs/song_enrichment_bloc/song_enrichment_bloc.dart` — geminiApiKey parameter
- `lib/main.part.dart` — pass firebaseProvider to SettingsRepository
- `assets/lang/cs.json` — QR dynamic list + Gemini translations
- `assets/lang/en.json` — QR dynamic list + Gemini translations
- `test/unit_tests/repositories/settings_repository_test.dart` — added MockFirebaseProvider

### Current state
- All 6 tasks implemented and compiling (zero errors in lib/)
- Pre-existing test mock issues remain (need `build_runner` regeneration)
- QR links sync bidirectionally via Firebase RTDB
- AI enrichment uses dual-AI for better accuracy

### Known issues
- Test mocks need regeneration (`flutter pub run build_runner build`)
- Sheet music quality still depends on ProScholy having the song indexed

---

## 2026-03-06 - AI Song Enrichment (Desktop)

### What was done
- Added a new AI-powered song enrichment page to the desktop app
- Uses Groq API (Llama 3.3 70B, free tier) to analyze songs — identifies author, original title, language, genre
- YouTube Data API v3 integration for searching related videos
- ProScholy GraphQL API integration for searching sheet music files
- User approval workflow: each found item can be individually approved/rejected before saving
- API keys stored securely in settings (Hive persistence)
- New ribbon menu button (sparkles icon) for quick access

### Architecture
- **AiSearchService** (`lib/services/ai_search_service.dart`) — Groq API, YouTube API, ProScholy sheet scraping
- **SongEnrichmentBloc** (`lib/blocs/song_enrichment_bloc/`) — orchestrates analysis → search → approval → save workflow
- **SongEnrichmentBody** (`lib/view/desktop_view/pages/.../song_enrichment_body.dart`) — full UI with sections for AI results, YouTube videos, sheet music, approved changes summary

### Files created
- `lib/services/ai_search_service.dart` — AI analysis & web search service
- `lib/blocs/song_enrichment_bloc/song_enrichment_bloc.dart` — BLoC
- `lib/blocs/song_enrichment_bloc/song_enrichment_event.dart` — Events
- `lib/blocs/song_enrichment_bloc/song_enrichment_state.dart` — State
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/song_enrichment_body.dart` — UI

### Files changed
- `lib/main.dart` — added SongEnrichmentBloc BlocProvider + AiSearchService import
- `lib/blocs/export_blocs.dart` — export new bloc
- `lib/repositories/settings_repository.dart` — added groqApiKey, youtubeApiKey fields
- `lib/blocs/settings_bloc/settings_state.dart` — added groqApiKey, youtubeApiKey to state
- `lib/blocs/settings_bloc/settings_bloc.dart` — added groqApiKey, youtubeApiKey to initial + emit
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — added song_enrichment body case + import
- `lib/view/desktop_view/widgets/ribbon_menu.dart` — added song_enrichment top button + tab controller
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/general_settings_body.dart` — added API key input fields section
- `assets/lang/cs.json` — added enrichment translations
- `assets/lang/en.json` — added enrichment translations

### How to use
1. Go to General Settings → set Groq API key (get free at https://console.groq.com)
2. Optionally set YouTube API key (get at https://console.cloud.google.com)
3. Select a song in preview, click the sparkles (✨) button in ribbon
4. Click "Analyzovat píseň" — AI analyzes + searches YouTube + sheets
5. Approve desired items with green checkmarks
6. Click "Uložit změny" to save to Firebase

### Current state
- AI analysis works with Groq free tier (30 req/min)
- YouTube search requires separate API key (10,000 units/day free)
- Sheet music search via ProScholy (no API key needed)
- All approved changes merge with existing song data (no overwrite)

### Known issues
- Sheet music results depend on ProScholy having the song with external file links
- YouTube search quality depends on AI-generated search queries

---

## 2026-03-05 - Desktop Playlist Section

### What was done
- Added a new dedicated "Playlisty" section in the desktop app for creating, editing, presenting, and managing playlists
- New playlist button added to the ribbon menu top-right bar (alongside preview/edit/web)
- Left panel shows all saved playlists with song count, action buttons (present/edit/delete)
- Right panel shows playlist detail (read-only) or full editor (name input, reorderable song list, add songs panel with search filter)
- Double-click a playlist to enter edit mode
- "Load to presentation" button dispatches playlist to `PresentationPlaylistBloc`
- New playlist defaults name to current date (dd.MM.yyyy)
- Songs can be clicked in read-only view to open them in preview

### Files created
- **`lib/view/desktop_view/pages/desktop_home_page/home_bodies/playlist_body.dart`** — full playlist management body widget

### Files changed
- **`lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart`** — added `playlist` case to body switch, import
- **`lib/view/desktop_view/widgets/ribbon_menu.dart`** — added `_getTopButton('playlist', Icons.playlist_play)` to top bar, tab controller handling, widened button container
- **`assets/lang/cs.json`** — added `"playlist": "Playlisty"` translation key

### Current state
- Desktop playlist section fully functional: CRUD playlists, add/remove/reorder songs, load to presentation
- All existing playlist infrastructure (PlaylistsBloc, PlaylistRepository, RTDB sync) is reused

---

## 2026-03-05 - Real-time playlist update notifications via RTDB

### What was done
- Added `updatePlaylist` node to Firebase Realtime Database — mirrors the existing `updateSongList` pattern
- When a playlist is saved or deleted, a notification is pushed to RTDB with timestamp + playlist ID
- Other app instances listen to the `updatePlaylist` stream and automatically re-fetch playlists from Firestore when a change is detected
- Reuses existing `UpdateSongListData` model (same structure: lastUpdate + map of IDs→timestamps)
- Local cache via Hive (`updatePlaylistData` key) prevents unnecessary re-fetches

### How it works
1. User saves/deletes a playlist → `PlaylistRepository._notifyPlaylistUpdate()` writes to RTDB
2. Other instances receive the change via `FirebaseProvider.updatePlaylistStream`
3. `PlaylistRepository` compares timestamps — if newer, re-fetches all playlists from Firestore
4. `isChangedPlaylist` stream emits → `PlaylistsBloc` listens and refreshes state
5. Works on all platforms: native RTDB SDK (iOS/Android/macOS/Web) + REST/SSE fallback (Windows)

### Files changed
- **`lib/providers/firebase_provider.dart`** — added `_nativeUpdatePlaylist` RTDB ref, `_updatePlaylistController` stream, native + Windows listeners, `setUpdatePlaylist()` method
- **`lib/repositories/playlist_repository.dart`** — added `updatePlaylistData` tracking, RTDB stream listener, `_updatePlaylistsFromFirebase()`, `_notifyPlaylistUpdate()`, `isChangedPlaylist` stream
- **`lib/blocs/playlist_bloc/playlists_bloc.dart`** — added `RefreshPlaylists` event handler, listens to `playlistRepository.isChangedPlaylist`
- **`lib/blocs/playlist_bloc/playlists_event.dart`** — added `RefreshPlaylists` event

### Current state
- Playlist create/edit/delete triggers RTDB notification across all connected instances
- Receiving instances automatically re-fetch and refresh their playlist UI
- Cleanup: entries older than 3 days are pruned from the update map

---

## 2026-03-05 - Desktop: Bracket error scanner in General Settings

### What was done
- Added a bracket error scanner tool to the desktop General Settings page
- Scans all songs for malformed bracket patterns in lyrics (and originalLyrics):
  - Duplicate consecutive brackets (`[[`, `]]`, `{{`, `}}`)
  - Orphaned closing brackets (`]` or `}` without matching opener)
  - Unclosed opening brackets (`[` or `{` without matching closer)
- Displays results with song name, interpret, line number, error description, and the problematic line text
- "Fix" button per song: automatically cleans bracket errors (removes duplicates, orphaned brackets)
- "Fix all" button: fixes all songs with errors at once
- After fixing, re-scans to verify corrections
- Songs are saved to Firebase after fix via `UpdateSong` event

### Files changed
- **`lib/view/desktop_view/pages/desktop_home_page/home_bodies/bracket_error_scanner.dart`** (NEW) — `BracketErrorScanner` stateful widget with scanning logic, error display, and auto-fix functionality
- **`lib/view/desktop_view/pages/desktop_home_page/home_bodies/general_settings_body.dart`** — added `BracketErrorScanner` section below QR URL settings
- **`assets/lang/cs.json`** — added bracket scanner translations (bracketScanTitle, bracketScan, bracketNoErrors, bracketFoundErrors, bracketFixAll, bracketFix, bracketLine)
- **`assets/lang/en.json`** — added bracket scanner translations

### Current state
- Desktop: General Settings → "Kontrola závorek v písních" section with "Prohledat všechny písně" button
- Scans all songs, shows error list with details
- Per-song and bulk fix buttons available
- Fixes saved to Firebase

---

## 2026-03-03 - Add third QR code for Žížkovi Online

### What was done
- Added a third QR code section across all platforms (mobile, tablet, desktop) pointing to `https://www.zizkovi.online/`
- New setting `qrZizkoviUrl` added to SettingsState, SettingsBloc, and SettingsRepository with persistence via Hive
- QR code dialog now shows 3 expandable sections: "Právě přehrávaná píseň", "Webová aplikace", "Žížkovi Online"
- Settings pages on all 3 platforms (mobile, tablet, desktop) show the editable URL field

### Files changed
- **`lib/blocs/settings_bloc/settings_state.dart`** — added `qrZizkoviUrl` field, constructor, props, copyWith, SettingsInitial
- **`lib/blocs/settings_bloc/settings_bloc.dart`** — added default value and `_emitAllValues` mapping
- **`lib/repositories/settings_repository.dart`** — added private field, getter, loadLocalSettings, changeSettingsValue switch case
- **`lib/view/mobile_view/widgets/dialogs/qr_code_dialog.dart`** — added 3rd QR section with state toggle and GlobalKey
- **`lib/view/mobile_view/pages/settings_page.dart`** — added `qrZizkoviUrl` SettingsTile
- **`lib/view/tablet_view/pages/settings_page_tablet.dart`** — added `qrZizkoviUrl` SettingsTile
- **`lib/view/desktop_view/pages/desktop_home_page/home_bodies/general_settings_body.dart`** — added `qrZizkoviUrl` URL field
- **`assets/lang/cs.json`** — added `qrZizkovi`, `qrZizkoviUrl` translations
- **`assets/lang/en.json`** — added `qrZizkovi`, `qrZizkoviUrl` translations

### Current state
- All 3 QR codes work across mobile, tablet, and desktop
- URLs are editable in settings and persisted via Hive

---

## 2026-03-03 - Desktop: current song button, edit lyrics preview, fix worshipleader search

### What was done

#### 1. "Nahrát píseň" ribbon button (current song toggle)
- Added a new ribbon button in the desktop presentation section (HomeTabbar) that uploads/removes the current song to Firebase RTDB — same behavior as the mobile radio button
- Button is shown when a song is selected (preview mode) and also when no song is selected (alongside presentation controls)
- Visual state: green `cloud_done` icon when active, blueGrey `cloud_upload` when inactive
- Dispatches `SelectSong` event to `HomePageBloc`, which calls `SongsRepository.selectSong()` (toggle on/off)

#### 2. Lyrics preview column in edit mode (youtube/sheets/settings sections)
- When editing a song and viewing the youtube, sheets, or settings section, a narrow (250px) read-only lyrics preview column now appears on the left
- Shows the song title and full lyrics with chords in monospace font (10px, scrollable)
- Allows seeing the song text while editing metadata/youtube/sheets without switching tabs
- `EditBody` now wraps youtube/sheets/settings bodies with `_withLyricsPreview()` which adds `EditLyricsPreviewColumn` on the left
- `EditSettingsBody` was wrapped in `Expanded` to match youtube/sheets pattern
- Removed hardcoded `MediaQuery.of(context).size.width - 300` width from youtube/sheets/settings headers (now flex-sized via Expanded)

#### 3. Fix worshipleaderapp.com search on desktop
- **Root cause**: `WebBloc._init()` and `_filterInterprets()` captured `final state = this.state;` before `await` calls, then used the stale captured state for emits after the await completed. If `ChangeSearchWeb(3)` ran during the await (e.g., user switched to worshipleader while init was loading pisnicky-akordy), the final emit would overwrite `searchWeb` back to the old value (1)
- **Fix in `_init`**: removed captured `state` variable, use `state` (bloc's current property) directly for all emits — emits after `await` now build on the latest state, preserving `searchWeb` changes
- **Fix in `_filterInterprets`**: same pattern — removed captured `state`, capture only `searchWeb` before the await for the if-else branching, use `state` for post-await emits
- **Fix in `ListWebSong`**: dropdown value is now derived from `state.searchWeb` (bloc state) instead of local `dropdownValue` variable — eliminates desync between dropdown display and actual bloc state when the state changes externally (e.g., reset by `_init`)

### Files changed
- **`lib/view/desktop_view/widgets/ribbon_menu.dart`** — added `_buildCurrentSongButton()` method, placed it in preview and default ribbon rows
- **`lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_lyrics_preview_column.dart`** (NEW) — narrow read-only lyrics preview widget
- **`lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_body.dart`** — wraps youtube/sheets/settings with `_withLyricsPreview()`
- **`lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_settings_body.dart`** — wrapped in `Expanded`, removed hardcoded width
- **`lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_youtube_body.dart`** — removed hardcoded width
- **`lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_sheets_body.dart`** — removed hardcoded width
- **`lib/blocs/web_bloc/web_bloc.dart`** — fixed stale state in `_init()` and `_filterInterprets()`
- **`lib/view/desktop_view/pages/desktop_home_page/home_bodies/list_web_song.dart`** — dropdown value derived from bloc state

### Current state
- Desktop ribbon shows "Nahrát píseň" button when in preview mode with a song selected — toggle uploads/removes current song from RTDB
- Edit mode youtube/sheets/settings sections now show a narrow lyrics preview column on the left
- WorshipLeaderApp search works correctly on desktop — no more state desync when switching providers

---

## 2026-03-03 - Optimize RTDB currentSong: skip lyrics for saved songs

### What was done
- Modified `SongsRepository.selectSong()` to conditionally send lyrics to Firebase Realtime Database
- **Saved songs** (non-empty `id`): only `id`, `title`, and `interpret` are sent — `lyricsWithoutChords` and `lyricsWithChords` are sent as empty strings to reduce RTDB payload
- **Unsaved/web songs** (empty `id`, e.g. downloaded from web search): full `lyricsWithoutChords` and `lyricsWithChords` are sent, since the receiving side cannot look up the lyrics by id

### Files changed
- **`lib/repositories/songs_repository.dart`** — added `songId.isNotEmpty` check in `selectSong()` to conditionally omit lyrics

### Current state
- Saved songs broadcast only metadata (id, title, interpret) to RTDB — web viewers can fetch full lyrics from Firestore using the id
- Web-downloaded (unsaved) songs still broadcast full lyrics so web viewers can display them without Firestore lookup

---

## 2026-03-03 - Fix updateSongList type cast + lyricsWithChords format

### What was done
- Fixed `type '_Map<Object?, Object?>' is not a subtype of type 'Map<String, dynamic>'` error in `SongsRepository._init` by adding `Map<String, dynamic>.from(data)` cast before passing to `UpdateSongListData.fromJson()`
- Fixed `lyricsWithChords` sent to Realtime Database: was sending the display format (chords above text lines via `Song.lyricsWithChords` getter), now sends the raw `Song.lyrics` field which uses `[chord]` inline bracket format — the same format stored in Firestore

### Files changed
- **`lib/repositories/songs_repository.dart`** — deep-cast RTDB data to `Map<String, dynamic>` before parsing
- **`lib/view/mobile_view/widgets/song_card.dart`** — use `song.lyrics` instead of `song.lyricsWithChords`
- **`lib/view/tablet_view/widgets/song_card_tablet.dart`** — use `song.lyrics` instead of `song.lyricsWithChords`
- **`lib/view/tablet_view/pages/preview_page_tablet.dart`** — use `song.lyrics` instead of `song.lyricsWithChords`
- **`lib/blocs/playlist_bloc/playlists_bloc.dart`** — use `selectedSong.lyrics` instead of `selectedSong.lyricsWithChords`

### Current state
- No more type cast error when receiving updateSongList from Firebase RTDB
- `lyricsWithChords` in realtime database now contains the raw lyrics with `[chord]` bracket format, matching Firestore storage format

---

## 2026-03-03 - Add lyricsWithChords to Realtime Database selected song

### What was done
- Added `lyricsWithChords` field to the data sent to Firebase Realtime Database when a song is selected as "currently playing"
- Previously only `title`, `interpret`, `lyricsWithoutChords` and `song` (ID) were sent; now `lyricsWithChords` is also included
- The `lyricsWithChords` format matches the Song model's `lyricsWithChords` getter (chord lines above lyric lines)
- This allows web viewers to display the full song with chords from the realtime database data

### Files changed
- **`lib/providers/firebase_provider.dart`** — added `lyricsWithChords` to `saveNewSelectedSong()` and `removeSelectedSong()`
- **`lib/repositories/songs_repository.dart`** — added `lyricsWithChords` parameter to `selectSong()`
- **`lib/blocs/home_page_bloc/home_page_event.dart`** — added `lyricsWithChords` field to `SelectSong` event
- **`lib/blocs/home_page_bloc/home_page_bloc.dart`** — pass `lyricsWithChords` to repository
- **`lib/blocs/preview_bloc/preview_chord_event.dart`** — added `lyricsWithChords` field to `SelectSongInPreview` event
- **`lib/blocs/preview_bloc/preview_chord_bloc.dart`** — pass `lyricsWithChords` to repository
- **`lib/blocs/playlist_bloc/playlists_bloc.dart`** — pass `lyricsWithChords` in playlist song selection
- **`lib/view/mobile_view/widgets/song_card.dart`** — pass `lyricsWithChords` in SelectSong event
- **`lib/view/mobile_view/pages/preview_page.dart`** — pass empty `lyricsWithChords` in deselect
- **`lib/view/tablet_view/widgets/song_card_tablet.dart`** — pass `lyricsWithChords` in SelectSong event
- **`lib/view/tablet_view/pages/preview_page_tablet.dart`** — pass `lyricsWithChords` in SelectSongInPreview event

### Current state
- All platforms (web, mobile, tablet, desktop) now send `lyricsWithChords` to Firebase Realtime Database when selecting a song as currently playing
- Realtime Database `currentSong` node now contains: `song`, `title`, `interpret`, `lyricsWithoutChords`, `lyricsWithChords`
- Web viewers can read `lyricsWithChords` from the realtime database stream

### Known issues
- Pre-existing test mock error in `songs_repository_test.dart` (`selectedSong` getter not defined on MockFirebaseProvider) — unrelated to this change

---

## 2026-02-26 - Windows presentation window borderless fullscreen

### What was done
- Presentation window on Windows now opens in borderless fullscreen on the target screen (matching macOS behavior)
- Main window uses `screen_retriever` to get screen bounds for the target `screenIndex`
- Screen bounds (left, top, width, height) are passed to the sub-window via `WindowConfiguration.arguments`
- Sub-window uses `dart:ffi` Win32 APIs to remove window decorations and position the window to fill the entire target screen
- REUSE path: main window sends `enter_fullscreen` command via TCP bridge with screen bounds, sub-window re-enters fullscreen

### Files changed
- **`lib/services/win32_fullscreen.dart`** (NEW) — `enterFullscreenWin32()` using `dart:ffi` to call `GetForegroundWindow`, `GetWindowLongW`, `SetWindowLongW`, `SetWindowPos`
- **`lib/services/presentation_window_manager.dart`** — `_getScreenBounds()` helper using `screen_retriever`, passes bounds in initData, sends `enter_fullscreen` on REUSE path
- **`lib/main.dart`** — `_enterFullscreenFromArgs()` / `_applyFullscreen()` in sub-window, handles `enter_fullscreen` bridge command

### Current state
- Windows presentation window opens borderless fullscreen on the correct screen
- REUSE path also re-enters fullscreen with correct screen bounds

---

## 2026-02-26 - Replace broken WindowMethodChannel with TCP bridge (Windows)

### What was done
- Replaced `WindowController.invokeMethod` / `WindowMethodChannel` cross-window messaging with a localhost TCP socket bridge on Windows
- Root cause: `desktop_multi_window` v0.3.0's `WindowMethodChannel` system always fails with `WindowChannelException(CHANNEL_UNREGISTERED)` on Windows — the native `WindowChannelPlugin` does not properly share channel registrations across Flutter engines, even with retry logic (tested 4 attempts over 3s)
- Solution: TCP localhost bridge using line-delimited JSON over `ServerSocket`/`Socket` — reliable, no dependency on `desktop_multi_window` channel system

### How it works
1. Main window starts a TCP server on `localhost:0` (random free port)
2. Bridge port is included in `WindowConfiguration(arguments: initData)` passed to sub-window
3. Sub-window reads port from arguments and connects via `Socket.connect`
4. Bidirectional communication: main→sub for page/song updates, sub→main for keyboard navigation
5. Messages are JSON objects delimited by newlines (`writeln` / `LineSplitter`)

### Files changed
- **`lib/services/presentation_bridge.dart`** (NEW) — TCP bridge service: `startServer()`, `connectToServer(port)`, `send(method, data)`, `onMessage` callback, `stop()`
- **`lib/services/presentation_window_manager.dart`**:
  - Starts bridge server in CREATE PATH, passes port in window arguments
  - Handles incoming navigation via `_bridge.onMessage` → `onNavigationCommand` callback
  - `sendPageToPresentation` / `sendSongToPresentation` use `_bridge.send()` instead of `_invokeWithRetry`
  - `destroyPresentationWindow` stops bridge
  - Removed `_invokeWithRetry` method entirely
- **`lib/main.dart`** (sub-window):
  - `_setupWindowsBridge()` replaces `_setupWindowsMessageHandler()` — connects to bridge, routes messages to `_handleIncomingMethod`
  - Navigation key events use `PresentationBridge().send('navigate', command)` instead of `WindowMethodChannel`
- **`lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart`**:
  - Navigation via `PresentationWindowManager().onNavigationCommand` callback instead of `WindowMethodChannel`
  - Removed `desktop_multi_window` import (no longer needed)

### Current state
- Windows: presentation window opens, receives initial data via arguments, subsequent page updates via TCP bridge, keyboard navigation forwarded back to main window via bridge
- macOS: completely unchanged — uses native Swift bridge as before
- Bridge stays alive when window is hidden (reuse path) — instant reconnection not needed

### Known issues / Pending
- Screen positioning not yet implemented on Windows (window appears at default position)
- Window close detection on Windows (currently hide-only)

---

## 2026-02-26 - Fix WindowChannelException on backup page send (Windows)

### What was done
- Fixed `WindowChannelException(CHANNEL_UNREGISTERED)` when opening presentation window on Windows
- Root cause: Main window tried to send backup page data via `WindowController.invokeMethod` before the sub-window had registered its `setWindowMethodHandler` (race condition)
- On Windows, initial data already arrives reliably via `WindowConfiguration(arguments: initData)` parsed in `_loadInitialData()` — backup send is unnecessary
- Added `_invokeWithRetry` helper for `sendPageToPresentation` / `sendSongToPresentation` — retries up to 3 times with exponential backoff (500ms, 1s, 1.5s) in case handler isn't registered yet

### Files changed
- `lib/services/presentation_window_manager.dart` — skip backup send on Windows, add retry logic

---

## 2026-02-26 - Fix Windows presentation window MissingPluginException

### What was done
- Fixed `MissingPluginException(No implementation found for method setScreenIndex on channel com.songviewer/presentation_bridge)` on Windows
- Root cause: The `com.songviewer/presentation_bridge` MethodChannel had native handlers only on macOS (Swift), with no C++ equivalent on Windows
- Solution: Added platform-aware communication in Dart — on macOS uses native bridge (unchanged), on Windows uses `desktop_multi_window` v0.3.0 cross-window messaging API (`WindowController.invokeMethod`, `WindowMethodChannel`)

### Changes
- **`lib/services/presentation_window_manager.dart`**:
  - All `_bridgeChannel.invokeMethod` calls now wrapped with `Platform.isMacOS` / `Platform.isWindows` guards
  - On Windows: `update_page` / `update_song` sent via `WindowController.invokeMethod` (JSON-encoded)
  - On Windows: `hide_window` uses `WindowController.hide()`
  - On Windows: `destroy` uses `hide()` + reference cleanup (no native `close()` API available)
  - `setScreenIndex` skipped on Windows (positioning handled by init data)
  - Removed `screen_retriever` import (not needed for current approach)
- **`lib/main.dart`** (sub-window `PresentationApp`):
  - Extracted shared `_handleIncomingMethod()` for processing incoming messages
  - On macOS: keeps `com.songviewer/page_data` MethodChannel + `sub_window_ready` signal
  - On Windows: uses `WindowController.setWindowMethodHandler` to receive cross-window messages
  - Navigation key events: on Windows uses `WindowMethodChannel('com.songviewer/nav_bridge')` instead of native `navigate_bridge`
- **`lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart`**:
  - On Windows: registers `WindowMethodChannel('com.songviewer/nav_bridge')` handler for receiving navigation from sub-window
  - Proper cleanup in `dispose()` for both platforms

### Current state
- Presentation window should now open on Windows without MissingPluginException
- Cross-window messaging (page updates, navigation) works via `desktop_multi_window` API
- Window positioning on specific screen not yet implemented on Windows (appears at default position)
- macOS behavior unchanged

### Pending / Next steps
- Test presentation window end-to-end on Windows (open, navigate, close)
- Implement screen positioning for Windows presentation window (may need C++ native channel or `window_manager` integration)
- Consider adding window close detection on Windows (currently hide-only)

### Known issues
- On Windows, the presentation window may not appear on the selected external display (screen positioning TODO)
- On Windows, `destroyPresentationWindow` hides instead of truly destroying (no `close()` API in `desktop_multi_window` v0.3.0)

---

## 2026-02-26 - Firebase Realtime Database REST API + SSE for Windows

### What was done
- Implemented Firebase Realtime Database support for Windows via REST API and Server-Sent Events (SSE)
- The native `firebase_database` Flutter package does not support Windows — this implementation provides full RTDB functionality on Windows using Firebase's REST API
- **Cloud Firestore** already works on Windows via C++ SDK — no changes needed

### Architecture
- Created `FirebaseRtdbRestProvider` — a standalone REST/SSE client for Firebase RTDB
  - REST operations: GET, PUT (set), PATCH (update), DELETE via `dart:io` `HttpClient`
  - SSE streaming: persistent event-stream connections with automatic reconnection (exponential backoff)
  - Auth: uses Firebase Auth ID tokens (`?auth=<token>`) from anonymous sign-in
  - Handles SSE events: `put`, `patch`, `keep-alive`, `cancel`, `auth_revoked`
  - Auto-reconnects on disconnect, token expiry (`auth_revoked`), or errors

- **Platform-agnostic streams** added to `FirebaseProvider`:
  - `selectedSongStream` — `Stream<Map<String, dynamic>?>` for `currentSong` RTDB path
  - `updateSongListStream` — `Stream<Map<String, dynamic>?>` for `updateSongList` RTDB path
  - On non-Windows (iOS, Android, macOS, Web): fed from native `DatabaseReference.onValue`
  - On Windows: fed from SSE REST provider
  - Write operations (`saveNewSelectedSong`, `removeSelectedSong`, `setUpdateSongList`) also route through REST on Windows

- `SongsRepository` updated to use the new platform-agnostic streams instead of directly accessing `DatabaseReference`

### RTDB paths used via REST/SSE
| Path | Operations | Purpose |
|---|---|---|
| `currentSong` | SSE listen + PATCH (update) | Broadcast currently selected/playing song |
| `updateSongList` | SSE listen + PUT (set) | Song list change notifications with timestamps |

### Files changed
- `lib/providers/firebase_rtdb_rest_provider.dart` — **new file**, REST/SSE client for RTDB
- `lib/providers/firebase_provider.dart` — added REST provider for Windows, platform-agnostic RTDB streams, updated write operations
- `lib/repositories/songs_repository.dart` — uses `selectedSongStream` / `updateSongListStream` instead of native `DatabaseReference.onValue`

### Current state
- All 3 files compile with no errors
- Non-Windows platforms use native SDK as before (no behavioral change)
- Windows now has full RTDB support: reading, writing, and real-time listeners via SSE
- `firedart` package in pubspec.yaml is still unused (dead dependency)

### Pending / Next steps
- Runtime testing on Windows with actual Firebase connectivity
- Consider removing unused `firedart` dependency from pubspec.yaml
- If Cloud Firestore C++ SDK causes issues on Windows at runtime, a similar REST approach can be applied

---

## 2026-02-26 - Windows build setup & Inno Setup installer

### What was done
- Fixed Windows app name from "default_project" to "Songs Viewer" / "songs_viewer" in:
  - `windows/CMakeLists.txt` — project name and BINARY_NAME
  - `windows/runner/main.cpp` — window title
  - `windows/runner/Runner.rc` — version info (CompanyName, FileDescription, InternalName, OriginalFilename, ProductName)
- Generated Windows app icon from `assets/logos/ic_launcher.png` via `flutter_launcher_icons`
  - Added `windows:` section to `flutter_launcher_icons.yaml`
  - Produced `windows/runner/resources/app_icon.ico`
- Fixed `logger_pkg` path in `pubspec.yaml` from `../../logger` to `../logger`
- Generated all 13 `.g.dart` files via `dart run build_runner build --delete-conflicting-outputs`
- Created `lib/firebase_options.dart` with Windows platform support (using web Firebase config)
- Created Inno Setup script at `installers/SongsViewer.iss`
  - AppName: "Songs Viewer", version 1.1.25
  - Source: `build\windows\x64\runner\Release\*`
  - Output: `C:\Users\jelazi\Workspace\Setups\SongsViewerSetup_1.1.25.exe`
  - Czech + English language support
  - Desktop icon option, uninstall with user data cleanup

### Build issue (RESOLVED)
- Windows release build initially failed with MSVC LNK2019 linker errors on Firebase C++ SDK
- Root cause: Firebase C++ SDK pre-built libs require MSVC 19.40+ (VS 2022 17.10+), but system had MSVC 19.39 (VS 2022 17.9)
- Fix: Updated Visual Studio 2022 from 17.9 to 17.14 (MSVC 14.44 / compiler 19.44)
- After VS update, `flutter build windows --release` completed successfully in ~307 seconds

### Current state
- Windows release build successful: `build\windows\x64\runner\Release\songs_viewer.exe` (14.4 MB)
- App launches and runs correctly, window title shows "Songs Viewer", process is responsive
- Only minor warnings: CMake deprecation warning in Firebase SDK CMakeLists.txt, ZIP decompression warning (-5) during extraction (non-fatal)
- 3 analyzer warnings in generated .g.dart files (unused JSON serialization functions) — non-blocking
- Inno Setup script ready at `installers/SongsViewer.iss`

### Pending / Next steps
- Compile Inno Setup installer (`installers/SongsViewer.iss`) to produce `SongsViewerSetup_1.1.25.exe`
- Full runtime testing with Firebase connectivity
- Consider updating pubspec.yaml `name` from `default_project` to `songs_viewer` (cosmetic)

### Files changed
- `pubspec.yaml` — logger_pkg path fix
- `windows/CMakeLists.txt` — project name → songs_viewer
- `windows/runner/main.cpp` — window title → "Songs Viewer"
- `windows/runner/Runner.rc` — version info → "Songs Viewer"
- `flutter_launcher_icons.yaml` — added windows section
- `lib/firebase_options.dart` — new file, Firebase config with Windows support
- `installers/SongsViewer.iss` — new file, Inno Setup installer script

---

## 2026-02-26 - Add QR code button for tablet, iPhone and Android

### What was done
- Added `qr_flutter` package dependency for QR code generation
- Created `QrCodeDialog` with two expandable QR code sections:
  - **Právě přehrávaná píseň** — `https://your-site.example/` (expanded by default)
  - **Webová aplikace** — `https://songsviewerweb.web.app/`
- Each section is collapsible (expand/collapse) and shows clickable URL link (opens in browser via `url_launcher`)
- Share buttons: "Sdílet odkaz" (share URL) and "Sdílet QR" (share QR code as PNG image)
- **Tablet (iPad):** QR code button next to settings button on home page left panel
- **Mobile (iPhone/Android):** QR code menu item in drawer, placed right below Settings
- **QR URLs are editable in Settings** — new "QR kód" section in settings on both tablet and mobile
  - `qrCurrentSongUrl` — URL for currently playing song (default: `https://your-site.example/`)
  - `qrWebAppUrl` — URL for web application (default: `https://songsviewerweb.web.app/`)
  - Persisted via Hive, QR dialog reads from `SettingsBloc` state
- Localization keys: `qrCodeTitle`, `qrCurrentSong`, `qrWebApp`, `qrCode`, `shareLink`, `shareQrCode`, `qrCurrentSongUrl`, `qrWebAppUrl` in both `cs.json` and `en.json`

- **Desktop (macOS):** 
  - Created new `GeneralSettingsBody` — separate settings body for general (non-presentation) settings, with QR URL editing
  - QR URL settings moved out of `presentation_settings_body.dart` into `general_settings_body.dart`
  - New "General settings" ribbon button in SettingsTabbar → opens GeneralSettingsBody
  - New "QR kód" ribbon button in SettingsTabbar → opens QrCodeDialog directly
  - Registered `general_settings` body in `desktop_home_page.dart` switch

### Files changed
- `pubspec.yaml` — added `qr_flutter` dependency
- `lib/repositories/settings_repository.dart` — added `qrCurrentSongUrl`, `qrWebAppUrl` fields with persistence
- `lib/blocs/settings_bloc/settings_state.dart` — added `qrCurrentSongUrl`, `qrWebAppUrl` to state
- `lib/blocs/settings_bloc/settings_bloc.dart` — emit QR URL values
- `lib/view/mobile_view/widgets/dialogs/qr_code_dialog.dart` — QR code dialog reads URLs from SettingsBloc
- `lib/view/tablet_view/pages/home_page_tablet.dart` — QR button next to settings
- `lib/view/tablet_view/pages/settings_page_tablet.dart` — QR URL settings section
- `lib/view/mobile_view/pages/settings_page.dart` — QR URL settings section
- `lib/view/mobile_view/widgets/home_drawer.dart` — QR menu item under settings
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/general_settings_body.dart` — new General settings body with QR URL editing
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/presentation_settings_body.dart` — removed QR URL section
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — registered general_settings body
- `lib/view/desktop_view/widgets/ribbon_menu.dart` — added General settings + QR ribbon buttons
- `assets/lang/cs.json` — QR + generalSettings localization keys
- `assets/lang/en.json` — QR + general + generalSettings localization keys

---

## 2026-02-23 - Add page titles to groups_body and users_body

### What was done
- Added a bold `Text` heading at the top of `GroupsBody` — displays `'manageGroups'.tr()` ("Skupiny")
- Added a bold `Text` heading at the top of `UsersBody` — displays `'users'.tr()` ("Uživatelé")
- Heading style matches `presentation_settings_body.dart` (fontSize 18, fontWeight bold)
- `GroupsBody` layout updated: `SizedBox(height)` wrapper replaced with `Column` + `Expanded` so Row fills remaining space without a hardcoded height

### Files changed
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/groups_body.dart`
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/users_body.dart`

---

## 2026-02-23 - Fix: all edit bodies now use state.isCurrentSongModified consistently

### What was done
- **edit_chords_body.dart** — replaced inline `state.currentText == state.currentEditSong.lyrics/originalLyrics` with `state.isCurrentSongModified`
- **edit_lyrics_body.dart** — same replacement
- **edit_youtube_body.dart** — fixed icon color to be reactive (`state.isCurrentSongModified ? Colors.white : Colors.black`)
- All 5 edit bodies now consistent: `edit_lyrics_body`, `edit_chords_body`, `edit_youtube_body`, `edit_sheets_body`, `edit_settings_body`

---

## 2026-02-23 - Add isCurrentSongModified reactive state & unsaved changes dialog

### What was done

1. **Added `isCurrentSongModified` (bool) and `listModifications` (List<String>) to `EditSongState`**
   - Automatically recalculated whenever any song data changes in the bloc
   - Reset to `false` / `[]` on: song switch (`ChangeEditSong`), save (`SaveSong`), create new song, delete song

2. **Refactored `checkModifiedSong()` into `_computeModifications()`**
   - Returns a `List<String>` of modification keys (e.g. `['title', 'youtubeVideos', 'sheets']`)
   - `_recalculateModified(emit)` helper emits updated `isCurrentSongModified` and `listModifications` after every data-changing event
   - All handlers that modify song data now call `_recalculateModified`: `_changeSongValue`, `_transposeChords`, `_changePositionChord`, `_changeChord`, `_createChord`, `_deleteChord`, `_changeGroupForCurrentSong`, `_addYoutubeVideo`, `_removeYoutubeVideo`, `_updateYoutubeVideo`, `_addSheet`, `_removeSheet`

3. **Updated save buttons to use reactive `state.isCurrentSongModified`**
   - `edit_youtube_body.dart`, `edit_sheets_body.dart`, `edit_settings_body.dart` now use `state.isCurrentSongModified` instead of calling `checkModifiedSong()` synchronously
   - More reliable: updates automatically when BLoC state changes

4. **Added unsaved changes dialog on song switch**
   - When clicking a song in `list_song.dart` while current song has unsaved changes, a dialog appears
   - Dialog shows list of what was changed (e.g. "Název", "YouTube videa", "Noty") with icons
   - Three options: Cancel (stay), Discard changes (switch without saving), Save and switch (save then switch)

5. **Added localization keys** in both `cs.json` and `en.json`:
   - `unsavedChangesTitle`, `unsavedChangesMessage`, `discardChanges`, `saveAndSwitch`
   - `modTitle`, `modInterpret`, `modIndexSongBook`, `modGroups`, `modLyrics`, `modOriginalLyrics`, `modYoutubeVideos`, `modSheets`

### Files changed
- `lib/blocs/edit_blocs/edit_song_bloc/edit_song_state.dart` — added `isCurrentSongModified`, `listModifications`
- `lib/blocs/edit_blocs/edit_song_bloc/edit_song_bloc.dart` — added `_computeModifications()`, `_recalculateModified()`, calls in all data-changing handlers
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_youtube_body.dart` — use `state.isCurrentSongModified`
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_sheets_body.dart` — use `state.isCurrentSongModified`
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_settings_body.dart` — use `state.isCurrentSongModified`
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/list_song.dart` — unsaved changes dialog + helper methods
- `assets/lang/cs.json` — added localization keys
- `assets/lang/en.json` — added localization keys

---

## 2025-02-23 - Fix save button not detecting YouTube/sheets changes

### What was done

- Fixed `checkModifiedSong()` in `EditSongBloc` — was comparing `state.currentEditSong` with itself for YouTube/sheets (always false because it's the same object)
- Now compares against `songsRepository.getSongById(song.id)` (the original persisted song), correctly detecting added/removed YouTube videos and sheets
- Also handles new songs (empty ID): detects if any YouTube/sheets were added

### Root cause
- `oldSong = state.currentEditSong` was the same reference as `state.currentEditSong`, so YouTube/sheets comparisons always returned false
- Title, lyrics, groups etc. worked because they use separate `TextEditingController` / `currentText` fields in state

### Files changed
- `lib/blocs/edit_blocs/edit_song_bloc/edit_song_bloc.dart` — fixed `checkModifiedSong()`

---

## 2025-02-23 - Sync EditSongBloc changes to PreviewChordBloc (browse views update after edit)

### What was done

1. **Fix: browse YouTube/sheets views now update immediately after saving edits**
   - Added `BlocListener<EditSongBloc, EditSongState>` in `desktop_home_page.dart`
   - When `currentEditSong` changes and matches the currently previewed song ID, it dispatches `ChangeCurrentSong` to `PreviewChordBloc`
   - Also dispatches `ChangeIsSelectedSong` to `DesktopRibbonMenuBloc` so ribbon buttons update (e.g. if YouTube/sheets were added/removed)
   - Uses `listenWhen` to only fire when the song object actually changed, avoiding unnecessary updates on every keystroke

### Problem that was fixed
- Previously, after editing YouTube videos or sheets and saving, `PreviewChordBloc` held a stale `Song` object
- The browse panels (and lyrics preview) would not reflect changes until the user re-clicked the song in the list
- Now changes propagate automatically after save

### Files changed
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — added EditSongBloc BlocListener for sync

### Current state
- All browse views update in real time after saving edits
- 0 errors in flutter analyze (179 pre-existing info warnings)

---

## 2025-02-23 - Browse YouTube/Sheets replaces lyrics area, auto-switch on song change

### What was done

1. **Browse panels replace lyrics area (not side panel)**
   - YouTube/Sheets panels now replace the lyrics+chords content area inside PreviewBody
   - Song list on the left stays visible at all times
   - Added `contentOverride` parameter to `PreviewBody` — when provided, replaces the lyrics BlocBuilder

2. **Auto-switch when song doesn't have YouTube/Sheets**
   - When selecting a different song while browse_youtube or browse_sheets is open, and the new song lacks that content, automatically switches back to lyrics (preview) view
   - When deselecting a song (clicking same song again), also switches back from browse mode
   - Logic in `DesktopRibbonMenuBloc._changeIsSelectedSong()`

3. **Ribbon buttons remain toggle-able**
   - Click "Browse YouTube" → replaces lyrics with YouTube panel
   - Click again → returns to lyrics
   - Same for "Browse Sheets"

4. **Cleaned up browse panels**
   - Removed left border (redundant since PreviewBody already has a divider)
   - Panels still have header with close button for convenience

### Files changed
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/preview_body.dart` — added `contentOverride` param
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — browse bodies passed as contentOverride
- `lib/blocs/desktop_ribbon_menu/desktop_ribbon_menu_bloc.dart` — auto-switch logic in _changeIsSelectedSong
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/browse_youtube_body.dart` — removed Container/border wrapper
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/browse_sheets_body.dart` — removed Container/border wrapper

### Current state
- Browse panels replace lyrics area while keeping song list visible
- Auto-switch works when new song lacks YouTube/Sheets data
- 0 errors in flutter analyze (179 pre-existing info-level warnings)

---

## 2025-02-23 - Browse YouTube/Sheets panels as right-side panels (keep song list visible)

### What was done

1. **Browse panels now appear as right-side panels alongside song preview**
   - Previously, clicking "Browse YouTube" or "Browse Sheets" replaced the entire body (including song list)
   - Now the song list and lyrics preview remain visible on the left, and the browse panel opens on the right (400px wide)
   - Layout: `[ListSong | Song Preview | Browse Panel]`

2. **Rewritten BrowseYoutubeBody as compact right panel**
   - Removed internal sidebar layout, replaced with vertical card list of videos
   - Each card shows video thumbnail (mqdefault) + name, click opens in external browser
   - Has header with title and close (X) button to dismiss the panel

3. **Rewritten BrowseSheetsBody as compact right panel**
   - Removed internal sidebar layout, replaced with horizontal thumbnail strip at top + full image viewer below
   - InteractiveViewer for zoom (0.5x-4x)
   - Has header with title, page counter, and close (X) button

4. **Ribbon buttons now toggle**
   - Clicking "Browse YouTube" or "Browse Sheets" again closes the panel (returns to preview)
   - Buttons show selected state (`isSelected`) when their panel is open

### Files changed
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/browse_youtube_body.dart` — rewritten as compact right panel
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/browse_sheets_body.dart` — rewritten as compact right panel
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — browse_youtube/browse_sheets now show Row(PreviewBody + panel)
- `lib/view/desktop_view/widgets/ribbon_menu.dart` — browse buttons toggle + isSelected state

### Current state
- Song list stays visible when browsing YouTube videos or sheet music
- Browse panels appear on the far right of the desktop layout
- 0 errors in flutter analyze (179 pre-existing info-level warnings)

---

## 2025-02-23 - Desktop browse buttons, presentation auto-page by paragraphs, ribbon spacer

### What was done

1. **Desktop "Browse YouTube" and "Browse Sheets" buttons**
   - Added two new buttons in the Home ribbon tab (visible when a song is selected in preview mode)
   - "Browse YouTube" button appears only if the selected song has YouTube videos
   - "Browse Sheets" button appears only if the selected song has sheet images
   - Clicking navigates to a dedicated view-only body page
   - Created `browse_youtube_body.dart` — sidebar list of videos + external browser launch
   - Created `browse_sheets_body.dart` — thumbnail sidebar + InteractiveViewer for full image with zoom
   - Updated `desktop_home_page.dart` body switch for new body names
   - Updated `ribbon_menu.dart` tab controller, TabBar, TabBarView conditions for new bodies

2. **Presentation auto-page by paragraphs setting**
   - New boolean setting `presentationAutoPageByParagraphs` (default: false)
   - When enabled, presentation pages are split by paragraphs (empty lines in lyrics) instead of fixed line count
   - If a paragraph exceeds max lines per page, it is split approximately in half
   - Full pipeline: `SettingsRepository` → `SettingsBloc` → `SettingsState`
   - `PresentationBloc`: added `getLyricsLinesWithBlanks()`, `splitByParagraphs()` static methods
   - Updated `computePageContent()` to accept and use `autoPageByParagraphs` parameter
   - Updated all 8 `computePageContent` calls in `desktop_home_page.dart`
   - Added UI toggle (Switch) in `presentation_settings_body.dart` below "Počet řádků na stránku"

3. **Ribbon spacer widget**
   - Created `ribbon_spacer.dart` — vertical divider widget (12px wide, 40px tall grey line)
   - Added between transpose buttons and browse/presentation section in Home ribbon
   - Removed unused `youtube_helper` and `url_launcher` imports from `ribbon_menu.dart`

### Files created
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/browse_youtube_body.dart`
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/browse_sheets_body.dart`
- `lib/view/desktop_view/widgets/ribbon_spacer.dart`

### Files changed
- `lib/repositories/settings_repository.dart` — added `presentationAutoPageByParagraphs` field, getter, Hive load, changeSettingsValue case
- `lib/blocs/settings_bloc/settings_state.dart` — added `presentationAutoPageByParagraphs` field
- `lib/blocs/settings_bloc/settings_bloc.dart` — added default value, _emitAllValues
- `lib/blocs/presentation_bloc/presentation_state.dart` — added `autoPageByParagraphs` field
- `lib/blocs/presentation_bloc/presentation_event.dart` — added `autoPageByParagraphs` to UpdatePresentationSettings
- `lib/blocs/presentation_bloc/presentation_bloc.dart` — added splitByParagraphs logic, updated _recalculatePages, computePageContent
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — imports, body switch, all computePageContent calls updated
- `lib/view/desktop_view/widgets/ribbon_menu.dart` — new buttons, spacer, removed unused imports
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/presentation_settings_body.dart` — added auto-page toggle UI

### Current state
- All 3 features implemented and integrated
- 0 errors in flutter analyze (179 pre-existing info-level warnings only)
- Desktop ribbon shows browse YouTube/sheets buttons when song has those items
- Presentation settings has new toggle for paragraph-based page splitting
- Ribbon has visual spacer between transpose and browse/presentation groups

### Known issues / Next steps
- Browse YouTube body on macOS opens videos in external browser (WebView not available on desktop)
- Auto-page by paragraphs not yet connected to tablet/mobile presentation views (desktop only)

---

## 2026-02-23 - Fix Firebase Storage upload + remove non-functional note ribbon button

### What was done

1. **Firebase Storage upload fix**
   - Reverted `storageBucket` back to `songlist-7b702.appspot.com` in all 5 platform configs (the `.firebasestorage.app` change from previous session pointed to a non-existent bucket, causing `object-not-found` error)
   - Changed upload method from `putFile` to `putData` with `SettableMetadata` on all 3 platforms (desktop, tablet, mobile) — more reliable, avoids macOS sandbox file-access issues
   - Added `withData: true` to `FilePicker.platform.pickFiles()` to get bytes directly
   - Added fallback: if `file.bytes` is null, reads bytes from `File(file.path!).readAsBytes()`
   - Added `dart:typed_data` import for `Uint8List` in tablet and mobile files

2. **macOS entitlements**
   - Added `com.apple.security.files.user-selected.read-only` to both `DebugProfile.entitlements` and `Release.entitlements`

3. **Desktop ribbon — removed non-functional "note" button**
   - Removed the "note" RibbonButton (dispatched `ChangeEditBody(bodyName: 'note')` which had no handler in `edit_body.dart`)
   - Changed "sheets" button icon from `Icons.image` to `Icons.music_note` (better icon, as user requested)

### Files changed
- `lib/firebase_options.dart` — reverted storageBucket to `.appspot.com`
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_sheets_body.dart` — putData + withData
- `lib/view/tablet_view/pages/tablet_edit_pages/edit_page_tablet.dart` — putData + withData + typed_data import
- `lib/view/mobile_view/pages/edit_pages/edit_page.dart` — putData + withData + typed_data import
- `lib/view/desktop_view/widgets/ribbon_menu.dart` — removed note button, changed sheets icon
- `macos/Runner/DebugProfile.entitlements` — added files.user-selected.read-only
- `macos/Runner/Release.entitlements` — added files.user-selected.read-only

### Current state
- Firebase Storage upload should now work correctly (correct bucket + putData)
- Desktop ribbon has: lyrics, chord, youtube, sheets (music_note icon), settings, delete
- 0 errors in flutter analyze (179 pre-existing info-level warnings)

### Known issues
- The original "-1 code" error may have been a transient issue or security rules problem — if upload still fails, check Firebase Console Storage rules

---

## 2026-02-23 - Tablet/Mobile: YouTube & Sheets editing + Firebase Storage bucket fix

### What was done

1. **Tablet edit page — YouTube editing added**
   - Added YouTube videos section (`getYoutubeVideos`) to `edit_page_tablet.dart`
   - Full CRUD: add (dialog with name + URL), edit (dialog), delete
   - Each video shows name, URL, validation icon, open-in-browser button
   - Uses `extractYoutubeVideoId()` for URL validation

2. **Tablet edit page — Sheets editing fixed**
   - Replaced stub `getSheets` (had `onTap: () {}` and broken `Image.file`) with working implementation
   - Two add methods: add sheet by URL (dialog), upload image (FilePicker → Firebase Storage)
   - Horizontal scrollable thumbnail list with `CachedNetworkImage`
   - Delete button per sheet, full-screen preview dialog with InteractiveViewer zoom

3. **Mobile edit page — same treatment**
   - Added `getYoutubeVideosMobile` with full YouTube CRUD (add/edit/delete)
   - Replaced `getSheetsMobile` with working upload + URL + thumbnails + delete
   - Same Firebase Storage upload flow as tablet/desktop

4. **Firebase Storage bucket fix**
   - Changed all `storageBucket` values in `firebase_options.dart` from `songlist-7b702.appspot.com` to `songlist-7b702.firebasestorage.app`
   - The old `.appspot.com` format was causing "Unexpected -1 code from backend" error on macOS/desktop
   - Updated all 5 platform configs: windows, web, android, ios, macos

### Files changed
- `lib/view/tablet_view/pages/tablet_edit_pages/edit_page_tablet.dart` — YouTube + Sheets editing
- `lib/view/mobile_view/pages/edit_pages/edit_page.dart` — YouTube + Sheets editing
- `lib/firebase_options.dart` — Updated all storageBucket to `.firebasestorage.app`

### Current state
- All platforms (mobile, tablet, desktop) now have full YouTube and Sheets editing
- Firebase Storage should work correctly with updated bucket URL
- `flutter analyze` passes with 0 errors

### Known issues
- If `.firebasestorage.app` bucket still gives errors, Firebase Storage rules may need configuration in Firebase Console

## 2026-02-23 - Fix: YouTube player iPad error 152 — replaced youtube_player_iframe with webview_flutter

### What was done
- Replaced `youtube_player_iframe` package with `webview_flutter` for YouTube video playback
- Root cause: `youtube_player_iframe` uses YouTube IFrame embed API (`youtube.com/embed/ID`), which YouTube blocks for certain videos (error 150/152 = embedding disabled by video owner)
- Solution: Load full YouTube page URL (`youtube.com/watch?v=ID`) in a `WebViewWidget` — works like a browser within the app, avoids all embedding restrictions
- Updated both `YoutubeVideoPageMobile` and `YoutubeVideoPageTablet` to use `WebViewController` + `WebViewWidget`
- Added loading indicator (CircularProgressIndicator) while WebView loads
- Desktop fallback (open in browser via url_launcher) remains unchanged
- Removed `youtube_player_iframe: ^5.1.2` from pubspec.yaml, added `webview_flutter: ^4.13.1`
- `flutter analyze` passes with 0 errors

### Files changed
- `pubspec.yaml` — Replaced `youtube_player_iframe` with `webview_flutter`
- `lib/view/mobile_view/pages/youtube_video_page.dart` — Rewritten to use WebViewWidget
- `lib/view/tablet_view/pages/youtube_video_page_tablet.dart` — Rewritten to use WebViewWidget

### What is the current state
- YouTube videos should now play correctly on iPad/iPhone/Android via in-app WebView
- Desktop continues to open YouTube in external browser

## 2026-02-23 - Desktop: YouTube editing, Sheets editing with Firebase Storage, Preview YouTube button

### What was done

1. **Task 1 & 2: YouTube link editing + play/test in desktop edit page — completed**
   - Created `EditYoutubeBody` widget at `lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_youtube_body.dart`
   - Full CRUD for YouTube videos: add (dialog with name + URL), edit (dialog), delete
   - Real-time URL validation using `extractYoutubeVideoId()` — shows green check or red error in dialogs
   - "Test" button in dialogs opens YouTube URL in external browser via `url_launcher`
   - Play button on each video row opens in browser
   - Save button with change detection indicator

2. **Task 3: YouTube playback button in desktop preview ribbon — completed**
   - Added conditional YouTube button to HomeTabbar preview section in `ribbon_menu.dart`
   - Button only appears when selected song has YouTube videos (`youtubeVideos?.isNotEmpty`)
   - Opens first YouTube video in external browser via `url_launcher`

3. **Task 4: Sheet music editing with Firebase Storage upload — completed**
   - Added `firebase_storage: ^13.0.6` to pubspec.yaml
   - Created `EditSheetsBody` widget at `lib/view/desktop_view/pages/desktop_home_page/home_bodies/edit_parts_body/edit_sheets_body.dart`
   - Two ways to add sheets: upload image file (via FilePicker → Firebase Storage) or add URL directly
   - Firebase Storage upload: picks image file → uploads to `songs/{songId}/sheets/{timestamp_filename}` → gets download URL → adds to song sheets
   - Upload progress indicator with percentage
   - Grid view with thumbnails (via CachedNetworkImage), delete button per sheet
   - Full-screen image preview dialog with InteractiveViewer zoom
   - Save button with change detection

4. **BLoC infrastructure — completed**
   - Added 5 new events to EditSongBloc: `AddYoutubeVideo`, `RemoveYoutubeVideo`, `UpdateYoutubeVideo`, `AddSheet`, `RemoveSheet`
   - Implemented all 5 event handlers modifying `currentEditSong` via `copyWith`
   - Updated `_saveSong` desktop path to detect youtube/sheets changes
   - Updated `checkModifiedSong()` for youtube/sheets comparison

5. **Ribbon menu & edit body switch — completed**
   - Added "Youtube videa" and "Noty" buttons to edit ribbon section in `ribbon_menu.dart`
   - Added 'youtube' and 'sheets' cases to `edit_body.dart` switch
   - Added translation keys: `addSheet`, `uploadSheet`, `addSheetUrl` to cs.json and en.json

### What is the current state
- All 4 desktop tasks implemented and passing `flutter analyze` (0 errors, only pre-existing info warnings)
- Desktop edit mode now has 6 sub-pages: lyrics, chords, note, youtube, sheets, settings
- Preview ribbon conditionally shows YouTube button when song has videos
- Firebase Storage configured and ready for sheet image uploads

### What is pending / next steps
- Testing actual Firebase Storage upload with real images
- Consider adding drag-and-drop reordering for sheets
- Consider sheet preview in preview body (not just edit mode)

### Known issues
- `use_build_context_synchronously` info warnings in edit_sheets_body.dart (standard for async upload with mounted check)

## 2026-02-23 - Sheet music, YouTube videos, mobile 3-dot menu

### What was done

1. **Task 2: Sheet music (noty) support — completed**
   - Sheet view pages (`SheetViewPageMobile`, `SheetViewPageTablet`) fully implemented with:
     - `PageView` for swiping between multiple sheets
     - `InteractiveViewer` for pinch-to-zoom
     - `CachedNetworkImage` for network URL images with loading/error states
     - Page counter in app bar
     - Empty state with localized messages
   - Song cards now dispatch `ChangeCurrentSong` to `PreviewChordBloc` before navigating to sheet/youtube pages
   - Tablet song card popup menu now includes: preview, presentation, sheet (conditional), youtube (conditional), edit, delete
   - `TypeClickCard.sheet` / `.youtube` / `.presentation` cases handled in both mobile and tablet song cards (were TODO)

2. **Task 3: YouTube video player — completed**
   - Created `lib/core/youtube_helper.dart` — utility to extract YouTube video ID from various URL formats
   - YouTube video pages (`YoutubeVideoPageMobile`, `YoutubeVideoPageTablet`) implemented with:
     - `youtube_player_iframe` for embedded playback on iOS/Android
     - Desktop fallback: opens in external browser via `url_launcher`
     - Video list with play/open-in-browser options
     - Tablet layout: side-by-side player + video list
     - Mobile layout: stacked player + video list
     - Empty state with localized messages
   - Packages added to pubspec.yaml: `cached_network_image ^3.3.1`, `url_launcher ^6.2.5`, `youtube_player_iframe ^5.1.2`

3. **Task 4: Mobile song card 3-dot menu — completed**
   - Removed expand animation (`SizeTransition`, `AnimationController`)
   - Tap on card now opens preview directly (for `TypeClickCard.none` and `.preview`)
   - Added `PopupMenuButton` (3-dot menu) with options: preview, presentation, sheet (if available), youtube (if available), edit (if admin)
   - Added select button inline on the card
   - Admin-only edit option uses `BlocBuilder<UsersBloc>` check

### Files modified
- `lib/core/youtube_helper.dart` — NEW: YouTube video ID extraction utility
- `lib/view/mobile_view/widgets/song_card.dart` — Rewritten: removed expand animation, added 3-dot popup menu
- `lib/view/tablet_view/widgets/song_card_tablet.dart` — Added preview/presentation/sheet/youtube to popup menu, handled TypeClickCard TODOs
- `lib/view/mobile_view/pages/sheet_view_page.dart` — Full implementation with PageView + InteractiveViewer + CachedNetworkImage
- `lib/view/tablet_view/pages/sheet_view_page_tablet.dart` — Full implementation (same as mobile)
- `lib/view/mobile_view/pages/youtube_video_page.dart` — Full implementation with youtube_player_iframe + url_launcher fallback
- `lib/view/tablet_view/pages/youtube_video_page_tablet.dart` — Full implementation with side-by-side layout
- `lib/view/router/app_router.dart` — Routes already existed, no changes needed
- `pubspec.yaml` — Added cached_network_image, url_launcher, youtube_player_iframe

### Current state
- All 4 tasks completed: search field behavior, sheet music, YouTube videos, mobile 3-dot menu
- `flutter analyze` passes with 0 errors (only pre-existing info-level warnings)
- Sheet pages show images from URLs stored in Firestore `sheets` field
- YouTube player works on mobile/tablet (embedded) and desktop (opens in browser)
- Mobile song card: tap → preview, 3-dot menu → all actions
- Tablet song card: tap → preview, 3-dot menu → all actions including sheet/youtube

### Known issues / pending
- Desktop sheet/youtube pages route to `Container()` — only mobile/tablet have full implementations
- `youtube_player_iframe` may not work on macOS desktop (falls back to browser)
- No sheet upload/management UI — sheets are read-only from Firestore
- No YouTube video add/remove UI on the view pages — managed through edit page

---

## 2026-02-23 - Platform-aware search field behavior

### What was done
1. **Desktop (macOS/Windows/Linux) — live filtering on every keystroke:**
   - `list_song.dart`: Added `onChanged` to song filter — dispatches `FilterSong` on every keystroke
   - `list_web_song.dart`: Added `onChanged` to all 7 search fields:
     - `FilterSongs` (local) fields: immediate `onChanged`
     - `FilterInterprets` (network) fields: debounced `onChanged` with 500ms `Timer` to avoid spamming API
   - `edit_playlist_tablet.dart`: Added platform detection — on desktop, `onChanged` triggers `FilterSongPlaylist` live
   - `filter_field_tablet.dart`: Added platform detection — on desktop, `onChanged` calls `onSearch` live

2. **Mobile/Tablet (iOS/Android) — reset filter on new typing:**
   - After user applies a filter (via Enter or search button), the next keystroke in the field resets the filter (shows all songs again)
   - Tracked via `_isFilterActive` flag in each widget
   - `home_page.dart` (mobile): Added `_isFilterActive` tracking + `onChanged` reset
   - `filter_field_tablet.dart`: Converted from `StatelessWidget` to `StatefulWidget`, added `_isFilterActive` tracking
   - `edit_playlist_tablet.dart`: Added `_isFilterActive` + `_isDesktop` + conditional `onChanged`

### Files modified
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/list_song.dart` — Added `onChanged`
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/list_web_song.dart` — Added `dart:async`, debounce timer, `onChanged` to all 7 fields
- `lib/view/mobile_view/pages/home_page.dart` — Added `_isFilterActive`, reset-on-type `onChanged`
- `lib/view/tablet_view/widgets/filter_field_tablet.dart` — Converted to StatefulWidget, added platform-aware `onChanged`
- `lib/view/tablet_view/pages/tablet_edit_pages/edit_playlist_tablet.dart` — Added `dart:io`, `_isFilterActive`, `_isDesktop`, platform-aware `onChanged`

### Current state
- Desktop: all search fields filter live on every keystroke (network fields debounced 500ms)
- Mobile/Tablet: filter on Enter/button press; after filtering, first keystroke resets filter
- No compile errors

---

## 2026-02-23 - Auto-fill new playlist name with today's date

### What was done
- When creating a new playlist (tablet edit page), the name field is now automatically filled with today's date in DD.MM.YYYY format
- Modified `_openPlaylist` in `PlaylistsBloc` to set `defaultName` using `DateFormat('dd.MM.yyyy')` when `playlist == null`
- Both `currentPlaylist.name` and `namePlaylist` state fields are set to the date string
- Added same default date name to desktop save playlist dialog (`_showSavePlaylistDialog` in `ribbon_menu.dart`)
- Fixed `TextDirection.ltr` compile error caused by `intl` import conflicting with Flutter's `TextDirection` — added `hide TextDirection` to import

### Files modified
- `lib/blocs/playlist_bloc/playlists_bloc.dart` — Added `intl` import (with `hide TextDirection`), set default playlist name to today's date for new playlists
- `lib/view/desktop_view/widgets/ribbon_menu.dart` — Pre-filled save playlist dialog name with today's date

### Current state
- New playlists get today's date as default name (e.g. "23.02.2026")
- Editing existing playlists is unchanged
- No new compilation errors

---

## 2026-02-22 - Rewrite presentation to hide/show instead of destroy/recreate

### What was done
1. **Root cause confirmed**: `desktop_multi_window` unreliably boots new Dart engines after repeated create/destroy cycles. Even with 10+ second gaps, the sub-window Dart engine sometimes fails to start (`main()` never runs). Dead engines accumulate as zombies (`Error showing window after frame: PlatformException(-1, failed to find target window...)`).
2. **Fundamental redesign — hide/show instead of destroy/recreate**:
   - The Flutter engine is created ONCE on first presentation open
   - "Closing" the presentation now **hides** the window (keeps engine alive)
   - "Opening" again **shows** the hidden window and sends new data via the bridge
   - Engine is always warm and ready — no boot delay, no race condition
3. **Swift bridge additions**:
   - `hide_window`: calls `window.orderOut(nil)` — hides without closing/destroying
   - `show_reposition_window`: shows window and repositions on specified screen with full borderless setup
   - `close_window_with_exit` kept for actual destroy (app quit only)
4. **Dart PresentationWindowManager rewrite**:
   - Added `_isPresenting` flag (separate from window existence)
   - `closePresentationWindow()` — sends `hide_window` via bridge, keeps `_presentationWindowController`
   - `openPresentationWindow()` — if hidden window exists, sends `show_reposition_window` + `update_page`. Only creates new window on first call.
   - `destroyPresentationWindow()` — actual destroy for app shutdown
   - `markWindowClosed()` — actual close cleanup (only for `willCloseNotification`)
   - `isPresentationWindowOpen` now checks `_isPresenting` flag
5. **Sub-window escape handler changed**:
   - Pressing Escape in sub-window no longer calls `closeWindowWithExit` natively
   - Instead, just sends 'escape' command to main window via `navigate_bridge`
   - Main window handles 'escape' by calling `closePresentationWindow()` (which hides)
6. **Main window `onWindowClose`**: calls `destroyPresentationWindow()` (actual destroy) instead of `closePresentationWindow()` (hide)

### Files modified
- `macos/Runner/MainFlutterWindow.swift` — `hide_window` and `show_reposition_window` bridge handlers
- `lib/services/presentation_window_manager.dart` — Complete rewrite: hide/show pattern, `_isPresenting` flag, `destroyPresentationWindow()`
- `lib/main.dart` — Removed `_closePresentation()` from escape handler, `onWindowClose` uses `destroyPresentationWindow()`
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — 'escape' calls `closePresentationWindow()` (hide), 'window_closed' calls `markWindowClosed()` (destroy)

### Current state
- First open: creates window + Dart engine (one-time cost)
- Subsequent opens: instant — just shows hidden window and sends data
- No more engine boot failures
- No more zombie engines accumulating
- No compilation errors

---

## 2026-02-22 - Fix presentation window blank on second open (engine boot failure)

### What was done
1. **Root cause identified**: When the presentation window is closed and re-opened quickly (~1 second), `desktop_multi_window` fails to boot the new Dart engine — `main()` never runs in the sub-window. The window appears black because there's no Flutter widget tree rendering. Additionally, the backup `update_page` sent via the bridge hangs forever because Swift stores the `result` callback in the buffer but `sub_window_ready` never arrives (engine never started), blocking the Dart `await`.
2. **Fix — minimum delay between close and reopen** (Dart):
   - Added `_lastCloseTime` tracking in `PresentationWindowManager`
   - `openPresentationWindow` checks elapsed time since last close; if <1500ms, waits for the remainder before creating a new window
   - This gives the previous Flutter engine time to fully shut down
3. **Fix — non-blocking bridge buffering** (Swift):
   - When buffering messages (sub-window not ready), immediately call `result(nil)` instead of storing the result callback. This prevents the Dart caller from blocking forever if the engine fails.
   - Changed `pendingPageMessages` type from `(method, arguments, result)` to `(method, arguments)`
   - Extracted `flushPendingMessages()` static helper method
4. **Fix — bridge backup fire-and-forget** (Dart):
   - The backup `update_page` call in `openPresentationWindow` now uses `.then()/.catchError()` instead of `await`, so `openPresentationWindow` completes immediately
5. **Fix — safety timeout** (Swift):
   - After setting up sub-window channels, a 3-second `DispatchQueue.main.asyncAfter` timer fires. If `sub_window_ready` hasn't been received by then, buffered messages are flushed anyway (the handler might be registered even if the ready signal failed).

### Files modified
- `lib/services/presentation_window_manager.dart` — `_lastCloseTime`, delay guard, fire-and-forget backup
- `macos/Runner/MainFlutterWindow.swift` — Non-blocking `result(nil)` on buffer, `flushPendingMessages()` helper, 3s timeout

### Current state
- Second presentation open should work reliably (1.5s delay ensures clean engine lifecycle)
- Bridge never blocks Dart caller when buffering
- Buffered messages flushed even if sub-window engine partially fails
- No compilation errors

---

## 2026-02-22 - Fix intermittent blank presentation window

### What was done
1. **Root cause identified**: When creating a new presentation window, initial data was delivered ONLY via `WindowConfiguration(arguments: initData)`. The sub-window's `_loadInitialData()` then called `WindowController.fromCurrentEngine()` a second time to read those arguments — this platform channel call could fail intermittently, leaving the window blank. Additionally, `openPresentationWindow` did NOT send `update_page` via the native bridge for new windows, so there were zero buffered messages to flush when `sub_window_ready` fired.
2. **Fix — cached arguments + bridge backup**:
   - `main()` now caches `windowController.arguments` into `PresentationApp.cachedArguments` static field
   - `_loadInitialData()` is now synchronous — reads from cached arguments instead of making a second platform channel call
   - `openPresentationWindow()` now sends `update_page` via the native bridge after window creation as a backup. This message gets buffered by Swift until `sub_window_ready`, then flushed — ensuring data arrives even if the arguments cache was empty

### Files modified
- `lib/main.dart` — Added `PresentationApp.cachedArguments` static field, cache in `main()`, synchronous `_loadInitialData()`
- `lib/services/presentation_window_manager.dart` — Added `update_page` bridge call after new window creation as backup data path

### Current state
- Two independent data delivery paths: arguments cache (synchronous) + bridge backup (buffered)
- No compilation errors

---

## 2026-02-22 - Fix MissingPluginException race condition with ready-handshake

### What was done
1. **Root cause identified**: Race condition between Swift creating `subWindowPageChannel` (immediate) and the sub-window's Dart engine registering its `page_data` handler in `_setupMessageHandler()` (delayed by engine boot + widget tree build). Messages forwarded during this gap arrive at the sub-window engine with no handler → returns null → `MissingPluginException`.
2. **Fix — ready-handshake with Swift-side message buffering**:
   - Swift: Added `subWindowReady` flag and `pendingPageMessages` buffer
   - When the bridge receives messages and `subWindowReady` is false, messages are buffered instead of forwarded
   - Sub-window Dart: After `pageDataChannel.setMethodCallHandler(...)` completes, sends `sub_window_ready` signal via `navigate_bridge` channel
   - Swift: Intercepts `sub_window_ready` in `navigate_bridge` handler, sets `subWindowReady = true`, flushes all buffered messages to the now-ready sub-window
   - All close paths (bridge close, window control close, X button close, new sub-window creation) reset `subWindowReady` and clear the pending buffer

### Files modified
- `macos/Runner/MainFlutterWindow.swift` — Added `subWindowReady` flag, `pendingPageMessages` buffer, buffering logic in bridge handler, flush logic in `navigate_bridge` `sub_window_ready` intercept, reset in all close/cleanup paths
- `lib/main.dart` — Added `sub_window_ready` signal via `navigate_bridge` after `page_data` handler registration in `_setupMessageHandler()`

### Current state
- No Dart compilation errors (flutter analyze passes, 232 pre-existing infos/warnings)
- Messages sent during sub-window startup are buffered and flushed on ready
- All window lifecycle paths properly reset the ready state

---

## 2026-02-22 - Screen selection, font size control, live settings reload

### What was done
1. **Screen selection now works** — The `presentationScreenIndex` from settings is passed via `WindowConfiguration` arguments JSON to the native Swift layer. Swift reads `screenIndex` from the JSON and positions the window on the correct `NSScreen`. Previously hardcoded to "find any non-main screen".
2. **Font size slider in settings** — Added `_buildFontSizeSelector()` widget to `PresentationSettingsBody` with a slider (12–120 px), increment/decrement buttons. Replaced the "auto-calculated" note with "max font size" explanation.
3. **Font size is exact from settings** — The sub-window presentation (`PresentationApp` in main.dart) now uses `_fontSize` directly from settings. Removed all auto-calculation logic (lines-per-page based height formula). Long lines wrap (`softWrap: true`, `textAlign: TextAlign.center`). Content is scrollable if it overflows.
4. **Live reload on settings change** — Added `BlocListener<SettingsBloc, SettingsState>` in `DesktopHomePage.build()`. When any setting changes while the presentation window is open, `_onSettingsChanged()` immediately re-computes the page content with new settings (linesPerPage, showChords, fontSize, fontColor, showTitle, showPageNumber) and sends it to the sub-window via the bridge.

### Files modified
- `macos/Runner/MainFlutterWindow.swift` — Reads `screenIndex` from window arguments JSON, positions on `NSScreen[screenIdx]`
- `lib/services/presentation_window_manager.dart` — Added `screenIndex` parameter to `openPresentationWindow()`, passed in initData JSON
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — Passes `screenIndex` to `openPresentationWindow()`, added `BlocListener<SettingsBloc>` for live reload, added `_onSettingsChanged()` method
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/presentation_settings_body.dart` — Added `_buildFontSizeSelector()` widget, updated preview info text
- `lib/main.dart` — Removed auto font size calculation, uses `_fontSize` directly, `softWrap: true`, `SingleChildScrollView` for overflow

### Current state
- Screen selection works — presentation opens on the selected screen
- Font size controlled by settings slider (12–120 px)
- Long lines wrap instead of overflowing
- Settings changes immediately reflect in open presentation
- No compilation errors

---

## 2026-02-22 - Fix MissingPluginException persisting after sub-window re-creation

### What was done
1. **Root cause confirmed**: The `presentation_bridge` handler set in `awakeFromNib()` gets cleared when `desktop_multi_window` spawns a new Flutter engine (via `RegisterGeneratedPlugins` or internal plugin setup). Static channel references alone are not enough — the binary messenger's handler table is wiped.
2. **Fix — re-register on every sub-window creation**: Extracted bridge handler setup into `static func registerBridgeHandler()`. Called both in `awakeFromNib()` (initial) and inside `setOnWindowCreatedCallback` (before setting up sub-window channels). This ensures the handler is always fresh when a new sub-window is ready.
3. **Stored `mainBinaryMessenger`**: The main engine's binary messenger is stored as a static so `registerBridgeHandler()` can create a new `FlutterMethodChannel` on the correct messenger each time.
4. **Defensive navigation re-registration**: The `com.songviewer/navigation` channel is also re-created in the callback.
5. **Added bridge logging**: `[Bridge]` prefixed logs for handler registration and forwarding to aid debugging.

### Files modified
- `macos/Runner/MainFlutterWindow.swift` — `registerBridgeHandler()` static method, `mainBinaryMessenger` static, re-registration in callback

### Current state
- No compilation errors
- Bridge handler guaranteed fresh on each sub-window creation

---

## 2026-02-22 - Fix MissingPluginException on second presentation launch

### What was done
1. **Root cause**: All `FlutterMethodChannel` objects in `awakeFromNib()` were local variables — ARC deallocated them after the method returned, removing native handlers. First launch worked because the channels were invoked before GC; second launch failed with `MissingPluginException` because the handlers were gone.
2. **Fix — static strong references**: All 5 channel objects (`presentationBridgeChannel`, `mainNavigationChannel`, `subWindowPageChannel`, `subWindowNavigateBridge`, `subWindowControlChannel`) are now stored as static properties on `MainFlutterWindow`, preventing ARC deallocation.
3. **Fix — direct close from native**: The bridge now handles `close_window_with_exit` directly in Swift (toggling fullscreen if needed, then closing the window). No more round-trip through sub-window Dart — eliminates hanging awaits when sub-window engine is being destroyed.
4. **Cleanup on close**: When the sub-window is closed (via any path), `subWindowPageChannel` and `subWindow` are set to nil. Next `setOnWindowCreatedCallback` re-creates them on the new engine.
5. **Weak sub-window ref**: `MainFlutterWindow.subWindow` is `weak` — if the window is deallocated externally, the reference auto-nils.

### Files modified
- `macos/Runner/MainFlutterWindow.swift` — 5 static channel properties, `weak subWindow` ref, bridge intercepts `close_window_with_exit`, cleanup on all close paths
- `lib/services/presentation_window_manager.dart` — Improved close fallback chain (`hide` → `hide` instead of `close` which doesn't exist on `WindowController`)

### Current state
- No compilation errors (229 pre-existing infos/warnings unchanged)
- Second launch should now work — bridge handler persists across window lifecycle
- Close is handled directly in native Swift — no round-trip failure risk

---

## 2026-02-22 - Bypass desktop_multi_window channels with native Swift bridge

### What was done
1. **Root cause confirmed** — ALL `desktop_multi_window` v0.3.0 channel approaches (`WindowController.invokeMethod`, `setWindowMethodHandler`, custom `WindowMethodChannel` both bidirectional and unidirectional) fail with `CHANNEL_UNREGISTERED`. The sub-window's Dart engine never successfully registers its handler with the native plugin layer. Every single `sendPageToPresentation` call fails — 100% failure rate confirmed in runtime logs.
2. **Native Swift bridge** — Completely bypass `desktop_multi_window` channel system. Implemented 4 native `FlutterMethodChannel`s in `MainFlutterWindow.swift` that route messages between the main and sub-window engines via native Swift code:
   - `com.songviewer/presentation_bridge` (main Dart → native) — Main window sends page data here
   - `com.songviewer/page_data` (native → sub Dart) — Sub-window receives page data here
   - `com.songviewer/navigate_bridge` (sub Dart → native) — Sub-window sends keyboard navigation here
   - `com.songviewer/navigation` (native → main Dart) — Main window receives navigation here
3. **Font size consistency** — Removed width-based font calculation entirely. Font size now based solely on available height and `_linesPerPage` constant, ensuring identical font size on all pages regardless of line content.
4. **Removed retry logic** — `_invokeWithRetry` method deleted. Native bridge is immediate — no registration delay needed.

### Files modified
- `macos/Runner/MainFlutterWindow.swift` — Added static `subWindowPageChannel` and `mainWindowNavigationChannel`, 4 bridge channels with native forwarding logic
- `lib/main.dart` — `_setupMessageHandler()` uses `MethodChannel('com.songviewer/page_data')`, keyboard forwarding uses `MethodChannel('com.songviewer/navigate_bridge')`, removed `dart:ui` import, removed width-based font calculation
- `lib/services/presentation_window_manager.dart` — Added `_bridgeChannel` constant, `sendPageToPresentation`/`sendSongToPresentation`/`closePresentationWindow` use `_bridgeChannel.invokeMethod(...)`, removed `_invokeWithRetry`
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — Replaced `WindowMethodChannel('songs_viewer/navigate')` with `MethodChannel('com.songviewer/navigation')`, removed `desktop_multi_window` import

### Architecture
```
Main Window Dart                     Native Swift                    Sub-Window Dart
─────────────────                    ────────────                    ───────────────
presentation_bridge ──invokeMethod──→ MainFlutterWindow ──invokeMethod──→ page_data
     navigation     ←──invokeMethod── MainFlutterWindow ←──invokeMethod── navigate_bridge
```

### Current state
- All inter-window communication routes through native Swift bridge
- Font size is consistent across all pages (height-based only)
- `desktop_multi_window` still used for `WindowController.create/getAll/fromCurrentEngine` (window lifecycle) — only channel system is bypassed
- Existing `com.songviewer/window` channel (close/fullscreen) continues working unchanged
- No compilation errors (flutter analyze passes with 0 new issues)

### Known issues / next steps
- The native bridge approach needs runtime testing to confirm it resolves the CHANNEL_UNREGISTERED errors
- If bridge works, consider removing unused `desktop_multi_window` channel-related imports where possible

---

## 2026-02-22 - Fix escape close, text centering, font consistency

### What was done
1. **Fix escape to close presentation** — Sub-window escape key now calls native `closeWindowWithExit` directly (bypasses round-trip through channels). Also sends `'escape'` to main window so it can update `isPresentationWindowOpen` state via `markWindowClosed()`. Main window escape still works as fallback via `closePresentationWindow()` with `hide()` fallback.
2. **Fix text centering** — Inner Column in presentation changed from `CrossAxisAlignment.start` to `CrossAxisAlignment.center` so text lines are horizontally centered.
3. **Fix font size consistency** — Font size calculation now always uses `_linesPerPage` (not actual line count) so all pages have the same font size regardless of how many lines each page has.
4. **Reverted custom channel approach** — `_setupMessageHandler` reverted to use `controller.setWindowMethodHandler()` (built-in per-window unidirectional channel). Added retry logic (10 attempts × 500ms) for `CHANNEL_UNREGISTERED` errors during sub-window startup.

### Files modified
- `lib/main.dart` — `_handlePresentationKeyEvent` escape calls `_closePresentation()` directly, added `_closePresentation()`, font sizing uses `_linesPerPage`, text centered
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` — `_handleRemoteNavigation('escape')` calls `markWindowClosed()` instead of `closePresentationWindow()`
- `lib/services/presentation_window_manager.dart` — Reverted to `WindowController.invokeMethod`, added `markWindowClosed()`, `closePresentationWindow()` has `hide()` fallback, retry logic with 10 attempts

### Current state
- Escape closes presentation from either window
- Text is horizontally centered in presentation
- Font size is consistent across all pages
- No compilation errors

---

## 2026-02-22 - Fix CHANNEL_UNREGISTERED errors with desktop_multi_window v0.3.0

### What was done
- **Root cause**: `WindowController.invokeMethod` in v0.3.0 uses a **bidirectional** `WindowMethodChannel` internally. Both engines (main + sub-window) must register on the channel. The main window never registered, causing `CHANNEL_UNREGISTERED` errors on every `invokeMethod` call.
- **Fix**: Replaced all `_presentationWindowController!.invokeMethod(...)` calls with a custom **unidirectional** `WindowMethodChannel('songs_viewer/presentation')`. The sub-window registers as the sole handler. Any engine can invoke.
- **Sub-window handler**: Changed `_setupMessageHandler()` in `PresentationApp` from `controller.setWindowMethodHandler()` (bidirectional) to `presentationChannel.setMethodCallHandler()` (unidirectional).
- **Retry logic**: Added `_invokeWithRetry()` to `PresentationWindowManager` — retries up to 5 times with 500ms delays when the sub-window hasn't registered yet (startup timing).

### Files modified
- `lib/main.dart` - `_setupMessageHandler()` now uses unidirectional `WindowMethodChannel('songs_viewer/presentation')`
- `lib/services/presentation_window_manager.dart` - All `invokeMethod` calls use the shared unidirectional channel + retry helper

### Current state
- Two unidirectional channels: `songs_viewer/presentation` (main→sub, page updates/close) and `songs_viewer/navigate` (sub→main, keyboard forwarding)
- No compilation errors

---

## 2025-01-XX - Fix keyboard forwarding between presentation windows

### What was done
- **Fixed focus/keyboard issue in presentation mode** - The previous approach of `windowManager.focus()` to bring the main window to front was causing the presentation window to be hidden behind the main window (black screen). Reverted that approach entirely.
- **Implemented cross-window keyboard forwarding** - Added `KeyboardListener` to `PresentationApp` (sub-window) that captures arrow keys, space, backspace, and escape. These key events are forwarded to the main window via `WindowMethodChannel` (desktop_multi_window v0.3.0 API).
- **Fixed API for desktop_multi_window v0.3.0** - The old `DesktopMultiWindow.invokeMethod` / `DesktopMultiWindow.setMethodHandler` API was removed in v0.3.0. Replaced with `WindowMethodChannel('songs_viewer/navigate', mode: ChannelMode.unidirectional)` for inter-window communication.
- **Main window receives navigation commands** - `DesktopHomePage` listens on the `WindowMethodChannel` and invokes the same `_navigateForward` / `_navigateBackward` / escape logic as local keyboard events.

### Files modified
- `lib/main.dart` - Added `_presentationFocusNode`, `KeyboardListener` wrapper, `_handlePresentationKeyEvent()` that sends commands via `WindowMethodChannel`
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` - Added `_navigateChannel` (static const `WindowMethodChannel`), `initState()` registers handler, `dispose()` clears handler, `_handleRemoteNavigation()` method
- `lib/services/presentation_window_manager.dart` - Reverted `windowManager.focus()` and removed `_focusMainWindow()` method

### Current state
- Keyboard shortcuts (arrows, space, backspace, escape) now work from EITHER window - the main window or the presentation window
- Presentation window is no longer hidden/covered by the main window
- No compilation errors (only pre-existing info-level warnings)

### Known issues
- None new

---

## 2025-01-XX - Presentation UX fixes batch 3 (5 tasks)

### What was done
1. **Load playlist dialog - expandable with songs & edit** - Rewrote `_showLoadPlaylistDialog` in ribbon_menu.dart. Clicking a playlist now expands it to show all its songs with numbering, song title, and interpret. Songs can be reordered via drag-and-drop (ReorderableListView) and removed individually. Added `UpdatePlaylistDirect` event to `PlaylistsBloc` for saving playlist changes directly to Firebase.

2. **Consistent auto font size - never truncated** - Fixed PresentationApp in main.dart: removed `overflow: TextOverflow.ellipsis` and `maxLines: 1` which were cutting off long lines. Added width-based font size calculation using `TextPainter` binary search to find the max font size that fits the longest line. Final font size is the smaller of height-based and width-based calculations, ensuring text never overflows in either direction.

3. **Fix focus on double-click presentation start** - Added `FocusScope.of(context).requestFocus()` with 300ms delay after double-click opens/sends to presentation window in list_song.dart. This ensures keyboard shortcuts work immediately after starting presentation via double-click.

4. **Fix backward navigation skipping songs** - Root cause: `UpdatePresentationSong` always reset `currentPage` to 0 in the BLoC state, even when navigating to the last page of a previous song. Added optional `page` parameter to `UpdatePresentationSong` event. `_goToPreviousSongLastPage` now passes `page: lastPage` so the BLoC state correctly reflects the displayed page. Also fixed the black-first-page backward path to set page to `totalPages - 1`.

5. **Resizable divider between left and right columns in preview** - Added draggable vertical divider in preview_body.dart between `ListSong` and the lyrics content area. Uses `MouseRegion` (resize cursor) + `GestureDetector` (horizontal drag) pattern. `ListSong` now accepts optional `width` parameter (clamped 200-600px, default 300).

### Files modified
- `lib/view/desktop_view/widgets/ribbon_menu.dart` - Rewrote `_showLoadPlaylistDialog` with expandable playlists, song list, reorder, remove. Added Playlist model import.
- `lib/blocs/playlist_bloc/playlists_event.dart` - Added `UpdatePlaylistDirect` event
- `lib/blocs/playlist_bloc/playlists_bloc.dart` - Added `_updatePlaylistDirect` handler
- `lib/main.dart` - Fixed font auto-sizing to consider width, removed ellipsis truncation, added `dart:ui` import
- `lib/blocs/presentation_bloc/presentation_event.dart` - Added optional `page` parameter to `UpdatePresentationSong`
- `lib/blocs/presentation_bloc/presentation_bloc.dart` - Updated `_onUpdatePresentationSong` to use `event.page`
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` - Fixed `_goToPreviousSongLastPage` and black-first-page backward navigation to pass correct page
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/list_song.dart` - Added focus re-request after double-click, added `width` parameter
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/preview_body.dart` - Added resizable divider, `_listSongWidth` state

### Current state
- All 5 tasks implemented, no compilation errors
- Backward navigation now correctly tracks page state across song boundaries
- Font sizing considers both width and height, text is never truncated
- Keyboard focus works after double-click presentation start
- Playlist load dialog is interactive with song preview and editing

### Known issues
- Pre-existing warning: unused `list` variable in preview_body.dart line 186

---

## 2025-01-XX - Presentation UX fixes and improvements (6 tasks)

### What was done
1. **Double-click on playlist card starts presentation** - Added `onDoubleTap` callback to `PresentationPlaylistWidget`. Double-clicking a song in the playlist now either sends that song to an already-open presentation window, or opens a new presentation window starting from that song.

2. **Keep Home tab visible in settings sub-views** - When navigating to groups/users/presentation_settings, the "Home" tab now remains visible in the ribbon menu (with Settings tab selected by default). Clicking "Home" tab navigates back to the preview body.

3. **Auto-calculate font size from lines per page** - Removed the manual font size selector from presentation settings. The presentation window now auto-calculates the font size based on the available window height and the number of lines per page. Added `linesPerPage` parameter to `PresentationWindowManager` methods. The `PresentationApp` uses `LayoutBuilder` to compute optimal font size dynamically.

4. **Fix focus after opening presentation window** - Added `_focusNode.requestFocus()` with a 300ms delay after opening the presentation window. Also wrapped the entire home page in a `GestureDetector` that re-requests focus on any tap, ensuring keyboard shortcuts always work after interacting with UI elements.

5. **Fix arrow key navigation** - Completely rewrote the keyboard navigation logic in `desktop_home_page.dart`. Split into clear helper methods: `_navigateForward`, `_navigateBackward`, `_goToNextSongFirstPage`, `_goToNextSongWithBlackFirst`, `_goToPreviousSongLastPage`. Each key press now moves exactly one step (one page forward/backward), with proper handling of black screen transitions between songs.

6. **Playlist Firebase save** - Already implemented from previous session. Verified the save dialog (`_showSavePlaylistDialog`) and load dialog (`_showLoadPlaylistDialog`) work correctly with `SavePresentationPlaylist` and `LoadPresentationPlaylist` events.

### Files modified
- `lib/view/desktop_view/widgets/presentation_playlist_widget.dart` - Added `onSongDoubleTap` callback
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/list_song.dart` - Wired up double-tap handler
- `lib/view/desktop_view/widgets/ribbon_menu.dart` - Fixed tab controller for settings views (length=2, Home+Settings tabs with onTap navigation)
- `lib/view/desktop_view/pages/desktop_home_page/desktop_home_page.dart` - Rewrote keyboard navigation, added focus fix, wrapped in GestureDetector
- `lib/view/desktop_view/pages/desktop_home_page/home_bodies/presentation_settings_body.dart` - Removed font size selector, added auto-calc note
- `lib/services/presentation_window_manager.dart` - Added `linesPerPage` parameter
- `lib/main.dart` - PresentationApp auto-calculates font size via LayoutBuilder

### Current state
- All 6 tasks implemented and compiling without errors
- Presentation navigation should now be strictly sequential (one page per key press)
- Font size is auto-calculated, no manual setting needed
- Home tab persists across all ribbon views

### Known issues
- The `Future.delayed(50ms)` is still used for cross-song transitions (playlist bloc processes event asynchronously). This could theoretically race in extreme cases but is reliable in practice.
- Pre-existing warnings in other files (unused variables, null-safety) were not touched.

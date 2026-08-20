/// Compile-time feature flags that separate the personal build from the
/// store build.
///
/// Every flag is a `const` read from the compilation environment, so the AOT
/// compiler can prove a disabled branch is dead and strip it — together with
/// the code and string literals it reaches. That is the point: for the store
/// build the excluded code must be *absent from the artifact*, not merely
/// switched off. Anyone can unpack an APK/IPA and read the strings inside.
///
/// A runtime setting would not do this. `if (settings.enableWebImport)` leaves
/// every source URL and API token in the binary.
///
/// `bool.fromEnvironment` defaults to `false`, and that default is deliberate:
/// **forgetting to pass a config yields the safe store build, not the personal
/// one.** Fail-closed, never fail-open.
///
/// Values come from `--dart-define-from-file`, and which file is used depends on
/// the flavour *and* on how the build is distributed:
///
/// | Build | Config | Web import |
/// |---|---|---|
/// | personal, any platform | `config/personal.json` | on |
/// | store, Android / iOS | `config/store_mobile.json` | **off** |
/// | store, macOS / Windows / Linux / web | `config/store_desktop.json` | on |
///
/// Only the mobile artifacts are published to Google Play and the App Store, so
/// only they are subject to the web-import restriction. Desktop builds are
/// distributed directly and keep the feature.
///
/// `build.sh` picks the right file automatically. See
/// `plans/store-release-plan.md` §10.
class Features {
  const Features._();

  /// Song import from third-party chord/lyrics sites.
  ///
  /// Must stay **off** for anything distributed through the App Store or Google
  /// Play — see `plans/store-release-plan.md` §2 (blocker B1). Shipping this in
  /// a paid app means reproducing copyrighted lyrics without a licence.
  static const bool webImport = bool.fromEnvironment('FEATURE_WEB_IMPORT');

  /// AI-assisted song enrichment (author/title lookup, YouTube suggestions).
  ///
  /// Requires user-supplied API keys, which are currently stored in plain text
  /// (see B2 item 3). Keep off in store builds until that is resolved.
  static const bool aiEnrichment = bool.fromEnvironment('FEATURE_AI');

  /// Connect to the configured PocketBase server automatically at startup.
  ///
  /// Off means local-first: the app is fully usable with no server and no
  /// configuration, and syncing is something the user opts into. On means the
  /// existing behaviour — authenticate during boot and pull server counts.
  static const bool sharedServer = bool.fromEnvironment('FEATURE_SHARED_SERVER');

  /// Whether server administration — the user and group screens — should be
  /// offered.
  ///
  /// Unlike the flags above this is a **runtime** check, not a compile-time
  /// one: self-hosted PocketBase stays available in every build, so a store
  /// user who configured a server of their own must still be able to
  /// administer it. [isConnected] is `PocketBaseProvider.isConnected`.
  static bool serverAdminVisible(bool isConnected) => sharedServer || isConnected;

  /// True when this build carries the full personal feature set.
  static const bool isPersonalBuild = webImport && sharedServer;

  /// Human-readable flavour name, useful in logs and the about screen.
  static const String flavorName = isPersonalBuild ? 'personal' : 'store';
}

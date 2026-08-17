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
/// Values come from `--dart-define-from-file=config/personal.json` or
/// `config/store.json`. See `plans/store-release-plan.md` §10.
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

  /// True when this build carries the full personal feature set.
  static const bool isPersonalBuild = webImport && sharedServer;

  /// Human-readable flavour name, useful in logs and the about screen.
  static const String flavorName = isPersonalBuild ? 'personal' : 'store';
}

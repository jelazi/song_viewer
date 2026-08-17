/// Entrypoint for the **store** build — the general, sellable version.
///
/// Startup never blocks on the network: the app is fully usable offline with no
/// server configured.
///
/// Which features are compiled in depends on how the build is distributed, not
/// on this entrypoint:
///
///   Android / iOS       — published to Google Play and the App Store, so web
///                         import is compiled out (blocker B1).
///                         Uses config/store_mobile.json.
///   macOS/Win/Linux/web — distributed directly, no store policy applies, so
///                         web import stays enabled.
///                         Uses config/store_desktop.json.
///
/// Prefer `./build.sh <platform> store <mode>`, which picks the right config and
/// runs the B1 scan on the artifacts that actually ship to a store.
///
/// See plans/store-release-plan.md §10.
library;

import 'main.dart' as app;

Future<void> main(List<String> args) => app.bootstrap(args);

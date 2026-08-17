/// Entrypoint for the **store** build — the version sold on the App Store and
/// Google Play.
///
/// Web import is compiled out entirely, and startup never blocks on the
/// network: the app is fully usable offline with no server configured. See
/// plans/store-release-plan.md §10.
///
/// Build with:
///   flutter build appbundle --flavor store -t lib/main_store.dart \
///       --dart-define-from-file=config/store.json
///
/// Then verify the artifact really is clean:
///   tool/verify_store_build.sh
library;

import 'main.dart' as app;

Future<void> main(List<String> args) => app.bootstrap(args);

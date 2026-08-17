/// Entrypoint for the **personal** build — the full feature set, including web
/// import and automatic PocketBase sync.
///
/// This build is for the developer's own use and desktop distribution. It must
/// never be submitted to the App Store or Google Play; see
/// plans/store-release-plan.md §2 (blocker B1) for why.
///
/// Build with:
///   flutter run --flavor personal -t lib/main_personal.dart \
///       --dart-define-from-file=config/personal.json
library;

import 'main.dart' as app;

Future<void> main(List<String> args) => app.bootstrap(args);

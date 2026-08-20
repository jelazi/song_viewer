import 'package:logger_pkg/logger_pkg.dart';

/// Initialises the global `logger` for tests.
///
/// `logger` is a `late` global that the app assigns in `bootstrap()`
/// (`lib/main.dart`). Tests never run bootstrap, so any repository code that
/// logs throws `LateInitializationError` instead of doing its job. Call this
/// from `setUp` in any suite that exercises code which logs.
///
/// Writes nothing: no file, no console.
void initTestLogger() {
  logger = MyLogger(
    debug: false,
    saveToFile: false,
    level: 0,
    isDebugConsole: false,
  );
}

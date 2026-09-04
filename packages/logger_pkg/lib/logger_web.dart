// Stub implementace pro web - tyto funkce by neměly být nikdy volány na webu
// protože isWeb kontroly je zastaví dříve

const bool isWeb = true;

dynamic createDirectory(String path) => throw UnsupportedError('Directory not supported on web');
dynamic createFile(String path) => throw UnsupportedError('File not supported on web');

Future<bool> directoryExists(dynamic dir) async => throw UnsupportedError('Directory not supported on web');
Future<void> createDirectoryRecursive(dynamic dir) async => throw UnsupportedError('Directory not supported on web');

Future<bool> fileExists(dynamic file) async => throw UnsupportedError('File not supported on web');
Future<void> createFileRecursive(dynamic file) async => throw UnsupportedError('File not supported on web');

dynamic openFileWrite(dynamic file) => throw UnsupportedError('File not supported on web');

Future<int> fileLength(dynamic file) async => throw UnsupportedError('File not supported on web');

List<dynamic> listDirectory(dynamic dir) => throw UnsupportedError('Directory not supported on web');

String getFilePath(dynamic file) => throw UnsupportedError('File not supported on web');

List<String> readFileLines(dynamic file) => throw UnsupportedError('File not supported on web');

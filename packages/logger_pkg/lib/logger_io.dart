import 'dart:io';

const bool isWeb = false;

dynamic createDirectory(String path) => Directory(path);
dynamic createFile(String path) => File(path);

Future<bool> directoryExists(dynamic dir) async => await (dir as Directory).exists();
Future<void> createDirectoryRecursive(dynamic dir) async => await (dir as Directory).create(recursive: true);

Future<bool> fileExists(dynamic file) async => await (file as File).exists();
Future<void> createFileRecursive(dynamic file) async => await (file as File).create(recursive: true);

dynamic openFileWrite(dynamic file) => (file as File).openWrite(mode: FileMode.append);

Future<int> fileLength(dynamic file) async => await (file as File).length();

List<dynamic> listDirectory(dynamic dir) => (dir as Directory).listSync();

String getFilePath(dynamic file) => (file as FileSystemEntity).path;

List<String> readFileLines(dynamic file) => (file as File).readAsLinesSync();

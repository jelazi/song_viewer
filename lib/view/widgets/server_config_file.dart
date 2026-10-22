import 'dart:convert';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../providers/pocketbase_provider.dart';

const serverConfigFileName = 'pocketbase_config.json';

/// Lets the user pick a server settings file exported from the desktop app.
/// Returns null when nothing was picked; throws [FormatException] when the
/// file is not a complete server config.
Future<PocketBaseConfig?> pickServerConfigFile() async {
  // Same reason as in ChordProImportView: iOS turns the extension filter into
  // UTIs, which can leave the picker with nothing selectable.
  final canFilterByExtension = defaultTargetPlatform != TargetPlatform.iOS;

  final result = await FilePicker.platform.pickFiles(
    withData: true,
    type: canFilterByExtension ? FileType.custom : FileType.any,
    allowedExtensions: canFilterByExtension ? ['json'] : null,
    dialogTitle: 'pbImportFromFile'.tr(),
  );
  final bytes = result?.files.singleOrNull?.bytes;
  if (bytes == null) return null;
  return PocketBaseConfig.fromFileContent(utf8.decode(bytes));
}

/// Fills the server settings fields from a picked file and reports the
/// outcome in a snack bar.
Future<void> importServerConfigInto(
  BuildContext context, {
  required TextEditingController url,
  required TextEditingController email,
  required TextEditingController password,
}) async {
  String message;
  try {
    final config = await pickServerConfigFile();
    if (config == null) return;
    url.text = config.pocketbaseUrl;
    email.text = config.email;
    password.text = config.password;
    message = 'pbImportLoaded'.tr();
  } on FormatException {
    message = 'pbImportInvalid'.tr();
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 2)));
  }
}

/// Saves the server settings to a file the mobile apps can import.
/// Returns false when the user cancelled the save dialog.
Future<bool> exportServerConfigFile(PocketBaseConfig config) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'pbExportToFile'.tr(),
    fileName: serverConfigFileName,
  );
  if (path == null) return false;
  await File(path).writeAsString(config.toFileContent());
  return true;
}

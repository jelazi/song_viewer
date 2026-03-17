import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:path/path.dart' as p;

import '../model/chord/chord_diagram.dart';
import '../model/playlist.dart';
import '../model/qr_link.dart';
import '../model/song/song.dart';
import '../model/user.dart';
import '../providers/pocketbase_provider.dart';
import '../repositories/playlist_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/songs_repository.dart';
import '../repositories/user_repository.dart';

/// Holds the result of a backup or restore operation.
class BackupResult {
  final bool success;
  final String message;
  final Map<String, int> counts;

  const BackupResult({
    required this.success,
    required this.message,
    this.counts = const {},
  });
}

/// Service to export and import a full application backup as a folder:
///   backup_folder/
///     backup.json          — all structured data
///     files/               — downloaded sheet images / uploaded files
class BackupService {
  final SongsRepository songsRepository;
  final PlaylistRepository playlistRepository;
  final UsersRepository usersRepository;
  final SettingsRepository settingsRepository;
  final PocketBaseProvider pocketBaseProvider;

  BackupService({
    required this.songsRepository,
    required this.playlistRepository,
    required this.usersRepository,
    required this.settingsRepository,
    required this.pocketBaseProvider,
  });

  // ---------------------------------------------------------------------------
  // EXPORT
  // ---------------------------------------------------------------------------

  /// Creates a full backup in [directoryPath].
  /// Returns a [BackupResult] with counts of exported items.
  Future<BackupResult> exportBackup(
    String directoryPath, {
    required ValueChanged<String> onProgress,
  }) async {
    try {
      final backupDir = Directory(directoryPath);
      if (!backupDir.existsSync()) {
        backupDir.createSync(recursive: true);
      }

      // --- Collect all data ---
      onProgress('backupLoadingSongs'.tr());
      final songs = songsRepository.songs;

      onProgress('backupLoadingPlaylists'.tr());
      final playlists = playlistRepository.playlists;

      onProgress('backupLoadingGroups'.tr());
      final groups = songsRepository.listAllGroups;

      onProgress('backupLoadingUsers'.tr());
      final users = usersRepository.users;

      onProgress('backupLoadingChordDiagrams'.tr());
      final chordCache = songsRepository.chordService.pbChordCache;
      final chordDiagrams = chordCache.entries.map((e) => ChordDiagram(name: e.key, positions: e.value)).toList();

      onProgress('backupLoadingSettings'.tr());
      final settings = _exportSettings();

      // --- Download sheet files ---
      final filesDir = Directory(p.join(directoryPath, 'files'));
      if (!filesDir.existsSync()) {
        filesDir.createSync(recursive: true);
      }

      final fileMapping = <String, String>{}; // original URL → local filename
      int fileIndex = 0;
      for (final song in songs) {
        if (song.sheets == null || song.sheets!.isEmpty) continue;
        for (final sheetUrl in song.sheets!) {
          if (sheetUrl.isEmpty || fileMapping.containsKey(sheetUrl)) continue;
          fileIndex++;
          onProgress('backupDownloadingFile'.tr(args: [fileIndex.toString()]));
          final localName = await _downloadFile(sheetUrl, filesDir, fileIndex);
          if (localName != null) {
            fileMapping[sheetUrl] = localName;
          }
        }
      }

      // --- Build backup JSON ---
      final backupData = {
        'version': 1,
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'songs': songs.map((s) => s.toJson()).toList(),
        'playlists': playlists.map((p) => p.toJson()).toList(),
        'groups': groups,
        'users': users.map((u) => u.toJson()).toList(),
        'chordDiagrams': chordDiagrams.map((c) => c.toJson()).toList(),
        'settings': settings,
        'fileMapping': fileMapping,
      };

      onProgress('savingBackupJson'.tr());
      final jsonFile = File(p.join(directoryPath, 'backup.json'));
      await jsonFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(backupData),
      );

      final counts = {
        'songs': songs.length,
        'playlists': playlists.length,
        'groups': groups.length,
        'users': users.length,
        'chordDiagrams': chordDiagrams.length,
        'files': fileMapping.length,
      };

      onProgress('backupDone'.tr());
      return BackupResult(
        success: true,
        message: 'backupSuccess'.tr(),
        counts: counts,
      );
    } catch (e) {
      logger.e('Backup export error: $e');
      return BackupResult(success: false, message: 'backupExportError'.tr(args: [e.toString()]));
    }
  }

  /// Downloads a file from [url] into [directory] and returns the local filename.
  Future<String?> _downloadFile(
    String url,
    Directory directory,
    int index,
  ) async {
    try {
      final uri = Uri.parse(url);
      final originalName = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : 'file_$index';
      final ext = p.extension(originalName);
      final localName = 'file_${index.toString().padLeft(4, '0')}$ext';
      final localPath = p.join(directory.path, localName);

      final dio = Dio();
      await dio.download(url, localPath);
      return localName;
    } catch (e) {
      logger.e('Error downloading file from $url: $e');
      return null;
    }
  }

  /// Exports settings into a serializable map.
  Map<String, dynamic> _exportSettings() {
    return {
      'previewFontTextSize': settingsRepository.previewFontTextSize,
      'previewFontChordSize': settingsRepository.previewFontChordSize,
      'editFontTextSize': settingsRepository.editFontTextSize,
      'editFontChordSize': settingsRepository.editFontChordSize,
      'previewColorText': settingsRepository.previewColorText.value,
      'previewColorChord': settingsRepository.previewColorChord.value,
      'editColorText': settingsRepository.editColorText.value,
      'editColorChord': settingsRepository.editColorChord.value,
      'isEditIconVisible': settingsRepository.isEditIconVisible,
      'autoHideTopBar': settingsRepository.autoHideTopBar,
      'twoColumns': settingsRepository.twoColumns,
      'presentationScreenIndex': settingsRepository.presentationScreenIndex,
      'presentationLinesPerPage': settingsRepository.presentationLinesPerPage,
      'presentationFontSize': settingsRepository.presentationFontSize,
      'presentationFontColor': settingsRepository.presentationFontColor.value,
      'presentationShowChords': settingsRepository.presentationShowChords,
      'presentationBlackFirstPage': settingsRepository.presentationBlackFirstPage,
      'presentationBlackLastPage': settingsRepository.presentationBlackLastPage,
      'presentationShowPageNumber': settingsRepository.presentationShowPageNumber,
      'presentationShowTitle': settingsRepository.presentationShowTitle,
      'presentationAutoPageByParagraphs': settingsRepository.presentationAutoPageByParagraphs,
      'groqApiKey': settingsRepository.groqApiKey,
      'youtubeApiKey': settingsRepository.youtubeApiKey,
      'geminiApiKey': settingsRepository.geminiApiKey,
      'qrLinks': settingsRepository.qrLinks.map((e) => e.toJson()).toList(),
    };
  }

  // ---------------------------------------------------------------------------
  // IMPORT
  // ---------------------------------------------------------------------------

  /// Reads a backup from [directoryPath] and returns parsed counts for preview.
  Future<BackupResult> previewBackup(String directoryPath) async {
    try {
      final jsonFile = File(p.join(directoryPath, 'backup.json'));
      if (!jsonFile.existsSync()) {
        return BackupResult(
          success: false,
          message: 'backupJsonNotFound'.tr(),
        );
      }
      final content = await jsonFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final counts = {
        'songs': (data['songs'] as List?)?.length ?? 0,
        'playlists': (data['playlists'] as List?)?.length ?? 0,
        'groups': (data['groups'] as List?)?.length ?? 0,
        'users': (data['users'] as List?)?.length ?? 0,
        'chordDiagrams': (data['chordDiagrams'] as List?)?.length ?? 0,
        'files': (data['fileMapping'] as Map?)?.length ?? 0,
      };

      final createdAt = data['createdAt'] as String? ?? '?';

      return BackupResult(
        success: true,
        message: 'backupFrom'.tr(args: [createdAt]),
        counts: counts,
      );
    } catch (e) {
      return BackupResult(success: false, message: 'backupReadError'.tr(args: [e.toString()]));
    }
  }

  /// Restores all data from backup in [directoryPath].
  Future<BackupResult> importBackup(
    String directoryPath, {
    required ValueChanged<String> onProgress,
  }) async {
    try {
      final jsonFile = File(p.join(directoryPath, 'backup.json'));
      if (!jsonFile.existsSync()) {
        return BackupResult(
          success: false,
          message: 'backupJsonNotFound'.tr(),
        );
      }

      final content = await jsonFile.readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;

      final counts = <String, int>{};

      // --- File mapping (reverse: local filename → new PB URL) ---
      final fileMapping = (data['fileMapping'] as Map<String, dynamic>?) ?? {};
      final reverseFileMapping = <String, String>{}; // old URL → new URL
      final filesDir = Directory(p.join(directoryPath, 'files'));

      if (fileMapping.isNotEmpty && filesDir.existsSync()) {
        int uploaded = 0;
        for (final entry in fileMapping.entries) {
          final oldUrl = entry.key;
          final localName = entry.value as String;
          final localFile = File(p.join(filesDir.path, localName));
          if (!localFile.existsSync()) continue;

          uploaded++;
          onProgress('backupUploadingFile'.tr(args: [uploaded.toString(), fileMapping.length.toString()]));
          final bytes = await localFile.readAsBytes();
          final newUrl = await pocketBaseProvider.uploadFile(localName, bytes);
          if (newUrl != null) {
            reverseFileMapping[oldUrl] = newUrl;
          }
        }
        counts['files'] = uploaded;
      }

      // --- Songs ---
      final songsJson = data['songs'] as List? ?? [];
      onProgress('backupRestoringSongs'.tr(args: [songsJson.length.toString()]));
      int songCount = 0;
      for (final sj in songsJson) {
        final song = Song.fromJson(Map<String, dynamic>.from(sj as Map));
        // Remap sheet URLs to newly uploaded files
        if (song.sheets != null) {
          song.sheets = song.sheets!.map((url) {
            return reverseFileMapping[url] ?? url;
          }).toList();
        }
        await pocketBaseProvider.addOrUpdateSong(song);
        songCount++;
        if (songCount % 20 == 0) {
          onProgress('backupRestoringSongsProgress'.tr(args: [songCount.toString(), songsJson.length.toString()]));
        }
      }
      counts['songs'] = songCount;

      // --- Playlists ---
      final playlistsJson = data['playlists'] as List? ?? [];
      onProgress('backupRestoringPlaylists'.tr(args: [playlistsJson.length.toString()]));
      int playlistCount = 0;
      for (final pj in playlistsJson) {
        final playlist = Playlist.fromJson(Map<String, dynamic>.from(pj as Map));
        await pocketBaseProvider.addOrUpdatePlaylist(playlist);
        playlistCount++;
      }
      counts['playlists'] = playlistCount;

      // --- Groups ---
      final groupsList = (data['groups'] as List?)?.cast<String>() ?? [];
      onProgress('backupRestoringGroups'.tr(args: [groupsList.length.toString()]));
      for (final group in groupsList) {
        await pocketBaseProvider.createGroup(group);
      }
      counts['groups'] = groupsList.length;

      // --- Users ---
      final usersJson = data['users'] as List? ?? [];
      onProgress('backupRestoringUsers'.tr(args: [usersJson.length.toString()]));
      for (final uj in usersJson) {
        final user = User.fromJson(Map<String, dynamic>.from(uj as Map));
        await pocketBaseProvider.addOrUpdateAppUser(user);
      }
      counts['users'] = usersJson.length;

      // --- Chord diagrams ---
      final chordsJson = data['chordDiagrams'] as List? ?? [];
      onProgress('backupRestoringChordDiagrams'.tr(args: [chordsJson.length.toString()]));
      for (final cj in chordsJson) {
        final diagram = ChordDiagram.fromJson(Map<String, dynamic>.from(cj as Map));
        await songsRepository.chordService.saveChordDiagram(diagram);
      }
      counts['chordDiagrams'] = chordsJson.length;

      // --- Settings ---
      final settingsMap = data['settings'] as Map<String, dynamic>?;
      if (settingsMap != null) {
        onProgress('backupRestoringSettings'.tr());
        _importSettings(settingsMap);
      }

      // --- Reload app data ---
      onProgress('backupSyncingData'.tr());
      await songsRepository.updateSongsFromServer();

      onProgress('backupDone'.tr());
      return BackupResult(
        success: true,
        message: 'backupRestoreSuccess'.tr(),
        counts: counts,
      );
    } catch (e) {
      logger.e('Backup import error: $e');
      return BackupResult(success: false, message: 'backupRestoreError'.tr(args: [e.toString()]));
    }
  }

  /// Restores settings from a map.
  void _importSettings(Map<String, dynamic> s) {
    // Simple scalar settings
    final scalarKeys = [
      'previewFontTextSize',
      'previewFontChordSize',
      'editFontTextSize',
      'editFontChordSize',
      'isEditIconVisible',
      'autoHideTopBar',
      'twoColumns',
      'presentationScreenIndex',
      'presentationLinesPerPage',
      'presentationFontSize',
      'presentationShowChords',
      'presentationBlackFirstPage',
      'presentationBlackLastPage',
      'presentationShowPageNumber',
      'presentationShowTitle',
      'presentationAutoPageByParagraphs',
      'groqApiKey',
      'youtubeApiKey',
      'geminiApiKey',
    ];

    for (final key in scalarKeys) {
      if (s.containsKey(key)) {
        settingsRepository.changeSettingsValue(key, s[key]);
      }
    }

    // Color settings (stored as int)
    for (final colorKey in [
      'previewColorText',
      'previewColorChord',
      'editColorText',
      'editColorChord',
      'presentationFontColor',
    ]) {
      if (s.containsKey(colorKey)) {
        settingsRepository.changeSettingsValue(colorKey, Color(s[colorKey] as int));
      }
    }

    // QR links
    if (s.containsKey('qrLinks')) {
      final linksJson = s['qrLinks'] as List? ?? [];
      final links = linksJson.map((e) => QrLink.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      settingsRepository.setQrLinks(links);
    }
  }
}

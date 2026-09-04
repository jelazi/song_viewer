// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:song_viewer/model/qr_link.dart';
import 'package:song_viewer/model/user.dart';
import 'package:song_viewer/services/enums.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/hive_provider.dart';
import '../providers/pocketbase_provider.dart';

class SettingsRepository {
  HiveProvider hiveProvider;
  PocketBaseProvider pocketBaseProvider;
  bool isLargeScreen = false;
  double _previewFontTextSize = 20;
  double _previewFontChordSize = 20;
  double _editFontTextSize = 20;
  double _editFontChordSize = 20;
  Color _previewColorText = Colors.black;
  Color _previewColorChord = Colors.red;
  Color _editColorText = Colors.black;
  Color _editColorChord = Colors.red;
  bool _isEditIconVisible = true;
  bool _autoHideTopBar = false;
  bool _superuserMode = false;
  bool _twoColumns = false;
  User _currentUser = User.empty();
  String version = '';
  String buildNumber = '';
  TypeClickCard _typeClickCard = TypeClickCard.none;

  // Presentation settings
  int _presentationScreenIndex = 0;
  int _presentationLinesPerPage = 8;
  double _presentationFontSize = 36.0;
  Color _presentationFontColor = const Color(0xFFFFFFFF);
  bool _presentationShowChords = false;
  bool _presentationBlackFirstPage = true;
  bool _presentationBlackLastPage = true;
  bool _presentationShowPageNumber = true;
  bool _presentationShowTitle = true;
  bool _presentationAutoPageByParagraphs = false;

  // Local web server (desktop only)
  bool _localWebEnabled = false;
  int _localWebPort = 8080;

  // QR code URLs — dynamic list
  List<QrLink> _qrLinks = QrLink.defaults;

  // AI enrichment API keys
  String _groqApiKey = '';
  String _youtubeApiKey = '';
  String _geminiApiKey = '';

  SettingsRepository({
    required this.hiveProvider,
    required this.pocketBaseProvider,
  });

  void getInfoApp() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    version = packageInfo.version;
    buildNumber = packageInfo.buildNumber;
  }

  bool get twoColumns {
    return _twoColumns;
  }

  double get previewFontTextSize {
    return _previewFontTextSize;
  }

  double get previewFontChordSize {
    return _previewFontChordSize;
  }

  double get editFontTextSize {
    return _editFontTextSize;
  }

  double get editFontChordSize {
    return _editFontChordSize;
  }

  Color get previewColorText {
    return _previewColorText;
  }

  Color get previewColorChord {
    return _previewColorChord;
  }

  Color get editColorText {
    return _editColorText;
  }

  Color get editColorChord {
    return _editColorChord;
  }

  bool get isEditIconVisible {
    return _isEditIconVisible;
  }

  bool get autoHideTopBar {
    return _autoHideTopBar;
  }

  bool get superuserMode {
    return _superuserMode;
  }

  User get currentUser {
    return _currentUser;
  }

  TypeClickCard get typeClickCard {
    return _typeClickCard;
  }

  bool get localWebEnabled {
    return _localWebEnabled;
  }

  int get localWebPort {
    return _localWebPort;
  }

  int get presentationScreenIndex => _presentationScreenIndex;
  int get presentationLinesPerPage => _presentationLinesPerPage;
  double get presentationFontSize => _presentationFontSize;
  Color get presentationFontColor => _presentationFontColor;
  bool get presentationShowChords => _presentationShowChords;
  bool get presentationBlackFirstPage => _presentationBlackFirstPage;
  bool get presentationBlackLastPage => _presentationBlackLastPage;
  bool get presentationShowPageNumber => _presentationShowPageNumber;
  bool get presentationShowTitle => _presentationShowTitle;
  bool get presentationAutoPageByParagraphs => _presentationAutoPageByParagraphs;

  List<QrLink> get qrLinks => List.unmodifiable(_qrLinks);

  String get groqApiKey => _groqApiKey;
  String get youtubeApiKey => _youtubeApiKey;
  String get geminiApiKey => _geminiApiKey;

  Future<void> loadLocalSettings() async {
    _previewFontTextSize = await hiveProvider.getSettingsValue('previewFontTextSize') ?? 20;
    _previewFontChordSize = await hiveProvider.getSettingsValue('previewFontChordSize') ?? 20;
    _editFontTextSize = await hiveProvider.getSettingsValue('editFontTextSize') ?? 20;
    _editFontChordSize = await hiveProvider.getSettingsValue('editFontChordSize') ?? 20;
    _previewColorText = Color(await hiveProvider.getSettingsValue('previewColorText') ?? Colors.black.toARGB32());
    _previewColorChord = Color(await hiveProvider.getSettingsValue('previewColorChord') ?? Colors.red.toARGB32());
    _editColorText = Color(await hiveProvider.getSettingsValue('editColorText') ?? Colors.black.toARGB32());
    _editColorChord = Color(await hiveProvider.getSettingsValue('editColorChord') ?? Colors.red.toARGB32());
    _isEditIconVisible = await hiveProvider.getSettingsValue('isEditIconVisible') ?? true;
    _autoHideTopBar = await hiveProvider.getSettingsValue('autoHideTopBar') ?? false;
    _superuserMode = await hiveProvider.getSettingsValue('superuserMode') ?? false;
    _currentUser = await hiveProvider.getSettingsValue('currentUser') ?? User.empty();
    _typeClickCard = await hiveProvider.getSettingsValue('typeClickCard') ?? TypeClickCard.none;
    _twoColumns = await hiveProvider.getSettingsValue('twoColumns') ?? false;
    _localWebEnabled = await hiveProvider.getSettingsValue('localWebEnabled') ?? false;
    _localWebPort = await hiveProvider.getSettingsValue('localWebPort') ?? 8080;

    // Presentation settings
    _presentationScreenIndex = await hiveProvider.getSettingsValue('presentationScreenIndex') ?? 0;
    _presentationLinesPerPage = await hiveProvider.getSettingsValue('presentationLinesPerPage') ?? 8;
    _presentationFontSize = (await hiveProvider.getSettingsValue('presentationFontSize') ?? 36.0).toDouble();
    final fontColorValue = await hiveProvider.getSettingsValue('presentationFontColor');
    _presentationFontColor = fontColorValue != null ? Color(fontColorValue) : const Color(0xFFFFFFFF);
    _presentationShowChords = await hiveProvider.getSettingsValue('presentationShowChords') ?? false;
    _presentationBlackFirstPage = await hiveProvider.getSettingsValue('presentationBlackFirstPage') ?? true;
    _presentationBlackLastPage = await hiveProvider.getSettingsValue('presentationBlackLastPage') ?? true;
    _presentationShowPageNumber = await hiveProvider.getSettingsValue('presentationShowPageNumber') ?? true;
    _presentationShowTitle = await hiveProvider.getSettingsValue('presentationShowTitle') ?? true;
    _presentationAutoPageByParagraphs = await hiveProvider.getSettingsValue('presentationAutoPageByParagraphs') ?? false;

    // QR code URLs — dynamic list
    final qrLinksJson = await hiveProvider.getSettingsValue('qrLinks');
    if (qrLinksJson != null && qrLinksJson is String) {
      try {
        final decoded = jsonDecode(qrLinksJson) as List;
        _qrLinks = decoded.map((e) => QrLink.fromJson(Map<String, dynamic>.from(e as Map))).toList();
      } catch (_) {
        _qrLinks = QrLink.defaults;
      }
    } else {
      // Migrate from old individual keys
      final oldCurrent = await hiveProvider.getSettingsValue('qrCurrentSongUrl');
      final oldWebApp = await hiveProvider.getSettingsValue('qrWebAppUrl');
      final oldZizkovi = await hiveProvider.getSettingsValue('qrZizkoviUrl');
      if (oldCurrent != null || oldWebApp != null || oldZizkovi != null) {
        _qrLinks = [
          QrLink(label: 'Current Song', url: oldCurrent ?? ''),
          QrLink(label: 'Web App', url: oldWebApp ?? 'https://songsviewerweb.web.app/'),
          QrLink(label: 'Žižkovi', url: oldZizkovi ?? 'https://www.zizkovi.online/'),
        ];
        _saveQrLinksToHive();
      } else {
        _qrLinks = QrLink.defaults;
      }
    }

    // Try loading QR links from PocketBase (overrides local if available)
    try {
      final serverLinks = await pocketBaseProvider.getQrLinks();
      if (serverLinks != null && serverLinks.isNotEmpty) {
        _qrLinks = serverLinks;
        _saveQrLinksToHive();
      } else {
        // No links on server — push local to PocketBase
        await pocketBaseProvider.setQrLinks(_qrLinks);
      }
    } catch (_) {
      // PocketBase unavailable, use local
    }

    // AI enrichment API keys
    _groqApiKey = await hiveProvider.getSettingsValue('groqApiKey') ?? '';
    _youtubeApiKey = await hiveProvider.getSettingsValue('youtubeApiKey') ?? '';
    _geminiApiKey = await hiveProvider.getSettingsValue('geminiApiKey') ?? '';
  }

  void setCurrentUser(User user) {
    _currentUser = user;
    hiveProvider.setSettingsValue('currentUser', user);
  }

  void changeTypeClickCard(TypeClickCard typeClickCard) {
    _typeClickCard = typeClickCard;
    hiveProvider.setSettingsValue('typeClickCard', typeClickCard);
  }

  void changeSettingsValue(String typeValue, dynamic value) {
    switch (typeValue) {
      case 'previewFontTextSize':
        {
          _previewFontTextSize = value;
          hiveProvider.setSettingsValue('previewFontTextSize', value);
          break;
        }

      case 'previewFontChordSize':
        {
          _previewFontChordSize = value;
          hiveProvider.setSettingsValue('previewFontChordSize', value);
          break;
        }
      case 'editFontTextSize':
        {
          _previewFontTextSize = value;
          hiveProvider.setSettingsValue('editFontTextSize', value);
          break;
        }

      case 'editFontChordSize':
        {
          _previewFontChordSize = value;
          hiveProvider.setSettingsValue('editFontChordSize', value);
          break;
        }
      case 'previewColorText':
        {
          _previewColorText = value;
          hiveProvider.setSettingsValue('previewColorText', value.value);
          break;
        }
      case 'previewColorChord':
        {
          _previewColorChord = value;
          hiveProvider.setSettingsValue('previewColorChord', value.value);
          break;
        }
      case 'editColorText':
        {
          _previewColorText = value;
          hiveProvider.setSettingsValue('editColorText', value.value);
          break;
        }
      case 'editColorChord':
        {
          _previewColorChord = value;
          hiveProvider.setSettingsValue('editColorChord', value.value);
          break;
        }
      case 'isEditIconVisible':
        {
          _isEditIconVisible = value;
          hiveProvider.setSettingsValue('isEditIconVisible', value);
          break;
        }
      case 'autoHideTopBar':
        {
          _autoHideTopBar = value;
          hiveProvider.setSettingsValue('autoHideTopBar', value);
          break;
        }
      case 'superuserMode':
        {
          _superuserMode = value;
          hiveProvider.setSettingsValue('superuserMode', value);
          break;
        }
      case 'currentUser':
        {
          _currentUser = value;
          hiveProvider.setSettingsValue('currentUser', value);
          break;
        }
      case 'typeClickCard':
        {
          _typeClickCard = value;
          hiveProvider.setSettingsValue('typeClickCard', value);
          break;
        }
      case 'twoColumns':
        {
          _twoColumns = value;
          hiveProvider.setSettingsValue('twoColumns', value);
          break;
        }
      case 'localWebEnabled':
        {
          _localWebEnabled = value;
          hiveProvider.setSettingsValue('localWebEnabled', value);
          break;
        }
      case 'localWebPort':
        {
          _localWebPort = value;
          hiveProvider.setSettingsValue('localWebPort', value);
          break;
        }
      case 'presentationScreenIndex':
        {
          _presentationScreenIndex = value;
          hiveProvider.setSettingsValue('presentationScreenIndex', value);
          break;
        }
      case 'presentationLinesPerPage':
        {
          _presentationLinesPerPage = value;
          hiveProvider.setSettingsValue('presentationLinesPerPage', value);
          break;
        }
      case 'presentationFontSize':
        {
          _presentationFontSize = value;
          hiveProvider.setSettingsValue('presentationFontSize', value);
          break;
        }
      case 'presentationFontColor':
        {
          _presentationFontColor = value;
          hiveProvider.setSettingsValue('presentationFontColor', (value as Color).toARGB32());
          break;
        }
      case 'presentationShowChords':
        {
          _presentationShowChords = value;
          hiveProvider.setSettingsValue('presentationShowChords', value);
          break;
        }
      case 'presentationBlackFirstPage':
        {
          _presentationBlackFirstPage = value;
          hiveProvider.setSettingsValue('presentationBlackFirstPage', value);
          break;
        }
      case 'presentationBlackLastPage':
        {
          _presentationBlackLastPage = value;
          hiveProvider.setSettingsValue('presentationBlackLastPage', value);
          break;
        }
      case 'presentationShowPageNumber':
        {
          _presentationShowPageNumber = value;
          hiveProvider.setSettingsValue('presentationShowPageNumber', value);
          break;
        }
      case 'presentationShowTitle':
        {
          _presentationShowTitle = value;
          hiveProvider.setSettingsValue('presentationShowTitle', value);
          break;
        }
      case 'presentationAutoPageByParagraphs':
        {
          _presentationAutoPageByParagraphs = value;
          hiveProvider.setSettingsValue('presentationAutoPageByParagraphs', value);
          break;
        }
      case 'groqApiKey':
        {
          _groqApiKey = value;
          hiveProvider.setSettingsValue('groqApiKey', value);
          break;
        }
      case 'youtubeApiKey':
        {
          _youtubeApiKey = value;
          hiveProvider.setSettingsValue('youtubeApiKey', value);
          break;
        }
      case 'geminiApiKey':
        {
          _geminiApiKey = value;
          hiveProvider.setSettingsValue('geminiApiKey', value);
          break;
        }
    }
  }

  // ---------------------------------------------------------------------------
  // QR link CRUD
  // ---------------------------------------------------------------------------

  void addQrLink(QrLink link) {
    _qrLinks = [..._qrLinks, link];
    _saveQrLinksToHive();
    pocketBaseProvider.setQrLinks(_qrLinks);
  }

  void updateQrLink(int index, QrLink link) {
    if (index < 0 || index >= _qrLinks.length) return;
    final updated = [..._qrLinks];
    updated[index] = link;
    _qrLinks = updated;
    _saveQrLinksToHive();
    pocketBaseProvider.setQrLinks(_qrLinks);
  }

  void removeQrLink(int index) {
    if (index < 0 || index >= _qrLinks.length) return;
    final updated = [..._qrLinks];
    updated.removeAt(index);
    _qrLinks = updated;
    _saveQrLinksToHive();
    pocketBaseProvider.setQrLinks(_qrLinks);
  }

  void setQrLinks(List<QrLink> links) {
    _qrLinks = links;
    _saveQrLinksToHive();
  }

  void _saveQrLinksToHive() {
    final json = jsonEncode(_qrLinks.map((e) => e.toJson()).toList());
    hiveProvider.setSettingsValue('qrLinks', json);
  }
}

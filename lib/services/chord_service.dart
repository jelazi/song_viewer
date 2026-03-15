import 'package:logger_pkg/logger_pkg.dart';

import '../model/chord/chord_diagram.dart';
import '../model/chord/chords_positions.dart';
import '../model/song/song.dart';
import '../providers/hive_provider.dart';
import '../providers/pocketbase_provider.dart';

/// Resolves chord fingering positions using a fallback chain:
/// 1. Song-level overrides (song.chordOverrides)
/// 2. PocketBase chord_diagrams collection (default library)
/// 3. Hardcoded ChordsPositions (built-in patterns)
/// 4. Empty list (nothing to display)
///
/// Uses Hive as primary cache, syncs with PocketBase when server data is newer.
class ChordService {
  final PocketBaseProvider _pocketBaseProvider;
  final HiveProvider _hiveProvider;

  /// In-memory cache of chord diagrams.
  Map<String, List<String>> _pbChordCache = {};
  bool _cacheLoaded = false;

  ChordService(this._pocketBaseProvider, this._hiveProvider);

  /// Load chord diagrams from Hive cache. Returns true if cache had data.
  bool loadFromCache() {
    final cached = _hiveProvider.loadChordDiagramsCache();
    if (cached != null && cached.isNotEmpty) {
      _pbChordCache = cached;
      _cacheLoaded = true;
      logger.i('Loaded ${_pbChordCache.length} chord diagrams from Hive cache');
      return true;
    }
    return false;
  }

  /// Check if PocketBase has newer chord data than our Hive cache.
  Future<bool> isServerDataNewer() async {
    final localTimestamp = _hiveProvider.getChordDiagramsSyncTimestamp();
    if (localTimestamp == null || localTimestamp.isEmpty) {
      return true;
    }
    final serverTimestamp = await _pocketBaseProvider.getServerUpdatedTimestamp();
    if (serverTimestamp == null || serverTimestamp.isEmpty) {
      return false;
    }
    return localTimestamp != serverTimestamp;
  }

  /// Sync chord diagrams from PocketBase and save to Hive cache.
  Future<void> syncFromServer() async {
    try {
      final diagrams = await _pocketBaseProvider.getAllChordDiagrams();
      _pbChordCache = {
        for (final d in diagrams) d.name: d.positions,
      };
      _cacheLoaded = true;
      await _saveToCache();
      logger.i('Synced ${_pbChordCache.length} chord diagrams from PocketBase');
    } catch (e) {
      logger.e('Error syncing chord diagrams from PB: $e');
      _cacheLoaded = true;
    }
  }

  /// Save current in-memory chord diagrams to Hive with server timestamp.
  Future<void> _saveToCache() async {
    try {
      final serverTimestamp = await _pocketBaseProvider.getServerUpdatedTimestamp();
      final timestamp = serverTimestamp ?? DateTime.now().toUtc().toIso8601String();
      _hiveProvider.saveChordDiagramsCache(_pbChordCache, timestamp);
    } catch (e) {
      logger.e('Error saving chord diagrams to Hive: $e');
    }
  }

  /// Returns all known chord diagrams from cache.
  Map<String, List<String>> get pbChordCache => Map.unmodifiable(_pbChordCache);

  bool get isCacheLoaded => _cacheLoaded;

  /// Resolves chord positions for a given chord name and song.
  List<String> resolveChordPositions(String chordName, {Song? song}) {
    // 1. Song-level override
    if (song?.chordOverrides != null && song!.chordOverrides!.containsKey(chordName)) {
      final positions = song.chordOverrides![chordName]!;
      if (positions.isNotEmpty) return positions;
    }

    // 2. PocketBase / Hive chord library
    if (_pbChordCache.containsKey(chordName)) {
      final positions = _pbChordCache[chordName]!;
      if (positions.isNotEmpty) return positions;
    }

    // 3. Hardcoded fallback
    final hardcoded = ChordsPositions.getPositionsChordsByName(chordName);
    if (hardcoded.isNotEmpty) return hardcoded;

    // 4. Nothing
    return [];
  }

  /// Saves a chord diagram to PocketBase and updates both caches.
  Future<bool> saveChordDiagram(ChordDiagram diagram) async {
    final result = await _pocketBaseProvider.addOrUpdateChordDiagram(diagram);
    if (result) {
      _pbChordCache[diagram.name] = List.from(diagram.positions);
      await _saveToCache();
    }
    return result;
  }

  /// Seeds all hardcoded chord diagrams to PocketBase (only chords not already in PB).
  /// Runs only once — tracked by a Hive flag.
  Future<void> seedHardcodedChordsToPocketBase() async {
    if (_hiveProvider.isChordsSeedDone()) return;
    final allNames = ChordsPositions.getAllChordNames();
    int uploaded = 0;
    for (final name in allNames) {
      if (_pbChordCache.containsKey(name)) continue; // already in PB, skip
      final positions = ChordsPositions.getPositionsChordsByName(name);
      if (positions.isEmpty) continue;
      final diagram = ChordDiagram(name: name, positions: positions);
      final ok = await _pocketBaseProvider.addOrUpdateChordDiagram(diagram);
      if (ok) {
        _pbChordCache[name] = positions;
        uploaded++;
      }
    }
    _hiveProvider.setChordsSeedDone();
    await _saveToCache();
    logger.i('Seeded $uploaded hardcoded chord diagrams to PocketBase');
  }

  /// Removes a chord from PocketBase and updates both caches.
  Future<bool> deleteChordDiagram(String chordName) async {
    final result = await _pocketBaseProvider.deleteChordDiagram(chordName);
    if (result) {
      _pbChordCache.remove(chordName);
      await _saveToCache();
    }
    return result;
  }
}

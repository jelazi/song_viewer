import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../model/song/song.dart';
import '../../../../../services/constants.dart';

class BracketError {
  final Song song;
  final int lineNumber;
  final String lineText;
  final String errorDescription;

  BracketError({
    required this.song,
    required this.lineNumber,
    required this.lineText,
    required this.errorDescription,
  });
}

class BracketErrorScanner extends StatefulWidget {
  const BracketErrorScanner({super.key});

  @override
  State<BracketErrorScanner> createState() => _BracketErrorScannerState();
}

class _BracketErrorScannerState extends State<BracketErrorScanner> {
  List<BracketError> _errors = [];
  bool _hasScanned = false;
  bool _isScanning = false;

  /// Scans a single line of lyrics for bracket errors.
  /// Returns a list of error descriptions found in the line.
  List<String> _checkLineForBracketErrors(String line) {
    final errors = <String>[];
    int openBrackets = 0;
    int openCurly = 0;

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '[') {
        openBrackets++;
        if (openBrackets > 1) {
          errors.add('bracketDoubleOpen'.tr(args: [i.toString()]));
          openBrackets = 1; // reset to track next
        }
      } else if (char == ']') {
        if (openBrackets == 0) {
          errors.add('bracketCloseWithoutOpen'.tr(args: [i.toString()]));
        } else {
          openBrackets--;
        }
        // Check for consecutive closing brackets
        if (i + 1 < line.length && line[i + 1] == ']') {
          errors.add('bracketDoubleClose'.tr(args: [i.toString()]));
        }
      } else if (char == '{') {
        openCurly++;
        if (openCurly > 1) {
          errors.add('bracketDoubleCurlyOpen'.tr(args: [i.toString()]));
          openCurly = 1;
        }
      } else if (char == '}') {
        if (openCurly == 0) {
          errors.add('bracketCurlyCloseWithoutOpen'.tr(args: [i.toString()]));
        } else {
          openCurly--;
        }
      }
    }

    if (openBrackets > 0) {
      errors.add('bracketUnclosedSquare'.tr());
    }
    if (openCurly > 0) {
      errors.add('bracketUnclosedCurly'.tr());
    }

    return errors;
  }

  void _scanAllSongs() {
    setState(() {
      _isScanning = true;
      _errors = [];
    });

    final songs = context.read<HomePageBloc>().songsRepository.songs;

    for (final song in songs) {
      final lines = song.lyrics.split('\n');
      for (int i = 0; i < lines.length; i++) {
        final lineErrors = _checkLineForBracketErrors(lines[i]);
        for (final errorDesc in lineErrors) {
          _errors.add(BracketError(
            song: song,
            lineNumber: i + 1,
            lineText: lines[i],
            errorDescription: errorDesc,
          ));
        }
      }
      // Also check originalLyrics if present
      if (song.originalLyrics != null && song.originalLyrics!.isNotEmpty) {
        final origLines = song.originalLyrics!.split('\n');
        for (int i = 0; i < origLines.length; i++) {
          final lineErrors = _checkLineForBracketErrors(origLines[i]);
          for (final errorDesc in lineErrors) {
            _errors.add(BracketError(
              song: song,
              lineNumber: i + 1,
              lineText: origLines[i],
              errorDescription: '$errorDesc (originalLyrics)',
            ));
          }
        }
      }
    }

    setState(() {
      _isScanning = false;
      _hasScanned = true;
    });
  }

  /// Automatically fixes bracket errors in a song's lyrics by:
  /// - Removing duplicate consecutive brackets (e.g. `[[` -> `[`, `]]` -> `]`)
  /// - Removing orphaned closing brackets (no matching opener)
  /// - Removing orphaned opening brackets (no matching closer)
  String _fixBrackets(String lyrics) {
    final buffer = StringBuffer();
    final chars = lyrics.split('');

    for (int i = 0; i < chars.length; i++) {
      final char = chars[i];

      // Skip duplicate consecutive brackets
      if (i + 1 < chars.length) {
        if ((char == '[' && chars[i + 1] == '[') || (char == ']' && chars[i + 1] == ']') || (char == '{' && chars[i + 1] == '{') || (char == '}' && chars[i + 1] == '}')) {
          continue; // skip this one, next iteration will pick the second
        }
      }

      buffer.write(char);
    }

    // Now validate bracket pairing line by line
    String result = buffer.toString();
    final lines = result.split('\n');
    final fixedLines = <String>[];

    for (final line in lines) {
      fixedLines.add(_fixLineBrackets(line));
    }

    return fixedLines.join('\n');
  }

  String _fixLineBrackets(String line) {
    // Pass 1: Remove orphaned ] (closing without opening)
    final pass1 = StringBuffer();
    int openCount = 0;
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '[') {
        openCount++;
        pass1.write(char);
      } else if (char == ']') {
        if (openCount > 0) {
          openCount--;
          pass1.write(char);
        }
        // else skip orphaned ]
      } else {
        pass1.write(char);
      }
    }

    // Pass 2: Remove orphaned [ (opening without closing) - scan from end
    final str = pass1.toString();
    final pass2 = StringBuffer();
    int closeCount = 0;
    for (int i = str.length - 1; i >= 0; i--) {
      final char = str[i];
      if (char == ']') {
        closeCount++;
        pass2.write(char);
      } else if (char == '[') {
        if (closeCount > 0) {
          closeCount--;
          pass2.write(char);
        }
        // else skip orphaned [
      } else {
        pass2.write(char);
      }
    }

    // Reverse since we built it backwards
    return pass2.toString().split('').reversed.join('');
  }

  void _fixSong(BracketError error) {
    final song = error.song;
    final fixedLyrics = _fixBrackets(song.lyrics);
    String? fixedOriginalLyrics;
    if (song.originalLyrics != null && song.originalLyrics!.isNotEmpty) {
      fixedOriginalLyrics = _fixBrackets(song.originalLyrics!);
    }

    final updatedSong = song.copyWith(
      lyrics: fixedLyrics,
      originalLyrics: fixedOriginalLyrics ?? song.originalLyrics,
    );

    context.read<HomePageBloc>().add(UpdateSong(song: updatedSong));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('fixedSong'.tr(args: [song.title])),
        duration: const Duration(seconds: 2),
      ),
    );

    // Re-scan to update the list
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scanAllSongs();
    });
  }

  void _fixAllErrors() {
    final songsToFix = <String, Song>{};
    for (final error in _errors) {
      songsToFix[error.song.id] = error.song;
    }

    for (final song in songsToFix.values) {
      final fixedLyrics = _fixBrackets(song.lyrics);
      String? fixedOriginalLyrics;
      if (song.originalLyrics != null && song.originalLyrics!.isNotEmpty) {
        fixedOriginalLyrics = _fixBrackets(song.originalLyrics!);
      }

      final updatedSong = song.copyWith(
        lyrics: fixedLyrics,
        originalLyrics: fixedOriginalLyrics ?? song.originalLyrics,
      );

      context.read<HomePageBloc>().add(UpdateSong(song: updatedSong));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('fixedNSongs'.tr(args: [songsToFix.length.toString()])),
        duration: const Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _scanAllSongs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanAllSongs,
                icon: _isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 18),
                label: Text('bracketScan'.tr()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
              const SizedBox(width: 16),
              if (_hasScanned)
                Text(
                  _errors.isEmpty ? 'bracketNoErrors'.tr() : '${'bracketFoundErrors'.tr()}: ${_errors.length}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _errors.isEmpty ? Colors.green : Colors.red,
                  ),
                ),
              const Spacer(),
              if (_hasScanned && _errors.isNotEmpty)
                ElevatedButton.icon(
                  onPressed: _fixAllErrors,
                  icon: const Icon(Icons.auto_fix_high, size: 18),
                  label: Text('bracketFixAll'.tr()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
            ],
          ),
          if (_hasScanned && _errors.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 500),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _errors.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final error = _errors[index];
                  return _buildErrorTile(error);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorTile(BracketError error) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${error.song.title}${error.song.interpret != null && error.song.interpret!.isNotEmpty ? ' - ${error.song.interpret}' : ''}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '${'bracketLine'.tr()} ${error.lineNumber}: ${error.errorDescription}',
                  style: const TextStyle(fontSize: 12, color: Colors.red),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    error.lineText,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _fixSong(error),
            icon: const Icon(Icons.auto_fix_high, size: 18),
            tooltip: 'bracketFix'.tr(),
            color: Colors.orange,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}

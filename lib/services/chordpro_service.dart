import '../model/song/song.dart';
import 'enums.dart';

/// Import of songs written in the [ChordPro](https://www.chordpro.org/) format.
///
/// The conversion is cheap because the app's own lyric markup already uses
/// inline `[Chord]` exactly like ChordPro does. Two things do *not* line up and
/// are the whole reason this service exists:
///
///  * **Braces.** ChordPro spends `{...}` on directives; the app spends it on
///    *notes* (`SongLine.createItemsFromString`). A directive passed through
///    verbatim would be rendered as a note, so every brace is either consumed
///    as a directive here or dropped from the lyric text. None may survive.
///  * **Chord naming.** ChordPro is international (`A#`, `B`), which in this
///    app is [TypeTranspose.german]. The model defaults to
///    [TypeTranspose.czech] (`B`, `H`), where the same `B` means a different
///    pitch — so an imported song that kept the default would transpose wrong.
///
/// The parser never throws. Anything it cannot map is reported through
/// [ChordProImportResult.warnings] rather than being dropped in silence.
class ChordProService {
  const ChordProService({
    this.chorusLabel = 'R:',
    this.bridgeLabel = 'B:',
  });

  /// Label written in place of `{start_of_chorus}` when the directive carries
  /// no label of its own. The caller passes a translated string.
  final String chorusLabel;

  /// Same as [chorusLabel], for `{start_of_bridge}`.
  final String bridgeLabel;

  /// Extensions offered in the file picker. `.txt` is included because plenty
  /// of ChordPro in the wild is distributed under it.
  static const List<String> supportedExtensions = ['cho', 'chopro', 'chordpro', 'crd', 'pro', 'txt'];

  /// Directives that are understood but have no home in [Song]. They are
  /// collected per song and reported once, so the user knows what was lost
  /// instead of wondering later.
  static const List<String> _unmappedMeta = [
    'key',
    'capo',
    'duration',
    'year',
    'album',
    'copyright',
    'ccli',
    'meta',
  ];

  /// Layout-only directives with no meaning outside a printed sheet. Dropping
  /// these is correct, not a loss, so they produce no warning.
  static const List<String> _ignoredLayout = [
    'columns',
    'column_break',
    'colb',
    'cb',
    'new_page',
    'np',
    'new_physical_page',
    'npp',
    'pagetype',
    'titles',
    'grid',
    'g',
    'no_grid',
    'ng',
    'textfont',
    'textsize',
    'textcolour',
    'textcolor',
    'chordfont',
    'chordsize',
    'chordcolour',
    'chordcolor',
    'tabfont',
    'tabsize',
    'zoom',
  ];

  static final RegExp _directive = RegExp(r'^\s*\{\s*([a-zA-Z_][a-zA-Z0-9_-]*)\s*(?::\s*(.*?))?\s*\}\s*$');
  static final RegExp _blankRun = RegExp(r'\n{3,}');

  /// Parses one file's [content].
  ///
  /// [fallbackTitle] is used for songs with no `{title}` directive — pass the
  /// file name without its extension.
  ChordProImportResult parse(String content, {String fallbackTitle = ''}) {
    final drafts = <_SongDraft>[];
    var draft = _SongDraft();
    var inTab = false;

    for (final rawLine in content.replaceAll('\r\n', '\n').replaceAll('\r', '\n').split('\n')) {
      // `#` at the start of a line is a ChordPro source comment, never content.
      if (rawLine.trimLeft().startsWith('#')) continue;

      final match = _directive.firstMatch(rawLine);
      if (match == null) {
        draft.body.add(_sanitize(rawLine, draft));
        continue;
      }

      final name = match.group(1)!.toLowerCase().replaceAll('-', '_');
      final value = match.group(2)?.trim() ?? '';

      // Inside a tab block only the terminator is a directive; everything else
      // is ASCII art that happens to look like one.
      if (inTab && name != 'end_of_tab' && name != 'eot') {
        draft.body.add(_sanitize(rawLine, draft));
        continue;
      }

      // A `{title}` on an already-started song means the file concatenates
      // several songs without the standard `{new_song}` separator, which is
      // common in shared collections.
      final startsNewSong = name == 'new_song' || name == 'ns' || ((name == 'title' || name == 't') && draft.hasContent);
      if (startsNewSong) {
        drafts.add(draft);
        draft = _SongDraft();
        if (name == 'new_song' || name == 'ns') continue;
      }

      inTab = _applyDirective(name, value, draft, inTab);
    }
    drafts.add(draft);

    final songs = <Song>[];
    final warnings = <String>[];
    var skipped = 0;
    var untitled = 0;

    for (final d in drafts) {
      if (!d.hasContent) {
        if (d.touched) skipped++;
        continue;
      }
      untitled += d.title.isEmpty ? 1 : 0;
      songs.add(d.toSong(fallbackTitle, untitled));
      warnings.addAll(d.warnings(fallbackTitle));
    }

    return ChordProImportResult(songs: songs, warnings: warnings, skipped: skipped);
  }

  /// Applies one directive to [draft]. Returns the new "inside a tab" state.
  bool _applyDirective(String name, String value, _SongDraft draft, bool inTab) {
    draft.touched = true;
    switch (name) {
      case 'title':
      case 't':
        if (draft.title.isEmpty) draft.title = value;
        break;
      case 'artist':
      case 'composer':
      case 'lyricist':
        // An explicit artist outranks a subtitle guess.
        if (draft.interpret.isEmpty || draft.interpretFromSubtitle) {
          draft.interpret = value;
          draft.interpretFromSubtitle = false;
        }
        break;
      case 'subtitle':
      case 'st':
        if (draft.interpret.isEmpty) {
          draft.interpret = value;
          draft.interpretFromSubtitle = true;
        }
        break;
      case 'tempo':
        final bpm = int.tryParse(value.split(RegExp(r'\D')).firstWhere((e) => e.isNotEmpty, orElse: () => ''));
        if (bpm != null) draft.bmp = bpm;
        break;
      case 'time':
        final beats = int.tryParse(value.split('/').first.trim());
        if (beats != null) draft.songBar = beats;
        break;
      case 'comment':
      case 'c':
      case 'comment_italic':
      case 'ci':
      case 'comment_box':
      case 'cb':
      case 'highlight':
        // A comment is text the author wants seen, so it becomes a lyric line.
        if (value.isNotEmpty) draft.body.add(_sanitize(value, draft));
        break;
      case 'start_of_chorus':
      case 'soc':
        draft.body.add(value.isNotEmpty ? _sanitize(value, draft) : chorusLabel);
        break;
      case 'start_of_bridge':
      case 'sob':
        draft.body.add(value.isNotEmpty ? _sanitize(value, draft) : bridgeLabel);
        break;
      case 'start_of_verse':
      case 'sov':
      case 'start_of_part':
      case 'sop':
        // Verses need no label; a named one is worth keeping.
        if (value.isNotEmpty) draft.body.add(_sanitize(value, draft));
        break;
      case 'start_of_tab':
      case 'sot':
        if (value.isNotEmpty) draft.body.add(_sanitize(value, draft));
        return true;
      case 'end_of_tab':
      case 'eot':
        draft.body.add('');
        return false;
      case 'end_of_chorus':
      case 'eoc':
      case 'end_of_verse':
      case 'eov':
      case 'end_of_bridge':
      case 'eob':
      case 'end_of_part':
      case 'eop':
        draft.body.add('');
        break;
      case 'define':
      case 'chord':
        // Deliberately not mapped: this app stores fingerings in its own
        // position-string format, and guessing the translation would write
        // silently wrong chord diagrams into the song. Better reported.
        draft.sawChordDefinition = true;
        break;
      default:
        if (_unmappedMeta.contains(name)) {
          draft.unmappedMeta.add(value.isEmpty ? name : '$name: $value');
        } else if (!_ignoredLayout.contains(name) && !name.startsWith('x_')) {
          draft.unknownDirectives.add(name);
        }
        break;
    }
    return inTab;
  }

  /// Strips every character that the app's own markup would misread.
  ///
  /// Braces become notes and unbalanced brackets desynchronise the chord
  /// parser, so neither may reach [Song.lyrics]. ChordPro backslash escapes are
  /// resolved first — an escaped brace is still a brace, and still has to go.
  String _sanitize(String raw, _SongDraft draft) {
    final out = StringBuffer();
    var openBracket = false;

    for (var i = 0; i < raw.length; i++) {
      final ch = raw[i];

      if (ch == r'\' && i + 1 < raw.length) {
        final next = raw[i + 1];
        if (next == r'\') {
          out.write(r'\');
          i++;
          continue;
        }
        if (next == '[' || next == ']' || next == '{' || next == '}') {
          draft.droppedMarkup = true;
          i++;
          continue;
        }
      }

      if (ch == '[') {
        if (openBracket) {
          draft.unbalanced = true;
          continue;
        }
        openBracket = true;
        out.write(ch);
        continue;
      }
      if (ch == ']') {
        if (!openBracket) {
          draft.unbalanced = true;
          continue;
        }
        openBracket = false;
        out.write(ch);
        continue;
      }
      if (ch == '{' || ch == '}') {
        draft.droppedMarkup = true;
        continue;
      }
      out.write(ch);
    }

    // A chord left hanging open would swallow the rest of the line.
    if (openBracket) {
      draft.unbalanced = true;
      out.write(']');
    }
    return out.toString();
  }

  static String _tidyBody(List<String> body) {
    return body.join('\n').replaceAll(_blankRun, '\n\n').trim();
  }
}

/// What one [ChordProService.parse] call produced.
class ChordProImportResult {
  const ChordProImportResult({
    this.songs = const [],
    this.warnings = const [],
    this.skipped = 0,
  });

  /// Parsed songs, each with a generated id, ready to be stored.
  final List<Song> songs;

  /// Human-readable notes about anything that could not be mapped.
  final List<String> warnings;

  /// Blocks that held directives but no lyrics, so no song was made.
  final int skipped;

  bool get isEmpty => songs.isEmpty;
}

/// One song under construction.
class _SongDraft {
  final List<String> body = [];
  final Set<String> unknownDirectives = {};
  final List<String> unmappedMeta = [];

  String title = '';
  String interpret = '';
  bool interpretFromSubtitle = false;
  int? bmp;
  int? songBar;

  /// Any directive at all was seen — used to tell an empty tail block apart
  /// from a real song that turned out to have no lyrics.
  bool touched = false;
  bool droppedMarkup = false;
  bool unbalanced = false;
  bool sawChordDefinition = false;

  bool get hasContent => body.any((l) => l.trim().isNotEmpty);

  Song toSong(String fallbackTitle, int untitledIndex) {
    final resolvedTitle = title.isNotEmpty
        ? title
        : untitledIndex > 1
            ? '$fallbackTitle ($untitledIndex)'
            : fallbackTitle;

    final song = Song(
      id: '',
      title: resolvedTitle,
      lyrics: ChordProService._tidyBody(body),
      interpret: interpret.isEmpty ? null : interpret,
      // ChordPro names chords internationally — see the class doc.
      typeTranspose: TypeTranspose.german,
      bmp: bmp,
      songBar: songBar,
      sheets: [],
      groups: [],
      tags: [],
      notes: [],
      youtubeVideos: [],
      chordOverrides: {},
    );
    song.generateId();
    return song;
  }

  List<String> warnings(String fallbackTitle) {
    final label = title.isNotEmpty ? title : fallbackTitle;
    final result = <String>[];
    if (sawChordDefinition) {
      result.add('$label: chord definitions ({define}) were not imported');
    }
    if (unmappedMeta.isNotEmpty) {
      result.add('$label: not stored — ${unmappedMeta.join(', ')}');
    }
    if (unknownDirectives.isNotEmpty) {
      result.add('$label: unknown directives ignored — ${unknownDirectives.join(', ')}');
    }
    if (droppedMarkup) {
      result.add('$label: braces removed from the lyrics (reserved for notes)');
    }
    if (unbalanced) {
      result.add('$label: unbalanced [ ] repaired');
    }
    return result;
  }
}

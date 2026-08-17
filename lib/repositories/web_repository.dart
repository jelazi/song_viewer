// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:async';
import 'dart:io';

import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:collection/collection.dart';
import 'package:default_project/services/auxiliary_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../model/web_interpret.dart';
import '../model/web_item.dart';
import '../model/web_song.dart';
import '../providers/web_provider.dart';
import '../services/enums.dart';

class WebChord {
  String text;
  int beforeSpaces = 0;

  WebChord({required this.text, this.beforeSpaces = 0});
}

extension InsertString on String {
  String insert(int index, String string) => replaceRange(index, index, string);
}

class WebRepository {
  WebProvider webProvider;
  Map<String, String> allInterpretersPisnickyAkordy = {};

  WebRepository({
    required this.webProvider,
  });

  Future<String> testGetSong() async {
    try {
      // Step 1: Raw MeiliSearch response
      String info = '';
      try {
        final rawResponse = await webProvider.searchPisnickyAkordy('kámen');
        info += 'HTTP ${rawResponse.statusCode} | type=${rawResponse.data.runtimeType} | ';
        if (rawResponse.data is Map) {
          final data = rawResponse.data as Map;
          info += 'keys=${data.keys} | ';
          final hits = data['hits'];
          info += 'hitsType=${hits.runtimeType} | ';
          if (hits is List) {
            info += 'count=${hits.length} | ';
            for (int i = 0; i < hits.length && i < 2; i++) {
              final hit = hits[i] as Map;
              info += 'hit$i:{${hit.keys}:${hit.values}} | ';
            }
          }
        } else {
          info += 'data=${rawResponse.data.toString().substring(0, 100)} | ';
        }
      } catch (e) {
        info += 'MeiliSearch FAILED: $e | ';
      }

      // Step 2: Parsed songs
      try {
        final songs = await findSongsPisnickyAkordy('kámen');
        info += 'parsed=${songs.length} songs | ';
        for (int i = 0; i < songs.length && i < 2; i++) {
          final s = songs[i];
          info += 'song$i: title="${s.title}" ref="${s.ref}" interpret="${s.interpret}" | ';
          if (s.lyric.isEmpty) {
            final lyric = await getTextSongPisnickyAkordy(s.ref);
            info += 'lyrics_len=${lyric.length} | ';
          }
        }
      } catch (e) {
        info += 'parse FAILED: $e | ';
      }
      debugPrint('[PA_TEST] $info');
    } catch (e) {
      debugPrint('[PA_TEST] FATAL: $e');
    }
    return '';
  }

  void _dp(String msg) {
    debugPrint('[PA_TEST] $msg');
  }

  Future<List<WebSong>> findSongByInterpretFromVelkyZpevnik(WebInterpret interpret) async {
    List<WebSong> songs = [];
    try {
      final response = await webProvider.getDataVelkyZpevnik(interpret.ref);
      if (response.statusCode != 200) {
        logger.e('error status Code ${response.statusCode}');
        return songs;
      }
      final parsedSongs = parseSongsByInterpretFromVelkyZpevnik(response.data);
      if (parsedSongs.isNotEmpty) {
        for (MapEntry<String, String> entry in parsedSongs.entries) {
          String title = entry.key;

          songs.add(WebSong(interpret: interpret.title, title: title, ref: entry.value, ischords: true, server: 'velkyzpevnik.cz'));
        }
      }
    } catch (e) {
      logger.e('error: $e');
    }

    return songs;
  }

  Map<String, String> parseSongsByInterpretFromVelkyZpevnik(String htmlText) {
    Map<String, String> map = {};
    BeautifulSoup bs = BeautifulSoup(htmlText);
    final songs = bs.find('*', class_: 'songs');
    if (songs != null) {
      for (Bs4Element element in songs.contents) {
        if (element.className == 'song show-upon-scroll') {
          String ref = element.attributes['href'] ?? '';
          String title = element.strippedStrings;
          if (title.isNotEmpty && ref.isNotEmpty) {
            map[title] = ref;
          }
        }
      }
    }

    return map;
  }

  Future<List<WebItem>> findSongAndInterpretsFromVelkyZpevnik(String searchText) async {
    List<WebItem> items = [];
    final responseItem = await webProvider.searchVelkyZpevnik(searchText);
    if (responseItem.statusCode != 200) {
      logger.e('error status Code ${responseItem.statusCode}');
      return items;
    }
    if (responseItem.data == null) {
      logger.e('error data is null');
      return items;
    }
    try {
      if (responseItem.data is List) {
        for (Map<String, dynamic> item in responseItem.data) {
          if (item.containsKey('type')) {
            if (item['type'] == 'interpret') {
              items.add(WebInterpret(title: item['name'], ref: item['url']));
            } else if (item['type'] == 'song') {
              items.add(WebSong(title: item['name'], ref: item['url'], interpret: item['interpret'], server: 'velkyzpevnik.cz'));
            }
          }
        }
      }
    } catch (e) {
      logger.e('error: $e');
    }
    return items;
  }

  Future<String> getTextSongPisnickyAkordy(String song) async {
    try {
      final response = await webProvider.getDataFromPisnickyAkordy(song);
      debugPrint('[PA_FETCH] song=$song status=${response.statusCode}');
      if (response.statusCode != 200) {
        debugPrint('[PA_FETCH] FAIL HTTP ${response.statusCode}');
        return '';
      }
      if (response.data == null || response.data.toString().isEmpty) {
        debugPrint('[PA_FETCH] FAIL empty response');
        return '';
      }
      final html = response.data.toString();
      final hasSongText = html.contains('songtext');
      debugPrint('[PA_FETCH] hasSongtext=$hasSongText htmlLen=${html.length}');
      debugPrint('[PA_FETCH] html=${html.substring(0, html.length > 400 ? 400 : html.length)}');
      if (!hasSongText) {
        debugPrint('[PA_FETCH] FAIL songtext not found in HTML');
        return '';
      }
      final songText = parseTextFromPisnickyAkordy(html);
      debugPrint('[PA_FETCH] parsedLen=${songText.length}');
      return songText;
    } catch (e) {
      debugPrint('[PA_FETCH] EXCEPTION: $e');
      return '';
    }
  }

  Future<List<WebSong>> findSongOfInterpretPisnickyAkordy(
    String ref,
  ) async {
    List<WebSong> songs = [];
    final response = await webProvider.getSongsFromInterpretPisnickyAkordy(ref);
    final parsedSongs = parseGetSongsFromInterpretFromPisnickyAkordy(response.data);
    if (parsedSongs.isNotEmpty) {
      for (MapEntry<String, String> entry in parsedSongs.entries) {
        String title = entry.key;
        bool isChords = title.contains('akordy a text písně');
        if (isChords) {
          title = title.replaceAll('akordy a text písně', '');
        } else if (title.contains(' text písně')) {
          title = title.replaceAll('text písně', '');
        }
        songs.add(WebSong(interpret: ref, title: title, ref: entry.value, server: 'pisnicky-akordy.cz'));
      }
    }
    return songs;
  }

  Future<List<WebInterpret>> findInterpretPisnickyAkordy(String searchText) async {
    List<WebInterpret> interprets = [];

    if (allInterpretersPisnickyAkordy.isEmpty) {
      // A third-party site being unreachable, slow or refusing the request
      // (403/429/Cloudflare) must never take the app down — this runs during
      // WebBloc init, so an uncaught error here breaks startup.
      try {
        final response = await webProvider.searchInterpretByFirstLetterPisnickyAkordy(searchText);
        allInterpretersPisnickyAkordy = parseSearchByFirstLetterFromPisnickyAkordy(response.data, searchText);
      } catch (e) {
        logger.w('pisnicky-akordy.cz interpret lookup failed: $e');
        return interprets;
      }
    }
    if (allInterpretersPisnickyAkordy.isNotEmpty) {
      final searchTextToLover = removeDiacriticsAndWhitespace(searchText.toLowerCase());
      for (MapEntry<String, String> entry in allInterpretersPisnickyAkordy.entries) {
        if (removeDiacriticsAndWhitespace(entry.key.toLowerCase()).contains(searchTextToLover)) {
          interprets.add(WebInterpret(title: entry.key, ref: entry.value));
          if (interprets.length > 50) {
            break;
          }
        }
      }
    }
    return interprets;
  }

  /// Search songs directly on PisnickyAkordy using MeiliSearch.
  Future<List<WebSong>> findSongsPisnickyAkordy(String searchText) async {
    List<WebSong> songs = [];
    try {
      final response = await webProvider.searchPisnickyAkordy(searchText);
      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map;
        final hits = data['hits'];
        if (hits is List) {
          for (final hit in hits) {
            if (hit is Map) {
              // Extract title
              final title = _firstOf(hit, ['title', 'nazev', 'name', 'jmeno']);
              if (title == null) continue;

              // Filter: only include songs (type contains "Písnička"), skip albums/interprets
              final type = hit['type'];
              if (type == null) continue;
              final typeStr = type is List ? type.join(' ') : type.toString();
              if (!typeStr.contains('Písnička')) continue;

              // Extract slug (short URL identifier)
              final slug = _firstOf(hit, ['slug', 'url', 'ref', 'path']);
              if (slug == null) continue;

              // Extract interpreter info from nested object: {id, name, slug, image}
              String interpretName = '';
              String interpretSlug = '';
              final interpreter = hit['interpreter'];
              if (interpreter is Map) {
                interpretName = (interpreter['name'] as String?) ?? '';
                interpretSlug = (interpreter['slug'] as String?) ?? '';
              }
              if (interpretName.isEmpty) {
                interpretName = _firstOf(hit, ['interpret', 'artist', 'autor']) ?? '';
              }

              // Construct the correct song page URL: {interpreter_slug}/{song_slug}
              // Pisnicky-akordy.cz URLs are like: /{autor-slug}/{song-slug}
              // Fallback: if no interpret slug, try just the song slug
              String ref;
              if (interpretSlug.isNotEmpty) {
                ref = '$interpretSlug/$slug';
              } else {
                // Some songs might be at /{slug} directly or /{slug}-akordy
                ref = slug;
              }

              // MeiliSearch might return lyrics directly in the hit
              final lyric = _firstOf(hit, ['text', 'lyric', 'lyrics', 'content', 'songtext']) ?? '';

              songs.add(WebSong(
                title: title,
                ref: ref,
                interpret: interpretName,
                server: 'pisnicky-akordy.cz',
                lyric: lyric,
              ));
            }
          }
        }
      }
    } catch (e) {
      logger.e('Error searching PisnickyAkordy songs: $e');
    }
    return songs;
  }

  /// Helper: return the first non-null/non-empty string value from [keys] in [map].
  String? _firstOf(Map map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }

  Map<String, String> parseSearchByFirstLetterFromPisnickyAkordy(String htmlText, String firstLetter) {
    Map<String, String> map = {};
    BeautifulSoup bs = BeautifulSoup(htmlText);
    final tabPaneAll = bs.findAll('*', class_: 'tab-pane');

    for (var tabPane in tabPaneAll) {
      final list = tabPane.find('*', class_: 'itemlist');
      int index = 0;
      if (list != null) {
        for (var element in list.children) {
          final contents = element.contents;
          if (contents.isNotEmpty) {
            String title = '';
            String ref = '';
            title = contents.first.attributes['title'] ?? '';
            ref = contents.first.attributes['href'] ?? '';
            if (!map.containsKey(title)) {
              map[title] = ref;
            } else {
              if (title.contains(firstLetter)) {
                map['$title$index'] = ref;
                index++;
              }
            }
          }
        }
      }
    }
    return map;
  }

  Map<String, String> parseGetSongsFromInterpretFromPisnickyAkordy(String htmlText) {
    Map<String, String> map = {};
    BeautifulSoup bs = BeautifulSoup(htmlText);
    final tabPane = bs.find('*', class_: 'tab-pane', id: 'az');
    final contents = tabPane?.contents;
    if (contents != null) {
      for (var element in contents) {
        final list = element.children;
        if (list.isNotEmpty) {
          for (var item in list) {
            if (item.children.isNotEmpty) {
              String title = '';
              String ref = '';
              title = item.children.first.attributes['title'] ?? '';
              ref = item.children.first.attributes['href'] ?? '';
              map[title] = ref;
            }
          }
        }
      }
    }
    return map;
  }

  String parseTextFromPisnickyAkordy(String htmlText) {
    BeautifulSoup bs = BeautifulSoup(htmlText);
    final songText = bs.find('*', id: 'songtext');
    final pre = songText?.find('pre');
    final nodes = pre?.nodes;
    String allText = '';
    if (nodes != null) {
      String text = '';
      List<WebChord> chords = [];
      int beforeSpaces = 0;
      for (var son in nodes) {
        if (son is Element && son.className == 'aline') {
          if (son.nodes.isNotEmpty) {
            for (var node in son.nodes) {
              if (node is Element && node.className == 'akord') {
                chords.add(WebChord(text: node.text, beforeSpaces: beforeSpaces));
              }
              if (node is Text) {
                beforeSpaces = node.text.length;
              }
            }
          }
        }
        if (son is Text) {
          text = son.text;
          int index = 0;
          if (chords.isNotEmpty) {
            for (WebChord chord in chords) {
              index += chord.beforeSpaces;
              if (index < text.length) {
                text = text.insert(index, '[${chord.text}]');
                index += chord.text.length + 2;
              } else {
                text = '$text[${chord.text}]';
              }
            }
          }
          allText += text;
          chords.clear();
          beforeSpaces = 0;
        }
      }
    }
    return allText;
  }

  Future<List<WebSong>> searchSongsProScholyLocal(String searchText) async {
    // Use the same Elasticsearch-based search as the ProScholy website.
    // This returns many relevant results directly from the server with proper relevance scoring.
    try {
      final response = await webProvider.searchSongsProScholyElastic(
        searchString: searchText,
        page: 1,
        perPage: 50,
      );

      if (response.statusCode != 200) {
        logger.e('ProScholy elastic search error: ${response.statusCode}');
        return [];
      }

      final data = response.data;
      if (data == null || data['data'] == null || data['data']['search_song_lyrics'] == null) {
        return [];
      }

      final searchResult = data['data']['search_song_lyrics'];
      final songs = searchResult['data'] as List? ?? [];
      final List<WebSong> results = [];

      for (var song in songs) {
        String authorName = '';
        if (song['authors_pivot'] != null && (song['authors_pivot'] as List).isNotEmpty) {
          authorName = song['authors_pivot'][0]['author']['name'] ?? '';
        }
        results.add(WebSong(
          title: song['name'] ?? '',
          ref: song['id'].toString(),
          interpret: authorName,
          ischords: song['has_chords'] ?? false,
          server: 'zpevnik.proscholy.cz',
        ));
      }

      final paginatorInfo = searchResult['paginatorInfo'];
      logger.i('ProScholy: found ${paginatorInfo?['total']} total results, returned ${results.length}');

      return results;
    } catch (e) {
      logger.e('Error in ProScholy elastic search: $e');
      return [];
    }
  }

  Future<List<WebItem>> findSongAndInterpretsFromProScholy(String searchText) async {
    List<WebItem> items = [];
    try {
      final response = await webProvider.searchSongsProScholy(searchText);
      if (response.statusCode != 200) {
        logger.e('error status Code ${response.statusCode}');
        return items;
      }
      final data = response.data;
      if (data != null && data['data'] != null && data['data']['song_lyrics'] != null) {
        for (var song in data['data']['song_lyrics']) {
          String authorName = '';
          if (song['authors_pivot'] != null && (song['authors_pivot'] as List).isNotEmpty) {
            authorName = song['authors_pivot'][0]['author']['name'] ?? '';
          }
          items.add(WebSong(
            title: song['name'] ?? '',
            ref: song['id'].toString(),
            interpret: authorName,
            ischords: song['has_chords'] ?? false,
            server: 'zpevnik.proscholy.cz',
          ));
        }
      }
    } catch (e) {
      logger.e('error: $e');
    }
    return items;
  }

  Future<List<WebInterpret>> findInterpretProScholy(String searchText) async {
    List<WebInterpret> interprets = [];
    try {
      final response = await webProvider.searchAuthorsProScholy(searchText);
      if (response.statusCode != 200) {
        logger.e('error status Code ${response.statusCode}');
        return interprets;
      }
      final data = response.data;
      if (data != null && data['data'] != null && data['data']['authors'] != null) {
        for (var author in data['data']['authors']) {
          interprets.add(WebInterpret(
            title: author['name'] ?? '',
            ref: author['id'].toString(),
          ));
        }
      }
    } catch (e) {
      logger.e('error: $e');
    }
    return interprets;
  }

  Future<List<WebSong>> findSongByInterpretFromProScholy(WebInterpret interpret) async {
    List<WebSong> songs = [];
    try {
      final response = await webProvider.getSongsByAuthorProScholy(interpret.ref);
      if (response.statusCode != 200) {
        logger.e('error status Code ${response.statusCode}');
        return songs;
      }
      final data = response.data;
      if (data != null && data['data'] != null && data['data']['author'] != null) {
        final author = data['data']['author'];
        final songLyrics = author['song_lyrics'];
        if (songLyrics != null) {
          for (var song in songLyrics) {
            songs.add(WebSong(
              title: song['name'] ?? '',
              ref: song['id'].toString(),
              interpret: author['name'] ?? '',
              ischords: song['has_chords'] ?? false,
              server: 'zpevnik.proscholy.cz',
            ));
          }
        }
      }
    } catch (e) {
      logger.e('error: $e');
    }
    return songs;
  }

  Future<String> getTextSongProScholy(String songId) async {
    String songText = '';
    try {
      final response = await webProvider.getSongLyricsProScholy(songId);
      if (response.statusCode != 200) {
        logger.e('error status Code ${response.statusCode}');
        return songText;
      }
      final data = response.data;
      if (data != null && data['data'] != null && data['data']['song_lyric'] != null) {
        songText = data['data']['song_lyric']['lyrics'] ?? '';
      }
    } catch (e) {
      logger.e('error: $e');
    }
    return songText;
  }

  // ── WorshipLeader (songs.worshipleaderapp.com) ──

  /// Search songs on songs.worshipleaderapp.com.
  /// Returns a flat list of [WebSong] (no separate interpret list).
  Future<List<WebSong>> searchSongsWorshipLeader(String searchText) async {
    final List<WebSong> results = [];
    try {
      final response = await webProvider.searchWorshipLeader(query: searchText, limit: 50);
      if (response.statusCode != 200) {
        logger.e('WorshipLeader search error: ${response.statusCode}');
        return results;
      }
      final data = response.data;
      if (data == null || data['data'] == null) return results;
      for (var song in data['data'] as List) {
        results.add(WebSong(
          title: song['title'] ?? '',
          ref: song['id'].toString(),
          interpret: '',
          ischords: (song['has_chord'] ?? 0) == 1,
          server: 'songs.worshipleaderapp.com',
        ));
      }
      logger.i('WorshipLeader: found ${data['total']} total, returned ${results.length}');
    } catch (e) {
      logger.e('Error searching WorshipLeader: $e');
    }
    return results;
  }

  /// Get the full song text (lyrics with chords) from songs.worshipleaderapp.com.
  Future<String> getTextSongWorshipLeader(String songId) async {
    String songText = '';
    try {
      final id = int.tryParse(songId);
      if (id == null) return songText;
      final response = await webProvider.getSongWorshipLeader(id);
      if (response.statusCode != 200) {
        logger.e('WorshipLeader get song error: ${response.statusCode}');
        return songText;
      }
      final data = response.data;
      if (data == null || data['data'] == null) return songText;
      final songXml = data['data']['songxml'] ?? '';
      songText = _parseWorshipLeaderSongXml(songXml);
    } catch (e) {
      logger.e('Error getting WorshipLeader song: $e');
    }
    return songText;
  }

  /// Parse the songxml format from WorshipLeader into plain text with [chord] notation.
  String _parseWorshipLeaderSongXml(String songXml) {
    if (songXml.isEmpty) return '';
    // Remove <verse> / </verse> tags
    String text = songXml.replaceAll(RegExp(r'</?verse>'), '');
    // Convert <chord>X</chord> to [X]
    text = text.replaceAllMapped(
      RegExp(r'<chord>([^<]*)</chord>'),
      (match) => '[${match.group(1)}]',
    );
    // Convert <br /> to newline
    text = text.replaceAll(RegExp(r'<br\s*/?>'), '\n');
    // Remove any remaining HTML tags
    text = text.replaceAll(RegExp(r'<[^>]+>'), '');
    // Clean up multiple newlines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return text.trim();
  }

  // ── WorshipChords (worshipchords.com) ──

  /// Matches a single chord token, e.g. `Ab`, `Em7`, `Csus4`, `Eb/G`, `Ab/C`.
  static final RegExp _wcChordToken = RegExp(r'^[A-G][#b]?(?:maj|min|m|sus|dim|aug|add|M)?\d*(?:sus\d*)?(?:/[A-G][#b]?)?$');

  /// Search songs directly on worshipchords.com using the site's `?s=` search.
  Future<List<WebSong>> searchSongsWorshipChords(String searchText) async {
    try {
      final response = await webProvider.searchWorshipChords(searchText);
      if (response.statusCode != 200 || response.data == null) {
        logger.e('WorshipChords search error: ${response.statusCode}');
        return [];
      }
      return _parseWorshipChordsSongList(response.data.toString());
    } catch (e) {
      logger.e('Error searching WorshipChords songs: $e');
      return [];
    }
  }

  /// Search artists/bands on worshipchords.com. The site has no artist index,
  /// so candidates are derived from the `?s=` result page: band names (the
  /// `categories` span) and linked authors ("View all posts in ...").
  Future<List<WebInterpret>> findInterpretWorshipChords(String searchText) async {
    final List<WebInterpret> interprets = [];
    try {
      final response = await webProvider.searchWorshipChords(searchText);
      if (response.statusCode != 200 || response.data == null) {
        logger.e('WorshipChords interpret search error: ${response.statusCode}');
        return interprets;
      }
      final document = parse(response.data.toString());
      final query = removeDiacriticsAndWhitespace(searchText.toLowerCase());
      final Map<String, WebInterpret> bySlug = {};

      // Band names from the "categories" span (e.g. "Bethel Music, Jenn Johnson").
      for (final span in document.querySelectorAll('span.categories')) {
        for (final raw in span.text.split(',')) {
          final name = raw.trim();
          if (name.isEmpty) continue;
          final slug = _slugifyWorshipChords(name);
          if (slug.isEmpty || bySlug.containsKey(slug)) continue;
          if (removeDiacriticsAndWhitespace(name.toLowerCase()).contains(query)) {
            bySlug[slug] = WebInterpret(title: name, ref: slug);
          }
        }
      }

      // Linked authors: <a href="/slug/" title="View all posts in Name">Name</a>.
      for (final a in document.querySelectorAll('a[title^="View all posts in"]')) {
        final name = a.text.trim();
        final href = a.attributes['href'] ?? '';
        if (name.isEmpty || href.isEmpty) continue;
        final slug = _worshipChordsSlugFromUrl(href);
        if (slug.isEmpty || bySlug.containsKey(slug)) continue;
        if (removeDiacriticsAndWhitespace(name.toLowerCase()).contains(query)) {
          bySlug[slug] = WebInterpret(title: name, ref: slug);
        }
      }

      interprets.addAll(bySlug.values);
      interprets.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } catch (e) {
      logger.e('Error finding WorshipChords interprets: $e');
    }
    return interprets;
  }

  /// Get all songs listed on an artist/band page (e.g. `/phil-wickham/`).
  Future<List<WebSong>> findSongByInterpretWorshipChords(WebInterpret interpret) async {
    try {
      final response = await webProvider.getArtistWorshipChords(interpret.ref);
      if (response.statusCode != 200 || response.data == null) {
        logger.e('WorshipChords artist page error: ${response.statusCode}');
        return [];
      }
      final songs = _parseWorshipChordsSongList(response.data.toString());
      // Prefer the page's artist name when a result lacks one.
      for (final s in songs) {
        if (s.interpret.isEmpty) s.interpret = interpret.title;
      }
      return songs;
    } catch (e) {
      logger.e('Error loading WorshipChords artist songs: $e');
      return [];
    }
  }

  /// Download a single worshipchords.com song: lyrics with inline chords plus
  /// an optional YouTube link found on the page.
  Future<({String lyric, String youtube})> getSongDataWorshipChords(String ref) async {
    try {
      final response = await webProvider.getSongWorshipChords(ref);
      if (response.statusCode != 200 || response.data == null) {
        logger.e('WorshipChords song error: ${response.statusCode}');
        return (lyric: '', youtube: '');
      }
      final html = response.data.toString();
      final document = parse(html);
      // Prefer the chords version; fall back to lyrics-only.
      final pre = document.querySelector('.song-chords-content pre') ?? document.querySelector('.song-lyrics-content pre');
      String lyric = '';
      if (pre != null) {
        lyric = _convertWorshipChordsChords(pre.text);
      } else {
        final lyricsBlock = document.querySelector('.song-lyrics-content');
        lyric = lyricsBlock?.text.trim() ?? '';
      }
      final youtube = _extractWorshipChordsYoutube(html);
      return (lyric: lyric, youtube: youtube);
    } catch (e) {
      logger.e('Error getting WorshipChords song: $e');
      return (lyric: '', youtube: '');
    }
  }

  /// Parse a list of songs from a worshipchords.com page. Both the search
  /// results and the artist pages wrap each song in `<div class="artist-songs">`.
  List<WebSong> _parseWorshipChordsSongList(String html) {
    final List<WebSong> songs = [];
    final document = parse(html);
    final seen = <String>{};
    for (final block in document.querySelectorAll('.artist-songs')) {
      // The song link ends with "-chords/". Prefer the bookmark anchor (search
      // results); otherwise take the first chords anchor (artist pages).
      Element? anchor = block.querySelector('a[rel="bookmark"]');
      anchor ??= block.querySelectorAll('a').cast<Element?>().firstWhere(
            (e) => (e?.attributes['href'] ?? '').contains('-chords'),
            orElse: () => null,
          );
      if (anchor == null) continue;
      final href = anchor.attributes['href'] ?? '';
      final ref = _worshipChordsSlugFromUrl(href);
      if (ref.isEmpty || seen.contains(ref)) continue;

      String title = (anchor.attributes['title'] ?? '').trim();
      if (title.isEmpty) title = anchor.text.trim();
      title = _cleanWorshipChordsTitle(title);
      if (title.isEmpty) continue;

      final interpret = block.querySelector('span.categories')?.text.trim() ?? '';

      seen.add(ref);
      songs.add(WebSong(
        title: title,
        ref: ref,
        interpret: interpret,
        ischords: true,
        server: 'worshipchords.com',
      ));
    }
    return songs;
  }

  String _cleanWorshipChordsTitle(String title) {
    var t = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    t = t.replaceAll(RegExp(r'\s*[Cc]hords$'), '').trim();
    return t;
  }

  /// Extract the path slug from a worshipchords.com URL or relative path.
  String _worshipChordsSlugFromUrl(String url) {
    var s = url.trim();
    s = s.replaceFirst(RegExp(r'^https?://[^/]+'), '');
    s = s.replaceAll(RegExp(r'[?#].*$'), '');
    s = s.replaceAll(RegExp(r'^/|/$'), '');
    return s;
  }

  /// Convert a band/author name into the WordPress category slug used in URLs,
  /// e.g. "Hillsong Worship" -> "hillsong-worship".
  String _slugifyWorshipChords(String name) {
    var s = name.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'[^a-z0-9\s-]'), '');
    s = s.replaceAll(RegExp(r'\s+'), '-');
    s = s.replaceAll(RegExp(r'-+'), '-');
    s = s.replaceAll(RegExp(r'^-|-$'), '');
    return s;
  }

  String _extractWorshipChordsYoutube(String html) {
    final embed = RegExp(r'youtube\.com/embed/([A-Za-z0-9_-]{6,})').firstMatch(html);
    if (embed != null) return 'https://www.youtube.com/watch?v=${embed.group(1)}';
    final watch = RegExp(r'youtube\.com/watch\?v=([A-Za-z0-9_-]{6,})').firstMatch(html);
    if (watch != null) return 'https://www.youtube.com/watch?v=${watch.group(1)}';
    final short = RegExp(r'youtu\.be/([A-Za-z0-9_-]{6,})').firstMatch(html);
    if (short != null) return 'https://www.youtube.com/watch?v=${short.group(1)}';
    return '';
  }

  /// Convert worshipchords.com "chords above lyrics" plain text into the app's
  /// inline `[Chord]` notation, aligning each chord to its column in the lyric.
  String _convertWorshipChordsChords(String pre) {
    final lines = pre.replaceAll('\r\n', '\n').split('\n');
    final List<String> out = [];
    int i = 0;
    while (i < lines.length) {
      final line = lines[i];
      if (_isWorshipChordsChordLine(line)) {
        final next = i + 1 < lines.length ? lines[i + 1] : '';
        if (next.trim().isNotEmpty && !_isWorshipChordsChordLine(next)) {
          out.add(_mergeWorshipChordsLine(line, next));
          i += 2;
          continue;
        } else {
          // Standalone chord line (intro/instrumental): wrap each chord.
          out.add(line.trim().split(RegExp(r'\s+')).map((c) => '[$c]').join(' '));
          i += 1;
          continue;
        }
      }
      out.add(line);
      i += 1;
    }
    return out.join('\n').trim();
  }

  bool _isWorshipChordsChordLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return false;
    return trimmed.split(RegExp(r'\s+')).every((tok) => _wcChordToken.hasMatch(tok));
  }

  /// Insert each chord from [chordLine] into [lyricLine] at its column position.
  String _mergeWorshipChordsLine(String chordLine, String lyricLine) {
    String buffer = lyricLine;
    int offset = 0;
    for (final match in RegExp(r'\S+').allMatches(chordLine)) {
      final pos = match.start + offset;
      final chord = '[${match.group(0)}]';
      if (pos >= buffer.length) {
        buffer = buffer.padRight(pos) + chord;
      } else {
        buffer = buffer.substring(0, pos) + chord + buffer.substring(pos);
      }
      offset += chord.length;
    }
    return buffer.trimRight();
  }

  Future<dynamic> findSongSupermusic(String text) async {
    dynamic response = await webProvider.getDataSupermusic('najdi.php?hladane=$text&typhladania=textpiesen');
    try {
      var document = parse(response.data);
      List<Element> clanek = document.getElementsByClassName('clanok');
      if (clanek.isEmpty) return [];
      List<Element> listSong = clanek.first.getElementsByTagName('a');
      List<WebSong> listWebSong = [];
      for (Element element in listSong) {
        String interpret = element.text;
        String ref = element.attributes['href'] ?? '';
        //id find ref idpiesne to end of string
        String id = ref.substring(ref.indexOf('idpiesne=') + 9, ref.length);
        if (ref.contains('action=piesen')) {
          listWebSong.add(WebSong(title: id, ref: ref, interpret: interpret));
        }
      }
      return listWebSong;
    } catch (e) {
      logger.e('$e');
      return <WebSong>[];
    }
  }

  Future<dynamic> findInterpretSupermusic(String text) async {
    dynamic response = await webProvider.getDataSupermusic('najdi.php?hladane=$text&typhladania=skupina');
    try {
      var document = parse(response.data);
      List<Element> listClanek = (document.getElementsByClassName('clanok'));
      if (listClanek.isEmpty) return [];
      for (Element element in listClanek) {
        if (element.attributes['valign'] != null) {
          List listTop = element.children;
          if (listTop is List<Element> && listTop.isNotEmpty) {
            var table = listTop.firstWhere((element) => element.localName == 'table').firstChild;
            if (table != null && table.children.isNotEmpty) {
              List<WebInterpret> interpreters = [];

              for (Element tr in table.children) {
                if (tr.children.isNotEmpty) {
                  Element td = tr.children.last;
                  String text = td.text;
                  if (text.isEmpty) continue;
                  int idx = text.indexOf("(");
                  String name = text.substring(0, idx);
                  idx = text.indexOf(':');
                  int? songs = int.tryParse(text.substring(idx + 2, text.length - 1));

                  Iterable refIt = td.getElementsByTagName('a').where((element) => element.attributes.containsKey('href')).map((e) => e.attributes['href']);
                  if (refIt.isNotEmpty && name.isNotEmpty) {
                    interpreters.add(WebInterpret(title: name, ref: refIt.first, songs: songs ?? -1));
                  }
                }
              }
              return interpreters;
            }
          }
        }
      }
      return [];
    } catch (e) {
      logger.e('$e');
      return [];
    }
  }

  Future<dynamic> findInterpretVelkyZpevnik(String text) async {
    dynamic resp = await webProvider.getDataVelkyZpevnik('vyhledavani/$text');

    final document = parse(resp.data);
    List results = document.getElementsByClassName('section__wrapper');
    if (results.isEmpty || results.firstWhereOrNull((element) => element.id == 'interpreti') == null) return [];
    Element elementInterpret = results.firstWhere((element) => element.id == 'interpreti').children.firstWhere((element) => element.className == 'boxes grid');
    List interprets = elementInterpret.children.map((e) {
      String name = e.children.firstWhere((element) => element.className == 'title').innerHtml;
      String ref = e.attributes['href'] ?? '';

      return WebInterpret(title: name, ref: ref);
    }).toList();

    return interprets;
  }

  Future<dynamic> findSongVelkyZpevnik(String text) async {
    dynamic resp = await webProvider.getDataVelkyZpevnik('vyhledavani/$text');

    final document = parse(resp.data);
    List results = document.getElementsByClassName('section__wrapper');
    if (results.isEmpty) return [];

    Element pisne = results.firstWhere((element) => element.id == 'pisne-dle-textu').children.firstWhere((element) => element.className == 'boxes grid');
    List songs = pisne.children.map((e) {
      String title = e.children.firstWhere((element) => element.className == 'title').innerHtml;
      String ref = e.children.firstWhere((element) => element.className == 'title').attributes['href'] ?? '';
      String interpret = e.children.firstWhere((element) => element.className == 'interpret').innerHtml;
      return WebSong(title: title, ref: ref, interpret: interpret, server: 'velkyzpevnik.cz');
    }).toList();

    return songs;
  }

  Future<dynamic> getSongByInterpretVelkyZpevnik(WebInterpret interpret) async {
    List<WebSong> listSong = [];
    dynamic response = await webProvider.getDataVelkyZpevnik('/${interpret.ref}');
    if (response.statusCode != 200) {
      logger.e('error status Code ${response.statusCode}');
      return listSong;
    }
    try {
      final document = parse(response.data);
      List<Element> songs = document.getElementsByClassName('songs');
      if (songs.isNotEmpty) {
        Element list = songs.first;
        if (list.children.isNotEmpty) {
          for (Element element in list.children) {
            if (element.className == 'song show-upon-scroll') {
              String ref = element.attributes['href'] ?? '';
              String title = element.children.first.innerHtml;
              if (title.isNotEmpty && ref.isNotEmpty) {
                WebSong song = WebSong(title: title, ref: ref, interpret: interpret.title, server: 'velkyzpevnik.cz');

                listSong.add(song);
              }
            }
          }
        }
      }
    } catch (e) {
      logger.e('error: $e');
    }

    return listSong;
  }

  Future<String> getNameSong(String path, WebAddress webAddress) async {
    String name = '';
    switch (webAddress) {
      case WebAddress.velkyZpevnik:
        // var resp = await networkProvider.getDataVelkyZpevnik('vyhledavani/$text');
        break;
      case WebAddress.superMusic:
        dynamic response = await webProvider.getDataSupermusic(path);

        try {
          final document = parse(response.data);

          if (document.head == null) {
            logger.v('document hasnot head');
            return name;
          }
          List<Element> listElementMeta = document.head!.getElementsByTagName('meta');
          for (Element element in listElementMeta) {
            if (element.attributes['name'] != null && element.attributes['name'] == 'description' && element.attributes['content'] != null) {
              name = element.attributes['content']!.substring(element.attributes['content']!.indexOf('-') + 1);
            }
          }
          break;
        } catch (e) {
          logger.e('$e');
        }
        break;
      case WebAddress.proScholy:
        // TODO: Handle this case.
        break;
    }
    return name;
  }

  Future<String> getTextSongVelkyZpevnik(WebSong song) async {
    dynamic response = await webProvider.getDataVelkyZpevnik(song.ref);
    String lyric = '';
    if (response.statusCode != 200) {
      logger.e('error status Code ${response.statusCode}');
      return lyric;
    }

    try {
      BeautifulSoup bs = BeautifulSoup(response.data);
      final songText = bs.find('*', class_: 'format', id: 'chordbox');
      if (songText == null) {
        logger.e('songText is null');
        return lyric;
      }
      String text = '';
      List<WebChord> chords = [];
      int beforeSpaces = 0;
      for (var son in songText.nodes) {
        if (son is Element && son.className == 'chord') {
          chords.add(WebChord(text: son.text, beforeSpaces: beforeSpaces));
        }
        if (songText.nodes.first == son) {
          if (son is Text && son.text.contains('\n')) {
            final lines = son.text.split('\n');
            for (String line in lines) {
              if (text.trim().isEmpty) {
                if (lines.last == line) {
                  beforeSpaces = text.length;
                }
              } else {
                lyric += line;
              }
            }
          } else if (son is Text && son.text.trim().isEmpty) {
            beforeSpaces = son.text.length;
            if (chords.isNotEmpty) {
              beforeSpaces += chords.last.text.length;
            }
          }
          continue;
        }
        if (son is Text && son.text.trim().isEmpty) {
          beforeSpaces = son.text.length;
          if (chords.isNotEmpty) {
            beforeSpaces += chords.last.text.length;
          }
        }
        if (son is Text && son.text.contains('\n')) {
          final lines = son.text.split('\n');
          for (String line in lines) {
            if (line.trim().isEmpty) {
              if (lines.last == line) {
                beforeSpaces = line.length;
              }
            } else {
              text = line;
              if (chords.isNotEmpty) {
                int index = 0;
                for (WebChord chord in chords) {
                  index += chord.beforeSpaces;
                  if (index < text.length) {
                    text = text.insert(index, '[${chord.text}]');
                    index += chord.text.length + 2;
                  } else {
                    text = '$text[${chord.text}]';
                  }
                }
              }
              lyric += '$text\n';
              chords.clear();
              beforeSpaces = 0;
            }
          }
        }
      }
    } catch (e) {
      logger.e('$e');
    }
    return lyric;
  }
}

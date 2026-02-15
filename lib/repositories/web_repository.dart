// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:collection/collection.dart';
import 'package:default_project/services/auxiliary_functions.dart';
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
  List<WebSong>? _cachedProScholySongs;
  bool _isLoadingProScholySongs = false;

  WebRepository({
    required this.webProvider,
  });

  Future<String> testGetSong() async {
    // var response = await webProvider.testGet();
    // final text = parseTextFromPisnickyAkordy(response.data);
    // final respnseSearch = await webProvider.searchPisnickyAkordy('touha');
    //  final responseFirstLetter = await webProvider.searchInterpretByFirstLetterPisnickyAkordy('b');
    // final responseSearch = parseSearchByFirstLetterFromPisnickyAkordy(responseFirstLetter.data, 'b');
    //   final responseSong = await webProvider.getSongsFromInterpretPisnickyAkordy('/pribuzni');
    //  final responseSongText = parseGetSongsFromInterpretFromPisnickyAkordy(responseSong.data);

    final response = await findSongAndInterpretsFromVelkyZpevnik('žalman');
    final resSong = await findSongByInterpretFromVelkyZpevnik(response.first as WebInterpret);
    final song = await getTextSongVelkyZpevnik(resSong[5]);

    return '';
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
    String songText = '';
    final response = await webProvider.getDataFromPisnickyAkordy(song);
    songText = parseTextFromPisnickyAkordy(response.data);
    return songText;
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
        if (title.contains(' akordy a text písně')) {
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
      final response = await webProvider.searchInterpretByFirstLetterPisnickyAkordy(searchText);
      allInterpretersPisnickyAkordy = parseSearchByFirstLetterFromPisnickyAkordy(response.data, searchText);
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

  void _startPreloadingProScholySongs() {
    if (_cachedProScholySongs != null || _isLoadingProScholySongs) return;
    _isLoadingProScholySongs = true;
    _loadAllProScholySongsInBackground();
  }

  Future<void> _loadAllProScholySongsInBackground() async {
    List<WebSong> allSongs = [];
    try {
      int page = 1;
      bool hasMore = true;
      while (hasMore) {
        final response = await webProvider.getSongsProScholyPaginated(page: page);
        if (response.statusCode != 200) break;
        final data = response.data;
        if (data == null || data['data'] == null || data['data']['song_lyrics_paginated'] == null) break;
        final paginated = data['data']['song_lyrics_paginated'];
        final songs = paginated['data'] as List? ?? [];
        for (var song in songs) {
          String authorName = '';
          if (song['authors_pivot'] != null && (song['authors_pivot'] as List).isNotEmpty) {
            authorName = song['authors_pivot'][0]['author']['name'] ?? '';
          }
          allSongs.add(WebSong(
            title: song['name'] ?? '',
            ref: song['id'].toString(),
            interpret: authorName,
            ischords: song['has_chords'] ?? false,
            server: 'zpevnik.proscholy.cz',
          ));
        }
        final paginatorInfo = paginated['paginatorInfo'];
        hasMore = paginatorInfo?['hasMorePages'] == true;
        page++;
      }
      _cachedProScholySongs = allSongs;
      logger.i('ProScholy: preloaded ${allSongs.length} songs');
    } catch (e) {
      logger.e('Error preloading ProScholy songs: $e');
    }
    _isLoadingProScholySongs = false;
  }

  Future<List<WebSong>> searchSongsProScholyLocal(String searchText) async {
    // Start background preloading if not done yet
    _startPreloadingProScholySongs();

    // Always get server-side results first (fast, fuzzy, searches lyrics too)
    final serverResults = await findSongAndInterpretsFromProScholy(searchText);
    final List<WebSong> serverSongs = serverResults.whereType<WebSong>().toList();

    // If cache is ready, supplement with local search
    if (_cachedProScholySongs != null && searchText.isNotEmpty) {
      final query = removeDiacriticsAndWhitespace(searchText.toLowerCase());
      final localMatches = _cachedProScholySongs!
          .where((song) => removeDiacriticsAndWhitespace(song.title.toLowerCase()).contains(query) || removeDiacriticsAndWhitespace(song.interpret.toLowerCase()).contains(query))
          .toList();

      // Merge: server results first, then local results not already in server results
      final existingIds = serverSongs.map((s) => s.ref).toSet();
      for (final song in localMatches) {
        if (!existingIds.contains(song.ref)) {
          serverSongs.add(song);
        }
      }
    }

    return serverSongs;
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

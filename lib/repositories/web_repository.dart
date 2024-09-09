// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:beautiful_soup_dart/beautiful_soup.dart';
import 'package:collection/collection.dart';
import 'package:default_project/services/auxiliary_functions.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../model/web_interpret.dart';
import '../model/web_song.dart';
import '../providers/web_provider.dart';
import '../services/enums.dart';
import 'package:html/dom.dart' as dom;

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
    var response = await webProvider.testGet();
    final text = parseTextFromPisnickyAkordy(response.data);
    final respnseSearch = await webProvider.searchPisnickyAkordy('touha');
    //  final responseFirstLetter = await webProvider.searchInterpretByFirstLetterPisnickyAkordy('b');
    // final responseSearch = parseSearchByFirstLetterFromPisnickyAkordy(responseFirstLetter.data, 'b');
    final responseSong = await webProvider.getSongsFromInterpretPisnickyAkordy('/pribuzni');
    final responseSongText = parseGetSongsFromInterpretFromPisnickyAkordy(responseSong.data);
    return '';
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
        songs.add(WebSong(interpret: ref, title: title, ref: entry.value));
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
          interprets.add(WebInterpret(name: entry.key, ref: entry.value));
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

  Future<dynamic> findSongProScholy(String text) async {
    String formatText = text.replaceAll(' ', '_');
    var response = await webProvider.getDataProScholy('?vyhledavani=$formatText');

    try {
      List<Element> songslist = response.getElementsByClassName('container');
      logger.d('test');
    } catch (e) {
      logger.e('error: $e');
    }

    return '';
  }

  Future<dynamic> findInterpretProScholy(String text) async {
    String formatText = text.replaceAll(' ', '_');
    var response = await webProvider.getDataProScholy('?vyhledavani=$formatText&autori=ano');
    return '';
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
                    interpreters.add(WebInterpret(name: name, ref: refIt.first, songs: songs ?? -1));
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
      logger.d('$e');
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

      return WebInterpret(name: name, ref: ref);
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
      return WebSong(title: title, ref: ref, interpret: interpret);
    }).toList();
    logger.d(songs.toString());
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
                WebSong song = WebSong(title: title, ref: ref, interpret: interpret.name);

                listSong.add(song);
              }
            }
          }
        }
        logger.d('stop');
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
            logger.d('document hasnot head');
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

  Future<WebSong> getTextSongVelkyZpevnik(WebSong song) async {
    WebSong newSong = song;
    dynamic response = await webProvider.getDataVelkyZpevnik(song.ref);
    if (response.statusCode != 200) {
      logger.e('error status Code ${response.statusCode}');
      return newSong;
    }
    try {
      final document = parse(response.data);
      Element? chordBox = document.getElementById('chordbox');
      List<String> chords = [];
      if (chordBox == null) {
        return newSong;
      }
      newSong.nodes = chordBox.nodes;
      newSong.unformatText = chordBox.text;
      for (dom.Node node in chordBox.nodes) {
        if (node.attributes['class'] == 'chord') {
          chords.add('[${node.attributes['data-chord']}]');
          continue;
        }
        if (node is dom.Text) {
          if (node.text.trim().isEmpty) {
            chords.add(node.text);
          } else {
            String lyric = node.text;
            final regExp = RegExp("\n");
            if (regExp.allMatches(lyric).length <= 3) {
              lyric = lyric.replaceAll('\n', '');
            }

            while (lyric[lyric.length - 1] == ' ') {
              lyric = lyric.substring(0, lyric.length - 1);
            }
            int index = 0;
            for (String chord in chords) {
              if (chord.trim().isEmpty) {
                index += chord.length;
              } else {
                if (index > lyric.length) {
                  lyric = '$lyric$chord';
                  index = lyric.length + 1;
                } else {
                  int indexChord = (index * 1.39).round();
                  if (indexChord > lyric.length - 1) {
                    indexChord = lyric.length - 1;
                  }
                  lyric = '${lyric.substring(0, indexChord)}$chord${lyric.substring(indexChord, lyric.length)}';
                  index += chord.length;
                }
              }
            }
            lyric += '\n';
            newSong.lyric += lyric;
            chords.clear();
          }
        }
      }

      //   text = chordBox?.text ?? '';
      List<Element> listSong = document.getElementsByTagName('span').where((element) => element.attributes['class'] == 'chord').toList();
      logger.d('text unformat: ${chordBox.text}');
      logger.d(newSong.lyric);

      logger.d('test');
    } catch (e) {
      logger.d('$e');
    }
    return newSong;
  }
}

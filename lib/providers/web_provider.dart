import 'dart:convert';

import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';
import 'package:logger_pkg/logger_pkg.dart';

class WebProvider {
  final dio.Dio _dio = dio.Dio();
  final String velkyZpevnikUrl = 'https://www.velkyzpevnik.cz';
  final String supermusicUrl = 'https://supermusic.cz/';
  final String proScholy = 'https://zpevnik.proscholy.cz/';
  final String pisnickyAkordy = 'https://pisnicky-akordy.cz';
  final String worshipLeaderUrl = 'https://songs.worshipleaderapp.com';
  final String worshipChordsUrl = 'https://worshipchords.com';
  final tokenPisnickyAkordy = 'f66490724034594fbc28593a67fffc5cfa6362bd628400e6991879c98639d8e8';

  Future<dynamic> testGet() async {
    dio.Response getTest = await _dio.get(
      'https://www.velkyzpevnik.cz',
      queryParameters: {'q': 'nedved', 'do': 'typeaheadSongInterpret'},
    );
    return getTest;
  }

  Future<Object> getDataSupermusic(String requir) async {
    return dio.Dio().get('$supermusicUrl$requir');
  }

  Future<Response> getDataVelkyZpevnik(String requir) async {
    try {
      return dio.Dio().get('$velkyZpevnikUrl$requir');
    } catch (e) {
      logger.e(e);
      return Response(requestOptions: RequestOptions(path: ''));
    }
  }

  Future<dynamic> getDataProScholy(String requir) async {
    return dio.Dio().get('$proScholy$requir');
  }

  Future<Response> searchSongsProScholy(String searchString) async {
    return dio.Dio().post(
      '${proScholy}graphql',
      data: {
        'query': '{ song_lyrics(search_string: "$searchString") { id name has_chords authors_pivot { author { name } } } }',
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  /// Builds Elasticsearch search_params JSON matching the website's search behavior.
  String _buildElasticSearchParams(String searchString) {
    final query = {
      'bool': {
        'must': <Map<String, dynamic>>[],
        'should': <Map<String, dynamic>>[
          {
            'multi_match': {
              'query': searchString,
              'fields': ['name^2', 'name_.2gram', 'name._3gram'],
              'type': 'bool_prefix',
            }
          },
          {
            'multi_match': {
              'query': searchString,
              'fields': ['name^2', 'lyrics^3'],
              'type': 'phrase',
              'slop': 2,
            }
          },
          {
            'multi_match': {
              'query': searchString,
              'fields': ['name'],
              'fuzziness': 1,
            }
          },
          {
            'multi_match': {
              'query': searchString,
              'fields': ['authors', 'hymnology'],
              'fuzziness': 'AUTO',
            }
          },
          {
            'multi_match': {
              'query': searchString,
              'fields': [
                'song_number^50',
                'songbook_records.songbook_number',
                'songbook_records.songbook_full_number^50',
              ],
            }
          },
        ],
        'filter': [
          {
            'term': {
              'is_arrangement': {'value': false},
            }
          },
        ],
      }
    };

    return jsonEncode({
      'sort': <dynamic>[],
      'query': query,
      'min_score': 0.5,
    });
  }

  /// Uses the same Elasticsearch-based search as the ProScholy website.
  /// Returns paginated results with relevance scoring.
  Future<Response> searchSongsProScholyElastic({
    required String searchString,
    int page = 1,
    int perPage = 50,
  }) async {
    final searchParams = _buildElasticSearchParams(searchString);
    return dio.Dio().post(
      '${proScholy}graphql',
      data: {
        'query': '''query(\$search_params: String, \$page: Int, \$per_page: Int) {
          search_song_lyrics(search_params: \$search_params, page: \$page, per_page: \$per_page) {
            data { id name has_chords authors_pivot { author { name } } }
            paginatorInfo { currentPage lastPage total hasMorePages }
          }
        }''',
        'variables': {
          'search_params': searchParams,
          'page': page,
          'per_page': perPage,
        },
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<Response> getSongsProScholyPaginated({required int page, int perPage = 500}) async {
    return dio.Dio().post(
      '${proScholy}graphql',
      data: {
        'query':
            '{ song_lyrics_paginated(per_page: $perPage, page: $page) { data { id name has_chords authors_pivot { author { name } } } paginatorInfo { total currentPage lastPage hasMorePages } } }',
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<Response> searchAuthorsProScholy(String searchString) async {
    return dio.Dio().post(
      '${proScholy}graphql',
      data: {
        'query': '{ authors(search_string: "$searchString") { id name } }',
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<Response> getSongsByAuthorProScholy(String authorId) async {
    return dio.Dio().post(
      '${proScholy}graphql',
      data: {
        'query': '{ author(id: $authorId) { id name song_lyrics { id name has_chords } } }',
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<Response> getSongLyricsProScholy(String songId) async {
    return dio.Dio().post(
      '${proScholy}graphql',
      data: {
        'query': '{ song_lyric(id: $songId) { id name lyrics has_chords authors_pivot { author { name } } } }',
      },
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<Response> getDataFromPisnickyAkordy(String requir) async {
    return dio.Dio().get('$pisnickyAkordy/$requir?tmpl=component&print=1&layout=default');
  }

  Future<Response> searchInterpretByFirstLetterPisnickyAkordy(String firstLetter) async {
    return dio.Dio().get('$pisnickyAkordy/#$firstLetter');
  }

  Future<Response> getSongsFromInterpretPisnickyAkordy(String interpret) async {
    return dio.Dio().get('$pisnickyAkordy$interpret#az');
  }

  Future<Response> searchVelkyZpevnik(String searchString) async {
    return dio.Dio().get('https://www.velkyzpevnik.cz', queryParameters: {'q': searchString, 'do': 'typeaheadSongInterpret'});
  }

  Future<Response> searchPisnickyAkordy(String searchString) async {
    return dio.Dio().post('$pisnickyAkordy/meilisearch/indexes/pa_hlavni_index/search',
        data: {
          'q': searchString,
          'limit': 10,
        },
        options: Options(headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $tokenPisnickyAkordy",
        }));
  }

  /// Search songs on songs.worshipleaderapp.com using their grid API.
  Future<Response> searchWorshipLeader({
    required String query,
    int start = 0,
    int limit = 50,
  }) async {
    return dio.Dio().get(
      '$worshipLeaderUrl/api/grid',
      queryParameters: {
        'query': query,
        'start': start,
        'limit': limit,
      },
    );
  }

  /// Get a single song detail from songs.worshipleaderapp.com.
  Future<Response> getSongWorshipLeader(int songId) async {
    return dio.Dio().get(
      '$worshipLeaderUrl/api/get',
      queryParameters: {'id': songId},
    );
  }

  // ── WorshipChords (worshipchords.com) ──

  /// worshipchords.com is a WordPress site that blocks non-browser clients,
  /// so every request must send a browser-like User-Agent.
  Options get _worshipChordsOptions => Options(
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36',
        },
        followRedirects: true,
        responseType: ResponseType.plain,
      );

  /// Full-text search on worshipchords.com (`?s=`). The site searches song
  /// titles, lyrics and authors and returns an HTML result page.
  Future<Response> searchWorshipChords(String query) async {
    return dio.Dio().get(
      '$worshipChordsUrl/',
      queryParameters: {'s': query},
      options: _worshipChordsOptions,
    );
  }

  /// Get an artist/author page (e.g. `/phil-wickham/`) which lists their songs.
  Future<Response> getArtistWorshipChords(String slug) async {
    final normalized = slug.replaceAll(RegExp(r'^/|/$'), '');
    return dio.Dio().get(
      '$worshipChordsUrl/$normalized/',
      options: _worshipChordsOptions,
    );
  }

  /// Get a single song page (e.g. `/goodness-of-god-chords/`).
  Future<Response> getSongWorshipChords(String slug) async {
    final normalized = slug.replaceAll(RegExp(r'^/|/$'), '');
    return dio.Dio().get(
      '$worshipChordsUrl/$normalized/',
      options: _worshipChordsOptions,
    );
  }
}

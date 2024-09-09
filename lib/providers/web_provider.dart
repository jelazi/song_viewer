import 'package:dio/dio.dart' as dio;
import 'package:dio/dio.dart';

class WebProvider {
  final dio.Dio _dio = dio.Dio();
  final String velkyZpevnikUrl = 'https://www.velkyzpevnik.cz/';
  final String supermusicUrl = 'https://supermusic.cz/';
  final String proScholy = 'https://zpevnik.proscholy.cz/';
  final tokenPisnickyAkordy = 'f66490724034594fbc28593a67fffc5cfa6362bd628400e6991879c98639d8e8';

  Future<dynamic> testGet() async {
    dio.Response getTest = await _dio.get('https://pisnicky-akordy.cz/pribuzni/touha?tmpl=component&print=1&layout=default');
    return getTest;
  }

  Future<Object> getDataSupermusic(String requir) async {
    return dio.Dio().get('$supermusicUrl$requir');
  }

  Future<Object> getDataVelkyZpevnik(String requir) async {
    return dio.Dio().get('$velkyZpevnikUrl$requir');
  }

  Future<dynamic> getDataProScholy(String requir) async {
    return dio.Dio().get('$proScholy$requir');
  }

  Future<Response> getDataFromPisnickyAkordy(String requir) async {
    return dio.Dio().get('https://pisnicky-akordy.cz/$requir?tmpl=component&print=1&layout=default');
  }

  Future<Response> searchInterpretByFirstLetterPisnickyAkordy(String firstLetter) async {
    return dio.Dio().get('https://pisnicky-akordy.cz/#$firstLetter');
  }

  Future<Response> getSongsFromInterpretPisnickyAkordy(String interpret) async {
    return dio.Dio().get('https://pisnicky-akordy.cz$interpret#az');
  }

  Future<Response> searchPisnickyAkordy(String searchString) async {
    return dio.Dio().post('https://pisnicky-akordy.cz/meilisearch/indexes/pa_hlavni_index/search',
        data: {
          'q': searchString,
          'limit': 10,
        },
        options: Options(headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $tokenPisnickyAkordy",
        }));
  }
}

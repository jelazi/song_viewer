import 'package:dio/dio.dart' as dio;

class WebProvider {
  final dio.Dio _dio = dio.Dio();
  final String velkyZpevnikUrl = 'https://www.velkyzpevnik.cz/';
  final String supermusicUrl = 'https://supermusic.cz/';
  final String proScholy = 'https://zpevnik.proscholy.cz/';

  Future<dynamic> testGet() async {
    dio.Response getTest = await _dio.get('${velkyZpevnikUrl}nohavica-jarek/amerika');
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
}

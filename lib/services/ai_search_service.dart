import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Result from AI analysis of a song
class AiSongAnalysis {
  final String? originalTitle;
  final String? author;
  final String? originalLanguage;
  final String? genre;
  final List<String> youtubeSearchQueries;
  final String? additionalInfo;

  AiSongAnalysis({
    this.originalTitle,
    this.author,
    this.originalLanguage,
    this.genre,
    this.youtubeSearchQueries = const [],
    this.additionalInfo,
  });

  factory AiSongAnalysis.fromJson(Map<String, dynamic> json) {
    return AiSongAnalysis(
      originalTitle: json['original_title'] as String?,
      author: json['author'] as String?,
      originalLanguage: json['original_language'] as String?,
      genre: json['genre'] as String?,
      youtubeSearchQueries: (json['youtube_search_queries'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      additionalInfo: json['additional_info'] as String?,
    );
  }
}

/// YouTube search result
class YoutubeSearchResult {
  final String title;
  final String videoId;
  final String thumbnailUrl;
  final String channelTitle;

  YoutubeSearchResult({
    required this.title,
    required this.videoId,
    required this.thumbnailUrl,
    required this.channelTitle,
  });

  String get videoUrl => 'https://www.youtube.com/watch?v=$videoId';
}

/// Sheet music image search result
class SheetMusicResult {
  final String title;
  final String imageUrl;
  final String sourceUrl;

  SheetMusicResult({
    required this.title,
    required this.imageUrl,
    required this.sourceUrl,
  });
}

class AiSearchService {
  final Dio _dio = Dio();

  /// Analyze a song using Groq API (free tier with Llama 3.3 70B)
  Future<AiSongAnalysis?> analyzeSong({
    required String apiKey,
    required String songTitle,
    required String songLyrics,
    String? currentInterpret,
  }) async {
    if (apiKey.isEmpty) return null;

    final lyricsSnippet = songLyrics.length > 800 ? songLyrics.substring(0, 800) : songLyrics;

    final prompt = '''Analyzuj tuto píseň a vrať výsledek POUZE jako JSON objekt (žádný jiný text):

Název písně: $songTitle
${currentInterpret != null && currentInterpret.isNotEmpty ? 'Aktuální interpret: $currentInterpret' : ''}
Text písně (začátek):
$lyricsSnippet

Vrať JSON v tomto formátu:
{
  "original_title": "původní název písně (pokud je přeložená)" nebo null,
  "author": "jméno autora/skladatele" nebo null,
  "original_language": "jazyk originálu" nebo null,
  "genre": "žánr písně" nebo null,
  "youtube_search_queries": ["dotaz1 pro YouTube", "dotaz2 pro YouTube"],
  "additional_info": "zajímavé informace o písni" nebo null
}

Pravidla:
- Pokud si nejsi jistý, vrať null pro daný klíč
- youtube_search_queries by měly být 2-3 vyhledávací dotazy optimalizované pro nalezení písně na YouTube (včetně českého i originálního názvu)
- Odpověz POUZE JSON objektem, žádný markdown, žádný další text''';

    try {
      final response = await _dio.post(
        'https://api.groq.com/openai/v1/chat/completions',
        options: Options(
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
          },
        ),
        data: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'Jsi hudební expert. Odpovídáš POUZE validním JSON objektem bez jakéhokoliv dalšího textu nebo markdown formátování.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.3,
          'max_tokens': 500,
        }),
      );

      final content = response.data['choices'][0]['message']['content'] as String;

      // Parse JSON from response - strip any markdown fences if present
      String jsonStr = content.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceFirst(RegExp(r'^```\w*\n?'), '');
        jsonStr = jsonStr.replaceFirst(RegExp(r'\n?```$'), '');
      }

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return AiSongAnalysis.fromJson(json);
    } catch (e) {
      debugPrint('[AiSearchService] analyzeSong error: $e');
      return null;
    }
  }

  /// Search YouTube videos using YouTube Data API v3
  Future<List<YoutubeSearchResult>> searchYoutube({
    required String apiKey,
    required String query,
    int maxResults = 5,
  }) async {
    if (apiKey.isEmpty) return [];

    try {
      final response = await _dio.get(
        'https://www.googleapis.com/youtube/v3/search',
        queryParameters: {
          'part': 'snippet',
          'q': query,
          'type': 'video',
          'maxResults': maxResults,
          'key': apiKey,
        },
      );

      final items = response.data['items'] as List<dynamic>;
      return items.map((item) {
        final snippet = item['snippet'] as Map<String, dynamic>;
        return YoutubeSearchResult(
          title: snippet['title'] as String? ?? '',
          videoId: item['id']['videoId'] as String? ?? '',
          thumbnailUrl: snippet['thumbnails']?['medium']?['url'] as String? ?? '',
          channelTitle: snippet['channelTitle'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('[AiSearchService] searchYoutube error: $e');
      return [];
    }
  }

  /// Search for sheet music images using ProScholy external links
  Future<List<SheetMusicResult>> searchSheetMusic({
    required String songTitle,
    String? interpret,
  }) async {
    try {
      final searchQuery = interpret != null && interpret.isNotEmpty ? '$songTitle $interpret' : songTitle;

      // Search ProScholy for songs which may have external sheet links
      final response = await _dio.post(
        'https://zpevnik.proscholy.cz/graphql',
        data: {
          'query':
              '{ song_lyrics(search_string: "${_sanitizeGraphql(searchQuery)}") { id name authors_pivot { author { name } } externals(type: "file") { url media_type content_type } } }',
        },
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      final data = response.data['data']?['song_lyrics'] as List<dynamic>?;
      if (data == null) return [];

      final results = <SheetMusicResult>[];
      for (final song in data.take(5)) {
        final externals = song['externals'] as List<dynamic>? ?? [];
        final songName = song['name'] as String? ?? '';
        for (final ext in externals) {
          final url = ext['url'] as String? ?? '';
          final mediaType = ext['media_type'] as String? ?? '';
          if (url.isNotEmpty &&
              (mediaType.contains('image') || url.endsWith('.png') || url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.gif') || url.endsWith('.pdf'))) {
            results.add(SheetMusicResult(
              title: songName,
              imageUrl: url,
              sourceUrl: 'https://zpevnik.proscholy.cz',
            ));
          }
        }
      }
      return results;
    } catch (e) {
      debugPrint('[AiSearchService] searchSheetMusic error: $e');
      return [];
    }
  }

  String _sanitizeGraphql(String input) {
    return input.replaceAll('"', '\\"').replaceAll('\n', ' ').replaceAll('\r', '');
  }
}

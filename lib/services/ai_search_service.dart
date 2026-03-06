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

  /// Analyze a song using multiple AI providers for better accuracy
  Future<AiSongAnalysis?> analyzeSong({
    required String apiKey,
    required String songTitle,
    required String songLyrics,
    String? currentInterpret,
    String? geminiApiKey,
  }) async {
    if (apiKey.isEmpty && (geminiApiKey == null || geminiApiKey.isEmpty)) return null;

    final lyricsSnippet = songLyrics.length > 1200 ? songLyrics.substring(0, 1200) : songLyrics;

    final prompt = '''You are a music expert specializing in identifying songs, their original authors, and original titles.

TASK: Identify the original author and original title of this song. Many songs in Czech churches are translations of well-known English, German, or other language worship/pop songs. Your job is to find the ORIGINAL source.

Song title: $songTitle
${currentInterpret != null && currentInterpret.isNotEmpty ? 'Current listed artist: $currentInterpret' : 'No artist listed.'}
Lyrics (beginning):
$lyricsSnippet

IMPORTANT RULES:
1. Most Czech worship songs are translations of English worship songs. Search your knowledge thoroughly.
2. Songs can also come from MUSICALS (e.g. Jesus Christ Superstar, Godspell, Joseph and the Amazing Technicolor Dreamcoat). For example:
   - "Apoštolská" = "The Last Supper" / "The Apostles' Song" from Jesus Christ Superstar by Andrew Lloyd Webber & Tim Rice
   - "Ať požehnán je Bůh" = "Blessed Be Your Name" by Matt Redman
   - "Pán je můj pastýř" = "The Lord Is My Shepherd"
   - "Svítá" = a Czech original by Bratři Ebenové or Svítá band (NOT a translation)
   - "Shine Jesus Shine" = "Shine, Jesus, Shine" (also known as "Lord, the Light of Your Love") by Graham Kendrick
3. Even if the Czech title seems original, check if the melody/lyrics match a known international song.
4. Return the ORIGINAL songwriter/composer, not the Czech translator.
5. If the song IS genuinely a Czech original, state that clearly in additional_info but still try to identify the author.
6. For youtube_search_queries: provide 4-5 queries. Put CZECH queries FIRST (Czech title + "píseň" or "chvály"), then original language queries. This ensures Czech results appear first.
7. Be confident — if you recognize the song, state the author definitively. Don't hedge with "possibly" or "probably" unless truly uncertain.
8. Pay attention to the LYRICS content, not just the title. The lyrics are the strongest clue for identification.

Return ONLY a valid JSON object (no markdown, no extra text):
{
  "original_title": "original title in original language, or null if Czech original",
  "author": "original songwriter/composer name",
  "original_language": "original language (e.g. English, German, Czech)",
  "genre": "genre (e.g. worship, hymn, pop, rock, musical)",
  "youtube_search_queries": ["czech query 1", "czech query 2", "original language query 1", "original language query 2"],
  "additional_info": "brief interesting facts about the song"
}''';

    // Run both AIs in parallel for better results
    final futures = <Future<AiSongAnalysis?>>[];

    if (apiKey.isNotEmpty) {
      futures.add(_analyzeWithGroq(apiKey, prompt));
    }
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      futures.add(_analyzeWithGemini(geminiApiKey, prompt));
    }

    final results = await Future.wait(futures);
    final validResults = results.whereType<AiSongAnalysis>().toList();

    if (validResults.isEmpty) return null;
    if (validResults.length == 1) return validResults.first;

    // Merge results — prefer non-null values, prefer Gemini for author/title (often better for song identification)
    return _mergeAnalyses(validResults);
  }

  /// Analyze with Groq (Llama 3.3 70B)
  Future<AiSongAnalysis?> _analyzeWithGroq(String apiKey, String prompt) async {
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
              'content': 'You are a music identification expert. You respond ONLY with a valid JSON object, no markdown formatting, no extra text.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.2,
          'max_tokens': 600,
        }),
      );

      final content = response.data['choices'][0]['message']['content'] as String;
      return _parseAiResponse(content);
    } catch (e) {
      debugPrint('[AiSearchService] Groq error: $e');
      return null;
    }
  }

  /// Analyze with Google Gemini (free tier)
  Future<AiSongAnalysis?> _analyzeWithGemini(String apiKey, String prompt) async {
    try {
      final response = await _dio.post(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$apiKey',
        options: Options(
          headers: {'Content-Type': 'application/json'},
        ),
        data: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 600,
          },
        }),
      );

      final content = response.data['candidates']?[0]?['content']?['parts']?[0]?['text'] as String?;
      if (content == null) return null;
      return _parseAiResponse(content);
    } catch (e) {
      debugPrint('[AiSearchService] Gemini error: $e');
      return null;
    }
  }

  /// Parse AI response JSON
  AiSongAnalysis? _parseAiResponse(String content) {
    try {
      String jsonStr = content.trim();
      if (jsonStr.startsWith('```')) {
        jsonStr = jsonStr.replaceFirst(RegExp(r'^```\w*\n?'), '');
        jsonStr = jsonStr.replaceFirst(RegExp(r'\n?```$'), '');
      }

      final json = jsonDecode(jsonStr.trim()) as Map<String, dynamic>;
      return AiSongAnalysis.fromJson(json);
    } catch (e) {
      debugPrint('[AiSearchService] JSON parse error: $e');
      return null;
    }
  }

  /// Merge results from multiple AI analyses
  AiSongAnalysis _mergeAnalyses(List<AiSongAnalysis> analyses) {
    // Prefer non-null values; if both have values, prefer the second (Gemini) for song identification
    String? bestAuthor;
    String? bestOriginalTitle;
    String? bestLanguage;
    String? bestGenre;
    String? bestInfo;
    final allQueries = <String>{};

    for (final a in analyses) {
      if (a.author != null && a.author!.isNotEmpty) bestAuthor = a.author;
      if (a.originalTitle != null && a.originalTitle!.isNotEmpty) bestOriginalTitle = a.originalTitle;
      if (a.originalLanguage != null && a.originalLanguage!.isNotEmpty) bestLanguage = a.originalLanguage;
      if (a.genre != null && a.genre!.isNotEmpty) bestGenre = a.genre;
      if (a.additionalInfo != null && a.additionalInfo!.isNotEmpty) bestInfo = a.additionalInfo;
      allQueries.addAll(a.youtubeSearchQueries);
    }

    return AiSongAnalysis(
      author: bestAuthor,
      originalTitle: bestOriginalTitle,
      originalLanguage: bestLanguage,
      genre: bestGenre,
      youtubeSearchQueries: allQueries.toList(),
      additionalInfo: bestInfo,
    );
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
      final results = <SheetMusicResult>[];
      final seenUrls = <String>{};

      // Try multiple search queries for better coverage
      final queries = <String>[
        songTitle,
        if (interpret != null && interpret.isNotEmpty) '$songTitle $interpret',
      ];

      for (final searchQuery in queries) {
        if (results.length >= 10) break;

        // Search with all externals (not just "file" type) for broader results
        final response = await _dio.post(
          'https://zpevnik.proscholy.cz/graphql',
          data: {
            'query':
                '{ song_lyrics(search_string: "${_sanitizeGraphql(searchQuery)}") { id name authors_pivot { author { name } } externals { url media_type content_type type } } }',
          },
          options: Options(headers: {'Content-Type': 'application/json'}),
        );

        final data = response.data['data']?['song_lyrics'] as List<dynamic>?;
        if (data == null) continue;

        for (final song in data.take(5)) {
          final externals = song['externals'] as List<dynamic>? ?? [];
          final songName = song['name'] as String? ?? '';
          for (final ext in externals) {
            final url = ext['url'] as String? ?? '';
            final mediaType = ext['media_type'] as String? ?? '';
            final extType = ext['type'] as String? ?? '';
            if (url.isNotEmpty && !seenUrls.contains(url)) {
              // Accept file externals (images/PDFs) or any external with sheet-like type
              final isImage = mediaType.contains('image') || url.endsWith('.png') || url.endsWith('.jpg') || url.endsWith('.jpeg') || url.endsWith('.gif');
              final isPdf = mediaType.contains('pdf') || url.endsWith('.pdf');
              final isFileType = extType == 'file' || extType == 'score' || extType == 'sheet';

              if (isImage || isPdf || isFileType) {
                seenUrls.add(url);
                results.add(SheetMusicResult(
                  title: songName,
                  imageUrl: url,
                  sourceUrl: 'https://zpevnik.proscholy.cz',
                ));
              }
            }
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

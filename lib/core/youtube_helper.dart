/// Extracts YouTube video ID from various URL formats or returns the input
/// if it's already a video ID.
///
/// Supported formats:
/// - https://www.youtube.com/watch?v=VIDEO_ID
/// - https://youtu.be/VIDEO_ID
/// - https://www.youtube.com/embed/VIDEO_ID
/// - https://m.youtube.com/watch?v=VIDEO_ID
/// - Just VIDEO_ID (11 characters)
String? extractYoutubeVideoId(String? input) {
  if (input == null || input.isEmpty) return null;

  // Try parsing as URL first
  final uri = Uri.tryParse(input);
  if (uri != null && uri.hasScheme) {
    // youtube.com/watch?v=VIDEO_ID
    if (uri.host.contains('youtube.com')) {
      return uri.queryParameters['v'];
    }
    // youtu.be/VIDEO_ID
    if (uri.host == 'youtu.be') {
      final path = uri.pathSegments;
      if (path.isNotEmpty) return path.first;
    }
    // youtube.com/embed/VIDEO_ID
    if (uri.pathSegments.contains('embed')) {
      final embedIndex = uri.pathSegments.indexOf('embed');
      if (embedIndex + 1 < uri.pathSegments.length) {
        return uri.pathSegments[embedIndex + 1];
      }
    }
  }

  // If it looks like a video ID (11 alphanumeric chars + - and _)
  final idRegex = RegExp(r'^[a-zA-Z0-9_-]{11}$');
  if (idRegex.hasMatch(input)) return input;

  return null;
}

/// Base URL the embed page is loaded from. YouTube rejects embeds without a
/// referrer (player error 153), so the page must have an https origin.
const String youtubeEmbedBaseUrl = 'https://com.lzizka.songviewer';

/// Minimal HTML page with a full-size, inline-playing YouTube embed.
String youtubeEmbedHtml(String videoId) => '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no">
<style>
html, body { margin: 0; height: 100%; background: #000; overflow: hidden; }
iframe { position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: 0; }
</style>
</head>
<body>
<iframe
  src="https://www.youtube.com/embed/$videoId?playsinline=1&rel=0&iv_load_policy=3"
  referrerpolicy="strict-origin-when-cross-origin"
  allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
  allowfullscreen></iframe>
</body>
</html>
''';

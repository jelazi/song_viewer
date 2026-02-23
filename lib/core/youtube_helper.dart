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

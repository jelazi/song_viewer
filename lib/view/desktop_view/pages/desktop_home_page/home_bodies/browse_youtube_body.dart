import 'dart:io';

import 'package:default_project/core/youtube_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../model/youtube_video.dart';

/// Desktop view-only body for browsing YouTube videos of the selected song.
class BrowseYoutubeBody extends StatefulWidget {
  const BrowseYoutubeBody({super.key});

  @override
  State<BrowseYoutubeBody> createState() => _BrowseYoutubeBodyState();
}

class _BrowseYoutubeBodyState extends State<BrowseYoutubeBody> {
  WebViewController? _webController;
  int _currentIndex = 0;
  bool _isLoading = true;

  bool get _isDesktop => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  void _loadVideo(List<YoutubeVideo> videos, int index) {
    if (videos.isEmpty || index < 0 || index >= videos.length) return;
    final videoId = extractYoutubeVideoId(videos[index].path);
    if (videoId == null) return;

    final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';

    if (_isDesktop) {
      // On desktop, open in external browser
      launchUrl(Uri.parse(youtubeUrl), mode: LaunchMode.externalApplication);
    } else {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _isLoading = false);
            },
          ),
        )
        ..loadRequest(Uri.parse(youtubeUrl));

      setState(() {
        _webController = controller;
        _currentIndex = index;
        _isLoading = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewChordBloc, PreviewChordState>(
      builder: (context, state) {
        final song = state.data.song;
        final videos = song?.youtubeVideos ?? [];

        if (videos.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('youtube'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
              ],
            ),
          );
        }

        return Row(
          children: [
            // Video list sidebar
            Container(
              width: 280,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      '${'youtube'.tr()} - ${song?.title ?? ''}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: videos.length,
                      itemBuilder: (context, index) {
                        final video = videos[index];
                        final videoId = extractYoutubeVideoId(video.path);
                        final isSelected = index == _currentIndex;
                        return ListTile(
                          leading: videoId != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: Image.network(
                                    'https://img.youtube.com/vi/$videoId/default.jpg',
                                    width: 60,
                                    height: 45,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.videocam, size: 30, color: Colors.red),
                                  ),
                                )
                              : const Icon(Icons.videocam, size: 30, color: Colors.red),
                          title: Text(
                            video.name.isNotEmpty ? video.name : 'Video ${index + 1}',
                            overflow: TextOverflow.ellipsis,
                          ),
                          selected: isSelected,
                          selectedTileColor: Colors.blue.shade50,
                          onTap: () {
                            if (_isDesktop) {
                              _loadVideo(videos, index);
                            } else {
                              setState(() => _currentIndex = index);
                              _loadVideo(videos, index);
                            }
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new, size: 18),
                            tooltip: 'Otevřít v prohlížeči',
                            onPressed: () {
                              if (videoId != null) {
                                launchUrl(
                                  Uri.parse('https://www.youtube.com/watch?v=$videoId'),
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Main content area
            Expanded(
              child: _isDesktop
                  ? _buildDesktopPlayer(videos)
                  : _webController != null
                      ? Stack(
                          children: [
                            WebViewWidget(controller: _webController!),
                            if (_isLoading) const Center(child: CircularProgressIndicator()),
                          ],
                        )
                      : _buildDesktopPlayer(videos),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopPlayer(List<YoutubeVideo> videos) {
    if (videos.isEmpty) return const SizedBox.shrink();
    final video = _currentIndex < videos.length ? videos[_currentIndex] : videos.first;
    final videoId = extractYoutubeVideoId(video.path);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (videoId != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
                width: 480,
                height: 360,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.videocam_off, size: 120, color: Colors.grey),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            video.name.isNotEmpty ? video.name : 'Video ${_currentIndex + 1}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_circle_fill, color: Colors.red),
            label: const Text('Přehrát na YouTube'),
            onPressed: () {
              if (videoId != null) {
                launchUrl(
                  Uri.parse('https://www.youtube.com/watch?v=$videoId'),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

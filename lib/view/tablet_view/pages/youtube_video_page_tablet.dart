import 'dart:io';

import 'package:default_project/core/youtube_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../../../blocs/export_blocs.dart';
import '../../../model/youtube_video.dart';

class YoutubeVideoPageTablet extends StatefulWidget {
  const YoutubeVideoPageTablet({super.key});

  @override
  State<YoutubeVideoPageTablet> createState() => _YoutubeVideoPageTabletState();
}

class _YoutubeVideoPageTabletState extends State<YoutubeVideoPageTablet> {
  YoutubePlayerController? _controller;
  int _currentIndex = 0;
  List<YoutubeVideo> _videos = [];

  bool get _isDesktop => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  void _initPlayer(List<YoutubeVideo> videos, {int index = 0}) {
    if (videos.isEmpty) return;
    final videoId = extractYoutubeVideoId(videos[index].path);
    if (videoId == null) return;

    _controller?.close();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
      ),
    );
    setState(() {
      _currentIndex = index;
      _videos = videos;
    });
  }

  void _openInBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _getYoutubeUrl(String path) {
    final videoId = extractYoutubeVideoId(path);
    if (videoId != null) return 'https://www.youtube.com/watch?v=$videoId';
    return path;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewChordBloc, PreviewChordState>(
      builder: (context, state) {
        final song = state.data.song;
        final videos = song?.youtubeVideos ?? [];

        if (_videos.isEmpty && videos.isNotEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initPlayer(videos);
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(song?.title ?? 'youtube'.tr()),
          ),
          body: videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text('noYoutube'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('noYoutubeVideosMessage'.tr(), style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Row(
                  children: [
                    // Video player area - left side
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          if (_controller != null && !_isDesktop)
                            YoutubePlayer(
                              controller: _controller!,
                              aspectRatio: 16 / 9,
                            )
                          else if (_isDesktop)
                            AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Container(
                                color: Colors.black,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.play_circle_outline, size: 64, color: Colors.white),
                                      const SizedBox(height: 16),
                                      ElevatedButton.icon(
                                        onPressed: () => _openInBrowser(_getYoutubeUrl(videos[_currentIndex].path)),
                                        icon: const Icon(Icons.open_in_browser),
                                        label: const Text('Open in Browser'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          else
                            const AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          // Currently playing info
                          if (videos.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Text(
                                videos[_currentIndex].name.isNotEmpty ? videos[_currentIndex].name : 'Video ${_currentIndex + 1}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Video list - right side
                    Expanded(
                      flex: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: ListView.builder(
                          itemCount: videos.length,
                          itemBuilder: (context, index) {
                            final video = videos[index];
                            final isSelected = index == _currentIndex;
                            return ListTile(
                              leading: Icon(
                                Icons.play_circle_fill,
                                color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
                              ),
                              title: Text(
                                video.name.isNotEmpty ? video.name : 'Video ${index + 1}',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              selected: isSelected,
                              trailing: IconButton(
                                icon: const Icon(Icons.open_in_browser, size: 20),
                                onPressed: () => _openInBrowser(_getYoutubeUrl(video.path)),
                              ),
                              onTap: () {
                                if (_isDesktop) {
                                  _openInBrowser(_getYoutubeUrl(video.path));
                                } else {
                                  _initPlayer(videos, index: index);
                                }
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

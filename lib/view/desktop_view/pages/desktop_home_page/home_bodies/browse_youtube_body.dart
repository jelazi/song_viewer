import 'package:default_project/core/youtube_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../blocs/export_blocs.dart';

/// Compact right-side panel for browsing YouTube videos of the selected song.
/// Designed to appear alongside the PreviewBody on desktop.
class BrowseYoutubeBody extends StatelessWidget {
  const BrowseYoutubeBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewChordBloc, PreviewChordState>(
      builder: (context, state) {
        final song = state.data.song;
        final videos = song?.youtubeVideos ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.play_circle_fill, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${'youtube'.tr()} - ${song?.title ?? ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Zavřít',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      context.read<DesktopRibbonMenuBloc>().add(const ChangeHomeBody(bodyName: 'preview'));
                    },
                  ),
                ],
              ),
            ),
            // Video list
            if (videos.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Žádná videa', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: videos.length,
                  itemBuilder: (context, index) {
                    final video = videos[index];
                    final videoId = extractYoutubeVideoId(video.path);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          if (videoId != null) {
                            launchUrl(
                              Uri.parse('https://www.youtube.com/watch?v=$videoId'),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (videoId != null)
                              Image.network(
                                'https://img.youtube.com/vi/$videoId/mqdefault.jpg',
                                width: double.infinity,
                                height: 140,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 140,
                                  color: Colors.grey.shade200,
                                  child: const Center(child: Icon(Icons.videocam_off, size: 40, color: Colors.grey)),
                                ),
                              )
                            else
                              Container(
                                height: 140,
                                color: Colors.grey.shade200,
                                child: const Center(child: Icon(Icons.videocam, size: 40, color: Colors.red)),
                              ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.play_circle_outline, size: 16, color: Colors.red),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      video.name.isNotEmpty ? video.name : 'Video ${index + 1}',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const Icon(Icons.open_in_new, size: 14, color: Colors.grey),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

import 'package:default_project/core/youtube_helper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../../blocs/export_blocs.dart';
import '../../../../../../model/youtube_video.dart';
import '../../../../../../services/constants.dart';

class EditYoutubeBody extends StatefulWidget {
  const EditYoutubeBody({super.key});

  @override
  State<EditYoutubeBody> createState() => _EditYoutubeBodyState();
}

class _EditYoutubeBodyState extends State<EditYoutubeBody> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditSongBloc, EditSongState>(
      builder: (context, state) {
        final videos = state.currentEditSong.youtubeVideos ?? [];
        return Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with save and add buttons
              SizedBox(
                width: MediaQuery.of(context).size.width - 300,
                height: 40,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('youtube'.tr(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        // Add button
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _showAddYoutubeDialog(context),
                            child: Container(
                              height: 30,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                color: AppColor.primaryColor,
                                border: Border.all(color: AppColor.grey1Color),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.add, size: 16, color: Colors.white),
                                  SizedBox(width: 4),
                                  Text('YouTube', style: TextStyle(color: Colors.white, fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Save button
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              context.read<EditSongBloc>().add(const SaveSong(typeApp: 'desktop'));
                            },
                            child: Container(
                              height: 30,
                              width: 30,
                              margin: const EdgeInsets.only(left: 5, right: 5),
                              decoration: BoxDecoration(
                                color: state.isCurrentSongModified ? AppColor.primaryColor : AppColor.defaultBackgroundColor,
                                border: Border.all(color: AppColor.grey1Color),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Center(child: Icon(Icons.save, size: 16, color: state.isCurrentSongModified ? Colors.white : Colors.black)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Video list
              Expanded(
                child: videos.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.videocam_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 8),
                            Text('noYoutubeVideosMessage'.tr(), style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddYoutubeDialog(context),
                              icon: const Icon(Icons.add),
                              label: Text('addYoutube'.tr()),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: videos.length,
                        itemBuilder: (context, index) {
                          final video = videos[index];
                          final videoId = extractYoutubeVideoId(video.path);
                          final isValidUrl = videoId != null;
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                isValidUrl ? Icons.play_circle_fill : Icons.error_outline,
                                color: isValidUrl ? AppColor.primaryColor : Colors.red,
                                size: 32,
                              ),
                              title: Text(
                                video.name.isNotEmpty ? video.name : 'Video ${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              subtitle: Text(
                                video.path,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isValidUrl ? Colors.grey : Colors.red,
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Test/Play button - open in browser
                                  Tooltip(
                                    message: 'Přehrát v prohlížeči',
                                    child: IconButton(
                                      icon: Icon(
                                        Icons.open_in_browser,
                                        color: isValidUrl ? AppColor.primaryColor : Colors.grey,
                                      ),
                                      onPressed: isValidUrl ? () => _openInBrowser(video.path) : null,
                                    ),
                                  ),
                                  // Edit button
                                  Tooltip(
                                    message: 'edit'.tr(),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.grey),
                                      onPressed: () => _showEditYoutubeDialog(context, index, video),
                                    ),
                                  ),
                                  // Delete button
                                  Tooltip(
                                    message: 'delete'.tr(),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        context.read<EditSongBloc>().add(RemoveYoutubeVideo(index: index));
                                      },
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
          ),
        );
      },
    );
  }

  void _showAddYoutubeDialog(BuildContext context) {
    final nameController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('addYoutube'.tr()),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Název videa',
                    border: OutlineInputBorder(),
                    hintText: 'např. Živá verze, Karaoke...',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube URL',
                    border: OutlineInputBorder(),
                    hintText: 'https://www.youtube.com/watch?v=...',
                  ),
                ),
                const SizedBox(height: 8),
                _buildUrlValidationIndicator(urlController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                if (urlController.text.isEmpty) return;
                context.read<EditSongBloc>().add(AddYoutubeVideo(
                      video: YoutubeVideo(
                        name: nameController.text,
                        path: urlController.text,
                      ),
                    ));
                Navigator.pop(dialogContext);
              },
              child: Text('ok'.tr()),
            ),
          ],
        );
      },
    );
  }

  void _showEditYoutubeDialog(BuildContext context, int index, YoutubeVideo video) {
    final nameController = TextEditingController(text: video.name);
    final urlController = TextEditingController(text: video.path);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Upravit YouTube video'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Název videa',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'YouTube URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                _buildUrlValidationIndicator(urlController),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text('cancel'.tr()),
            ),
            ElevatedButton(
              onPressed: () {
                if (urlController.text.isEmpty) return;
                context.read<EditSongBloc>().add(UpdateYoutubeVideo(
                      index: index,
                      video: YoutubeVideo(
                        name: nameController.text,
                        path: urlController.text,
                      ),
                    ));
                Navigator.pop(dialogContext);
              },
              child: Text('save'.tr()),
            ),
          ],
        );
      },
    );
  }

  Widget _buildUrlValidationIndicator(TextEditingController controller) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        controller.addListener(() => setLocalState(() {}));
        final videoId = extractYoutubeVideoId(controller.text);
        final isValid = videoId != null;
        final text = controller.text;

        if (text.isEmpty) return const SizedBox.shrink();

        return Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              color: isValid ? Colors.green : Colors.red,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isValid ? 'Platný YouTube odkaz (ID: $videoId)' : 'Neplatný YouTube odkaz',
                style: TextStyle(
                  fontSize: 12,
                  color: isValid ? Colors.green : Colors.red,
                ),
              ),
            ),
            if (isValid)
              TextButton.icon(
                onPressed: () => _openInBrowser(controller.text),
                icon: const Icon(Icons.open_in_browser, size: 16),
                label: const Text('Test', style: TextStyle(fontSize: 12)),
              ),
          ],
        );
      },
    );
  }

  void _openInBrowser(String url) async {
    final videoId = extractYoutubeVideoId(url);
    final youtubeUrl = videoId != null ? 'https://www.youtube.com/watch?v=$videoId' : url;
    final uri = Uri.tryParse(youtubeUrl);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

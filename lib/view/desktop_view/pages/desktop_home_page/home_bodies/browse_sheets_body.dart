import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';

/// Desktop view-only body for browsing sheet music of the selected song.
class BrowseSheetsBody extends StatefulWidget {
  const BrowseSheetsBody({super.key});

  @override
  State<BrowseSheetsBody> createState() => _BrowseSheetsBodyState();
}

class _BrowseSheetsBodyState extends State<BrowseSheetsBody> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewChordBloc, PreviewChordState>(
      builder: (context, state) {
        final song = state.data.song;
        final sheets = song?.sheets ?? [];

        if (sheets.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.music_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('noSheet'.tr(), style: const TextStyle(fontSize: 18, color: Colors.grey)),
                const SizedBox(height: 8),
                Text('noSheetMessage'.tr(), style: const TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return Row(
          children: [
            // Thumbnails sidebar
            Container(
              width: 200,
              decoration: BoxDecoration(
                border: Border(right: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      '${'sheets'.tr()} - ${song?.title ?? ''}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: sheets.length,
                      itemBuilder: (context, index) {
                        final sheetUrl = sheets[index];
                        final isSelected = index == _currentIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _currentIndex = index),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Column(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: _buildThumbnail(sheetUrl),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    '${index + 1} / ${sheets.length}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected ? Colors.blue : Colors.grey,
                                    ),
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
            ),
            // Main view area
            Expanded(
              child: _currentIndex < sheets.length
                  ? InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: _buildFullImage(sheets[_currentIndex]),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThumbnail(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        height: 120,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => const SizedBox(
          height: 120,
          child: Center(child: Icon(Icons.broken_image, color: Colors.grey)),
        ),
      );
    }
    return const SizedBox(
      height: 120,
      child: Center(child: Icon(Icons.image_not_supported, color: Colors.grey)),
    );
  }

  Widget _buildFullImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: url,
        fit: BoxFit.contain,
        placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
        errorWidget: (_, __, error) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('${'error'.tr()} $error', textAlign: TextAlign.center),
          ],
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
        const SizedBox(height: 8),
        Text(url, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';

/// Compact right-side panel for browsing sheet music of the selected song.
/// Designed to appear alongside the PreviewBody on desktop.
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
                  const Icon(Icons.music_note, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${'sheets'.tr()} - ${song?.title ?? ''}',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (sheets.length > 1)
                    Text(
                      '${_currentIndex + 1} / ${sheets.length}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'closeTooltip'.tr(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      context.read<DesktopRibbonMenuBloc>().add(const ChangeHomeBody(bodyName: 'preview'));
                    },
                  ),
                ],
              ),
            ),
            // Sheet navigation (thumbnails strip at top if multiple)
            if (sheets.length > 1)
              Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(4),
                  itemCount: sheets.length,
                  itemBuilder: (context, index) {
                    final isSelected = index == _currentIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _currentIndex = index),
                      child: Container(
                        width: 60,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected ? Colors.blue : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: _buildThumbnail(sheets[index]),
                        ),
                      ),
                    );
                  },
                ),
              ),
            // Main image view
            if (sheets.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.music_off, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('noSheetsAvailable'.tr(), style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Center(
                    child: _buildFullImage(sheets[_currentIndex < sheets.length ? _currentIndex : 0]),
                  ),
                ),
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
        height: 70,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => const SizedBox(
          height: 70,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (_, __, ___) => const SizedBox(
          height: 70,
          child: Center(child: Icon(Icons.broken_image, size: 20, color: Colors.grey)),
        ),
      );
    }
    return const SizedBox(
      height: 70,
      child: Center(child: Icon(Icons.image_not_supported, size: 20, color: Colors.grey)),
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

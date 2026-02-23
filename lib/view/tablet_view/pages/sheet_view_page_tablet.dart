import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';

class SheetViewPageTablet extends StatefulWidget {
  const SheetViewPageTablet({super.key});

  @override
  State<SheetViewPageTablet> createState() => _SheetViewPageTabletState();
}

class _SheetViewPageTabletState extends State<SheetViewPageTablet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewChordBloc, PreviewChordState>(
      builder: (context, state) {
        final song = state.data.song;
        final sheets = song?.sheets ?? [];

        return Scaffold(
          appBar: AppBar(
            title: Text(song?.title ?? 'sheets'.tr()),
            actions: [
              if (sheets.length > 1)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Center(
                    child: Text(
                      '${_currentPage + 1} / ${sheets.length}',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
            ],
          ),
          body: sheets.isEmpty
              ? Center(
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
                )
              : PageView.builder(
                  controller: _pageController,
                  itemCount: sheets.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final sheetUrl = sheets[index];
                    return InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: Center(
                        child: _buildSheetImage(sheetUrl),
                      ),
                    );
                  },
                ),
        );
      },
    );
  }

  Widget _buildSheetImage(String sheetUrl) {
    if (sheetUrl.startsWith('http://') || sheetUrl.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: sheetUrl,
        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('${'error'.tr()} $error', textAlign: TextAlign.center),
          ],
        ),
        fit: BoxFit.contain,
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
          const SizedBox(height: 8),
          Text(sheetUrl, style: const TextStyle(color: Colors.grey)),
        ],
      );
    }
  }
}

import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../../../core/youtube_helper.dart';
import '../../../model/youtube_video.dart';

/// A small YouTube player window that floats above the page and can be
/// dragged around by its header bar.
class FloatingVideoPlayer extends StatefulWidget {
  final List<YoutubeVideo> videos;
  final VoidCallback onClose;

  const FloatingVideoPlayer({super.key, required this.videos, required this.onClose});

  @override
  State<FloatingVideoPlayer> createState() => _FloatingVideoPlayerState();
}

class _FloatingVideoPlayerState extends State<FloatingVideoPlayer> {
  static const double _margin = 16;
  static const double _headerHeight = 40;
  static const double _minWidth = 240;

  late final WebViewController _controller = _createController();
  int _currentIndex = 0;
  bool _isLarge = false;
  Offset? _position;
  final ValueNotifier<Offset?> _dragPosition = ValueNotifier(null);

  @override
  void initState() {
    super.initState();
    _loadEmbed(0);
  }

  @override
  void dispose() {
    // Stops playback and frees the video decoder now instead of whenever the
    // native web view is garbage collected; matters on low-memory tablets.
    _controller.loadHtmlString('');
    _dragPosition.dispose();
    super.dispose();
  }

  WebViewController _createController() {
    // Without inline playback iOS switches every video to fullscreen on play.
    final PlatformWebViewControllerCreationParams params = WebViewPlatform.instance is WebKitWebViewPlatform
        ? WebKitWebViewControllerCreationParams(allowsInlineMediaPlayback: true)
        : const PlatformWebViewControllerCreationParams();

    return WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);
  }

  void _loadEmbed(int index) {
    final videoId = extractYoutubeVideoId(widget.videos[index].path);
    if (videoId == null) return;
    _controller.loadHtmlString(youtubeEmbedHtml(videoId), baseUrl: youtubeEmbedBaseUrl);
  }

  void _selectVideo(int index) {
    _loadEmbed(index);
    setState(() => _currentIndex = index);
  }

  String _videoName(int index) {
    final name = widget.videos[index].name;
    return name.isNotEmpty ? name : 'Video ${index + 1}';
  }

  Size _windowSize(Size area) {
    final width = min(max(area.width * (_isLarge ? 0.5 : 0.3), _minWidth), area.width - 2 * _margin);
    return Size(width, width * 9 / 16 + _headerHeight);
  }

  Offset _clampPosition(Offset position, Size window, Size area) {
    return Offset(
      position.dx.clamp(0.0, max(0.0, area.width - window.width)),
      position.dy.clamp(0.0, max(0.0, area.height - window.height)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        final window = _windowSize(area);
        final position = _clampPosition(
          _position ?? Offset(area.width - window.width - _margin, area.height - window.height - _margin),
          window,
          area,
        );

        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              width: window.width,
              height: window.height,
              child: Material(
                elevation: 8,
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      dragStartBehavior: DragStartBehavior.down,
                      onPanStart: (_) => _dragPosition.value = position,
                      onPanUpdate: (details) {
                        final current = _dragPosition.value ?? position;
                        _dragPosition.value = _clampPosition(current + details.delta, window, area);
                      },
                      onPanEnd: (_) => _finishDrag(),
                      onPanCancel: _finishDrag,
                      child: _buildHeader(context),
                    ),
                    Expanded(child: WebViewWidget(controller: _controller)),
                  ],
                ),
              ),
            ),
            // Moving the native web view lags far behind the finger on slow
            // tablets, so only this Flutter-drawn outline follows the drag.
            ValueListenableBuilder<Offset?>(
              valueListenable: _dragPosition,
              builder: (context, dragPosition, _) {
                if (dragPosition == null) return const SizedBox.shrink();
                return Positioned(
                  left: dragPosition.dx,
                  top: dragPosition.dy,
                  width: window.width,
                  height: window.height,
                  child: IgnorePointer(child: _buildDragOutline(context)),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _finishDrag() {
    final target = _dragPosition.value;
    if (target == null) return;
    _dragPosition.value = null;
    setState(() => _position = target);
  }

  Widget _buildDragOutline(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.15),
        border: Border.all(color: primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Icon(Icons.open_with, size: 32, color: primary)),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.onSurface);

    return Container(
      height: _headerHeight,
      color: colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const SizedBox(width: 4),
          Icon(Icons.drag_indicator, color: colorScheme.onSurfaceVariant),
          Expanded(
            child: widget.videos.length > 1
                ? PopupMenuButton<int>(
                    initialValue: _currentIndex,
                    onSelected: _selectVideo,
                    itemBuilder: (context) => [
                      for (var i = 0; i < widget.videos.length; i++) PopupMenuItem(value: i, child: Text(_videoName(i))),
                    ],
                    child: Row(
                      children: [
                        Flexible(child: Text(_videoName(_currentIndex), style: textStyle, overflow: TextOverflow.ellipsis)),
                        Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
                      ],
                    ),
                  )
                : Text(_videoName(_currentIndex), style: textStyle, overflow: TextOverflow.ellipsis),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            color: colorScheme.onSurface,
            icon: Icon(_isLarge ? Icons.close_fullscreen : Icons.open_in_full),
            onPressed: () => setState(() => _isLarge = !_isLarge),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            iconSize: 20,
            color: colorScheme.onSurface,
            icon: const Icon(Icons.close),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }
}

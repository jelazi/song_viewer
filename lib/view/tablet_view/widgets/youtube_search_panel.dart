import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';
import '../../../core/youtube_helper.dart';
import '../../../model/song/song.dart';
import '../../../services/ai_search_service.dart';
import '../../../services/constants.dart';

/// Side panel on the song page: searches YouTube and lists the results with a
/// small thumbnail. Tapping a result hands it to [onPreview].
class YoutubeSearchPanel extends StatefulWidget {
  final Song song;
  final String? previewVideoId;
  final bool canAdd;
  final ValueChanged<YoutubeSearchResult> onPreview;
  final VoidCallback onClose;

  const YoutubeSearchPanel({
    super.key,
    required this.song,
    required this.previewVideoId,
    required this.canAdd,
    required this.onPreview,
    required this.onClose,
  });

  @override
  State<YoutubeSearchPanel> createState() => _YoutubeSearchPanelState();
}

class _YoutubeSearchPanelState extends State<YoutubeSearchPanel> {
  late final TextEditingController _queryController = TextEditingController(text: widget.song.title);

  @override
  void initState() {
    super.initState();
    context.read<YoutubeSearchBloc>().add(const ClearYoutubeSearch());
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _search() {
    FocusScope.of(context).unfocus();
    context.read<YoutubeSearchBloc>().add(SearchYoutube(query: _queryController.text));
  }

  @override
  Widget build(BuildContext context) {
    final songVideoIds = (widget.song.youtubeVideos ?? []).map((video) => extractYoutubeVideoId(video.path)).toSet();

    return Material(
      elevation: 8,
      color: AppColor.whiteColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 4, 0),
            child: Row(
              children: [
                const Icon(Icons.youtube_searched_for, color: AppColor.primaryColor),
                const SizedBox(width: 8),
                Expanded(child: Text('youtubeSearch'.tr(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                IconButton(icon: const Icon(Icons.close, color: AppColor.grey1Color), onPressed: widget.onClose),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TextField(
              controller: _queryController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _search(),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'youtubeSearchHint'.tr(),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(icon: const Icon(Icons.search, color: AppColor.primaryColor), onPressed: _search),
              ),
            ),
          ),
          if (!widget.canAdd)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text('youtubeAddNeedsSuperuser'.tr(), style: const TextStyle(fontSize: 12, color: AppColor.grey1Color)),
            ),
          const Divider(height: 8),
          Expanded(
            child: BlocBuilder<YoutubeSearchBloc, YoutubeSearchState>(
              builder: (context, state) {
                switch (state.status) {
                  case YoutubeSearchStatus.initial:
                    return const SizedBox.shrink();
                  case YoutubeSearchStatus.loading:
                    return const Center(child: CircularProgressIndicator());
                  case YoutubeSearchStatus.failure:
                    return _buildMessage('youtubeSearchFailed'.tr());
                  case YoutubeSearchStatus.success:
                    if (state.results.isEmpty) return _buildMessage('youtubeNoResults'.tr());
                    return ListView.builder(
                      itemCount: state.results.length,
                      itemBuilder: (context, index) {
                        final result = state.results[index];
                        return _YoutubeResultTile(
                          key: ValueKey(result.videoId),
                          result: result,
                          isPlaying: result.videoId == widget.previewVideoId,
                          isInSong: songVideoIds.contains(result.videoId),
                          onTap: () => widget.onPreview(result),
                        );
                      },
                    );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(String text) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text, textAlign: TextAlign.center, style: const TextStyle(color: AppColor.grey1Color)),
    );
  }
}

class _YoutubeResultTile extends StatelessWidget {
  static const double _thumbnailWidth = 64;
  static const double _thumbnailHeight = 36;

  final YoutubeSearchResult result;
  final bool isPlaying;
  final bool isInSong;
  final VoidCallback onTap;

  const _YoutubeResultTile({
    super.key,
    required this.result,
    required this.isPlaying,
    required this.isInSong,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;

    return Material(
      color: isPlaying ? AppColor.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: CachedNetworkImage(
                  imageUrl: result.thumbnailUrl,
                  width: _thumbnailWidth,
                  height: _thumbnailHeight,
                  memCacheWidth: (_thumbnailWidth * pixelRatio).round(),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) => Container(color: AppColor.grey4Color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(result.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                    Text(result.channelTitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: AppColor.grey1Color)),
                  ],
                ),
              ),
              if (isInSong) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.check_circle, size: 18, color: AppColor.alertSuccessColor)),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:cached_network_image/cached_network_image.dart';
import 'package:default_project/services/ai_search_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../model/song/song.dart';
import '../../../../../services/constants.dart';
import '../../../widgets/my_toast.dart';

class SongEnrichmentBody extends StatefulWidget {
  const SongEnrichmentBody({super.key});

  @override
  State<SongEnrichmentBody> createState() => _SongEnrichmentBodyState();
}

class _SongEnrichmentBodyState extends State<SongEnrichmentBody> {
  final TextEditingController _youtubeSearchController = TextEditingController();
  final TextEditingController _songSearchController = TextEditingController();
  Song? _selectedSong;

  @override
  void dispose() {
    _youtubeSearchController.dispose();
    _songSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SongEnrichmentBloc, SongEnrichmentState>(
      listener: (context, state) {
        if (state.status == EnrichmentStatus.saved && state.song != null) {
          context.read<HomePageBloc>().add(UpdateSong(song: state.song!));
          context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: state.song!));
          context.read<DesktopRibbonMenuBloc>().add(ChangeIsSelectedSong(song: state.song!));
          MyToast.showText(text: 'enrichSaved'.tr(), typeNotification: TypeNotification.success);
        }
        if (state.status == EnrichmentStatus.error && state.errorMessage != null) {
          MyToast.showText(text: state.errorMessage!, typeNotification: TypeNotification.error);
        }
      },
      child: BlocBuilder<SongEnrichmentBloc, SongEnrichmentState>(
        builder: (context, enrichState) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left panel – song search & select
              SizedBox(
                width: 280,
                child: _buildSongSearchPanel(),
              ),
              const VerticalDivider(width: 1),
              // Right panel – enrichment results
              Expanded(
                child: _selectedSong == null
                    ? Center(
                        child: Text(
                          'enrichNoSong'.tr(),
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, _selectedSong!, enrichState),
                            const SizedBox(height: 20),
                            if (enrichState.status == EnrichmentStatus.analyzing) _buildLoadingSection('enrichAnalyzing'.tr()),
                            if (enrichState.status == EnrichmentStatus.searchingYoutube) _buildLoadingSection('enrichSearchingYoutube'.tr()),
                            if (enrichState.status == EnrichmentStatus.searchingSheets) _buildLoadingSection('enrichSearchingSheets'.tr()),
                            if (enrichState.analysis != null) ...[
                              _buildAiAnalysisSection(context, enrichState),
                              const SizedBox(height: 16),
                              _buildYoutubeSection(context, enrichState),
                              const SizedBox(height: 16),
                              _buildSheetMusicSection(context, enrichState),
                              const SizedBox(height: 16),
                              _buildApprovedSummary(context, enrichState),
                            ],
                          ],
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSongSearchPanel() {
    final allSongs = context.read<HomePageBloc>().state.listSong;
    final filter = _songSearchController.text.toLowerCase();
    final filteredSongs =
        filter.isEmpty ? allSongs : allSongs.where((s) => s.title.toLowerCase().contains(filter) || (s.interpret?.toLowerCase().contains(filter) ?? false)).toList();

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColor.grey3Color)),
          ),
          child: TextField(
            controller: _songSearchController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              labelText: 'filterSong'.tr(),
              labelStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _songSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _songSearchController.clear();
                        });
                      },
                    )
                  : null,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: filteredSongs.length,
            itemBuilder: (context, index) {
              final song = filteredSongs[index];
              final isSelected = _selectedSong?.id == song.id;
              return ListTile(
                dense: true,
                selected: isSelected,
                selectedTileColor: AppColor.primaryColor.withValues(alpha: 0.1),
                title: Text(
                  song.title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: song.interpret != null && song.interpret!.isNotEmpty ? Text(song.interpret!, style: const TextStyle(fontSize: 10, color: Colors.grey)) : null,
                leading: isSelected ? const Icon(Icons.auto_awesome, size: 16, color: AppColor.primaryColor) : null,
                onTap: () {
                  if (_selectedSong?.id != song.id) {
                    context.read<SongEnrichmentBloc>().add(const ResetEnrichment());
                  }
                  setState(() {
                    _selectedSong = song;
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Song song, SongEnrichmentState enrichState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColor.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColor.primaryColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'enrichTitle'.tr(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  '${song.title}${song.interpret != null && song.interpret!.isNotEmpty ? ' — ${song.interpret}' : ''}',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (enrichState.status == EnrichmentStatus.initial ||
              enrichState.status == EnrichmentStatus.error ||
              enrichState.status == EnrichmentStatus.saved ||
              enrichState.song?.id != song.id)
            ElevatedButton.icon(
              onPressed: () {
                context.read<SongEnrichmentBloc>().add(StartEnrichment(song: song));
              },
              icon: const Icon(Icons.search, size: 18),
              label: Text('enrichAnalyze'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          if (enrichState.hasApprovedChanges && enrichState.status != EnrichmentStatus.saving && enrichState.status != EnrichmentStatus.saved) ...[
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: () {
                context.read<SongEnrichmentBloc>().add(const SaveEnrichment());
              },
              icon: const Icon(Icons.save, size: 18),
              label: Text('enrichSave'.tr()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingSection(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildAiAnalysisSection(BuildContext context, SongEnrichmentState enrichState) {
    final analysis = enrichState.analysis!;
    return _buildSection(
      title: 'enrichAiResults'.tr(),
      icon: Icons.psychology,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (analysis.author != null && analysis.author!.isNotEmpty)
            _buildApprovalRow(
              label: 'enrichAuthor'.tr(),
              value: analysis.author!,
              isApproved: enrichState.approvedAuthor == analysis.author,
              onApprove: () {
                context.read<SongEnrichmentBloc>().add(ApproveAuthor(author: analysis.author!));
              },
              onRemove: () {
                context.read<SongEnrichmentBloc>().add(const ResetEnrichment());
                // Re-trigger with a state that clears author
              },
            ),
          if (analysis.originalTitle != null && analysis.originalTitle!.isNotEmpty)
            _buildApprovalRow(
              label: 'enrichOriginalTitle'.tr(),
              value: analysis.originalTitle!,
              isApproved: enrichState.approvedOriginalTitle == analysis.originalTitle,
              onApprove: () {
                context.read<SongEnrichmentBloc>().add(
                      ApproveOriginalTitle(originalTitle: analysis.originalTitle!),
                    );
              },
              onRemove: null,
            ),
          if (analysis.originalLanguage != null) _buildInfoRow('enrichOriginalLanguage'.tr(), analysis.originalLanguage!),
          if (analysis.genre != null) _buildInfoRow('enrichGenre'.tr(), analysis.genre!),
          if (analysis.additionalInfo != null && analysis.additionalInfo!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                analysis.additionalInfo!,
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildApprovalRow({
    required String label,
    required String value,
    required bool isApproved,
    required VoidCallback onApprove,
    VoidCallback? onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13)),
          ),
          if (!isApproved)
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 22),
              tooltip: 'enrichApprove'.tr(),
              onPressed: onApprove,
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 22),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                    tooltip: 'enrichRemove'.tr(),
                    onPressed: onRemove,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Widget _buildYoutubeSection(BuildContext context, SongEnrichmentState enrichState) {
    return _buildSection(
      title: 'enrichYoutube'.tr(),
      icon: Icons.play_circle_fill,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Custom search
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _youtubeSearchController,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    hintText: 'enrichYoutubeSearch'.tr(),
                    hintStyle: const TextStyle(fontSize: 12),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      context.read<SongEnrichmentBloc>().add(SearchYoutubeVideos(query: value));
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.search, size: 20),
                onPressed: () {
                  final query = _youtubeSearchController.text;
                  if (query.isNotEmpty) {
                    context.read<SongEnrichmentBloc>().add(SearchYoutubeVideos(query: query));
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Results
          if (enrichState.youtubeResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'enrichNoYoutubeResults'.tr(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            ...enrichState.youtubeResults.map((video) {
              final isApproved = enrichState.approvedVideos.any((v) => v.videoId == video.videoId);
              return _buildYoutubeVideoTile(context, video, isApproved);
            }),
        ],
      ),
    );
  }

  Widget _buildYoutubeVideoTile(BuildContext context, YoutubeSearchResult video, bool isApproved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: video.thumbnailUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: video.thumbnailUrl,
                    width: 120,
                    height: 68,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 120,
                      height: 68,
                      color: Colors.grey[200],
                      child: const Icon(Icons.play_circle, size: 30),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 120,
                      height: 68,
                      color: Colors.grey[200],
                      child: const Icon(Icons.error, size: 30),
                    ),
                  )
                : Container(
                    width: 120,
                    height: 68,
                    color: Colors.grey[200],
                    child: const Icon(Icons.play_circle, size: 30),
                  ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  video.channelTitle,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          // Open in browser
          IconButton(
            icon: const Icon(Icons.open_in_new, size: 18, color: Colors.blue),
            tooltip: 'enrichOpenYoutube'.tr(),
            onPressed: () {
              final uri = Uri.tryParse(video.videoUrl);
              if (uri != null) launchUrl(uri);
            },
          ),
          // Approve/remove
          if (!isApproved)
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 22),
              tooltip: 'enrichApprove'.tr(),
              onPressed: () {
                context.read<SongEnrichmentBloc>().add(ApproveYoutubeVideo(video: video));
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.remove_circle, color: Colors.red, size: 22),
              tooltip: 'enrichRemove'.tr(),
              onPressed: () {
                context.read<SongEnrichmentBloc>().add(RemoveEnrichmentVideo(videoId: video.videoId));
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSheetMusicSection(BuildContext context, SongEnrichmentState enrichState) {
    return _buildSection(
      title: 'enrichSheetMusic'.tr(),
      icon: Icons.music_note,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (enrichState.sheetResults.isEmpty)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                'enrichNoSheetResults'.tr(),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: enrichState.sheetResults.map((sheet) {
                final isApproved = enrichState.approvedSheets.any((s) => s.imageUrl == sheet.imageUrl);
                return _buildSheetMusicTile(context, sheet, isApproved);
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildSheetMusicTile(BuildContext context, SheetMusicResult sheet, bool isApproved) {
    return Container(
      width: 180,
      decoration: BoxDecoration(
        border: Border.all(color: isApproved ? Colors.green : Colors.grey[300]!, width: isApproved ? 2 : 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(7)),
            child: CachedNetworkImage(
              imageUrl: sheet.imageUrl,
              height: 120,
              width: 180,
              fit: BoxFit.cover,
              placeholder: (_, __) => Container(
                height: 120,
                color: Colors.grey[100],
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              errorWidget: (_, __, ___) => Container(
                height: 120,
                color: Colors.grey[100],
                child: const Icon(Icons.broken_image, size: 40),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Text(
                  sheet.title,
                  style: const TextStyle(fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!isApproved)
                      InkWell(
                        onTap: () {
                          context.read<SongEnrichmentBloc>().add(ApproveSheetMusic(sheet: sheet));
                        },
                        child: const Icon(Icons.add_circle_outline, color: Colors.green, size: 20),
                      )
                    else
                      InkWell(
                        onTap: () {
                          context.read<SongEnrichmentBloc>().add(RemoveSheetMusic(imageUrl: sheet.imageUrl));
                        },
                        child: const Icon(Icons.remove_circle, color: Colors.red, size: 20),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApprovedSummary(BuildContext context, SongEnrichmentState enrichState) {
    if (!enrichState.hasApprovedChanges) return const SizedBox.shrink();

    return _buildSection(
      title: 'enrichApprovedChanges'.tr(),
      icon: Icons.checklist,
      color: Colors.green.withValues(alpha: 0.05),
      borderColor: Colors.green.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (enrichState.approvedAuthor != null) _buildSummaryItem(Icons.person, '${'enrichAuthor'.tr()}: ${enrichState.approvedAuthor}'),
          if (enrichState.approvedOriginalTitle != null) _buildSummaryItem(Icons.title, '${'enrichOriginalTitle'.tr()}: ${enrichState.approvedOriginalTitle}'),
          if (enrichState.approvedVideos.isNotEmpty)
            ...enrichState.approvedVideos.map(
              (v) => _buildSummaryItem(Icons.play_circle, v.title),
            ),
          if (enrichState.approvedSheets.isNotEmpty)
            ...enrichState.approvedSheets.map(
              (s) => _buildSummaryItem(Icons.music_note, s.title),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Color? color,
    Color? borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor ?? AppColor.grey3Color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColor.primaryColor),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }
}

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/presentation_playlist_bloc/presentation_playlist_bloc.dart';
import '../../../model/song/song.dart';

/// Widget for managing presentation playlist with drag & drop support
class PresentationPlaylistWidget extends StatelessWidget {
  final Function(Song)? onSongSelected;
  final Function(Song, int)? onSongDoubleTap;

  const PresentationPlaylistWidget({
    super.key,
    this.onSongSelected,
    this.onSongDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PresentationPlaylistBloc, PresentationPlaylistState>(
      builder: (context, state) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            children: [
              _buildHeader(context, state),
              Expanded(
                child: state.isEmpty ? _buildEmptyState(context) : _buildPlaylist(context, state),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, PresentationPlaylistState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.playlist_play,
            size: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'presentationPlaylistTitle'.tr(),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${state.songCount}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          if (state.isNotEmpty) ...[
            IconButton(
              icon: const Icon(Icons.clear_all, size: 16),
              tooltip: 'deleteAll'.tr(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () {
                context.read<PresentationPlaylistBloc>().add(
                      const ClearPresentationPlaylist(),
                    );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return DragTarget<Song>(
      onAcceptWithDetails: (details) {
        context.read<PresentationPlaylistBloc>().add(
              AddSongToPresentation(song: details.data),
            );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHovering ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1) : null,
            border: isHovering
                ? Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  )
                : null,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(8),
              bottomRight: Radius.circular(8),
            ),
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.playlist_add,
                  size: 48,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'dragSongsHere'.tr(),
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'toCreatePlaylist'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaylist(BuildContext context, PresentationPlaylistState state) {
    return DragTarget<Song>(
      onAcceptWithDetails: (details) {
        // Add song from external source (song list)
        context.read<PresentationPlaylistBloc>().add(
              AddSongToPresentation(song: details.data),
            );
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          decoration: BoxDecoration(
            color: isHovering ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.05) : null,
          ),
          child: ReorderableListView.builder(
            buildDefaultDragHandles: false, // Disable default drag handles
            padding: const EdgeInsets.all(8),
            itemCount: state.playlist.songs.length,
            // newIndex is already adjusted for the removal at oldIndex — do
            // not decrement it.
            onReorderItem: (oldIndex, newIndex) {
              context.read<PresentationPlaylistBloc>().add(
                    ReorderPresentationSongs(
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    ),
                  );
            },
            itemBuilder: (context, index) {
              final song = state.playlist.songs[index];
              final isSelected = state.playlist.currentIndex == index;

              return _buildSongItem(
                context,
                song,
                index,
                isSelected,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSongItem(
    BuildContext context,
    Song song,
    int index,
    bool isSelected,
  ) {
    // Just return the card - ReorderableListView handles dragging
    return _buildSongCard(context, song, index, isSelected);
  }

  Widget _buildSongCard(
    BuildContext context,
    Song song,
    int index,
    bool isSelected,
  ) {
    return Card(
      key: ValueKey('${song.id}_$index'),
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surface,
      elevation: isSelected ? 2 : 0,
      child: InkWell(
        onTap: () {
          context.read<PresentationPlaylistBloc>().add(
                SelectPresentationSong(index: index),
              );
          if (onSongSelected != null) {
            onSongSelected!(song);
          }
        },
        onDoubleTap: () {
          context.read<PresentationPlaylistBloc>().add(
                SelectPresentationSong(index: index),
              );
          if (onSongDoubleTap != null) {
            onSongDoubleTap!(song, index);
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSurface,
                          ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (song.interpret != null && song.interpret!.isNotEmpty)
                      Text(
                        song.interpret!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected ? Theme.of(context).colorScheme.onPrimaryContainer.withValues(alpha: 0.7) : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Icon(
                    Icons.drag_indicator,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  Icons.close,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                tooltip: 'removeBtn'.tr(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  context.read<PresentationPlaylistBloc>().add(
                        RemoveSongFromPresentation(index: index),
                      );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

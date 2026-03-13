import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../blocs/export_blocs.dart';
import '../../../model/playlist.dart';
import '../../../services/constants.dart';

class PlaylistsPageMobile extends StatelessWidget {
  const PlaylistsPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('playlists'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'createPlaylist'.tr(),
            onPressed: () {
              context.read<PlaylistsBloc>().add(const OpenPlaylist(playlist: null, forEdit: true));
              Navigator.of(context).pushNamed('/editPlaylistPage');
            },
          ),
        ],
      ),
      body: BlocBuilder<PlaylistsBloc, PlaylistsState>(
        builder: (context, state) {
          final playlists = state.playlists;
          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.playlist_play, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'noPlaylists'.tr(),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: playlists.length,
            itemBuilder: (context, index) {
              final playlist = playlists[index];
              return _PlaylistTile(playlist: playlist);
            },
          );
        },
      ),
    );
  }
}

class _PlaylistTile extends StatelessWidget {
  final Playlist playlist;
  const _PlaylistTile({required this.playlist});

  @override
  Widget build(BuildContext context) {
    final allSongs = context.read<PlaylistsBloc>().songsRepository.songs;
    String songNames = '';
    var songIndex = 0;
    for (final songId in playlist.listSongIds) {
      try {
        final song = allSongs.firstWhere((s) => s.id == songId);
        songNames += song.title;
        if (songIndex < playlist.listSongIds.length - 1) {
          songNames += ', ';
        }
      } catch (_) {}
      songIndex++;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.playlist_play, color: AppColor.primaryColor),
        title: Text(playlist.name),
        subtitle: Text(
          songNames,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'open':
                context.read<PlaylistsBloc>().add(OpenPlaylist(playlist: playlist, forEdit: false));
                Navigator.of(context).pushNamed('/playlistPage');
                break;
              case 'edit':
                context.read<PlaylistsBloc>().add(OpenPlaylist(playlist: playlist, forEdit: true));
                Navigator.of(context).pushNamed('/editPlaylistPage');
                break;
              case 'copy':
                _copyPlaylistToClipboard(context, playlist);
                break;
              case 'delete':
                context.read<PlaylistsBloc>().add(DeletePlaylist(playlist: playlist));
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  const Icon(Icons.play_arrow, size: 20),
                  const SizedBox(width: 8),
                  Text('openPlaylist'.tr()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  const Icon(Icons.edit, size: 20, color: AppColor.primaryColor),
                  const SizedBox(width: 8),
                  Text('editPlaylist'.tr()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'copy',
              child: Row(
                children: [
                  const Icon(Icons.copy, size: 20, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('copyPlaylist'.tr()),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  const Icon(Icons.delete, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Text('deletePlaylist'.tr()),
                ],
              ),
            ),
          ],
        ),
        onTap: () {
          context.read<PlaylistsBloc>().add(OpenPlaylist(playlist: playlist, forEdit: false));
          Navigator.of(context).pushNamed('/playlistPage');
        },
      ),
    );
  }

  void _copyPlaylistToClipboard(BuildContext context, Playlist playlist) {
    final allSongs = context.read<PlaylistsBloc>().songsRepository.songs;
    final buffer = StringBuffer();
    buffer.writeln(playlist.name);
    var index = 1;
    for (final songId in playlist.listSongIds) {
      try {
        final song = allSongs.firstWhere((s) => s.id == songId);
        buffer.writeln('$index. ${song.title}');
        index++;
      } catch (_) {}
    }
    Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('playlistCopied'.tr()),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

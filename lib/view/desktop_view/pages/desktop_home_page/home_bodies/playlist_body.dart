import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../model/playlist.dart';
import '../../../../../model/song/song.dart';
import '../../../../../services/constants.dart';
import '../../../widgets/my_toast.dart';

class PlaylistBody extends StatefulWidget {
  const PlaylistBody({super.key});

  @override
  State<PlaylistBody> createState() => _PlaylistBodyState();
}

class _PlaylistBodyState extends State<PlaylistBody> {
  Playlist? _selectedPlaylist;
  bool _isEditing = false;
  bool _isCreatingNew = false;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  List<Song> _editSongs = [];

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _startNewPlaylist() {
    setState(() {
      _isCreatingNew = true;
      _isEditing = true;
      _selectedPlaylist = null;
      _nameController.text = DateFormat('dd.MM.yyyy').format(DateTime.now());
      _editSongs = [];
      _searchController.clear();
    });
  }

  void _editPlaylist(Playlist playlist) {
    final allSongs = context.read<HomePageBloc>().songsRepository.songs;
    final songs = <Song>[];
    for (final id in playlist.listSongIds) {
      try {
        final song = allSongs.firstWhere((s) => s.id == id);
        songs.add(song);
      } catch (_) {}
    }
    setState(() {
      _selectedPlaylist = playlist;
      _isEditing = true;
      _isCreatingNew = false;
      _nameController.text = playlist.name;
      _editSongs = songs;
      _searchController.clear();
    });
  }

  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      _isCreatingNew = false;
      _selectedPlaylist = null;
      _editSongs = [];
    });
  }

  Future<void> _savePlaylist() async {
    if (_nameController.text.trim().isEmpty) {
      MyToast.showText(text: 'emptyNameTitle'.tr(), typeNotification: TypeNotification.warning);
      return;
    }
    if (_editSongs.isEmpty) {
      MyToast.showText(text: 'Playlist neobsahuje žádné písně', typeNotification: TypeNotification.warning);
      return;
    }

    final playlist = Playlist(
      id: _isCreatingNew ? null : _selectedPlaylist?.id,
      name: _nameController.text.trim(),
    );
    playlist.listSongIds = _editSongs.map((s) => s.id).toList();

    final result = await context.read<PlaylistsBloc>().playlistRepository.savePlaylist(playlist);
    if (result) {
      MyToast.showText(text: 'Playlist uložen', typeNotification: TypeNotification.success);
      context.read<PlaylistsBloc>().add(const RefreshPlaylists());
      setState(() {
        _isEditing = false;
        _isCreatingNew = false;
        _selectedPlaylist = null;
        _editSongs = [];
      });
    } else {
      MyToast.showText(text: 'Chyba při ukládání', typeNotification: TypeNotification.error);
    }
  }

  void _loadToPresentation(Playlist playlist) {
    context.read<PresentationPlaylistBloc>().add(
          LoadPresentationPlaylist(playlist: playlist),
        );
    MyToast.showText(text: 'Playlist "${playlist.name}" načten do prezentace', typeNotification: TypeNotification.success);
  }

  Future<void> _deletePlaylist(Playlist playlist) async {
    final result = await context.read<PlaylistsBloc>().playlistRepository.deletePlaylist(playlist);
    if (result) {
      MyToast.showText(text: 'Playlist smazán', typeNotification: TypeNotification.success);
      context.read<PlaylistsBloc>().add(const RefreshPlaylists());
      if (_selectedPlaylist?.id == playlist.id) {
        _cancelEdit();
      }
    } else {
      MyToast.showText(text: 'Chyba při mazání', typeNotification: TypeNotification.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistsBloc, PlaylistsState>(
      builder: (context, playlistsState) {
        return Row(
          children: [
            // Left panel: list of saved playlists
            _buildPlaylistList(playlistsState),
            // Vertical divider
            Container(
              width: 1,
              color: AppColor.grey3Color,
            ),
            // Right panel: editor or playlist detail
            Expanded(
              child: _isEditing ? _buildEditor(playlistsState) : _buildDetailOrEmpty(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistList(PlaylistsState state) {
    final playlists = state.playlists;
    return Container(
      width: 320,
      decoration: const BoxDecoration(
        border: Border(right: BorderSide(color: AppColor.grey3Color, width: 1)),
      ),
      child: Column(
        children: [
          // Header with "New" button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColor.grey3Color)),
            ),
            child: Row(
              children: [
                const Icon(Icons.playlist_play, size: 20, color: AppColor.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'playlistScreenTitle'.tr(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '${playlists.length}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, size: 20, color: Colors.green),
                  tooltip: 'Nový playlist',
                  onPressed: _startNewPlaylist,
                ),
              ],
            ),
          ),
          // Playlist items
          Expanded(
            child: playlists.isEmpty
                ? Center(
                    child: Text(
                      'Žádné uložené playlisty',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: playlists.length,
                    itemBuilder: (context, index) {
                      final playlist = playlists[index];
                      final isSelected = _selectedPlaylist?.id == playlist.id && !_isCreatingNew;
                      return _buildPlaylistTile(playlist, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylistTile(Playlist playlist, bool isSelected) {
    return InkWell(
      onTap: () {
        if (_isEditing) return;
        setState(() {
          _selectedPlaylist = playlist;
          _isEditing = false;
          _isCreatingNew = false;
        });
      },
      onDoubleTap: () => _editPlaylist(playlist),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primaryColor.withOpacity(0.08) : null,
          border: const Border(bottom: BorderSide(color: AppColor.grey3Color, width: 0.5)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.playlist_play,
              size: 20,
              color: isSelected ? AppColor.primaryColor : Colors.grey,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    playlist.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? AppColor.primaryColor : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${playlist.listSongIds.length} písní',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            // Action buttons
            IconButton(
              icon: const Icon(Icons.present_to_all, size: 16),
              tooltip: 'Načíst do prezentace',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _loadToPresentation(playlist),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
              tooltip: 'Editovat',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _editPlaylist(playlist),
            ),
            IconButton(
              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
              tooltip: 'deletePlaylist'.tr(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => _deletePlaylist(playlist),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailOrEmpty() {
    if (_selectedPlaylist == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_play, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Vyberte playlist ze seznamu nebo vytvořte nový',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _startNewPlaylist,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nový playlist'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    // Read-only detail view of selected playlist
    final allSongs = context.read<HomePageBloc>().songsRepository.songs;
    final songs = <Song>[];
    for (final id in _selectedPlaylist!.listSongIds) {
      try {
        final song = allSongs.firstWhere((s) => s.id == id);
        songs.add(song);
      } catch (_) {}
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColor.grey3Color)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedPlaylist!.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${songs.length} písní',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _loadToPresentation(_selectedPlaylist!),
                icon: const Icon(Icons.present_to_all, size: 18),
                label: const Text('Načíst do prezentace'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _editPlaylist(_selectedPlaylist!),
                icon: const Icon(Icons.edit, size: 18),
                label: const Text('Editovat'),
              ),
            ],
          ),
        ),
        // Song list (read-only)
        Expanded(
          child: songs.isEmpty
              ? const Center(child: Text('Playlist neobsahuje žádné písně', style: TextStyle(color: Colors.grey)))
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        backgroundColor: AppColor.primaryLightestColor,
                        child: Text('${index + 1}', style: const TextStyle(fontSize: 11, color: AppColor.primaryDarkColor)),
                      ),
                      title: Text(song.title, style: const TextStyle(fontSize: 13)),
                      subtitle: song.interpret != null && song.interpret!.isNotEmpty ? Text(song.interpret!, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
                      onTap: () {
                        // Open song in preview
                        context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: song));
                        context.read<DesktopRibbonMenuBloc>().add(ChangeIsSelectedSong(song: song));
                        context.read<DesktopRibbonMenuBloc>().add(const ChangeHomeBody(bodyName: 'preview'));
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEditor(PlaylistsState playlistsState) {
    return Row(
      children: [
        // Editor: current playlist songs + name
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with name field + actions
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColor.grey3Color)),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _isCreatingNew ? Icons.add_circle : Icons.edit,
                          size: 20,
                          color: AppColor.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isCreatingNew ? 'Nový playlist' : 'Editace playlistu',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 200,
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          labelText: 'enterPlaylistName'.tr(),
                          labelStyle: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    Text(
                      '${_editSongs.length} písní',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    ElevatedButton.icon(
                      onPressed: _savePlaylist,
                      icon: const Icon(Icons.save, size: 16),
                      label: const Text('Uložit', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _cancelEdit,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text('Zrušit', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
              // Current songs in playlist (reorderable)
              Expanded(
                child: _editSongs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.playlist_add, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 8),
                            Text('Přidejte písně ze seznamu vpravo', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _editSongs.length,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final song = _editSongs.removeAt(oldIndex);
                            _editSongs.insert(newIndex, song);
                          });
                        },
                        itemBuilder: (context, index) {
                          final song = _editSongs[index];
                          return Card(
                            key: ValueKey('edit_${song.id}_$index'),
                            margin: const EdgeInsets.only(bottom: 4),
                            child: ListTile(
                              dense: true,
                              leading: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle, size: 18, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: AppColor.primaryLightestColor,
                                    child: Text('${index + 1}', style: const TextStyle(fontSize: 10, color: AppColor.primaryDarkColor)),
                                  ),
                                ],
                              ),
                              title: Text(song.title, style: const TextStyle(fontSize: 13)),
                              subtitle:
                                  song.interpret != null && song.interpret!.isNotEmpty ? Text(song.interpret!, style: const TextStyle(fontSize: 11, color: Colors.grey)) : null,
                              trailing: IconButton(
                                icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                tooltip: 'Odebrat',
                                onPressed: () {
                                  setState(() {
                                    _editSongs.removeAt(index);
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
        // Vertical divider
        Container(width: 1, color: AppColor.grey3Color),
        // Add songs panel (right)
        SizedBox(
          width: 300,
          child: _buildAddSongsPanel(),
        ),
      ],
    );
  }

  Widget _buildAddSongsPanel() {
    final allSongs = context.read<HomePageBloc>().state.listSong;
    final filter = _searchController.text.toLowerCase();
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
            controller: _searchController,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              labelText: 'filterSong'.tr(),
              labelStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
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
              final isInPlaylist = _editSongs.any((s) => s.id == song.id);
              return ListTile(
                dense: true,
                title: Text(
                  song.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isInPlaylist ? Colors.grey : null,
                  ),
                ),
                subtitle: song.interpret != null && song.interpret!.isNotEmpty ? Text(song.interpret!, style: const TextStyle(fontSize: 10, color: Colors.grey)) : null,
                trailing: IconButton(
                  icon: Icon(
                    isInPlaylist ? Icons.check : Icons.add,
                    size: 16,
                    color: isInPlaylist ? Colors.green : AppColor.primaryColor,
                  ),
                  onPressed: () {
                    setState(() {
                      _editSongs.add(song);
                    });
                  },
                ),
                onTap: () {
                  setState(() {
                    _editSongs.add(song);
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

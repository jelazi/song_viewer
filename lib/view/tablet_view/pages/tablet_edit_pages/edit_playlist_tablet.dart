import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../blocs/export_blocs.dart';
import '../../../../model/song/song.dart';
import '../../../../services/constants.dart';

class EditPlaylistTablet extends StatefulWidget {
  const EditPlaylistTablet({super.key});

  @override
  State<EditPlaylistTablet> createState() => _EditPlaylistTabletState();
}

class _EditPlaylistTabletState extends State<EditPlaylistTablet> {
  final TextEditingController _filter = TextEditingController();
  final TextEditingController _playlistName = TextEditingController();
  final _scrollController = ScrollController();
  var draggedItem;
  var dragIndex;

  @override
  void initState() {
    super.initState();
    _playlistName.text = context.read<PlaylistsBloc>().state.namePlaylist;
  }

  @override
  Widget build(BuildContext context) {
    if (_playlistName.text.isEmpty || _playlistName.text != context.read<PlaylistsBloc>().state.currentPlaylist.name) {
      _playlistName.text = context.read<PlaylistsBloc>().state.currentPlaylist.name;
    }
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          context.read<PlaylistsBloc>().add(const ClosePlaylist());
          return;
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          actions: [
            BlocBuilder<PlaylistsBloc, PlaylistsState>(
              builder: (context, state) {
                return OutlinedButton(
                  onPressed: () {
                    context.read<PlaylistsBloc>().add(const SavePlaylist());
                  },
                  child: Row(
                    children: [
                      const Icon(Icons.save, color: AppColor.primaryColor),
                      const SizedBox(width: 8),
                      Text('save'.tr()),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<PlaylistsBloc, PlaylistsState>(
          builder: (context, state) {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _playlistName,
                        decoration: InputDecoration(
                          hintText: 'playlistName'.tr(),
                          prefixIcon: const Icon(Icons.playlist_add),
                        ),
                        onChanged: (value) {
                          context.read<PlaylistsBloc>().add(ChangeNamePlaylist(playlist: state.currentPlaylist, name: value));
                        },
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.height - 180,
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: Column(
                            children: [
                              for (int i = 0; i < state.currentSongs.length; i++)
                                CurrentSongCard(
                                  song: state.currentSongs[i],
                                  key: ValueKey(i),
                                ),
                              if (draggedItem != null)
                                CurrentSongCard(
                                  song: draggedItem['song'],
                                  key: const ValueKey('drag-placeholder'),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 20, thickness: 2),
                Expanded(
                  child: Column(
                    children: [
                      TextField(
                        controller: _filter,
                        decoration: InputDecoration(
                          hintText: 'filterSong'.tr(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            onPressed: () {
                              _filter.clear();
                              context.read<PlaylistsBloc>().add(const FilterSongPlaylist(filter: ''));
                            },
                            icon: const Icon(Icons.clear),
                          ),
                        ),
                        onChanged: (value) {
                          context.read<PlaylistsBloc>().add(FilterSongPlaylist(filter: value));
                        },
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: state.filteredSongs.isEmpty ? state.allSongs.length : state.filteredSongs.length,
                          itemBuilder: (context, index) {
                            final song = state.filteredSongs.isEmpty ? state.allSongs[index] : state.filteredSongs[index];
                            return CardSongForPlaylist(song: song);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class CurrentSongCard extends StatelessWidget {
  final Song? song;

  const CurrentSongCard({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistsBloc, PlaylistsState>(
      builder: (context, state) {
        return Card(
          color: AppColor.whiteColor,
          borderOnForeground: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5.0),
            side: const BorderSide(
              color: AppColor.grey3Color,
              width: 1.0,
            ),
          ),
          child: GestureDetector(
            onTap: () {
              //   context.read<PlaylistsBloc>().add(DeleteSongFromPlaylist(song: e));
            },
            child: Container(
                child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(song?.title ?? '', style: const TextStyle(fontSize: 16)),
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 60,
                      height: 80,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                            onTap: () {
                              if (song == null) {
                                return;
                              }
                              context.read<PlaylistsBloc>().add(MoveSongInPlaylist(oldIndex: state.currentSongs.indexOf(song!), newIndex: state.currentSongs.indexOf(song!) - 1));
                            },
                            child: Container(
                              padding: EdgeInsets.zero,
                              child: const Icon(
                                Icons.arrow_upward,
                                color: AppColor.primaryColor,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              if (song == null) {
                                return;
                              }
                              context.read<PlaylistsBloc>().add(MoveSongInPlaylist(oldIndex: state.currentSongs.indexOf(song!), newIndex: state.currentSongs.indexOf(song!) + 1));
                            },
                            child: Container(
                              padding: EdgeInsets.zero,
                              child: const Icon(Icons.arrow_downward, color: AppColor.primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: AppColor.alertErrorColor),
                      onPressed: () {
                        if (song == null) {
                          return;
                        }
                        context.read<PlaylistsBloc>().add(RemoveSongFromPlaylist(index: state.currentSongs.indexOf(song!)));
                      },
                    ),
                  ],
                ),
              ],
            )),
          ),
        );
      },
    );
  }
}

class CardSongForPlaylist extends StatelessWidget {
  final Song song;
  const CardSongForPlaylist({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        context.read<PlaylistsBloc>().add(AddSongToPlaylist(playlist: context.read<PlaylistsBloc>().state.currentPlaylist, song: song));
      },
      child: Card(
        color: AppColor.whiteColor,
        borderOnForeground: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
          side: const BorderSide(
            color: AppColor.grey3Color,
            width: 1.0,
          ),
        ),
        child: ListTile(
          title: Text(song.title),
          trailing: IconButton(
            icon: const Icon(Icons.add, color: AppColor.primaryColor),
            onPressed: () {
              context.read<PlaylistsBloc>().add(AddSongToPlaylist(playlist: context.read<PlaylistsBloc>().state.currentPlaylist, song: song));
            },
          ),
          onTap: () {
            // context.read<PlaylistsBloc>().add(DeleteSongFromPlaylist(song: e));
          },
        ),
      ),
    );
  }
}

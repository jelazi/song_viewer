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

  @override
  void initState() {
    super.initState();
    _playlistName.text = context.read<PlaylistsBloc>().state.currentPlaylist.name;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) {
          context.read<PlaylistsBloc>().add(const ClosePlaylist());
          return;
        }
      },
      child: Scaffold(
          appBar: AppBar(),
          body: BlocBuilder<PlaylistsBloc, PlaylistsState>(
            builder: (context, state) {
              return SizedBox(
                height: MediaQuery.of(context).size.height - 90,
                width: MediaQuery.of(context).size.width,
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
                    Row(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height - 140,
                            width: MediaQuery.of(context).size.width * 0.5 - 20,
                            child: Column(
                              children: [
                                Text('currentPlaylist'.tr()),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height - 180,
                                  child: ListView(
                                    children: state.currentSongs.map((e) => CurrentSongCard(song: e)).toList(),
                                  ),
                                ),
                              ],
                            )),
                        const SizedBox(
                          width: 8,
                        ),
                        const VerticalDivider(
                          width: 20,
                          thickness: 2,
                        ),
                        const SizedBox(
                          width: 8,
                        ),
                        SizedBox(
                            width: MediaQuery.of(context).size.width * 0.5 - 20,
                            height: MediaQuery.of(context).size.height - 180,
                            child: Column(
                              children: [
                                Text(state.filteredSongs.isEmpty ? 'allSongs'.tr() : 'filteredSongs'.tr()),
                                TextField(
                                  controller: _filter,
                                  decoration: InputDecoration(
                                    hintText: 'filterSong'.tr(),
                                    prefixIcon: const Icon(Icons.search),
                                    suffixIcon: IconButton(
                                      onPressed: (() {
                                        _filter.clear();
                                        context.read<PlaylistsBloc>().add(const FilterSongPlaylist(filter: ''));
                                      }),
                                      icon: const Icon(Icons.clear),
                                    ),
                                  ),
                                  onChanged: (value) {
                                    context.read<PlaylistsBloc>().add(FilterSongPlaylist(filter: value));
                                  },
                                ),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height - 250,
                                  child: Scrollbar(
                                    controller: _scrollController,
                                    thumbVisibility: true,
                                    trackVisibility: true,
                                    thickness: 40,
                                    radius: const Radius.circular(5),
                                    child: ListView.builder(
                                        controller: _scrollController,
                                        itemCount: state.filteredSongs.isEmpty ? state.allSongs.length : state.filteredSongs.length,
                                        itemBuilder: (context, index) {
                                          if (state.filteredSongs.isEmpty) {
                                            return CardSongForPlaylist(song: state.allSongs[index]);
                                          } else {
                                            return CardSongForPlaylist(song: state.filteredSongs[index]);
                                          }
                                        }),
                                  ),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ],
                ),
              );
            },
          )),
    );
  }
}

class CurrentSongCard extends StatelessWidget {
  final Song song;
  const CurrentSongCard({
    super.key,
    required this.song,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistsBloc, PlaylistsState>(
      builder: (context, state) {
        return Draggable(
          feedback: Container(
            height: 50,
            width: 60,
            decoration: BoxDecoration(
              color: AppColor.whiteColor,
              border: Border.all(color: AppColor.grey3Color),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
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
                icon: const Icon(Icons.delete, color: AppColor.alertErrorColor),
                onPressed: () {
                  context.read<PlaylistsBloc>().add(RemoveSongFromPlaylist(index: state.currentSongs.indexOf(song)));
                },
              ),
              onTap: () {
                //   context.read<PlaylistsBloc>().add(DeleteSongFromPlaylist(song: e));
              },
            ),
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
    return Draggable(
      childWhenDragging: Container(
        height: 60,
        width: 150,
        decoration: BoxDecoration(
          color: AppColor.whiteColor,
          border: Border.all(color: AppColor.grey3Color),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
      feedback: Card(
        color: AppColor.whiteColor,
        borderOnForeground: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
          side: const BorderSide(
            color: AppColor.grey3Color,
            width: 1.0,
          ),
        ),
        child: Container(
          height: 60,
          width: MediaQuery.of(context).size.width * 0.5 - 100,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.only(left: 15),
          child: Text(song.title),
        ),
      ),
      child: GestureDetector(
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
      ),
    );
  }
}

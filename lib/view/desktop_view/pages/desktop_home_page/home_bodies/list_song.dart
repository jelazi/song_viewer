import 'package:default_project/model/song/song.dart';
import 'package:default_project/services/presentation_window_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../services/constants.dart';
import '../../../widgets/presentation_playlist_widget.dart';
import '../../../widgets/search_field_desktop.dart';

class ListSong extends StatefulWidget {
  const ListSong({
    super.key,
  });

  @override
  State<ListSong> createState() => _ListSongState();
}

class _ListSongState extends State<ListSong> {
  final TextEditingController _filter = TextEditingController();
  double _songListHeight = 400.0; // Absolute height instead of flex

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePageBloc, HomePageState>(
      builder: (context, state) {
        return Container(
            width: 300,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColor.grey3Color, width: 1.0), right: BorderSide(color: AppColor.grey3Color, width: 1.0)),
            ),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                height: 50,
                child: SearchFieldDesktop(
                  controller: _filter,
                  labelText: 'filterSong'.tr(),
                  onSearch: (value) {
                    context.read<HomePageBloc>().add(FilterSong(filter: value));
                  },
                  onClear: () {
                    context.read<HomePageBloc>().add(const FilterSong(filter: ''));
                  },
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableHeight = constraints.maxHeight;
                    final minPlaylistHeight = 150.0;
                    final dividerSpacing = 24.0; // 8 + 8 + 8 for divider and spacing
                    final maxSongListHeight = availableHeight - minPlaylistHeight - dividerSpacing;

                    // Clamp song list height
                    final clampedSongListHeight = _songListHeight.clamp(100.0, maxSongListHeight);
                    final playlistHeight = availableHeight - clampedSongListHeight - dividerSpacing;

                    return Column(
                      children: [
                        SizedBox(
                          height: clampedSongListHeight,
                          child: ListView(
                            children: state.listSong
                                .map((song) => Draggable<Song>(
                                      data: song,
                                      feedback: Material(
                                        elevation: 4,
                                        borderRadius: BorderRadius.circular(4),
                                        child: Container(
                                          width: 280,
                                          height: 40,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColor.primaryColor.withOpacity(0.9),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(Icons.music_note, size: 16, color: Colors.white),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  song.title,
                                                  style: const TextStyle(fontSize: 14, color: Colors.white),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      child: Container(
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          border: Border(
                                            top: BorderSide(color: AppColor.grey3Color, width: 1.0),
                                          ),
                                        ),
                                        child: BlocBuilder<PreviewChordBloc, PreviewChordState>(
                                          builder: (context, state) {
                                            return ListTile(
                                              selected: state.data.song?.id == song.id,
                                              selectedTileColor: AppColor.grey4Color,
                                              title: SizedBox(
                                                  width: 200,
                                                  child: Text(
                                                    song.title,
                                                    style: const TextStyle(fontSize: 14),
                                                    overflow: TextOverflow.ellipsis,
                                                  )),
                                              onTap: () {
                                                if (state.data.song?.id != song.id) {
                                                  context.read<DesktopRibbonMenuBloc>().add(ChangeIsSelectedSong(song: song));
                                                  context.read<PreviewChordBloc>().add(ChangeCurrentSong(song: song));
                                                  context.read<EditSongBloc>().add(ChangeEditSong(song: song, isOriginalLyrics: false));
                                                } else {
                                                  context.read<DesktopRibbonMenuBloc>().add(const ChangeIsSelectedSong(song: null));
                                                  context.read<PreviewChordBloc>().add(const ChangeCurrentSong(song: null));
                                                  context.read<EditSongBloc>().add(ChangeEditSong(song: Song.empty(), isOriginalLyrics: false));
                                                }
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Resizable divider
                        MouseRegion(
                          cursor: SystemMouseCursors.resizeRow,
                          child: GestureDetector(
                            onVerticalDragUpdate: (details) {
                              setState(() {
                                _songListHeight = (_songListHeight + details.delta.dy).clamp(100.0, maxSongListHeight);
                              });
                            },
                            child: Container(
                              height: 8,
                              color: Colors.transparent,
                              child: Center(
                                child: Container(
                                  height: 2,
                                  color: AppColor.grey3Color,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: playlistHeight,
                          child: PresentationPlaylistWidget(
                            onSongSelected: (song) {
                              PresentationWindowManager().sendSongToPresentation(context, song);
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ]));
      },
    );
  }
}

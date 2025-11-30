import 'package:default_project/model/song/song.dart';
import 'package:default_project/services/presentation_window_manager.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../services/constants.dart';
import '../../../widgets/presentation_playlist_widget.dart';

class ListSong extends StatefulWidget {
  const ListSong({
    super.key,
  });

  @override
  State<ListSong> createState() => _ListSongState();
}

class _ListSongState extends State<ListSong> {
  final TextEditingController _filter = TextEditingController();
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
                child: TextField(
                  controller: _filter,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: 'filterSong'.tr(),
                  ),
                  onChanged: (value) {
                    context.read<HomePageBloc>().add(FilterSong(filter: value));
                  },
                ),
              ),
              Expanded(
                flex: 3,
                child: ListView(
                  shrinkWrap: true,
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
              const Divider(height: 1, color: AppColor.grey3Color),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: PresentationPlaylistWidget(
                  onSongSelected: (song) {
                    PresentationWindowManager().sendSongToPresentation(context, song);
                  },
                ),
              ),
            ]));
      },
    );
  }
}

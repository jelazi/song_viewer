import 'package:default_project/model/song/song.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../services/constants.dart';

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
                child: ListView(
                  shrinkWrap: true,
                  children: state.listSong
                      .map((song) => Container(
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
                          ))
                      .toList(),
                ),
              ),
            ]));
      },
    );
  }
}

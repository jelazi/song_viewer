import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:toggle_switch/toggle_switch.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../services/constants.dart';

class ListWebSong extends StatefulWidget {
  const ListWebSong({
    super.key,
  });

  @override
  State<ListWebSong> createState() => _ListWebSongState();
}

class _ListWebSongState extends State<ListWebSong> {
  final listSearchWeb = [
    'superMusic',
    'velkyZpevnik',
  ];

  final listSelectTypeSearch = ['song', 'interpret'];

  final TextEditingController _filter = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebBloc, WebState>(
      builder: (context, state) {
        return Container(
            width: 300,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColor.grey3Color, width: 1.0), right: BorderSide(color: AppColor.grey3Color, width: 1.0)),
            ),
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ToggleSwitch(
                  fontSize: 11.0,
                  minWidth: 120.0,
                  initialLabelIndex: state.searchWeb,
                  cornerRadius: 10.0,
                  activeBgColor: const [AppColor.primaryColor],
                  activeFgColor: Colors.white,
                  inactiveBgColor: Colors.grey,
                  inactiveFgColor: Colors.white,
                  labels: state.listSearchWeb,
                  onToggle: (index) {
                    context.read<WebBloc>().add(ChangeSearchWeb(searchWeb: index ?? 0));
                  },
                ),
              ),
              // search type
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ToggleSwitch(
                  fontSize: 11.0,
                  minWidth: 120.0,
                  initialLabelIndex: state.searchType,
                  cornerRadius: 10.0,
                  activeBgColor: const [AppColor.primaryColor],
                  activeFgColor: Colors.white,
                  inactiveBgColor: Colors.grey,
                  inactiveFgColor: Colors.white,
                  labels: state.listSelectTypeSearch,
                  onToggle: (index) {
                    context.read<WebBloc>().add(ChangeSearchType(searchType: index ?? 0));
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.only(bottom: 10),
                height: 50,
                child: TextField(
                  controller: _filter,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: state.searchType == 0 ? 'filterSong'.tr() : 'filterInterpret'.tr(),
                  ),
                  onChanged: (value) {},
                ),
              ),
              ElevatedButton(
                  onPressed: () {
                    context.read<WebBloc>().add(FilterSongs(filter: _filter.text));
                  },
                  child: Center(
                    child: Text('search'.tr()),
                  )),
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: state.filteredSongs
                      .map((song) => Container(
                            height: 40,
                            decoration: const BoxDecoration(
                              border: Border(
                                top: BorderSide(color: AppColor.grey3Color, width: 1.0),
                              ),
                            ),
                            child: BlocBuilder<WebBloc, WebState>(
                              builder: (context, state) {
                                return ListTile(
                                  selected: state.currentSong?.title == song.title,
                                  selectedTileColor: AppColor.grey4Color,
                                  title: SizedBox(
                                      width: 200,
                                      child: Text(
                                        song.title,
                                        style: const TextStyle(fontSize: 14),
                                        overflow: TextOverflow.ellipsis,
                                      )),
                                  onTap: () {
                                    if (state.currentSong?.title == song.title) {
                                      context.read<WebBloc>().add(const ChangeCurrentWebSong(song: null));
                                    } else {
                                      context.read<WebBloc>().add(ChangeCurrentWebSong(song: song));
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

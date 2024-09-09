import 'package:default_project/blocs/web_bloc/web_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
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

  final TextEditingController _filterInterpret = TextEditingController();
  final TextEditingController _filterSong = TextEditingController();
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
              const Row(
                children: [
                  Text('pisnicky-akordy.cz', style: const TextStyle(fontSize: 12)),
                ],
              ),
              Visibility(
                visible: state.currentInterpret == null,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 10),
                  height: 50,
                  child: TextField(
                    controller: _filterInterpret,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'filterInterpret'.tr(),
                    ),
                    onChanged: (value) {
                      context.read<WebBloc>().add(FilterInterprets(filter: value));
                    },
                  ),
                ),
              ),
              state.currentInterpret != null
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            if (state.currentInterpret?.name == state.currentInterpret?.name) {
                              context.read<WebBloc>().add(const ChangeCurrentInterpret(interpret: null));
                            }
                          },
                          child: Container(
                            height: 30,
                            margin: const EdgeInsets.all(5),
                            padding: const EdgeInsets.only(left: 5),
                            decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(5)),
                            alignment: Alignment.centerLeft,
                            child: Text(
                              state.currentInterpret?.name ?? '',
                              style: const TextStyle(fontSize: 14, color: AppColor.alertErrorColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    )
                  : Expanded(
                      flex: 1,
                      child: state.isSearching
                          ? const Center(
                              child: SizedBox(height: 40, width: 40, child: CircularProgressIndicator()),
                            )
                          : Container(
                              padding: const EdgeInsets.only(left: 10),
                              alignment: Alignment.topLeft,
                              child: SingleChildScrollView(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: state.filteredInterprets
                                      .map((interpret) => MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: GestureDetector(
                                              onTap: () {
                                                if (state.currentInterpret?.name == interpret.name) {
                                                  context.read<WebBloc>().add(const ChangeCurrentInterpret(interpret: null));
                                                } else {
                                                  context.read<WebBloc>().add(ChangeCurrentInterpret(interpret: interpret));
                                                }
                                              },
                                              child: Container(
                                                height: 30,
                                                width: 200,
                                                decoration: const BoxDecoration(
                                                  border: Border(
                                                    top: BorderSide(color: AppColor.grey3Color, width: 1.0),
                                                  ),
                                                ),
                                                child: Text(
                                                  interpret.name,
                                                  style: TextStyle(
                                                      fontSize: 14, color: state.currentInterpret?.name == interpret.name ? AppColor.alertErrorColor : AppColor.grey1Color),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ),
                    ),
              Visibility(
                visible: state.currentInterpret != null,
                child: Container(
                  padding: const EdgeInsets.only(bottom: 10),
                  height: 50,
                  child: TextField(
                    controller: _filterSong,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      labelText: 'filterSong'.tr(),
                    ),
                    onChanged: (value) {
                      context.read<WebBloc>().add(FilterInterprets(filter: value));
                    },
                  ),
                ),
              ),
              Visibility(
                visible: state.currentInterpret != null,
                child: Expanded(
                  flex: 10,
                  child: state.isSearching
                      ? const Center(
                          child: SizedBox(height: 40, width: 40, child: CircularProgressIndicator()),
                        )
                      : Container(
                          padding: EdgeInsets.only(left: 10),
                          alignment: Alignment.topLeft,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: state.filteredSongs
                                  .map((song) => MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            context
                                                .read<WebBloc>()
                                                .add(ChangeCurrentWebSong(song: state.currentSong != null && state.currentSong?.title == song.title ? null : song));
                                          },
                                          child: Container(
                                            height: 30,
                                            width: 200,
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                top: BorderSide(color: AppColor.grey3Color, width: 1.0),
                                              ),
                                            ),
                                            child: Text(
                                              song.title,
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: state.currentSong != null && state.currentSong?.title == song.title ? AppColor.alertErrorColor : AppColor.grey1Color),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ),
                        ),
                ),
              ),
            ]));
      },
    );
  }
}

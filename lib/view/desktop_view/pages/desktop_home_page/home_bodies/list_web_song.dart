import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../services/constants.dart';

class ListWebSong extends StatefulWidget {
  ListWebSong({
    super.key,
  });

  @override
  State<ListWebSong> createState() => _ListWebSongState();
}

class _ListWebSongState extends State<ListWebSong> {
  List<String> list = <String>[
    'velkyzpevnik.cz',
    'pisnicky-akordy.cz',
    'zpevnik.proscholy.cz',
    'songs.worshipleaderapp.com',
  ];
  String dropdownValue = 'pisnicky-akordy.cz';

  final TextEditingController _filterInterpretPisnickyAkordy = TextEditingController();
  final TextEditingController _filterSongPisnickyAkordy = TextEditingController();
  final TextEditingController _filterInterpretVelkyZpevnik = TextEditingController();
  final TextEditingController _filterSongVelkyZpevnik = TextEditingController();
  final TextEditingController _filterInterpretProScholy = TextEditingController();
  final TextEditingController _filterSongProScholy = TextEditingController();
  final TextEditingController _filterWorshipLeader = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebBloc, WebState>(
      builder: (context, state) {
        return Container(
            width: 250,
            height: MediaQuery.of(context).size.height - 150,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColor.grey3Color, width: 1.0), right: BorderSide(color: AppColor.grey3Color, width: 1.0)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                height: 40,
                width: 250,
                color: AppColor.whiteColor,
                child: DropdownButton(
                    dropdownColor: AppColor.whiteColor,
                    iconEnabledColor: AppColor.primaryColor,
                    items: list.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == dropdownValue) {
                        return;
                      }
                      setState(() {
                        _filterSongVelkyZpevnik.clear();
                        _filterInterpretVelkyZpevnik.clear();
                        _filterInterpretPisnickyAkordy.clear();
                        _filterSongPisnickyAkordy.clear();
                        _filterInterpretProScholy.clear();
                        _filterSongProScholy.clear();
                        _filterWorshipLeader.clear();
                        dropdownValue = value!;
                        context.read<WebBloc>().add(ChangeSearchWeb(searchWeb: list.indexOf(dropdownValue)));
                      });
                    },
                    value: dropdownValue),
              ),
              ...state.searchWeb == 0
                  ? getSearchWidgetForVelkyZpevnik(state)
                  : state.searchWeb == 1
                      ? getSearchWidgetForPisnickyAkordy(state)
                      : state.searchWeb == 2
                          ? getSearchWidgetForProScholy(state)
                          : getSearchWidgetForWorshipLeader(state),
            ]));
      },
    );
  }

  List<Widget> getSearchWidgetForVelkyZpevnik(WebState state) {
    return [
      Visibility(
        visible: state.currentInterpret == null,
        child: Container(
          padding: const EdgeInsets.only(bottom: 10),
          height: 50,
          width: 250,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _filterInterpretVelkyZpevnik,
            builder: (context, value, child) {
              return TextField(
                controller: _filterInterpretVelkyZpevnik,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'filterInterpret'.tr(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<WebBloc>().add(FilterInterprets(filter: _filterInterpretVelkyZpevnik.text));
                        },
                        icon: const Icon(Icons.search, size: 18),
                      ),
                      if (value.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _filterInterpretVelkyZpevnik.clear();
                            context.read<WebBloc>().add(const FilterInterprets(filter: ''));
                          },
                          icon: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                ),
                onSubmitted: (value) {
                  context.read<WebBloc>().add(FilterInterprets(filter: value));
                },
              );
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
                    if (state.currentInterpret?.title == state.currentInterpret?.title) {
                      context.read<WebBloc>().add(const ChangeCurrentInterpret(
                            interpret: null,
                          ));
                    }
                  },
                  child: Container(
                    height: 30,
                    margin: const EdgeInsets.all(5),
                    padding: const EdgeInsets.only(left: 5),
                    decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(5)),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.currentInterpret?.title ?? '',
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
                                        if (state.currentInterpret?.title == interpret.title) {
                                          context.read<WebBloc>().add(const ChangeCurrentInterpret(
                                                interpret: null,
                                              ));
                                        } else {
                                          context.read<WebBloc>().add(ChangeCurrentInterpret(
                                                interpret: interpret,
                                              ));
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
                                          interpret.title,
                                          style: TextStyle(fontSize: 14, color: state.currentInterpret?.title == interpret.title ? AppColor.alertErrorColor : AppColor.grey1Color),
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
          width: 250,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _filterSongVelkyZpevnik,
            builder: (context, value, child) {
              return TextField(
                controller: _filterSongVelkyZpevnik,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'filterSong'.tr(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<WebBloc>().add(FilterSongs(filter: _filterSongVelkyZpevnik.text));
                        },
                        icon: const Icon(Icons.search, size: 18),
                      ),
                      if (value.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _filterSongVelkyZpevnik.clear();
                            context.read<WebBloc>().add(const FilterSongs(filter: ''));
                          },
                          icon: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                ),
                onSubmitted: (value) {
                  context.read<WebBloc>().add(FilterSongs(filter: value));
                },
              );
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
                                    context.read<WebBloc>().add(ChangeCurrentWebSong(
                                        song: state.currentSong != null && state.currentSong?.title == song.title ? null : song, typeSearching: 'velkyzpevnik.cz'));
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
      )
    ];
  }

  List<Widget> getSearchWidgetForPisnickyAkordy(WebState state) {
    return [
      Visibility(
        visible: state.currentInterpret == null,
        child: Container(
          margin: EdgeInsets.only(top: 10),
          padding: const EdgeInsets.only(bottom: 10),
          height: 50,
          width: 250,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _filterInterpretPisnickyAkordy,
            builder: (context, value, child) {
              return TextField(
                controller: _filterInterpretPisnickyAkordy,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'filterInterpret'.tr(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<WebBloc>().add(FilterInterprets(filter: _filterInterpretPisnickyAkordy.text));
                        },
                        icon: const Icon(Icons.search, size: 18),
                      ),
                      if (value.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _filterInterpretPisnickyAkordy.clear();
                            context.read<WebBloc>().add(const FilterInterprets(filter: ''));
                          },
                          icon: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                ),
                onSubmitted: (value) {
                  context.read<WebBloc>().add(FilterInterprets(filter: value));
                },
              );
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
                    if (state.currentInterpret?.title == state.currentInterpret?.title) {
                      context.read<WebBloc>().add(const ChangeCurrentInterpret(
                            interpret: null,
                          ));
                    }
                  },
                  child: Container(
                    height: 30,
                    margin: const EdgeInsets.all(5),
                    padding: const EdgeInsets.only(left: 5),
                    decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(5)),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.currentInterpret?.title ?? '',
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
                                        if (state.currentInterpret?.title == interpret.title) {
                                          context.read<WebBloc>().add(const ChangeCurrentInterpret(
                                                interpret: null,
                                              ));
                                        } else {
                                          context.read<WebBloc>().add(ChangeCurrentInterpret(
                                                interpret: interpret,
                                              ));
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
                                          interpret.title,
                                          style: TextStyle(fontSize: 14, color: state.currentInterpret?.title == interpret.title ? AppColor.alertErrorColor : AppColor.grey1Color),
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
          width: 250,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _filterSongPisnickyAkordy,
            builder: (context, value, child) {
              return TextField(
                controller: _filterSongPisnickyAkordy,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'filterSong'.tr(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<WebBloc>().add(FilterSongs(filter: _filterSongPisnickyAkordy.text));
                        },
                        icon: const Icon(Icons.search, size: 18),
                      ),
                      if (value.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _filterSongPisnickyAkordy.clear();
                            context.read<WebBloc>().add(const FilterSongs(filter: ''));
                          },
                          icon: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                ),
                onSubmitted: (value) {
                  context.read<WebBloc>().add(FilterSongs(filter: value));
                },
              );
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
                                    context.read<WebBloc>().add(ChangeCurrentWebSong(
                                        song: state.currentSong != null && state.currentSong?.title == song.title ? null : song, typeSearching: 'pisnicky-akordy.cz'));
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
      )
    ];
  }

  List<Widget> getSearchWidgetForProScholy(WebState state) {
    return [
      Container(
        padding: const EdgeInsets.only(bottom: 10),
        height: 50,
        width: 250,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _filterInterpretProScholy,
          builder: (context, value, child) {
            return TextField(
              controller: _filterInterpretProScholy,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'filterSongOrInterpret'.tr(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        context.read<WebBloc>().add(FilterInterprets(filter: _filterInterpretProScholy.text));
                      },
                      icon: const Icon(Icons.search, size: 18),
                    ),
                    if (value.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _filterInterpretProScholy.clear();
                          context.read<WebBloc>().add(const FilterInterprets(filter: ''));
                        },
                        icon: const Icon(Icons.clear, size: 18),
                      ),
                  ],
                ),
              ),
              onSubmitted: (value) {
                context.read<WebBloc>().add(FilterInterprets(filter: value));
              },
            );
          },
        ),
      ),
      state.currentInterpret != null && state.currentInterpret.title.isNotEmpty
          ? Align(
              alignment: Alignment.centerLeft,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    context.read<WebBloc>().add(const ChangeCurrentInterpret(
                          interpret: null,
                        ));
                  },
                  child: Container(
                    height: 30,
                    margin: const EdgeInsets.all(5),
                    padding: const EdgeInsets.only(left: 5),
                    decoration: BoxDecoration(border: Border.all(), borderRadius: BorderRadius.circular(5)),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      state.currentInterpret.title,
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
                          children: [
                            if (state.filteredInterprets.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(top: 5, bottom: 3),
                                child: Text('Autoři', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.grey1Color)),
                              ),
                              ...state.filteredInterprets
                                  .map((interpret) => MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            context.read<WebBloc>().add(ChangeCurrentInterpret(
                                                  interpret: interpret,
                                                ));
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
                                              interpret.title,
                                              style: const TextStyle(fontSize: 14, color: AppColor.grey1Color),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ))
                            ],
                            if (state.filteredSongs.isNotEmpty) ...[
                              const Padding(
                                padding: EdgeInsets.only(top: 8, bottom: 3),
                                child: Text('Písně', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.grey1Color)),
                              ),
                              ...state.filteredSongs
                                  .map((song) => MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            context.read<WebBloc>().add(ChangeCurrentWebSong(
                                                song: song, typeSearching: 'zpevnik.proscholy.cz'));
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
                                              '${song.title} - ${song.interpret}',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color: state.currentSong != null && state.currentSong?.ref == song.ref ? AppColor.alertErrorColor : AppColor.grey1Color),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ),
                                      ))
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
      Visibility(
        visible: state.currentInterpret != null,
        child: Container(
          padding: const EdgeInsets.only(bottom: 10),
          height: 50,
          width: 250,
          child: ValueListenableBuilder<TextEditingValue>(
            valueListenable: _filterSongProScholy,
            builder: (context, value, child) {
              return TextField(
                controller: _filterSongProScholy,
                style: const TextStyle(fontSize: 12),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: 'filterSong'.tr(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          context.read<WebBloc>().add(FilterSongs(filter: _filterSongProScholy.text));
                        },
                        icon: const Icon(Icons.search, size: 18),
                      ),
                      if (value.text.isNotEmpty)
                        IconButton(
                          onPressed: () {
                            _filterSongProScholy.clear();
                            context.read<WebBloc>().add(const FilterSongs(filter: ''));
                          },
                          icon: const Icon(Icons.clear, size: 18),
                        ),
                    ],
                  ),
                ),
                onSubmitted: (value) {
                  context.read<WebBloc>().add(FilterSongs(filter: value));
                },
              );
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
                  padding: const EdgeInsets.only(left: 10),
                  alignment: Alignment.topLeft,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: state.filteredSongs
                          .map((song) => MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    context.read<WebBloc>().add(ChangeCurrentWebSong(
                                        song: state.currentSong != null && state.currentSong?.title == song.title ? null : song, typeSearching: 'zpevnik.proscholy.cz'));
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
      )
    ];
  }

  List<Widget> getSearchWidgetForWorshipLeader(WebState state) {
    return [
      Container(
        padding: const EdgeInsets.only(bottom: 10),
        height: 50,
        width: 250,
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _filterWorshipLeader,
          builder: (context, value, child) {
            return TextField(
              controller: _filterWorshipLeader,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'filterSong'.tr(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        context.read<WebBloc>().add(FilterInterprets(filter: _filterWorshipLeader.text));
                      },
                      icon: const Icon(Icons.search, size: 18),
                    ),
                    if (value.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          _filterWorshipLeader.clear();
                          context.read<WebBloc>().add(const FilterInterprets(filter: ''));
                        },
                        icon: const Icon(Icons.clear, size: 18),
                      ),
                  ],
                ),
              ),
              onSubmitted: (value) {
                context.read<WebBloc>().add(FilterInterprets(filter: value));
              },
            );
          },
        ),
      ),
      Expanded(
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
                    children: state.filteredSongs
                        .map((song) => MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () {
                                  context.read<WebBloc>().add(ChangeCurrentWebSong(
                                      song: state.currentSong != null && state.currentSong?.ref == song.ref ? null : song,
                                      typeSearching: 'songs.worshipleaderapp.com'));
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
                                        color: state.currentSong != null && state.currentSong?.ref == song.ref ? AppColor.alertErrorColor : AppColor.grey1Color),
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
    ];
  }
}

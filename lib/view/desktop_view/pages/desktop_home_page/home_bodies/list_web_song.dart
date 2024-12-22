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
    'pisnicky-akordy.cz',
    'velkyzpevnik.cz',
  ];
  String dropdownValue = 'pisnicky-akordy.cz';

  final TextEditingController _filterInterpretPisnickyAkordy = TextEditingController();
  final TextEditingController _filterSongPisnickyAkordy = TextEditingController();
  final TextEditingController _filterInterpretVelkyZpevnik = TextEditingController();
  final TextEditingController _filterSongVelkyZpevnik = TextEditingController();
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
                        dropdownValue = value!;
                        context.read<WebBloc>().add(ChangeSearchWeb(searchWeb: dropdownValue == 'pisnicky-akordy.cz' ? 0 : 1));
                      });
                    },
                    value: dropdownValue),
              ),
              ...state.searchWeb == 0 ? getSearchWidgetForPisnickyAkordy(state) : getSearchWidgetForVelkyZpevnik(state),
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
          child: TextField(
            controller: _filterInterpretVelkyZpevnik,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'filterInterpret'.tr(),
            ),
            onChanged: (value) {
              context.read<WebBloc>().add(FilterInterprets(
                    filter: value,
                  ));
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
          child: TextField(
            controller: _filterSongVelkyZpevnik,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'filterSong'.tr(),
            ),
            onChanged: (value) {
              context.read<WebBloc>().add(FilterInterprets(
                    filter: value,
                  ));
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
          child: TextField(
            controller: _filterInterpretPisnickyAkordy,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'filterInterpret'.tr(),
            ),
            onChanged: (value) {
              context.read<WebBloc>().add(FilterInterprets(
                    filter: value,
                  ));
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
          child: TextField(
            controller: _filterSongPisnickyAkordy,
            style: const TextStyle(fontSize: 12),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: 'filterSong'.tr(),
            ),
            onChanged: (value) {
              context.read<WebBloc>().add(FilterInterprets(
                    filter: value,
                  ));
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
}

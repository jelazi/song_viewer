import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../../blocs/export_blocs.dart';
import '../../../../../model/web_interpret.dart';
import '../../../../../model/web_song.dart';
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

  final TextEditingController _filterInterpretPisnickyAkordy = TextEditingController();
  final TextEditingController _filterSongPisnickyAkordy = TextEditingController();
  final TextEditingController _filterInterpretVelkyZpevnik = TextEditingController();
  final TextEditingController _filterSongVelkyZpevnik = TextEditingController();
  final TextEditingController _filterInterpretProScholy = TextEditingController();
  final TextEditingController _filterSongProScholy = TextEditingController();
  final TextEditingController _filterWorshipLeader = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _debouncedSearch(VoidCallback action) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), action);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebBloc, WebState>(
      builder: (context, state) {
        final isSongMode = state.searchType == 0;
        return Container(
            width: 400,
            height: MediaQuery.of(context).size.height - 150,
            padding: const EdgeInsets.all(5),
            decoration: const BoxDecoration(
              border: Border(left: BorderSide(color: AppColor.grey3Color, width: 1.0), right: BorderSide(color: AppColor.grey3Color, width: 1.0)),
            ),
            child: Column(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Modern segmented website tabs
              _buildWebsiteTabs(state),
              const SizedBox(height: 8),
              // Search type toggle
              if (state.searchWeb == 0 || state.searchWeb == 1 || state.searchWeb == 2)
                _buildSearchTypeToggle(state),
              const SizedBox(height: 4),
              // Search body
              Expanded(
                child: state.searchWeb == 0
                    ? Column(children: getSearchWidgetForVelkyZpevnik(state))
                    : state.searchWeb == 1
                        ? Column(children: getSearchWidgetForPisnickyAkordy(state))
                        : state.searchWeb == 2
                            ? Column(children: getSearchWidgetForProScholy(state))
                            : Column(children: getSearchWidgetForWorshipLeader(state)),
              ),
            ]));
      },
    );
  }

  Widget _buildWebsiteTabs(WebState state) {
    final names = ['Velký zpěvník', 'Písničky-akordy', 'ProScholy', 'Worship Leader'];
    final icons = [Icons.library_music, Icons.music_note, Icons.church, Icons.mic];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(names.length, (index) {
          final isSelected = state.searchWeb == index;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: GestureDetector(
              onTap: () {
                _filterSongVelkyZpevnik.clear();
                _filterInterpretVelkyZpevnik.clear();
                _filterInterpretPisnickyAkordy.clear();
                _filterSongPisnickyAkordy.clear();
                _filterInterpretProScholy.clear();
                _filterSongProScholy.clear();
                _filterWorshipLeader.clear();
                context.read<WebBloc>().add(ChangeSearchWeb(searchWeb: index));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColor.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isSelected ? AppColor.primaryColor : AppColor.grey3Color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icons[index], size: 14, color: isSelected ? Colors.white : AppColor.grey1Color),
                    const SizedBox(width: 4),
                    Text(
                      names[index],
                      style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? Colors.white : AppColor.grey1Color),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchTypeToggle(WebState state) {
    return Row(
      children: [
        _buildToggleChip(
          label: 'interpret'.tr(),
          icon: Icons.person,
          isSelected: state.searchType == 1,
          onTap: () {
            if (state.searchType != 1) {
              context.read<WebBloc>().add(const ChangeSearchType(searchType: 1));
            }
          },
        ),
        const SizedBox(width: 8),
        _buildToggleChip(
          label: 'song'.tr(),
          icon: Icons.music_note,
          isSelected: state.searchType == 0,
          onTap: () {
            if (state.searchType != 0) {
              context.read<WebBloc>().add(const ChangeSearchType(searchType: 0));
            }
          },
        ),
      ],
    );
  }

  Widget _buildToggleChip({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? AppColor.primaryColor : AppColor.grey3Color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? AppColor.primaryColor : AppColor.grey1Color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: isSelected ? AppColor.primaryColor : AppColor.grey1Color, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> getSearchWidgetForVelkyZpevnik(WebState state) {
    return [
      Visibility(
        visible: state.currentInterpret.title.isEmpty,
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
                onChanged: (value) {
                  _debouncedSearch(() {
                    context.read<WebBloc>().add(FilterInterprets(filter: value));
                  });
                },
                onSubmitted: (value) {
                  _debounceTimer?.cancel();
                  context.read<WebBloc>().add(FilterInterprets(filter: value));
                },
              );
            },
          ),
        ),
      ),
      state.currentInterpret.title.isNotEmpty
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
                          children: state.filteredInterprets
                              .map((interpret) => _buildDesktopInterpretCard(state, interpret))
                              .toList(),
                        ),
                      ),
                    ),
              ),
      Visibility(
        visible: state.currentInterpret.title.isNotEmpty,
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
                onChanged: (value) {
                  context.read<WebBloc>().add(FilterSongs(filter: value));
                },
                onSubmitted: (value) {
                  context.read<WebBloc>().add(FilterSongs(filter: value));
                },
              );
            },
          ),
        ),
      ),
      Visibility(
        visible: state.currentInterpret.title.isNotEmpty,
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
                          .map((song) => _buildDesktopSongCard(
                            state, song, 'velkyzpevnik.cz',
                            isSelected: state.currentSong?.title == song.title,
                          ))
                          .toList(),
                ),
                ),
              ),
          ),
        ),
      ];
  }

  List<Widget> getSearchWidgetForPisnickyAkordy(WebState state) {
    return [
      Visibility(
        visible: state.currentInterpret.title.isEmpty,
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
                onChanged: (value) {
                  _debouncedSearch(() {
                    context.read<WebBloc>().add(FilterInterprets(filter: value));
                  });
                },
                onSubmitted: (value) {
                  _debounceTimer?.cancel();
                  context.read<WebBloc>().add(FilterInterprets(filter: value));
                },
              );
            },
          ),
        ),
      ),
      state.currentInterpret.title.isNotEmpty
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
                                children: state.filteredInterprets
                                    .map((interpret) => _buildDesktopInterpretCard(state, interpret))
                                    .toList(),
                              ),
                            ),
                          ),
                  ),
      Visibility(
        visible: state.currentInterpret.title.isNotEmpty,
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
                onChanged: (value) {
                  context.read<WebBloc>().add(FilterSongs(filter: value));
                },
                onSubmitted: (value) {
                  context.read<WebBloc>().add(FilterSongs(filter: value));
                },
              );
            },
          ),
        ),
      ),
      Visibility(
        visible: state.currentInterpret.title.isNotEmpty,
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
                          .map((song) => _buildDesktopSongCard(
                            state, song, 'pisnicky-akordy.cz',
                            isSelected: state.currentSong?.title == song.title,
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
              onChanged: (value) {
                _debouncedSearch(() {
                  context.read<WebBloc>().add(FilterInterprets(filter: value));
                });
              },
              onSubmitted: (value) {
                _debounceTimer?.cancel();
                context.read<WebBloc>().add(FilterInterprets(filter: value));
              },
            );
          },
        ),
      ),
      state.currentInterpret.title.isNotEmpty
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
                              Padding(
                                padding: const EdgeInsets.only(top: 5, bottom: 3),
                                child: Text('authorsLabel'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.grey1Color)),
                              ),
                              ...state.filteredInterprets.map((interpret) => _buildDesktopInterpretCard(state, interpret))
                            ],
                            if (state.filteredSongs.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(top: 8, bottom: 3),
                                child: Text('songsLabel'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.grey1Color)),
                              ),
                              ...state.filteredSongs.map((song) => _buildDesktopSongCard(
                                state, song, 'zpevnik.proscholy.cz',
                                isSelected: state.currentSong?.ref == song.ref,
                              ))
                            ],
                          ],
                        ),
                      ),
                    ),
            ),
      Visibility(
        visible: state.currentInterpret.title.isNotEmpty,
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
                onChanged: (value) {
                  context.read<WebBloc>().add(FilterSongs(filter: value));
                },
                onSubmitted: (value) {
                  context.read<WebBloc>().add(FilterSongs(filter: value));
                },
              );
            },
          ),
        ),
      ),
      Visibility(
        visible: state.currentInterpret.title.isNotEmpty,
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
                          .map((song) => _buildDesktopSongCard(
                            state, song, 'zpevnik.proscholy.cz',
                            isSelected: state.currentSong?.title == song.title,
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
              onChanged: (value) {
                _debouncedSearch(() {
                  context.read<WebBloc>().add(FilterInterprets(filter: value));
                });
              },
              onSubmitted: (value) {
                _debounceTimer?.cancel();
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
                          .map((song) => _buildDesktopSongCard(
                            state, song, 'songs.worshipleaderapp.com',
                            isSelected: state.currentSong?.ref == song.ref,
                          ))
                          .toList(),
                  ),
                ),
          ),
        ),
      ];
  }

  Widget _buildDesktopSongCard(WebState state, WebSong song, String typeSearching, {required bool isSelected}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            context.read<WebBloc>().add(ChangeCurrentWebSong(
                song: isSelected ? null : song, typeSearching: typeSearching));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.08) : Colors.white,
              border: Border.all(color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.3) : AppColor.grey3Color),
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.music_note, size: 14, color: AppColor.primaryColor),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: isSelected ? AppColor.primaryColor : AppColor.grey1Color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.interpret.isNotEmpty)
                        Text(
                          song.interpret,
                          style: TextStyle(fontSize: 11, color: AppColor.grey1Color.withValues(alpha: 0.7)),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopInterpretCard(WebState state, WebInterpret interpret) {
    final isSelected = state.currentInterpret.title == interpret.title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () {
            if (isSelected) {
              context.read<WebBloc>().add(const ChangeCurrentInterpret(interpret: null));
            } else {
              context.read<WebBloc>().add(ChangeCurrentInterpret(interpret: interpret));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.3) : AppColor.grey3Color),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: isSelected ? AppColor.primaryColor : AppColor.grey3Color,
                  child: Text(
                    interpret.title.isNotEmpty ? interpret.title[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColor.grey1Color),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    interpret.title,
                    style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppColor.primaryColor : AppColor.grey1Color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (interpret.songs > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.1) : AppColor.grey3Color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${interpret.songs}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSelected ? AppColor.primaryColor : AppColor.grey1Color)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';
import '../../../services/constants.dart';

class WebPageMobile extends StatefulWidget {
  const WebPageMobile({super.key});

  @override
  State<WebPageMobile> createState() => _WebPageMobileState();
}

class _WebPageMobileState extends State<WebPageMobile> {
  final List<String> _listSearchWeb = [
    'velkyzpevnik.cz',
    'pisnicky-akordy.cz',
    'zpevnik.proscholy.cz',
    'songs.worshipleaderapp.com',
  ];

  final TextEditingController _filterController = TextEditingController();
  final TextEditingController _filterSongController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _filterController.dispose();
    _filterSongController.dispose();
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
        return Scaffold(
          appBar: AppBar(
            backgroundColor: AppColor.primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text('web'.tr(), style: const TextStyle(color: Colors.white)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: DropdownButton<String>(
                  dropdownColor: AppColor.primaryColor,
                  iconEnabledColor: Colors.white,
                  underline: const SizedBox(),
                  value: _listSearchWeb[state.searchWeb],
                  items: _listSearchWeb.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _filterController.clear();
                    _filterSongController.clear();
                    context.read<WebBloc>().add(ChangeSearchWeb(searchWeb: _listSearchWeb.indexOf(value)));
                  },
                ),
              ),
            ],
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(WebState state) {
    // WorshipLeader: only song search, no interpret
    if (state.searchWeb == 3) {
      return _buildWorshipLeaderBody(state);
    }

    // ProScholy (searchWeb == 2): combined interpret + song search
    if (state.searchWeb == 2) {
      return _buildProScholyBody(state);
    }

    // VelkyZpevnik (0) and PisnickyAkordy (1): interpret -> songs
    return _buildInterpretSongBody(state);
  }

  Widget _buildInterpretSongBody(WebState state) {
    // If an interpret is selected, show song list
    if (state.currentInterpret.title.isNotEmpty) {
      return Column(
        children: [
          _buildSelectedInterpretChip(state),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: _buildSongFilterField(state),
          ),
          Expanded(
            child: state.searchWebSongs
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: state.filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = state.filteredSongs[index];
                      return ListTile(
                        title: Text(song.title),
                        onTap: () {
                          context.read<PreviewChordBloc>().add(
                                ChangeLyricFromWebSongUpdate(
                                  webSong: song,
                                  typeSearching: state.searchWeb,
                                ),
                              );
                          Navigator.pushNamed(context, '/previewPage');
                        },
                      );
                    },
                  ),
          ),
        ],
      );
    }

    // Show interpret search
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: _buildInterpretFilterField(state),
        ),
        Expanded(
          child: state.isSearching
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (state.filteredInterprets.isNotEmpty)
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.filteredInterprets.length,
                          itemBuilder: (context, index) {
                            final interpret = state.filteredInterprets[index];
                            return ListTile(
                              title: Text(interpret.title),
                              onTap: () {
                                context.read<WebBloc>().add(ChangeCurrentInterpret(interpret: interpret));
                              },
                            );
                          },
                        ),
                      ),
                    if (state.historyInterprets.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                        child: Text(
                          'history'.tr(),
                          style: const TextStyle(fontSize: 13, color: AppColor.grey1Color, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: state.historyInterprets.length,
                          itemBuilder: (context, index) {
                            final interpret = state.historyInterprets[index];
                            return ListTile(
                              leading: const Icon(Icons.history, size: 18, color: AppColor.grey2Color),
                              title: Text(interpret.title),
                              onTap: () {
                                context.read<WebBloc>().add(ChangeCurrentInterpret(interpret: interpret));
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildProScholyBody(WebState state) {
    if (state.currentInterpret.title.isNotEmpty) {
      return Column(
        children: [
          _buildSelectedInterpretChip(state),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: _buildSongFilterField(state),
          ),
          Expanded(
            child: state.searchWebSongs
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: state.filteredSongs.length,
                    itemBuilder: (context, index) {
                      final song = state.filteredSongs[index];
                      return ListTile(
                        title: Text(song.title),
                        onTap: () {
                          context.read<PreviewChordBloc>().add(
                                ChangeLyricFromWebSongUpdate(
                                  webSong: song,
                                  typeSearching: state.searchWeb,
                                ),
                              );
                          Navigator.pushNamed(context, '/previewPage');
                        },
                      );
                    },
                  ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: _buildInterpretFilterField(state),
        ),
        Expanded(
          child: state.isSearching
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  children: [
                    if (state.filteredInterprets.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                        child: Text(
                          'authorsLabel'.tr(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.grey1Color),
                        ),
                      ),
                      ...state.filteredInterprets.map((interpret) => ListTile(
                            title: Text(interpret.title),
                            onTap: () {
                              context.read<WebBloc>().add(ChangeCurrentInterpret(interpret: interpret));
                            },
                          )),
                    ],
                    if (state.filteredSongs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
                        child: Text(
                          'songsLabel'.tr(),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.grey1Color),
                        ),
                      ),
                      ...state.filteredSongs.map((song) => ListTile(
                            title: Text(song.title),
                            subtitle: song.interpret.isNotEmpty ? Text(song.interpret) : null,
                            onTap: () {
                              context.read<PreviewChordBloc>().add(
                                    ChangeLyricFromWebSongUpdate(
                                      webSong: song,
                                      typeSearching: state.searchWeb,
                                    ),
                                  );
                              Navigator.pushNamed(context, '/previewPage');
                            },
                          )),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildWorshipLeaderBody(WebState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: _buildSearchField(
            controller: _filterController,
            hintText: 'filterSong'.tr(),
            onSearch: (value) {
              _debounceTimer?.cancel();
              _debounceTimer = Timer(const Duration(milliseconds: 500), () {
                context.read<WebBloc>().add(FilterInterprets(filter: value));
              });
            },
            onSubmitted: (value) {
              _debounceTimer?.cancel();
              context.read<WebBloc>().add(FilterInterprets(filter: value));
            },
            onClear: () {
              _filterController.clear();
              context.read<WebBloc>().add(const FilterInterprets(filter: ''));
            },
          ),
        ),
        Expanded(
          child: state.isSearching
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: state.filteredSongs.length,
                  itemBuilder: (context, index) {
                    final song = state.filteredSongs[index];
                    return ListTile(
                      title: Text(song.title),
                      onTap: () {
                        context.read<PreviewChordBloc>().add(
                              ChangeLyricFromWebSongUpdate(
                                webSong: song,
                                typeSearching: state.searchWeb,
                              ),
                            );
                        Navigator.pushNamed(context, '/previewPage');
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSelectedInterpretChip(WebState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: GestureDetector(
        onTap: () {
          _filterSongController.clear();
          context.read<WebBloc>().add(const ChangeCurrentInterpret(interpret: null));
        },
        child: Chip(
          avatar: const Icon(Icons.arrow_back, size: 16),
          label: Text(
            state.currentInterpret.title,
            style: const TextStyle(color: AppColor.alertErrorColor),
          ),
          backgroundColor: AppColor.grey4Color,
        ),
      ),
    );
  }

  Widget _buildInterpretFilterField(WebState state) {
    final hintText = state.searchWeb == 2 ? 'filterSongOrInterpret'.tr() : 'filterInterpret'.tr();
    return _buildSearchField(
      controller: _filterController,
      hintText: hintText,
      onSearch: (value) {
        _debouncedSearch(() {
          context.read<WebBloc>().add(FilterInterprets(filter: value));
        });
      },
      onSubmitted: (value) {
        _debounceTimer?.cancel();
        context.read<WebBloc>().add(FilterInterprets(filter: value));
      },
      onClear: () {
        _filterController.clear();
        context.read<WebBloc>().add(const FilterInterprets(filter: ''));
      },
    );
  }

  Widget _buildSongFilterField(WebState state) {
    return _buildSearchField(
      controller: _filterSongController,
      hintText: 'filterSong'.tr(),
      onSearch: (value) {
        context.read<WebBloc>().add(FilterSongs(filter: value));
      },
      onSubmitted: (value) {
        context.read<WebBloc>().add(FilterSongs(filter: value));
      },
      onClear: () {
        _filterSongController.clear();
        context.read<WebBloc>().add(const FilterSongs(filter: ''));
      },
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onSearch,
    required ValueChanged<String> onSubmitted,
    required VoidCallback onClear,
  }) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, child) {
        return TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () => onSubmitted(controller.text),
                ),
                if (value.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: onClear,
                  ),
              ],
            ),
          ),
          onChanged: onSearch,
          onSubmitted: onSubmitted,
        );
      },
    );
  }
}

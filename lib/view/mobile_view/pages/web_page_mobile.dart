import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';
import '../../../model/web_interpret.dart';
import '../../../model/web_song.dart';
import '../../../services/constants.dart';
import '../../widgets/web_search_history_menu.dart';

class WebPageMobile extends StatefulWidget {
  const WebPageMobile({super.key});

  @override
  State<WebPageMobile> createState() => _WebPageMobileState();
}

class _WebPageMobileState extends State<WebPageMobile> {
  final List<String> _siteNames = ['Velký zpěvník', 'Písničky-akordy', 'ProScholy', 'Worship Leader', 'Worship Chords'];
  final List<IconData> _siteIcons = [Icons.library_music, Icons.music_note, Icons.church, Icons.mic, Icons.queue_music];

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
          ),
          body: Column(
            children: [
              _buildWebsiteTabs(state),
              if (state.searchWeb == 0 || state.searchWeb == 1 || state.searchWeb == 2 || state.searchWeb == 4)
                _buildSearchTypeToggle(state),
              Expanded(child: _buildBody(state)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWebsiteTabs(WebState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      color: AppColor.grey4Color,
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _siteNames.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final isSelected = state.searchWeb == index;
            return GestureDetector(
              onTap: () {
                _filterController.clear();
                _filterSongController.clear();
                context.read<WebBloc>().add(ChangeSearchWeb(searchWeb: index));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? AppColor.primaryColor : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isSelected ? AppColor.primaryColor : AppColor.grey3Color),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_siteIcons[index], size: 16, color: isSelected ? Colors.white : AppColor.grey1Color),
                    const SizedBox(width: 6),
                    Text(
                      _siteNames[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.white : AppColor.grey1Color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSearchTypeToggle(WebState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: AppColor.grey4Color,
      child: Row(
        children: [
          _buildToggleChip(
            label: 'interpret'.tr(),
            icon: Icons.person,
            isSelected: state.searchType == 1,
            onTap: () {
              if (state.searchType != 1) {
                context.read<WebBloc>().add(const ChangeSearchType(searchType: 1));
                _filterController.clear();
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
                _filterController.clear();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildToggleChip({required String label, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? AppColor.primaryColor : AppColor.grey1Color, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(WebState state) {
    final isSongMode = state.searchType == 0;

    // Song mode: directly search songs
    if (isSongMode || state.searchWeb == 3) {
      return _buildSongSearchResult(state);
    }

    // Interpret mode
    switch (state.searchWeb) {
      case 2:
        return _buildProScholyBody(state);
      default:
        return _buildInterpretSongBody(state);
    }
  }

  Widget _buildSongSearchResult(WebState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildModernSearchField(
            controller: _filterController,
            hintText: 'filterSong'.tr(),
            onChanged: (value) {
              _debouncedSearch(() {
                context.read<WebBloc>().add(FilterInterprets(filter: value));
              });
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
              : state.filteredSongs.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: state.filteredSongs.length,
                      itemBuilder: (context, index) {
                        return _buildMobileSongCard(state, state.filteredSongs[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildInterpretSongBody(WebState state) {
    if (state.currentInterpret.title.isNotEmpty) {
      return Column(
        children: [
          _buildSelectedInterpretChip(state),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: _buildModernSearchField(
              controller: _filterSongController,
              hintText: 'filterSong'.tr(),
              onChanged: (value) {
                context.read<WebBloc>().add(FilterSongs(filter: value));
              },
              onClear: () {
                _filterSongController.clear();
                context.read<WebBloc>().add(const FilterSongs(filter: ''));
              },
            ),
          ),
          Expanded(
            child: state.searchWebSongs
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: state.filteredSongs.length,
                    itemBuilder: (context, index) {
                      return _buildMobileSongCard(state, state.filteredSongs[index]);
                    },
                  ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildModernSearchField(
            controller: _filterController,
            hintText: 'filterInterpret'.tr(),
            onChanged: (value) {
              _debouncedSearch(() {
                context.read<WebBloc>().add(FilterInterprets(filter: value));
              });
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
              : _buildInterpretList(state),
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
            child: _buildModernSearchField(
              controller: _filterSongController,
              hintText: 'filterSong'.tr(),
              onChanged: (value) {
                context.read<WebBloc>().add(FilterSongs(filter: value));
              },
              onClear: () {
                _filterSongController.clear();
                context.read<WebBloc>().add(const FilterSongs(filter: ''));
              },
            ),
          ),
          Expanded(
            child: state.searchWebSongs
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: state.filteredSongs.length,
                    itemBuilder: (context, index) {
                      return _buildMobileSongCard(state, state.filteredSongs[index]);
                    },
                  ),
          ),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: _buildModernSearchField(
            controller: _filterController,
            hintText: 'filterSongOrInterpret'.tr(),
            onChanged: (value) {
              _debouncedSearch(() {
                context.read<WebBloc>().add(FilterInterprets(filter: value));
              });
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
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  children: [
                    if (state.filteredInterprets.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 4, left: 4),
                        child: Text('authorsLabel'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.grey1Color)),
                      ),
                      ...state.filteredInterprets.map((interpret) => _buildMobileInterpretCard(state, interpret)),
                    ],
                    if (state.filteredSongs.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
                        child: Text('songsLabel'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.grey1Color)),
                      ),
                      ...state.filteredSongs.map((song) => _buildMobileSongCard(state, song)),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildInterpretList(WebState state) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        ...state.filteredInterprets.map((interpret) => _buildMobileInterpretCard(state, interpret)),
        if (state.historyInterprets.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4, left: 4),
            child: Row(
              children: [
                Icon(Icons.history, size: 14, color: AppColor.grey1Color),
                const SizedBox(width: 4),
                Text('history'.tr(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColor.grey1Color)),
              ],
            ),
          ),
          ...state.historyInterprets.map((interpret) => _buildMobileInterpretCard(state, interpret)),
        ],
        if (state.filteredInterprets.isEmpty && state.historyInterprets.isEmpty)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildMobileSongCard(WebState state, WebSong song) {
    final isSelected = state.currentSong?.ref == song.ref;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            context.read<PreviewChordBloc>().add(
              ChangeLyricFromWebSongUpdate(
                webSong: song,
                typeSearching: state.searchWeb,
              ),
            );
            Navigator.pushNamed(context, '/previewPage');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.3) : AppColor.grey3Color,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, size: 18, color: AppColor.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: AppColor.grey1Color),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.interpret.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            song.interpret,
                            style: TextStyle(fontSize: 12, color: AppColor.grey1Color.withValues(alpha: 0.7)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: AppColor.grey1Color.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileInterpretCard(WebState state, WebInterpret interpret) {
    final isSelected = state.currentInterpret.title == interpret.title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            if (isSelected) {
              context.read<WebBloc>().add(const ChangeCurrentInterpret(interpret: null));
            } else {
              context.read<WebBloc>().add(ChangeCurrentInterpret(interpret: interpret));
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.3) : AppColor.grey3Color),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isSelected ? AppColor.primaryColor : AppColor.grey3Color,
                  child: Text(
                    interpret.title.isNotEmpty ? interpret.title[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColor.grey1Color),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    interpret.title,
                    style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal, color: isSelected ? AppColor.primaryColor : AppColor.grey1Color),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (interpret.songs > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.1) : AppColor.grey3Color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${interpret.songs}',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? AppColor.primaryColor : AppColor.grey1Color),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedInterpretChip(WebState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: GestureDetector(
        onTap: () {
          _filterSongController.clear();
          context.read<WebBloc>().add(const ChangeCurrentInterpret(interpret: null));
        },
        child: Chip(
          avatar: const Icon(Icons.arrow_back, size: 16),
          label: Text(state.currentInterpret.title, style: const TextStyle(color: AppColor.alertErrorColor)),
          backgroundColor: AppColor.grey4Color,
        ),
      ),
    );
  }

  Widget _buildModernSearchField({
    required TextEditingController controller,
    required String hintText,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
  }) {
    void runSearch(String value) {
      onChanged(value);
      context.read<WebBloc>().add(AddWebSearchHistory(query: value));
    }

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColor.grey3Color),
      ),
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (context, value, child) {
          return TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: const Icon(Icons.search, color: AppColor.grey1Color, size: 20),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WebSearchHistoryMenu(
                    onSelected: (query) {
                      controller.text = query;
                      controller.selection = TextSelection.fromPosition(TextPosition(offset: query.length));
                      runSearch(query);
                    },
                  ),
                  if (value.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: onClear,
                    ),
                ],
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
            ),
            onChanged: onChanged,
            onSubmitted: runSearch,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search, size: 48, color: AppColor.grey3Color),
          const SizedBox(height: 8),
          Text('searchForSongOrInterpret'.tr(), style: TextStyle(color: AppColor.grey1Color)),
        ],
      ),
    );
  }
}

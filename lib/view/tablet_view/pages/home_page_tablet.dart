import 'package:default_project/model/web_interpret.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/edit_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../blocs/export_blocs.dart';
import '../../../model/web_song.dart';
import '../../../services/constants.dart';
import '../../mobile_view/widgets/dialogs/qr_code_dialog.dart';
import '../widgets/filter_field_tablet.dart';
import '../widgets/song_card_tablet.dart';
import '../widgets/song_card_tablet_web.dart';

class HomePageTablet extends StatefulWidget {
  final SettingsRepository settingsRepository;
  const HomePageTablet({
    super.key,
    required this.settingsRepository,
  });

  @override
  State<HomePageTablet> createState() => _HomePageTabletState();
}

class _HomePageTabletState extends State<HomePageTablet> {
  final TextEditingController _previewFilterSearchSong = TextEditingController();
  final TextEditingController _filterInterpretPisnickyAkordy = TextEditingController();
  final TextEditingController _filterSongPisnickyAkordy = TextEditingController();
  final TextEditingController _filterInterpretVelkyZpevnik = TextEditingController();
  final TextEditingController _filterSongVelkyZpevnik = TextEditingController();
  String selectPage = 'preview';
  final List<String> _listSearchWeb = ['velkyzpevnik.cz', 'pisnicky-akordy.cz', 'zpevnik.proscholy.cz', 'songs.worshipleaderapp.com'];

  bool selectLargeScreen(Size size) {
    bool isLargeScreen = false;
    if (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux) {
      widget.settingsRepository.isLargeScreen = true;
      isLargeScreen = true;
      Size screenSize = PlatformDispatcher.instance.views.first.physicalSize;
      final height = screenSize.height;
      const estimatedHeight = 1640.0;
      fontSizeRatio = height / estimatedHeight;
    } else {
      widget.settingsRepository.isLargeScreen = false;
      isLargeScreen = false;
    }

    if (kIsWeb) {
      resizeFontsForWeb();
    } else {
      if (!widget.settingsRepository.isLargeScreen) {
        resizeFontsForMobile();
      } else {
        resizeFontsForDesktop();
      }
    }

    return isLargeScreen;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      selectLargeScreen(MediaQuery.of(context).size);
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomePageBloc, HomePageState>(
      buildWhen: (previous, current) =>
          previous.listSong != current.listSong ||
          previous.selectedSongId != current.selectedSongId ||
          previous.isEditIconVisible != current.isEditIconVisible ||
          previous.superuserMode != current.superuserMode ||
          previous.listExpandedSongs != current.listExpandedSongs ||
          previous.selectedPage != current.selectedPage ||
          previous.listAllGroups != current.listAllGroups ||
          previous.listSelectedGroups != current.listSelectedGroups,
      builder: (context, state) {
        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            child: Row(children: [
              SizedBox(
                  width: 250,
                  height: MediaQuery.of(context).size.height,
                  child: Column(
                    children: [
                      Text(
                        'songsViewer'.tr(),
                        style: const TextStyle(
                          fontSize: 24,
                        ),
                      ),
                      Text('${'version'.tr()} ${context.read<HomePageBloc>().settingsRepository.version}',
                          style: const TextStyle(
                            fontSize: 14,
                          )),
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Visibility(
                              visible: state.selectedPage == 'preview',
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: SizedBox(
                                  height: 30,
                                  child: Text('${context.read<HomePageBloc>().songsRepository.songs.length} ${'songs'.tr()}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      )),
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      QrCodeDialog.show(context);
                                    },
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(border: Border.all(color: AppColor.grey3Color), borderRadius: BorderRadius.circular(5)),
                                      padding: EdgeInsets.zero,
                                      child: const Icon(Icons.qr_code, color: AppColor.grey2Color, size: 14),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.pushNamed(context, '/settingsPage');
                                    },
                                    child: Container(
                                      height: 40,
                                      width: 40,
                                      decoration: BoxDecoration(border: Border.all(color: AppColor.grey3Color), borderRadius: BorderRadius.circular(5)),
                                      padding: EdgeInsets.zero,
                                      child: const Icon(Icons.settings, color: AppColor.grey2Color, size: 14),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Divider(
                        color: AppColor.grey3Color,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      getSelectPageDropDown(),
                      const Divider(
                        color: AppColor.grey3Color,
                        thickness: 1,
                        indent: 20,
                        endIndent: 20,
                      ),
                      state.selectedPage == 'preview'
                          ? getPreviewFilterItems(context)
                          : Container(),
                    ],
                  )),
              SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width - 250,
                child: state.selectedPage == 'preview'
                    ? getPreviewBody(state)
                    : state.selectedPage == 'web'
                        ? getWebBody(state)
                        : state.selectedPage == 'playlists'
                            ? getPlaylistsBody()
                            : Container(),
              )
            ]),
          ),
        );
      },
    );
  }

  Widget getPlaylistsBody() => Container(child: BlocBuilder<PlaylistsBloc, PlaylistsState>(
        buildWhen: (previous, current) =>
            previous.playlists != current.playlists,
        builder: (context, state) {
          return Column(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width - 250,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColor.grey3Color),
                      ),
                      onPressed: () {
                        context.read<PlaylistsBloc>().add(const OpenPlaylist(playlist: null, forEdit: true));
                        Navigator.of(context).pushNamed('/editPlaylistPage');
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.add, color: AppColor.primaryColor),
                          const SizedBox(width: 8),
                          Text('createPlaylist'.tr()),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                ),
              ),
              const Divider(color: AppColor.grey3Color, thickness: 1, indent: 20, endIndent: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: state.playlists.length,
                  itemBuilder: (context, index) {
                    final playlist = state.playlists[index];
                    String songNamesSubtitle = '';
                    if (playlist.listSongIds.isNotEmpty) {
                      final songs = context.read<PlaylistsBloc>().songsRepository.songs;
                      final nameParts = <String>[];
                      for (var songId in playlist.listSongIds) {
                        try {
                          final songName = songs.firstWhere((element) => element.id == songId).title;
                          if (songName.isNotEmpty) {
                            nameParts.add(songName);
                          }
                        } catch (_) {}
                      }
                      songNamesSubtitle = nameParts.join(', ');
                    }
                    return GestureDetector(
                      key: ValueKey('playlist_${playlist.id}'),
                      onTap: () {
                        context.read<PlaylistsBloc>().add(OpenPlaylist(playlist: playlist, forEdit: false));
                        Navigator.of(context).pushNamed('/playlistPage');
                      },
                      child: Card(
                          color: AppColor.whiteColor,
                          borderOnForeground: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            side: const BorderSide(
                              color: AppColor.grey3Color,
                              width: 1.0,
                            ),
                          ),
                          child: ListTile(
                            title: Text(
                              playlist.name,
                            ),
                            subtitle: Text(
                              songNamesSubtitle,
                            ),
                            trailing: SizedBox(
                              width: 150,
                              height: 50,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.copy, color: Colors.grey),
                                    tooltip: 'copyPlaylist'.tr(),
                                    onPressed: () {
                                      final songs = context.read<PlaylistsBloc>().songsRepository.songs;
                                      final buffer = StringBuffer();
                                      buffer.writeln(playlist.name);
                                      var songNum = 1;
                                      for (final songId in playlist.listSongIds) {
                                        try {
                                          final song = songs.firstWhere((s) => s.id == songId);
                                          buffer.writeln('$songNum. ${song.title}');
                                          songNum++;
                                        } catch (_) {}
                                      }
                                      Clipboard.setData(ClipboardData(text: buffer.toString().trim()));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('playlistCopied'.tr()),
                                          duration: const Duration(seconds: 2),
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: AppColor.primaryColor),
                                    onPressed: () {
                                      context.read<PlaylistsBloc>().add(OpenPlaylist(playlist: playlist, forEdit: true));
                                      Navigator.of(context).pushNamed('/editPlaylistPage');
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: AppColor.alertErrorColor),
                                    onPressed: () {
                                      context.read<PlaylistsBloc>().add(DeletePlaylist(playlist: playlist));
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ));

  Container newMethod() {
    return Container(
      color: AppColor.grey3Color,
    );
  }

  Widget getWebBody(HomePageState state) {
    return BlocBuilder<WebBloc, WebState>(
      builder: (context, wState) {
        return Column(
          children: [
            _buildWebSearchBar(context, wState),
            const SizedBox(height: 12),
            _buildWebSearchTypeToggle(context, wState),
            const SizedBox(height: 12),
            Expanded(
              child: _buildWebResults(context, wState),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWebSearchBar(BuildContext context, WebState wState) {
    final label = switch (wState.searchWeb) {
      2 => 'filterSongOrInterpret'.tr(),
      3 => 'filterSong'.tr(),
      _ => wState.searchType == 0 ? 'filterSong'.tr() : 'filterInterpret'.tr(),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColor.grey3Color),
              ),
              child: TextField(
                controller: _filterInterpretPisnickyAkordy,
                decoration: InputDecoration(
                  hintText: label,
                  prefixIcon: const Icon(Icons.search, color: AppColor.grey1Color),
                  suffixIcon: _filterInterpretPisnickyAkordy.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _filterInterpretPisnickyAkordy.clear();
                            context.read<WebBloc>().add(const FilterInterprets(filter: ''));
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onSubmitted: (value) {
                  if (wState.searchType == 0) {
                    context.read<WebBloc>().add(FilterInterprets(filter: value));
                  } else {
                    context.read<WebBloc>().add(FilterInterprets(filter: value));
                  }
                },
                onChanged: (value) {
                  context.read<WebBloc>().add(FilterInterprets(filter: value));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebSearchTypeToggle(BuildContext context, WebState wState) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Website segmented tabs
              Expanded(
                child: SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _listSearchWeb.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final isSelected = wState.searchWeb == index;
                      return buildWebsiteChip(index, isSelected, wState);
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Search type toggle (show for sites that support both)
          if (wState.searchWeb == 0 || wState.searchWeb == 1 || wState.searchWeb == 2)
            Row(
              children: [
                _buildToggleChip(
                  label: 'interpret'.tr(),
                  icon: Icons.person,
                  isSelected: wState.searchType == 1,
                  onTap: () {
                    if (wState.searchType != 1) {
                      context.read<WebBloc>().add(const ChangeSearchType(searchType: 1));
                      _filterInterpretPisnickyAkordy.clear();
                    }
                  },
                ),
                const SizedBox(width: 8),
                _buildToggleChip(
                  label: 'song'.tr(),
                  icon: Icons.music_note,
                  isSelected: wState.searchType == 0,
                  onTap: () {
                    if (wState.searchType != 0) {
                      context.read<WebBloc>().add(const ChangeSearchType(searchType: 0));
                      _filterInterpretPisnickyAkordy.clear();
                    }
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget buildWebsiteChip(int index, bool isSelected, WebState wState) {
    final names = ['Velký zpěvník', 'Písničky-akordy', 'ProScholy', 'Worship Leader'];
    final icons = [Icons.library_music, Icons.music_note, Icons.church, Icons.mic];
    return GestureDetector(
      onTap: () {
        _filterInterpretPisnickyAkordy.clear();
        _filterSongVelkyZpevnik.clear();
        _filterInterpretVelkyZpevnik.clear();
        _filterSongPisnickyAkordy.clear();
        context.read<WebBloc>().add(ChangeSearchWeb(searchWeb: index));
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColor.primaryColor : AppColor.grey3Color,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icons[index], size: 16, color: isSelected ? Colors.white : AppColor.grey1Color),
            const SizedBox(width: 6),
            Text(
              names[index],
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
  }

  Widget _buildToggleChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColor.primaryColor : AppColor.grey3Color,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? AppColor.primaryColor : AppColor.grey1Color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isSelected ? AppColor.primaryColor : AppColor.grey1Color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebResults(BuildContext context, WebState wState) {
    if (wState.searchWebInterprets || wState.isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    final hasInterprets = wState.filteredInterprets.isNotEmpty;
    final hasHistory = wState.historyInterprets.isNotEmpty;
    final isSongMode = wState.searchType == 0;
    final songsToShow = isSongMode ? wState.filteredSongs : wState.songs;

    // Song mode: show full-width songs, no interpret panel
    if (isSongMode || wState.searchWeb == 3) {
      return wState.searchWebSongs
          ? const Center(child: CircularProgressIndicator())
          : _buildSongList(context, wState, songsToShow.isEmpty ? wState.songs : songsToShow);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left panel: interprets
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasInterprets) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    'interpret'.tr().toUpperCase(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.grey1Color, letterSpacing: 1.2),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: wState.filteredInterprets.length,
                    itemBuilder: (context, index) {
                      return WebInterpretCard(interpret: wState.filteredInterprets[index]);
                    },
                  ),
                ),
              ],
              if (hasHistory && !hasInterprets) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 12, top: 8, bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 14, color: AppColor.grey1Color),
                      const SizedBox(width: 4),
                      Text(
                        'history'.tr().toUpperCase(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.grey1Color, letterSpacing: 1.2),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: wState.historyInterprets.length,
                    itemBuilder: (context, index) {
                      return WebInterpretCard(interpret: wState.historyInterprets[index]);
                    },
                  ),
                ),
              ],
              if (!hasInterprets && !hasHistory)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 48, color: AppColor.grey3Color),
                        const SizedBox(height: 8),
                        Text('searchForSongOrInterpret'.tr(), style: TextStyle(color: AppColor.grey1Color)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1, color: AppColor.grey3Color),
        // Right panel: songs
        Expanded(
          flex: 3,
          child: wState.searchWebSongs
              ? const Center(child: CircularProgressIndicator())
              : _buildSongList(context, wState, songsToShow),
        ),
      ],
    );
  }

  Widget _buildSongList(BuildContext context, WebState wState, List<WebSong> songs) {
    if (songs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.music_note, size: 48, color: AppColor.grey3Color),
              const SizedBox(height: 8),
              Text('searchResults'.tr(), style: TextStyle(color: AppColor.grey1Color, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Row(
            children: [
              Text(
                wState.currentInterpret.title.isNotEmpty ? wState.currentInterpret.title : 'searchResults'.tr(),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColor.grey1Color),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColor.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${songs.length}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.primaryColor),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: songs.length,
            itemBuilder: (context, index) {
              return SongCardTabletWeb(
                song: songs[index],
                index: index,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget getPreviewBody(HomePageState state) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: state.listSong.length,
      itemBuilder: (context, index) {
        final song = state.listSong[index];
        return RepaintBoundary(
          child: SongCardTablet(
            key: ValueKey(song.id),
            song: song,
            index: index,
            isEditIconVisible: state.isEditIconVisible,
            isSelectedSong: state.selectedSongId == song.id,
            superuserMode: state.superuserMode,
          ),
        );
      },
    );
  }

  Widget getPreviewFilterItems(BuildContext context) {
    return Column(
      children: [
        BlocBuilder<HomePageBloc, HomePageState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: OutlinedButton(
                onPressed: () {
                  List<String> choiceGroups = [];
                  for (String group in state.listSelectedGroups) {
                    choiceGroups.add(group);
                  }
                  showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(builder: (context, setState) {
                            return EditDialog(
                              height: 500,
                              width: 400,
                              title: 'selectGroups'.tr(),
                              okClick: () {
                                context.read<HomePageBloc>().add(SelectGroups(groups: choiceGroups));
                              },
                              widgetContent: SizedBox(
                                height: 350,
                                child: Wrap(
                                    children: state.listAllGroups
                                        .map((e) => Padding(
                                              padding: const EdgeInsets.all(4.0),
                                              child: ChoiceChip(
                                                selectedColor: AppColor.primaryColor,
                                                checkmarkColor: choiceGroups.contains(e) ? Colors.white : Colors.black,
                                                padding: const EdgeInsets.all(8),
                                                label: Text(e, style: TextStyle(color: choiceGroups.contains(e) ? Colors.white : Colors.black)),
                                                selected: choiceGroups.contains(e),
                                                onSelected: (value) {
                                                  setState(() {
                                                    if (value) {
                                                      choiceGroups.add(e);
                                                    } else {
                                                      choiceGroups.remove(e);
                                                    }
                                                  });
                                                },
                                              ),
                                            ))
                                        .toList()),
                              ),
                            );
                          }));
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: state.listAllGroups.length != state.listSelectedGroups.length ? AppColor.alertErrorColor : AppColor.grey3Color),
                ),
                child: Text('groups'.tr(),
                    style: TextStyle(fontSize: 16, color: state.listAllGroups.length != state.listSelectedGroups.length ? AppColor.alertErrorColor : AppColor.grey1Color)),
              ),
            );
          },
        ),
        FilterFieldTablet(
          filter: _previewFilterSearchSong,
          clearFilter: () => context.read<HomePageBloc>().add(const FilterSong(filter: '')),
          onSearch: (value) => context.read<HomePageBloc>().add(FilterSong(filter: value)),
          hintText: 'filterSong'.tr(),
        ),
      ],
    );
  }

  Widget getSelectPageDropDown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // add hide/show button
        Padding(
          padding: const EdgeInsets.only(left: 10.0, top: 20),
          child: Text('selectPage'.tr(), style: const TextStyle(fontSize: 16)),
        ),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColor.grey3Color),
            borderRadius: BorderRadius.circular(5),
          ),
          margin: const EdgeInsets.all(8),
          width: 250,
          height: 40,
          child: DropdownButton<String>(
            underline: const SizedBox(),
            value: selectPage,
            padding: const EdgeInsets.only(left: 8),
            items: [
              DropdownMenuItem(
                value: 'preview',
                child: SizedBox(
                  width: 200,
                  child: Row(
                    children: [
                      const Icon(Icons.remove_red_eye, color: AppColor.grey1Color),
                      const SizedBox(width: 8),
                      Text('viewSongs'.tr()),
                    ],
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'web',
                child: SizedBox(
                  width: 200,
                  child: Row(
                    children: [
                      const Icon(Icons.web, color: AppColor.grey1Color),
                      const SizedBox(width: 8),
                      Text('web'.tr()),
                    ],
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'playlists',
                child: SizedBox(
                  width: 200,
                  child: Row(
                    children: [
                      const Icon(Icons.playlist_play, color: AppColor.grey1Color),
                      const SizedBox(width: 8),
                      Text('playlists'.tr()),
                    ],
                  ),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                selectPage = value!;
              });
              context.read<HomePageBloc>().add(SelectPage(page: value ?? 'preview'));
            },
            hint: const Text('Select an option'),
          ),
        ),
      ],
    );
  }

}

class WebInterpretCard extends StatelessWidget {
  final WebInterpret interpret;

  const WebInterpretCard({
    super.key,
    required this.interpret,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebBloc, WebState>(
      buildWhen: (previous, current) =>
          previous.currentInterpret.title != current.currentInterpret.title,
      builder: (context, state) {
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
                  border: Border.all(
                    color: isSelected ? AppColor.primaryColor.withValues(alpha: 0.3) : AppColor.grey3Color,
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: isSelected ? AppColor.primaryColor : AppColor.grey3Color,
                      child: Text(
                        interpret.title.isNotEmpty ? interpret.title[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : AppColor.grey1Color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            interpret.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              color: isSelected ? AppColor.primaryColor : AppColor.grey1Color,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (interpret.songs > 0)
                            Text(
                              '${interpret.songs} ${'songs'.tr()}',
                              style: TextStyle(fontSize: 11, color: AppColor.grey1Color.withValues(alpha: 0.7)),
                            ),
                        ],
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
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColor.primaryColor : AppColor.grey1Color,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

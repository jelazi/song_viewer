import 'package:song_viewer/repositories/settings_repository.dart';
import 'package:song_viewer/view/mobile_view/widgets/song_card.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';
import '../../../services/constants.dart';
import '../widgets/home_drawer.dart';

class HomePageMobile extends StatefulWidget {
  final SettingsRepository settingsRepository;
  const HomePageMobile({
    super.key,
    required this.settingsRepository,
  });

  @override
  State<HomePageMobile> createState() => _HomePageMobileState();
}

class _HomePageMobileState extends State<HomePageMobile> {
  final TextEditingController _filter = TextEditingController();
  bool _isFilterActive = false;

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
  Widget build(BuildContext context) {
    selectLargeScreen(MediaQuery.of(context).size);
    return BlocBuilder<HomePageBloc, HomePageState>(
      buildWhen: (previous, current) =>
          previous.listSong != current.listSong ||
          previous.selectedSongId != current.selectedSongId ||
          previous.isEditIconVisible != current.isEditIconVisible ||
          previous.superuserMode != current.superuserMode ||
          previous.listExpandedSongs != current.listExpandedSongs,
      builder: (context, state) {
        return Scaffold(
          drawer: const HomeDrawer(),
          body: RefreshIndicator(
            onRefresh: () => context.read<HomePageBloc>().refreshFromServer(),
            child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), slivers: [
              SliverLayoutBuilder(builder: ((context, constraints) {
                return SliverAppBar(
                  floating: true,
                  pinned: true,
                  snap: false,
                  centerTitle: false,
                  title: Align(alignment: Alignment.centerRight, child: Text('songsViewer'.tr())),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(50),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                          width: MediaQuery.of(context).size.width - 20,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColor.primaryColor),
                          ),
                          child: Center(
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _filter,
                              builder: (context, value, child) {
                                return TextField(
                                  controller: _filter,
                                  decoration: InputDecoration(
                                    hintText: 'filterSong'.tr(),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          onPressed: () {
                                            context.read<HomePageBloc>().add(FilterSong(filter: _filter.text));
                                            _isFilterActive = _filter.text.isNotEmpty;
                                          },
                                          icon: const Icon(Icons.search),
                                        ),
                                        if (value.text.isNotEmpty)
                                          IconButton(
                                            onPressed: () {
                                              _filter.clear();
                                              context.read<HomePageBloc>().add(const FilterSong(filter: ''));
                                              _isFilterActive = false;
                                            },
                                            icon: const Icon(Icons.clear),
                                          ),
                                      ],
                                    ),
                                  ),
                                  onSubmitted: (value) {
                                    context.read<HomePageBloc>().add(FilterSong(filter: value));
                                    _isFilterActive = value.isNotEmpty;
                                  },
                                  onChanged: (value) {
                                    if (_isFilterActive) {
                                      context.read<HomePageBloc>().add(const FilterSong(filter: ''));
                                      _isFilterActive = false;
                                    }
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        )
                      ],
                    ),
                  ),
                );
              })),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = state.listSong[index];
                    return RepaintBoundary(
                      child: SongCard(
                        key: ValueKey(song.id),
                        song: song,
                        index: index,
                        isSelectedSong: state.selectedSongId == song.id,
                        isEditIconVisible: state.isEditIconVisible,
                        isExpanded: state.listExpandedSongs.contains(song.id),
                        superuserMode: state.superuserMode,
                      ),
                    );
                  },
                  childCount: state.listSong.length,
                ),
              )
            ]),
          ),
        );
      },
    );
  }
}

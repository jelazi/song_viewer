import 'package:default_project/model/web_interpret.dart';
import 'package:default_project/repositories/settings_repository.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/edit_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';
import '../../../services/constants.dart';
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
  final List<String> _listSearchWeb = ['velkyzpevnik.cz', 'pisnicky-akordy.cz'];

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
                          : state.selectedPage == 'web'
                              ? getWebSiteDropDown()
                              : const SizedBox(),
                    ],
                  )),
              SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width - 250,
                child: state.selectedPage == 'preview'
                    ? getPreviewBody(state)
                    : state.selectedPage == 'web'
                        ? getWebBody(state)
                        : const SizedBox(),
              )
            ]),
          ),
        );
      },
    );
  }

  Widget getWebBody(HomePageState state) {
    return BlocBuilder<WebBloc, WebState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 15.0, bottom: 20),
              child: FilterFieldTablet(
                filter: _filterInterpretPisnickyAkordy,
                clearFilter: () => context.read<WebBloc>().add(const FilterInterprets(filter: '')),
                onChanged: (value) => context.read<WebBloc>().add(FilterInterprets(
                      filter: value,
                    )),
                hintText: 'filterInterpret'.tr(),
              ),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width - 280,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    flex: 2,
                    child: state.searchWebInterprets
                        ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator())
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                  height: MediaQuery.of(context).size.height / 2 - 100,
                                  child: SingleChildScrollView(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.start,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: state.filteredInterprets.map((interpret) => WebInterpretCard(interpret: interpret)).toList(),
                                    ),
                                  )),
                              Visibility(
                                visible: state.historyInterprets.isNotEmpty,
                                child: Container(
                                  height: 40,
                                  padding: EdgeInsets.zero,
                                  child: const Divider(
                                    color: AppColor.grey1Color,
                                    thickness: 2,
                                  ),
                                ),
                              ),
                              Visibility(
                                  visible: state.historyInterprets.isNotEmpty, child: Text('history'.tr(), style: const TextStyle(fontSize: 16, color: AppColor.grey1Color))),
                              SizedBox(
                                height: MediaQuery.of(context).size.height / 2 - 100,
                                child: SingleChildScrollView(child: Column(children: state.historyInterprets.map((interpret) => WebInterpretCard(interpret: interpret)).toList())),
                              )
                            ],
                          ),
                  ),
                  Flexible(
                    flex: 3,
                    child: state.searchWebSongs
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(),
                          )
                        : SizedBox(
                            height: MediaQuery.of(context).size.height - 110,
                            child: Column(
                              children: [
                                Text(state.currentInterpret.title, style: const TextStyle(fontSize: 16, color: AppColor.grey1Color)),
                                SizedBox(
                                  height: MediaQuery.of(context).size.height - 135,
                                  child: ListView(
                                    shrinkWrap: true,
                                    children: state.songs
                                        .map((song) => SongCardTabletWeb(
                                              song: song,
                                              index: state.songs.indexOf(song),
                                            ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget getPreviewBody(HomePageState state) {
    return ListView(
      shrinkWrap: true,
      children: state.listSong
          .map((song) => SongCardTablet(
                song: song,
                index: state.listSong.indexOf(song),
                isEditIconVisible: state.isEditIconVisible,
                isSelectedSong: state.selectedSongId == song.id,
              ))
          .toList(),
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
          onChanged: (value) => context.read<HomePageBloc>().add(FilterSong(filter: value)),
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
                      Text('preview'.tr()),
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

  Widget getWebSiteDropDown() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 10.0,
            ),
            child: Text('selectWebSite'.tr(), style: const TextStyle(fontSize: 16)),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColor.grey3Color),
              borderRadius: BorderRadius.circular(5),
            ),
            margin: const EdgeInsets.all(8),
            width: 250,
            height: 40,
            child: BlocBuilder<WebBloc, WebState>(
              builder: (context, state) {
                return DropdownButton<String>(
                  underline: const SizedBox(),
                  value: _listSearchWeb[state.searchWeb],
                  padding: const EdgeInsets.only(left: 8),
                  items: [
                    DropdownMenuItem(
                      value: _listSearchWeb[0],
                      child: SizedBox(
                        width: 200,
                        child: Text(_listSearchWeb[0]),
                      ),
                    ),
                    DropdownMenuItem(
                      value: _listSearchWeb[1],
                      child: SizedBox(
                        width: 200,
                        child: Text(_listSearchWeb[1]),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      int index = _listSearchWeb.indexOf(value ?? _listSearchWeb[0]);
                      _filterSongVelkyZpevnik.clear();
                      _filterInterpretVelkyZpevnik.clear();
                      _filterInterpretPisnickyAkordy.clear();
                      _filterSongPisnickyAkordy.clear();
                      context.read<WebBloc>().add(ChangeSearchWeb(searchWeb: index));
                    });
                  },
                  hint: const Text('Select an option'),
                );
              },
            ),
          ),
        ],
      ),
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
      builder: (context, state) {
        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              if (state.currentInterpret.title == interpret.title) {
                context.read<WebBloc>().add(const ChangeCurrentInterpret(interpret: null));
              } else {
                context.read<WebBloc>().add(ChangeCurrentInterpret(interpret: interpret));
              }
            },
            child: Container(
              height: 60,
              width: 200,
              alignment: Alignment.centerLeft,
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
        );
      },
    );
  }
}

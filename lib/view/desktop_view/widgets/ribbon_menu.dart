import 'dart:io';

import 'package:default_project/services/constants.dart';
import 'package:default_project/services/presentation_window_manager.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/dialogs_export.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/qr_code_dialog.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/question_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';
import '../../../model/playlist.dart';
import '../../../model/song/song.dart';
import 'my_toast.dart';
import 'ribbon_button.dart';
import 'ribbon_spacer.dart';

class RibbonMenu extends StatefulWidget {
  const RibbonMenu({super.key});

  @override
  State<RibbonMenu> createState() => _RibbonMenuState();
}

class _RibbonMenuState extends State<RibbonMenu> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
      builder: (context, state) {
        if (state.bodyName == 'edit') {
          _tabController = TabController(length: 2, vsync: this);
        } else if (state.bodyName == 'preview' || state.bodyName == 'browse_youtube' || state.bodyName == 'browse_sheets') {
          _tabController = TabController(length: 2, vsync: this);
        } else if (state.bodyName == 'web') {
          _tabController = TabController(length: 2, vsync: this);
        } else if (state.bodyName == 'groups') {
          _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
        } else if (state.bodyName == 'users') {
          _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
        } else if (state.bodyName == 'presentation_settings') {
          _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
        } else if (state.bodyName == 'general_settings') {
          _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
        } else if (state.bodyName == 'playlist') {
          _tabController = TabController(length: 2, vsync: this);
        } else if (state.bodyName == 'song_enrichment') {
          _tabController = TabController(length: 2, vsync: this);
        } else {
          _tabController = TabController(length: 1, vsync: this);
        }

        return Container(
          height: 92,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                child: SizedBox(
                  height: 90,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    children: [
                      SizedBox(
                        height: 30,
                        child: state.bodyName == 'preview' || state.bodyName == 'browse_youtube' || state.bodyName == 'browse_sheets'
                            ? TabBar(
                                isScrollable: true,
                                tabAlignment: TabAlignment.start,
                                controller: _tabController,
                                tabs: [
                                  Tab(text: 'home'.tr()),
                                  Tab(text: 'settings'.tr()),
                                ],
                              )
                            : state.bodyName == 'edit'
                                ? TabBar(
                                    isScrollable: true,
                                    tabAlignment: TabAlignment.start,
                                    controller: _tabController,
                                    tabs: [
                                      Tab(text: 'home'.tr()),
                                      Tab(text: 'settings'.tr()),
                                    ],
                                  )
                                : state.bodyName == 'web'
                                    ? TabBar(
                                        isScrollable: true,
                                        tabAlignment: TabAlignment.start,
                                        controller: _tabController,
                                        tabs: [
                                          Tab(text: 'home'.tr()),
                                          Tab(text: 'settings'.tr()),
                                        ],
                                      )
                                    : state.bodyName == 'groups'
                                        ? TabBar(
                                            isScrollable: true,
                                            tabAlignment: TabAlignment.start,
                                            controller: _tabController,
                                            onTap: (index) {
                                              if (index == 0) {
                                                context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: 'preview'));
                                              }
                                            },
                                            tabs: [
                                              Tab(text: 'home'.tr()),
                                              Tab(text: 'settings'.tr()),
                                            ],
                                          )
                                        : state.bodyName == 'users'
                                            ? TabBar(
                                                isScrollable: true,
                                                tabAlignment: TabAlignment.start,
                                                controller: _tabController,
                                                onTap: (index) {
                                                  if (index == 0) {
                                                    context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: 'preview'));
                                                  }
                                                },
                                                tabs: [
                                                  Tab(text: 'home'.tr()),
                                                  Tab(text: 'settings'.tr()),
                                                ],
                                              )
                                            : state.bodyName == 'presentation_settings'
                                                ? TabBar(
                                                    isScrollable: true,
                                                    tabAlignment: TabAlignment.start,
                                                    controller: _tabController,
                                                    onTap: (index) {
                                                      if (index == 0) {
                                                        context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: 'preview'));
                                                      }
                                                    },
                                                    tabs: [
                                                      Tab(text: 'home'.tr()),
                                                      Tab(text: 'settings'.tr()),
                                                    ],
                                                  )
                                                : state.bodyName == 'general_settings'
                                                    ? TabBar(
                                                        isScrollable: true,
                                                        tabAlignment: TabAlignment.start,
                                                        controller: _tabController,
                                                        onTap: (index) {
                                                          if (index == 0) {
                                                            context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: 'preview'));
                                                          }
                                                        },
                                                        tabs: [
                                                          Tab(text: 'home'.tr()),
                                                          Tab(text: 'settings'.tr()),
                                                        ],
                                                      )
                                                    : state.bodyName == 'playlist' || state.bodyName == 'song_enrichment'
                                                        ? TabBar(
                                                            isScrollable: true,
                                                            tabAlignment: TabAlignment.start,
                                                            controller: _tabController,
                                                            onTap: (index) {
                                                              if (index == 0) {
                                                                context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: state.bodyName));
                                                              }
                                                            },
                                                            tabs: [
                                                              Tab(text: 'home'.tr()),
                                                              Tab(text: 'settings'.tr()),
                                                            ],
                                                          )
                                                        : TabBar(
                                                            isScrollable: true,
                                                            tabAlignment: TabAlignment.start,
                                                            controller: _tabController,
                                                            tabs: [
                                                              Tab(text: 'home'.tr()),
                                                            ],
                                                          ),
                      ),
                      SizedBox(
                        height: 60,
                        child: state.bodyName == 'preview' || state.bodyName == 'browse_youtube' || state.bodyName == 'browse_sheets'
                            ? TabBarView(
                                controller: _tabController,
                                children: const [
                                  HomeTabbar(),
                                  SettingsTabbar(),
                                ],
                              )
                            : state.bodyName == 'edit'
                                ? TabBarView(
                                    controller: _tabController,
                                    children: const [
                                      HomeTabbar(),
                                      SettingsTabbar(),
                                    ],
                                  )
                                : state.bodyName == 'groups'
                                    ? TabBarView(
                                        controller: _tabController,
                                        children: const [
                                          HomeTabbar(),
                                          SettingsTabbar(),
                                        ],
                                      )
                                    : state.bodyName == 'web'
                                        ? TabBarView(
                                            controller: _tabController,
                                            children: const [
                                              HomeTabbar(),
                                              SettingsTabbar(),
                                            ],
                                          )
                                        : state.bodyName == 'users'
                                            ? TabBarView(
                                                controller: _tabController,
                                                children: const [
                                                  HomeTabbar(),
                                                  SettingsTabbar(),
                                                ],
                                              )
                                            : state.bodyName == 'presentation_settings'
                                                ? TabBarView(
                                                    controller: _tabController,
                                                    children: const [
                                                      HomeTabbar(),
                                                      SettingsTabbar(),
                                                    ],
                                                  )
                                                : state.bodyName == 'general_settings'
                                                    ? TabBarView(
                                                        controller: _tabController,
                                                        children: const [
                                                          HomeTabbar(),
                                                          SettingsTabbar(),
                                                        ],
                                                      )
                                                    : state.bodyName == 'playlist' || state.bodyName == 'song_enrichment'
                                                        ? TabBarView(
                                                            controller: _tabController,
                                                            children: const [
                                                              HomeTabbar(),
                                                              SettingsTabbar(),
                                                            ],
                                                          )
                                                        : TabBarView(
                                                            controller: _tabController,
                                                            children: const [
                                                              HomeTabbar(),
                                                            ],
                                                          ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 0,
                right: 0,
                child: SizedBox(
                  height: 30,
                  width: 240,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _getTopButton('preview', Icons.preview),
                      _getTopButton('edit', Icons.edit),
                      _getTopButton('web', Icons.web),
                      _getTopButton('playlist', Icons.playlist_play),
                      _getTopButton('song_enrichment', Icons.auto_awesome),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

Widget _getTopButton(String name, IconData icon) {
  return BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
    builder: (context, state) {
      return Tooltip(
        message: name.tr(),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () {
              context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: name));
            },
            child: BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
              builder: (context, state) {
                return Container(
                    padding: const EdgeInsets.only(top: 2, left: 8, right: 8, bottom: 2),
                    decoration: BoxDecoration(
                      color: state.bodyName == name ? AppColor.primaryColor : null,
                      border: const Border(
                          left: BorderSide(
                            color: AppColor.grey3Color,
                          ),
                          bottom: BorderSide(
                            color: AppColor.grey3Color,
                          )),
                    ),
                    child: Icon(
                      icon,
                      color: state.bodyName == name ? AppColor.whiteColor : AppColor.primaryColor,
                    ));
              },
            ),
          ),
        ),
      );
    },
  );
}

class EditTabbar extends StatelessWidget {
  const EditTabbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
      builder: (context, state) {
        return SizedBox(
            width: MediaQuery.of(context).size.width,
            child: const Row(
              children: [],
            ));
      },
    );
  }
}

class SettingsTabbar extends StatelessWidget {
  const SettingsTabbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Row(
          children: [
            RibbonButton(
                text: 'exportAllSongs'.tr(),
                icon: const Icon(
                  Icons.exit_to_app,
                  color: Colors.blue,
                ),
                isEnabled: true,
                onPressed: () async {
                  final listSong = context.read<HomePageBloc>().songsRepository.getListSongToJson();
                  String? outputFile = await FilePicker.platform.saveFile(
                    dialogTitle: 'pleaseSelectPathToSaveFile'.tr(),
                    fileName: 'list_songs.json',
                  );
                  if (outputFile == null) {
                    return;
                  }
                  File returnedFile = File(outputFile);
                  await returnedFile.writeAsString(listSong);
                }),
            BlocBuilder<EditSongBloc, EditSongState>(
              builder: (context, state) {
                return Visibility(
                  visible: state.currentEditSong.id.isNotEmpty,
                  child: RibbonButton(
                      text: 'exportLyricsToTxt'.tr(),
                      icon: SizedBox(height: 25, child: Image.asset('assets/icons/txt.png')),
                      isEnabled: true,
                      onPressed: () async {
                        String lyric = '';
                        showDialog(
                            context: context,
                            builder: (context) {
                              return SelectDialog(
                                title: 'exportLyricsToTxt'.tr(),
                                selectQuestion: 'withOrWithoutChords'.tr(),
                                firstSelectTitle: 'withChords'.tr(),
                                firstSelectFunction: () async {
                                  lyric = state.currentEditSong.lyricsWithChords;
                                  String? outputFile = await FilePicker.platform.saveFile(
                                    dialogTitle: 'pleaseSelectPathToSaveFile'.tr(),
                                    fileName: '${state.currentEditSong.title}.txt',
                                  );
                                  if (outputFile == null) {
                                    return;
                                  }
                                  File returnedFile = File(outputFile);
                                  await returnedFile.writeAsString(lyric);
                                },
                                secondSelectTitle: 'withoutChords'.tr(),
                                secondSelectFunction: () async {
                                  lyric = state.currentEditSong.lyricsWithoutChordsWithLines;
                                  String? outputFile = await FilePicker.platform.saveFile(
                                    dialogTitle: 'pleaseSelectPathToSaveFile'.tr(),
                                    fileName: '${state.currentEditSong.title}.txt',
                                  );
                                  if (outputFile == null) {
                                    return;
                                  }
                                  File returnedFile = File(outputFile);
                                  await returnedFile.writeAsString(lyric);
                                },
                              );
                            });
                      }),
                );
              },
            ),
            const RibbonSpacer(),
            RibbonButton(
                text: 'groups'.tr(),
                icon: const Icon(
                  Icons.group,
                  color: Colors.teal,
                ),
                isEnabled: true,
                onPressed: () {
                  context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: 'groups'));
                }),
            RibbonButton(
                text: 'users'.tr(),
                icon: const Icon(
                  Icons.person,
                  color: Colors.indigo,
                ),
                isEnabled: true,
                onPressed: () {
                  context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: 'users'));
                }),
            RibbonButton(
                text: 'Prezentace',
                icon: const Icon(
                  Icons.present_to_all,
                  color: Colors.deepPurple,
                ),
                isEnabled: true,
                onPressed: () {
                  context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: 'presentation_settings'));
                }),
            RibbonButton(
                text: 'generalSettings'.tr(),
                icon: const Icon(
                  Icons.settings,
                  color: Colors.blueGrey,
                ),
                isEnabled: true,
                onPressed: () {
                  context.read<DesktopRibbonMenuBloc>().add(ChangeHomeBody(bodyName: 'general_settings'));
                }),
            const RibbonSpacer(),
            RibbonButton(
                text: 'qrCode'.tr(),
                icon: const Icon(
                  Icons.qr_code,
                  color: Colors.orange,
                ),
                isEnabled: true,
                onPressed: () {
                  QrCodeDialog.show(context);
                }),
          ],
        ));
  }
}

class PreviewTabbar extends StatelessWidget {
  const PreviewTabbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Row(children: [
        BlocBuilder<PreviewChordBloc, PreviewChordState>(
          builder: (context, state) {
            return RibbonButton(
                text: 'zoomIn'.tr(),
                icon: const Icon(
                  Icons.zoom_in,
                  color: Colors.blue,
                ),
                isEnabled: state.data.song != null,
                onPressed: () {
                  context.read<PreviewChordBloc>().add(const ChangeFontSize(isIncrease: true));
                });
          },
        ),
        BlocBuilder<PreviewChordBloc, PreviewChordState>(
          builder: (context, state) {
            return RibbonButton(
                text: 'zoomOut'.tr(),
                isEnabled: state.data.song != null,
                icon: const Icon(
                  Icons.zoom_out,
                  color: Colors.blue,
                ),
                onPressed: () {
                  context.read<PreviewChordBloc>().add(const ChangeFontSize(isIncrease: false));
                });
          },
        ),
        BlocBuilder<PreviewChordBloc, PreviewChordState>(
          builder: (context, state) {
            return RibbonButton(
                text: 'transpose'.tr(),
                isEnabled: state.data.song != null,
                icon: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.orange,
                    ),
                    Icon(
                      Icons.music_note,
                      size: 18,
                      color: Colors.orange,
                    ),
                  ],
                ),
                onPressed: () {
                  context.read<PreviewChordBloc>().add(const TransposeChord(increment: 1));
                });
          },
        ),
        BlocBuilder<PreviewChordBloc, PreviewChordState>(
          builder: (context, state) {
            return RibbonButton(
                text: 'transpose'.tr(),
                isEnabled: state.data.song != null,
                icon: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove,
                      size: 18,
                      color: Colors.orange,
                    ),
                    Icon(
                      Icons.music_note,
                      size: 18,
                      color: Colors.orange,
                    ),
                  ],
                ),
                onPressed: () {
                  context.read<PreviewChordBloc>().add(const TransposeChord(increment: -1));
                });
          },
        ),
      ]),
    );
  }
}

class HomeTabbar extends StatelessWidget {
  const HomeTabbar({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: MediaQuery.of(context).size.width,
        child: BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
          builder: (context, state) {
            return state.isSelectedSong
                ? state.bodyName == 'preview' || state.bodyName == 'browse_youtube' || state.bodyName == 'browse_sheets'
                    ? Row(
                        children: [
                          _buildCurrentSongButton(context),
                          const RibbonSpacer(),
                          BlocBuilder<PreviewChordBloc, PreviewChordState>(
                            builder: (context, state) {
                              return RibbonButton(
                                  text: 'zoomIn'.tr(),
                                  icon: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.blue,
                                  ),
                                  isEnabled: state.data.song != null,
                                  onPressed: () {
                                    context.read<PreviewChordBloc>().add(const ChangeFontSize(isIncrease: true));
                                  });
                            },
                          ),
                          BlocBuilder<PreviewChordBloc, PreviewChordState>(
                            builder: (context, state) {
                              return RibbonButton(
                                  text: 'zoomOut'.tr(),
                                  isEnabled: state.data.song != null,
                                  icon: const Icon(
                                    Icons.zoom_out,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    context.read<PreviewChordBloc>().add(const ChangeFontSize(isIncrease: false));
                                  });
                            },
                          ),
                          BlocBuilder<PreviewChordBloc, PreviewChordState>(
                            builder: (context, state) {
                              return RibbonButton(
                                  text: 'transpose'.tr(),
                                  isEnabled: state.data.song != null,
                                  icon: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                      Icon(
                                        Icons.music_note,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                    ],
                                  ),
                                  onPressed: () {
                                    context.read<PreviewChordBloc>().add(const TransposeChord(increment: 1));
                                  });
                            },
                          ),
                          BlocBuilder<PreviewChordBloc, PreviewChordState>(
                            builder: (context, state) {
                              return RibbonButton(
                                  text: 'transpose'.tr(),
                                  isEnabled: state.data.song != null,
                                  icon: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.remove,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                      Icon(
                                        Icons.music_note,
                                        size: 18,
                                        color: Colors.orange,
                                      ),
                                    ],
                                  ),
                                  onPressed: () {
                                    context.read<PreviewChordBloc>().add(const TransposeChord(increment: -1));
                                  });
                            },
                          ),
                          const RibbonSpacer(),
                          BlocBuilder<PreviewChordBloc, PreviewChordState>(
                            builder: (context, previewState) {
                              final hasYoutube = previewState.data.song?.youtubeVideos?.isNotEmpty ?? false;
                              if (!hasYoutube) return const SizedBox.shrink();
                              final isActive = state.bodyName == 'browse_youtube';
                              return RibbonButton(
                                  text: 'openVideos'.tr(),
                                  isEnabled: true,
                                  isSelected: isActive,
                                  icon: const Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    context.read<DesktopRibbonMenuBloc>().add(
                                          ChangeHomeBody(bodyName: isActive ? 'preview' : 'browse_youtube'),
                                        );
                                  });
                            },
                          ),
                          BlocBuilder<PreviewChordBloc, PreviewChordState>(
                            builder: (context, previewState) {
                              final hasSheets = previewState.data.song?.sheets?.isNotEmpty ?? false;
                              if (!hasSheets) return const SizedBox.shrink();
                              final isActive = state.bodyName == 'browse_sheets';
                              return RibbonButton(
                                  text: 'openSheet'.tr(),
                                  isEnabled: true,
                                  isSelected: isActive,
                                  icon: Icon(
                                    Icons.music_note,
                                    color: Colors.green.shade700,
                                  ),
                                  onPressed: () {
                                    context.read<DesktopRibbonMenuBloc>().add(
                                          ChangeHomeBody(bodyName: isActive ? 'preview' : 'browse_sheets'),
                                        );
                                  });
                            },
                          ),
                          BlocBuilder<PreviewChordBloc, PreviewChordState>(
                            builder: (context, state) {
                              return state.data.song?.youtubeVideos?.isNotEmpty == true || state.data.song?.sheets?.isNotEmpty == true
                                  ? const RibbonSpacer()
                                  : const SizedBox.shrink();
                            },
                          ),
                          const RibbonSpacer(),
                          _buildPresentationButton(context),
                        ],
                      )
                    : state.bodyName == 'edit'
                        ? Row(
                            children: [
                              getNewSongButton(context),
                              const RibbonSpacer(),
                              RibbonButton(
                                  text: 'lyrics'.tr(),
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    context.read<DesktopRibbonMenuBloc>().add(const ChangeEditBody(bodyName: 'lyrics'));
                                  },
                                  isEnabled: true,
                                  isSelected: state.bodyEditName == 'lyrics'),
                              RibbonButton(
                                  text: 'chord'.tr(),
                                  icon: const Icon(
                                    Icons.piano,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () {
                                    context.read<DesktopRibbonMenuBloc>().add(const ChangeEditBody(bodyName: 'chords'));
                                  },
                                  isEnabled: true,
                                  isSelected: state.bodyEditName == 'chords'),
                              RibbonButton(
                                  text: 'youtube'.tr(),
                                  icon: const Icon(
                                    Icons.videocam,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    context.read<DesktopRibbonMenuBloc>().add(const ChangeEditBody(bodyName: 'youtube'));
                                  },
                                  isEnabled: true,
                                  isSelected: state.bodyEditName == 'youtube'),
                              RibbonButton(
                                  text: 'sheets'.tr(),
                                  icon: Icon(
                                    Icons.music_note,
                                    color: Colors.green.shade700,
                                  ),
                                  onPressed: () {
                                    context.read<DesktopRibbonMenuBloc>().add(const ChangeEditBody(bodyName: 'sheets'));
                                  },
                                  isEnabled: true,
                                  isSelected: state.bodyEditName == 'sheets'),
                              RibbonButton(
                                  text: 'otherSettings'.tr(),
                                  icon: Icon(
                                    Icons.settings,
                                    color: Colors.grey.shade700,
                                  ),
                                  onPressed: () {
                                    context.read<DesktopRibbonMenuBloc>().add(const ChangeEditBody(bodyName: 'settings'));
                                  },
                                  isEnabled: true,
                                  isSelected: state.bodyEditName == 'settings'),
                              RibbonButton(
                                  text: 'delete'.tr(),
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (context) {
                                          return QuestionDialog(
                                              title: 'deleteSong'.tr(),
                                              okClick: () {
                                                context.read<EditSongBloc>().add(const DeleteCurrentSong());
                                              },
                                              question: 'deleteSongQuestion'.tr());
                                        });
                                  },
                                  isEnabled: true,
                                  isSelected: state.bodyEditName == 'settings'),
                            ],
                          )
                        : const Row(
                            children: [],
                          )
                : Row(
                    children: [
                      getNewSongButton(context),
                      const RibbonSpacer(),
                      _buildCurrentSongButton(context),
                      const RibbonSpacer(),
                      _buildPresentationButton(context),
                    ],
                  );
          },
        ));
  }

  RibbonButton getNewSongButton(BuildContext context) {
    return RibbonButton(
      text: 'newSong'.tr(),
      icon: const Icon(
        Icons.new_label,
        color: Colors.green,
      ),
      onPressed: () {
        TextEditingController nameController = TextEditingController();
        TextEditingController artistController = TextEditingController();
        showDialog(
            context: context,
            builder: (context) {
              return EditDialog(
                  width: 300,
                  height: 300,
                  title: 'newSong'.tr(),
                  okBack: false,
                  okClick: () {
                    if (nameController.text.isEmpty) {
                      MyToast.showText(text: 'nameSongIsEmpty'.tr(), typeNotification: TypeNotification.error);
                      return;
                    }
                    Song song = Song.empty()
                      ..title = nameController.text
                      ..interpret = artistController.text;
                    context.read<EditSongBloc>().add(CreateNewSong(song: song));
                    Navigator.pop(context);
                    context.read<DesktopRibbonMenuBloc>().add(ChangeIsSelectedSong(song: song));
                    context.read<DesktopRibbonMenuBloc>().add(const ChangeHomeBody(bodyName: 'edit'));
                  },
                  widgetContent: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: 'songName'.tr(),
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextField(
                        controller: artistController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          labelText: 'artist'.tr(),
                        ),
                      ),
                    ],
                  ));
            });
      },
      isEnabled: true,
    );
  }

  Widget _buildCurrentSongButton(BuildContext context) {
    return BlocBuilder<PreviewChordBloc, PreviewChordState>(
      builder: (context, previewState) {
        final song = previewState.data.song;
        if (song == null) return const SizedBox.shrink();
        return BlocBuilder<HomePageBloc, HomePageState>(
          builder: (context, homeState) {
            final isActive = homeState.selectedSongId == song.id && song.id.isNotEmpty;
            return RibbonButton(
              text: 'currentSong'.tr(),
              isEnabled: true,
              isSelected: isActive,
              icon: Icon(
                isActive ? Icons.cloud_done : Icons.cloud_upload,
                size: 22,
                color: isActive ? Colors.green : Colors.blueGrey,
              ),
              onPressed: () {
                context.read<HomePageBloc>().add(SelectSong(
                      selectedSongId: song.id,
                      title: song.title,
                      interpret: song.interpret ?? '',
                      lyricsWithoutChords: song.lyricsWithoutChords,
                      lyricsWithChords: song.lyrics,
                    ));
              },
            );
          },
        );
      },
    );
  }

  Widget _buildPresentationButton(BuildContext context) {
    return BlocBuilder<DesktopRibbonMenuBloc, DesktopRibbonMenuState>(
      builder: (context, ribbonState) {
        final isOpen = ribbonState.isPresentationWindowOpen;

        return BlocBuilder<PresentationPlaylistBloc, PresentationPlaylistState>(
          builder: (context, playlistState) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Presentation button - only enabled if playlist is not empty
                RibbonButton(
                    text: isOpen ? 'Zavřít prezentaci' : 'Prezentace (F5)',
                    isEnabled: isOpen || playlistState.isNotEmpty,
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isOpen ? Icons.close_fullscreen : Icons.present_to_all,
                          size: 18,
                          color: (isOpen || playlistState.isNotEmpty) ? Colors.deepPurple : Colors.grey,
                        ),
                      ],
                    ),
                    onPressed: () async {
                      final manager = PresentationWindowManager();
                      if (isOpen) {
                        await manager.closePresentationWindow();
                      } else if (playlistState.isNotEmpty) {
                        _openPresentationFromPlaylist(context);
                      }
                    }),
                // Add songs to playlist dialog button
                RibbonButton(
                    text: 'Přidat do playlistu',
                    isEnabled: true,
                    icon: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.playlist_add, size: 18, color: Colors.teal),
                      ],
                    ),
                    onPressed: () {
                      _showAddSongsDialog(context);
                    }),
                // Save playlist button
                RibbonButton(
                    text: 'Uložit playlist',
                    isEnabled: playlistState.isNotEmpty,
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.save, size: 18, color: playlistState.isNotEmpty ? Colors.blue : Colors.grey),
                      ],
                    ),
                    onPressed: () {
                      if (playlistState.isNotEmpty) {
                        _showSavePlaylistDialog(context);
                      }
                    }),
                // Load playlist button
                RibbonButton(
                    text: 'Načíst playlist',
                    isEnabled: true,
                    icon: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.folder_open, size: 18, color: Colors.amber.shade800),
                      ],
                    ),
                    onPressed: () {
                      _showLoadPlaylistDialog(context);
                    }),
              ],
            );
          },
        );
      },
    );
  }

  void _openPresentationFromPlaylist(BuildContext context) {
    final playlistBloc = context.read<PresentationPlaylistBloc>();
    final presentationBloc = context.read<PresentationBloc>();
    final settingsState = context.read<SettingsBloc>().state;
    final manager = PresentationWindowManager();

    if (playlistBloc.state.isEmpty) return;

    // Select first song if none selected
    if (playlistBloc.state.currentSong == null) {
      playlistBloc.add(const SelectPresentationSong(index: 0));
    }

    // Apply settings to presentation bloc
    presentationBloc.add(UpdatePresentationSettings(
      linesPerPage: settingsState.presentationLinesPerPage,
      fontSize: settingsState.presentationFontSize,
      textColor: settingsState.presentationFontColor,
      showChords: settingsState.presentationShowChords,
      screenIndex: settingsState.presentationScreenIndex,
    ));

    // Get song directly from playlist (don't rely on BLoC state timing)
    final currentSong = playlistBloc.state.currentSong ?? (playlistBloc.state.isNotEmpty ? playlistBloc.state.playlist.songs.first : null);

    if (currentSong == null) return;

    // Update presentation bloc with the song
    presentationBloc.add(UpdatePresentationSong(song: currentSong));

    // Compute page content directly — no race condition
    final result = PresentationBloc.computePageContent(
      song: currentSong,
      linesPerPage: settingsState.presentationLinesPerPage,
      showChords: settingsState.presentationShowChords,
      page: 0,
    );

    debugPrint('Opening presentation from playlist: ${currentSong.title}, '
        'pageContent length: ${result.pageContent.length}, '
        'totalPages: ${result.totalPages}, '
        'screenIndex: ${settingsState.presentationScreenIndex}');

    // Open window immediately with computed content
    manager.openPresentationWindow(
      context,
      title: currentSong.title,
      pageContent: result.pageContent,
      fontSize: settingsState.presentationFontSize,
      textColor: settingsState.presentationFontColor,
      showChords: settingsState.presentationShowChords,
      currentPage: result.currentPage,
      totalPages: result.totalPages,
      linesPerPage: settingsState.presentationLinesPerPage,
      showTitle: settingsState.presentationShowTitle,
      showPageNumber: settingsState.presentationShowPageNumber,
      screenIndex: settingsState.presentationScreenIndex,
    );
  }

  void _showSavePlaylistDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(
      text: DateFormat('dd.MM.yyyy').format(DateTime.now()),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Uložit prezentační playlist'),
          content: SizedBox(
            width: 350,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Název playlistu',
                    hintText: 'Zadejte název...',
                  ),
                ),
                const SizedBox(height: 12),
                BlocBuilder<PresentationPlaylistBloc, PresentationPlaylistState>(
                  builder: (context, state) {
                    return Text(
                      'Počet písní: ${state.songCount}',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Zrušit'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  context.read<PresentationPlaylistBloc>().add(
                        SavePresentationPlaylist(name: name),
                      );
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playlist "$name" uložen'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              },
              child: const Text('Uložit'),
            ),
          ],
        );
      },
    );
  }

  void _showLoadPlaylistDialog(BuildContext context) {
    final playlistsBloc = context.read<PlaylistsBloc>();
    final allSongs = context.read<HomePageBloc>().songsRepository.songs;
    int? expandedIndex; // which playlist is expanded (-1 = none)

    // Resolve song IDs to Song objects
    List<Song> resolveSongs(List<String> songIds) {
      final songs = <Song>[];
      for (final id in songIds) {
        try {
          final song = allSongs.firstWhere((s) => s.id == id);
          songs.add(song);
        } catch (_) {
          // Song not found, skip
        }
      }
      return songs;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BlocBuilder<PlaylistsBloc, PlaylistsState>(
              builder: (context, playlistsState) {
                final playlists = playlistsState.playlists;

                return AlertDialog(
                  title: const Text('Načíst playlist'),
                  content: SizedBox(
                    width: 500,
                    height: 500,
                    child: playlists.isEmpty
                        ? const Center(
                            child: Text(
                              'Žádné uložené playlisty',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: playlists.length,
                            itemBuilder: (context, index) {
                              final playlist = playlists[index];
                              final isExpanded = expandedIndex == index;
                              final songs = isExpanded ? resolveSongs(playlist.listSongIds) : <Song>[];

                              return Column(
                                children: [
                                  InkWell(
                                    onTap: () {
                                      setDialogState(() {
                                        expandedIndex = isExpanded ? null : index;
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isExpanded ? Colors.blue.withOpacity(0.08) : null,
                                        border: const Border(bottom: BorderSide(color: Colors.black12)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isExpanded ? Icons.expand_less : Icons.expand_more,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 4),
                                          const Icon(Icons.playlist_play, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(playlist.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                                Text(
                                                  '${playlist.listSongIds.length} písní',
                                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.download, size: 20),
                                            tooltip: 'Načíst do prezentace',
                                            onPressed: () {
                                              context.read<PresentationPlaylistBloc>().add(
                                                    LoadPresentationPlaylist(playlist: playlist),
                                                  );
                                              Navigator.pop(dialogContext);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Playlist "${playlist.name}" načten'),
                                                  backgroundColor: Colors.green,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                            tooltip: 'Smazat playlist',
                                            onPressed: () {
                                              playlistsBloc.add(DeletePlaylist(playlist: playlist));
                                              if (isExpanded) {
                                                setDialogState(() {
                                                  expandedIndex = null;
                                                });
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  // Expanded song list
                                  if (isExpanded)
                                    Container(
                                      constraints: const BoxConstraints(maxHeight: 250),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.withOpacity(0.05),
                                        border: const Border(bottom: BorderSide(color: Colors.black12)),
                                      ),
                                      child: songs.isEmpty
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: Text('Žádné písně', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                            )
                                          : ReorderableListView.builder(
                                              shrinkWrap: true,
                                              itemCount: songs.length,
                                              onReorder: (oldIdx, newIdx) {
                                                if (newIdx > oldIdx) newIdx--;
                                                final ids = List<String>.from(playlist.listSongIds);
                                                final movedId = ids.removeAt(oldIdx);
                                                ids.insert(newIdx, movedId);
                                                // Update the playlist in Firebase
                                                final updatedPlaylist = Playlist(
                                                  id: playlist.id,
                                                  name: playlist.name,
                                                );
                                                updatedPlaylist.listSongIds = ids;
                                                playlistsBloc.add(UpdatePlaylistDirect(playlist: updatedPlaylist));
                                                setDialogState(() {});
                                              },
                                              itemBuilder: (context, songIndex) {
                                                final song = songs[songIndex];
                                                return ListTile(
                                                  key: ValueKey('${playlist.id}_${song.id}_$songIndex'),
                                                  dense: true,
                                                  leading: Text(
                                                    '${songIndex + 1}.',
                                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                                  ),
                                                  title: Text(song.title, style: const TextStyle(fontSize: 13)),
                                                  subtitle: song.interpret != null && song.interpret!.isNotEmpty
                                                      ? Text(song.interpret!, style: const TextStyle(fontSize: 11, color: Colors.grey))
                                                      : null,
                                                  trailing: IconButton(
                                                    icon: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                                    tooltip: 'Odebrat z playlistu',
                                                    onPressed: () {
                                                      final ids = List<String>.from(playlist.listSongIds);
                                                      ids.removeAt(songIndex);
                                                      final updatedPlaylist = Playlist(
                                                        id: playlist.id,
                                                        name: playlist.name,
                                                      );
                                                      updatedPlaylist.listSongIds = ids;
                                                      playlistsBloc.add(UpdatePlaylistDirect(playlist: updatedPlaylist));
                                                      setDialogState(() {});
                                                    },
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                ],
                              );
                            },
                          ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Zavřít'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddSongsDialog(BuildContext context) {
    final homePageBloc = context.read<HomePageBloc>();
    final allSongs = homePageBloc.state.listSong;
    final TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filter = searchController.text.toLowerCase();
            final filteredSongs =
                filter.isEmpty ? allSongs : allSongs.where((s) => s.title.toLowerCase().contains(filter) || (s.interpret?.toLowerCase().contains(filter) ?? false)).toList();

            return AlertDialog(
              title: const Text('Přidat písně do prezentačního playlistu'),
              content: SizedBox(
                width: 400,
                height: 500,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Hledat...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredSongs.length,
                        itemBuilder: (context, index) {
                          final song = filteredSongs[index];
                          return ListTile(
                            dense: true,
                            title: Text(song.title, style: const TextStyle(fontSize: 13)),
                            subtitle: song.interpret != null && song.interpret!.isNotEmpty ? Text(song.interpret!, style: const TextStyle(fontSize: 11)) : null,
                            trailing: IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              onPressed: () {
                                context.read<PresentationPlaylistBloc>().add(
                                      AddSongToPresentation(song: song),
                                    );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${song.title} přidána'),
                                    duration: const Duration(milliseconds: 800),
                                  ),
                                );
                              },
                            ),
                            onTap: () {
                              context.read<PresentationPlaylistBloc>().add(
                                    AddSongToPresentation(song: song),
                                  );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Zavřít'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

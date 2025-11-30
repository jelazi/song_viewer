import 'dart:io';

import 'package:default_project/services/constants.dart';
import 'package:default_project/services/presentation_window_manager.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/dialogs_export.dart';
import 'package:default_project/view/mobile_view/widgets/dialogs/question_dialog.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../blocs/export_blocs.dart';
import '../../../model/song/song.dart';
import 'my_toast.dart';
import 'ribbon_button.dart';

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
        } else if (state.bodyName == 'preview') {
          _tabController = TabController(length: 2, vsync: this);
        } else if (state.bodyName == 'web') {
          _tabController = TabController(length: 1, vsync: this);
        } else if (state.bodyName == 'groups') {
          _tabController = TabController(length: 2, vsync: this);
        } else if (state.bodyName == 'users') {
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
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    SizedBox(
                      height: 30,
                      child: state.bodyName == 'preview'
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
                                      ],
                                    )
                                  : state.bodyName == 'groups'
                                      ? TabBar(
                                          isScrollable: true,
                                          tabAlignment: TabAlignment.start,
                                          controller: _tabController,
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
                      child: state.bodyName == 'preview'
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
                                          ],
                                        )
                                      : state.bodyName == 'users'
                                          ? TabBarView(
                                              controller: _tabController,
                                              children: [
                                                Container(),
                                                Container(),
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
              _getTopButton('preview', Icons.preview),
              _getTopButton('edit', Icons.edit),
              _getTopButton('web', Icons.web),
              _getTopButton('groups', Icons.folder_shared),
              _getTopButton('users', Icons.people),
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
                  color: Colors.black,
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
                  color: Colors.black,
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
                  color: Colors.black,
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
                      color: Colors.black,
                    ),
                    Icon(
                      Icons.music_note,
                      size: 18,
                      color: Colors.black,
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
                      color: Colors.black,
                    ),
                    Icon(
                      Icons.music_note,
                      size: 18,
                      color: Colors.black,
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
                ? state.bodyName == 'preview'
                    ? Row(
                        children: [
                          BlocBuilder<PreviewChordBloc, PreviewChordState>(
                            builder: (context, state) {
                              return RibbonButton(
                                  text: 'zoomIn'.tr(),
                                  icon: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.black,
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
                                    color: Colors.black,
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
                                        color: Colors.black,
                                      ),
                                      Icon(
                                        Icons.music_note,
                                        size: 18,
                                        color: Colors.black,
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
                                        color: Colors.black,
                                      ),
                                      Icon(
                                        Icons.music_note,
                                        size: 18,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                  onPressed: () {
                                    context.read<PreviewChordBloc>().add(const TransposeChord(increment: -1));
                                  });
                            },
                          ),
                          BlocBuilder<PreviewChordBloc, PreviewChordState>(
                            builder: (context, state) {
                              return RibbonButton(
                                  text: 'present'.tr(),
                                  isEnabled: true, // Always enabled
                                  icon: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.present_to_all,
                                        size: 18,
                                        color: Colors.black,
                                      ),
                                    ],
                                  ),
                                  onPressed: () async {
                                    // Open with current song or empty song
                                    final song = state.data.song ?? Song.empty();
                                    await PresentationWindowManager().openPresentationWindow(context, song);
                                  });
                            },
                          ),
                        ],
                      )
                    : state.bodyName == 'edit'
                        ? Row(
                            children: [
                              getNewSongButton(context),
                              RibbonButton(
                                  text: 'lyrics'.tr(),
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.black,
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
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    context.read<DesktopRibbonMenuBloc>().add(const ChangeEditBody(bodyName: 'chords'));
                                  },
                                  isEnabled: true,
                                  isSelected: state.bodyEditName == 'chords'),
                              RibbonButton(
                                  text: 'note'.tr(),
                                  icon: const Icon(
                                    Icons.music_note,
                                    color: Colors.black,
                                  ),
                                  onPressed: () {
                                    context.read<DesktopRibbonMenuBloc>().add(const ChangeEditBody(bodyName: 'note'));
                                  },
                                  isEnabled: true,
                                  isSelected: state.bodyEditName == 'note'),
                              RibbonButton(
                                  text: 'otherSettings'.tr(),
                                  icon: const Icon(
                                    Icons.settings,
                                    color: Colors.black,
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
                                    color: Colors.black,
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
                      BlocBuilder<PreviewChordBloc, PreviewChordState>(
                        builder: (context, state) {
                          return RibbonButton(
                              text: 'present'.tr(),
                              isEnabled: true, // Always enabled
                              icon: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.present_to_all,
                                    size: 18,
                                    color: Colors.black,
                                  ),
                                ],
                              ),
                              onPressed: () async {
                                // Open with current song or empty song
                                final song = state.data.song ?? Song.empty();
                                await PresentationWindowManager().openPresentationWindow(context, song);
                              });
                        },
                      ),
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
        color: Colors.black,
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
}

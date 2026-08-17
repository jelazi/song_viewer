import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/services/constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../model/song/song_item.dart';

// ignore: must_be_immutable
class EditSpanTablet extends StatefulWidget {
  final String char;
  final TextStyle style;
  final int index;
  final TypeSongItem typeSongItem;
  OverlayEntry overlayEntry;

  EditSpanTablet(this.index, this.char, this.typeSongItem, this.style, this.overlayEntry, {Key? key}) : super(key: key);

  @override
  State<EditSpanTablet> createState() => _EditSpanTabletState();
}

class _EditSpanTabletState extends State<EditSpanTablet> {
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.typeSongItem == TypeSongItem.chord ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: BlocBuilder<EditSongBloc, EditSongState>(
        builder: (context, state) {
          return Row(
            children: [
              Visibility(
                  visible: state.selectedChord == widget.index,
                  child: GestureDetector(
                    onSecondaryTap: () {
                      if (widget.typeSongItem == TypeSongItem.chord) {}
                    },
                    onTap: () {
                      if (widget.typeSongItem == TypeSongItem.chord) {
                        context.read<EditSongBloc>().add(ChangePositionChord(index: widget.index, increase: false));
                      }
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black),
                      ),
                      width: 40,
                      height: 40,
                      child: Center(
                        child: Text(
                          '<',
                          style: widget.style,
                        ),
                      ),
                    ),
                  )),
              GestureDetector(
                /// right click
                onSecondaryTap: () {
                  if (widget.typeSongItem == TypeSongItem.chord) {
                    // create menu for right click on position mouse
                  }
                },
                onTap: () {
                  if (widget.typeSongItem == TypeSongItem.chord) {
                    context.read<EditSongBloc>().add(SelectChord(index: widget.index));
                  }
                },

                onLongPressStart: (value) {
                  if (widget.typeSongItem == TypeSongItem.chord) {
                    _showChordMenu(context, value.globalPosition, widget.index);
                  } else {
                    _showLyricMenu(context, value.globalPosition, widget.index);
                  }
                },
                child: RichText(
                    text: TextSpan(
                  text: widget.char,
                  style: widget.style,
                )),
              ),
              Visibility(
                visible: state.selectedChord == widget.index,
                child: GestureDetector(
                  onSecondaryTap: () {
                    if (widget.typeSongItem == TypeSongItem.chord) {}
                  },
                  onTap: () {
                    if (widget.typeSongItem == TypeSongItem.chord) {
                      context.read<EditSongBloc>().add(ChangePositionChord(index: widget.index, increase: true));
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black),
                    ),
                    width: 40,
                    height: 40,
                    child: Center(
                      child: Text(
                        '>',
                        style: widget.style,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool isOpen = false;

  void _showChordMenu(BuildContext context, Offset position, int index) {
    // ignore: unused_local_variable
    double dx = position.dx;
    // ignore: unused_local_variable
    double dy = position.dy;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
            value: "changeChord",
            height: 35,
            child: BlocBuilder<EditSongBloc, EditSongState>(
              builder: (context, state) {
                return PopupMenuButton(
                  tooltip: '',
                  offset: const Offset(100, 0),
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry>[
                      CustomPopupMenuItem(
                        color: AppColor.primaryLightestColor,
                        height: 35,
                        child: Listener(
                            onPointerMove: (event) {
                              dx = event.position.dx;
                              dy = event.position.dy;
                            },
                            child: Text('newChord'.tr())),
                        onTap: () {
                          _createNewChord(context, position, index, false);
                          Navigator.pop(context, 'changeChord');
                        },
                      ),
                      _changeAllSameChordsItem(height: 40, fontSize: 14, iconSize: 22),
                      const PopupMenuDivider(height: 1),
                      ...state.listUniqueChords
                          .map((e) => PopupMenuItem(
                                height: 35,
                                child: Text(e),
                                onTap: () {
                                  context.read<EditSongBloc>().add(ChangeChord(index: index, chord: e));
                                  Navigator.pop(context, 'changeChord');
                                },
                              ))
                          .toList()
                    ];
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('changeChord'.tr()),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                );
              },
            )),
        PopupMenuItem(
          height: 30,
          child: Text('deleteChord'.tr()),
          onTap: () {
            context.read<EditSongBloc>().add(DeleteChord(index: index));
          },
        ),
      ],
    );
  }

  /// Checkable menu item: when enabled, picking a chord rewrites every
  /// occurrence of the edited chord in the whole song. Tapping it toggles the
  /// flag without closing the menu.
  PopupMenuEntry _changeAllSameChordsItem({required double height, required double fontSize, required double iconSize}) {
    return CustomPopupMenuItem(
      height: height,
      child: BlocBuilder<EditSongBloc, EditSongState>(
        builder: (context, state) {
          return InkWell(
            onTap: () {
              context.read<EditSongBloc>().add(SetChangeAllSameChords(value: !state.changeAllSameChords));
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  state.changeAllSameChords ? Icons.check_box : Icons.check_box_outline_blank,
                  size: iconSize,
                  color: Colors.black,
                ),
                const SizedBox(width: 8),
                Text('changeAllSameChords'.tr(), style: TextStyle(fontSize: fontSize, color: Colors.black)),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLyricMenu(BuildContext context, Offset position, int index) {
    double dx = position.dx;
    double dy = position.dy;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
            value: "createChord",
            height: 20,
            child: BlocBuilder<EditSongBloc, EditSongState>(
              builder: (context, state) {
                return PopupMenuButton(
                  tooltip: '',
                  offset: const Offset(100, 0),
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuEntry>[
                      CustomPopupMenuItem(
                        color: AppColor.primaryLightestColor,
                        height: 35,
                        child: Listener(
                            onPointerMove: (event) {
                              dx = event.position.dx;
                              dy = event.position.dy;
                            },
                            child: Text('newChord'.tr())),
                        onTap: () {
                          _createNewChord(context, Offset(dx, dy), index, true);
                          Navigator.pop(context, 'createChord');
                        },
                      ),
                      ...state.listUniqueChords
                          .map((e) => PopupMenuItem(
                                height: 35,
                                child: Text(e),
                                onTap: () {
                                  context.read<EditSongBloc>().add(CreateChord(index: index, chord: e));
                                  Navigator.pop(context, 'createChord');
                                },
                              ))
                          .toList()
                    ];
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('createChord'.tr()),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                );
              },
            )),
      ],
    );
  }

  void _createNewChord(BuildContext context, Offset position, int index, bool isNew) {
    TextEditingController controller = TextEditingController();
    OverlayState overlayState = Overlay.of(context);
    final EditSongBloc bloc = context.read<EditSongBloc>();
    OverlayEntry? entry;

    /// The overlay must be removed exactly once — a key press delivers both a
    /// down and an up event, and the confirm button can be tapped as well.
    void removeOverlay() {
      final currentEntry = entry;
      entry = null;
      currentEntry?.remove();
    }

    void submit() {
      if (entry == null || controller.text.isEmpty) {
        return;
      }
      if (isNew) {
        bloc.add(CreateChord(index: index, chord: controller.text));
      } else {
        bloc.add(ChangeChord(index: index, chord: controller.text));
      }
      removeOverlay();
    }

    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          /// Tapping anywhere outside the input cancels it.
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: removeOverlay,
            ),
          ),
          Positioned(
            top: position.dy,
            left: position.dx,
            child: Material(
              color: Colors.white,
              elevation: 4,
              child: KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is! KeyDownEvent) {
                    return;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                    submit();
                  }
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    removeOverlay();
                  }
                },
                child: SizedBox(
                  width: 330,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 50,
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                focusNode: FocusNode(),
                                controller: controller,
                                textInputAction: TextInputAction.done,
                                autofocus: true,
                                style: const TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  labelText: 'inputNewChord'.tr(),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'ok'.tr(),
                              icon: const Icon(Icons.check, size: 22, color: Colors.black),
                              onPressed: submit,
                            ),
                            IconButton(
                              tooltip: 'cancel'.tr(),
                              icon: const Icon(Icons.close, size: 22, color: Colors.black),
                              onPressed: removeOverlay,
                            ),
                          ],
                        ),
                      ),
                      if (!isNew)
                        BlocBuilder<EditSongBloc, EditSongState>(
                          bloc: bloc,
                          builder: (context, state) {
                            return InkWell(
                              onTap: () => bloc.add(SetChangeAllSameChords(value: !state.changeAllSameChords)),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      state.changeAllSameChords ? Icons.check_box : Icons.check_box_outline_blank,
                                      size: 22,
                                      color: Colors.black,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(child: Text('changeAllSameChords'.tr(), style: const TextStyle(fontSize: 14, color: Colors.black))),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    widget.overlayEntry = entry!;
    overlayState.insert(entry!);
  }
}

class CustomPopupMenuItem<T> extends PopupMenuItem<T> {
  const CustomPopupMenuItem({
    super.key,
    super.value,
    super.onTap,
    super.height,
    super.enabled,
    super.child,
    this.color,
  });
  final Color? color;

  @override
  CustomPopupMenuItemState<T> createState() => CustomPopupMenuItemState<T>();
}

class CustomPopupMenuItemState<T> extends PopupMenuItemState<T, CustomPopupMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.color,
      child: super.build(context),
    );
  }
}

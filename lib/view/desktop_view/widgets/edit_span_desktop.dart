import 'package:default_project/blocs/export_blocs.dart';
import 'package:default_project/services/constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../../../model/song/song_item.dart';

// ignore: must_be_immutable
class EditSpanDesktop extends StatefulWidget {
  final String char;
  final TextStyle style;
  final int index;
  final TypeSongItem typeSongItem;
  OverlayEntry overlayEntry;

  EditSpanDesktop(this.index, this.char, this.typeSongItem, this.style, this.overlayEntry, {Key? key}) : super(key: key);

  @override
  State<EditSpanDesktop> createState() => _EditSpanDesktopState();
}

class _EditSpanDesktopState extends State<EditSpanDesktop> {
  Offset? lastPosition;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: widget.typeSongItem == TypeSongItem.chord ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: BlocBuilder<EditSongBloc, EditSongState>(
        builder: (context, state) {
          return Listener(
            onPointerDown: (details) {
              if (details.kind == PointerDeviceKind.mouse && details.buttons == kSecondaryMouseButton) {
                if (widget.typeSongItem == TypeSongItem.chord) {
                  _showChordMenu(context, details.position, widget.index);
                } else {
                  _showLyricMenu(context, details.position, widget.index);
                }
              }
            },
            child: Row(
              children: [
                Visibility(
                    visible: state.listSelectedChords.contains(widget.index),
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
                        width: 30,
                        height: 30,
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
                  child: RichText(
                      text: TextSpan(
                    text: widget.char,
                    style: widget.style,
                  )),
                ),
                Visibility(
                  visible: state.listSelectedChords.contains(widget.index),
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
                      width: 30,
                      height: 30,
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
            ),
          );
        },
      ),
    );
  }

  bool isOpen = false;

  void _showChordMenu(BuildContext context, Offset position, int index) {
    double dx = position.dx;
    double dy = position.dy;
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(position.dx, position.dy, position.dx, position.dy),
      items: [
        PopupMenuItem(
            value: "changeChord",
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
                        height: 25,
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
                      ...state.listUniqueChords
                          .map((e) => PopupMenuItem(
                                height: 25,
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
                        height: 25,
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
                                height: 25,
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
    widget.overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy,
        left: position.dx,
        child: Material(
          child: SizedBox(
            width: 200,
            height: 50,
            child: RawKeyboardListener(
              focusNode: FocusNode(),
              onKey: (event) {
                if (event.logicalKey == LogicalKeyboardKey.enter || event.logicalKey == LogicalKeyboardKey.numpadEnter) {
                  if (controller.text.isEmpty) {
                    return;
                  }
                  if (isNew) {
                    context.read<EditSongBloc>().add(CreateChord(index: index, chord: controller.text));
                  } else {
                    context.read<EditSongBloc>().add(ChangeChord(index: index, chord: controller.text));
                  }
                  _removeOverlay();
                }
                if (event.logicalKey == LogicalKeyboardKey.escape) {
                  _removeOverlay();
                }
              },
              child: TextField(
                focusNode: FocusNode(),
                controller: controller,
                textInputAction: TextInputAction.done,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'inputNewChord'.tr(),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(widget.overlayEntry);
  }

  void _removeOverlay() {
    widget.overlayEntry.remove();
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

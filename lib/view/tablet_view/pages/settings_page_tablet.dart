import 'dart:convert';

import 'package:default_project/view/mobile_view/widgets/settings_ui/settings_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:numberpicker/numberpicker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../blocs/export_blocs.dart';
import '../../mobile_view/widgets/dialogs/edit_dialog.dart';
import '../../mobile_view/widgets/settings_ui/settings_section.dart';
import '../../mobile_view/widgets/settings_ui/settings_tile.dart';

class SettingsPageTablet extends StatefulWidget {
  const SettingsPageTablet({super.key});

  @override
  State<SettingsPageTablet> createState() => _SettingsPageTabletState();
}

class _SettingsPageTabletState extends State<SettingsPageTablet> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('settings'.tr()),
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return SettingsList(
              sections: [
                SettingsSection(
                  title: 'general'.tr(),
                  tiles: [
                    SettingsTile(
                      title: 'previewFontTextSize'.tr(),
                      onPressed: (BuildContext context) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return getTextFontDialog(
                                  title: 'previewFontTextSize'.tr(),
                                  context: context,
                                  minValue: 10,
                                  maxValue: 40,
                                  value: state.previewFontTextSize.toInt(),
                                  nameValue: 'previewFontTextSize',
                                  isChord: false);
                            });
                      },
                      iconData: Icons.font_download,
                      value: state.previewFontTextSize,
                    ),
                    SettingsTile(
                      title: 'previewFontChordSize'.tr(),
                      onPressed: (BuildContext context) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return getTextFontDialog(
                                  title: 'previewFontChordSize'.tr(),
                                  context: context,
                                  minValue: 10,
                                  maxValue: 40,
                                  value: state.previewFontChordSize.toInt(),
                                  nameValue: 'previewFontChordSize',
                                  isChord: true);
                            });
                      },
                      iconData: Icons.font_download,
                      value: state.previewFontChordSize,
                    ),
                    SettingsTile(
                      title: 'editFontTextSize'.tr(),
                      onPressed: (BuildContext context) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return getTextFontDialog(
                                  title: 'editFontTextSize'.tr(),
                                  context: context,
                                  minValue: 10,
                                  maxValue: 40,
                                  value: state.editFontTextSize.toInt(),
                                  nameValue: 'editFontTextSize',
                                  isChord: false);
                            });
                      },
                      iconData: Icons.font_download,
                      value: state.editFontTextSize,
                    ),
                    SettingsTile(
                      title: 'editFontChordSize'.tr(),
                      onPressed: (BuildContext context) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return getTextFontDialog(
                                  title: 'editFontChordSize'.tr(),
                                  context: context,
                                  minValue: 10,
                                  maxValue: 40,
                                  value: state.editFontChordSize.toInt(),
                                  nameValue: 'editFontChordSize',
                                  isChord: true);
                            });
                      },
                      iconData: Icons.font_download,
                      value: state.editFontChordSize,
                    ),
                    SettingsTile(
                      title: 'previewColorText'.tr(),
                      onPressed: (BuildContext context) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return getColorFont(
                                title: 'previewColorText'.tr(),
                                context: context,
                                value: state.previewColorText,
                                nameValue: 'previewColorText',
                                isChord: false,
                              );
                            });
                      },
                      iconData: Icons.color_lens,
                      value: state.previewColorText,
                      iconColor: state.previewColorText,
                    ),
                    SettingsTile(
                      title: 'previewColorChord'.tr(),
                      onPressed: (BuildContext context) {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return getColorFont(
                                title: 'previewColorChord'.tr(),
                                context: context,
                                value: state.previewColorChord,
                                nameValue: 'previewColorChord',
                                isChord: false,
                              );
                            });
                      },
                      iconData: Icons.color_lens,
                      value: state.previewColorChord,
                      iconColor: state.previewColorChord,
                    ),
                    SettingsTile(
                      title: 'editColorText'.tr(),
                      onPressed: (BuildContext context) {
                        Navigator.of(context).pushNamed('/language');
                      },
                      iconData: Icons.color_lens,
                      value: state.editColorText,
                      iconColor: state.editColorText,
                    ),
                    SettingsTile(
                      title: 'editColorChord'.tr(),
                      onPressed: (BuildContext context) {
                        Navigator.of(context).pushNamed('/language');
                      },
                      iconData: Icons.color_lens,
                      value: state.editColorChord,
                      iconColor: state.editColorChord,
                    ),
                    SettingsTile.switched(
                      title: 'editIconVisibility'.tr(),
                      onPressed: (conte, value) {
                        context.read<SettingsBloc>().add(ChangeSettingsValue('isEditIconVisible', value));
                        context.read<HomePageBloc>().add(const UpdateSettingsData());
                      },
                      iconData: Icons.visibility,
                      switchValue: state.isEditIconVisible,
                    ),
                  ],
                ),
                SettingsSection(
                  title: 'functions'.tr(),
                  tiles: [
                    SettingsTile(
                      title: 'importData'.tr(),
                      onPressed: (BuildContext context) {},
                      iconData: Icons.import_export,
                      value: '',
                    ),
                    SettingsTile(
                      title: 'exportData'.tr(),
                      onPressed: (BuildContext context) async {
                        final songs = context.read<SettingsBloc>().songsRepository.songs;
                        final json = songs.map((e) => e.toJson()).toList();
                        _onShareTextAsXFile(context, jsonEncode(json), 'songs.json');
                      },
                      iconData: Icons.save_as,
                      value: '',
                    ),
                  ],
                ),
              ],
            );
          },
        ));
  }

  void _onShareTextAsXFile(BuildContext context, String text, String fileName) async {
    final box = context.findRenderObject() as RenderBox?;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final data = utf8.encode(text);
    final shareResult = await Share.shareXFiles(
      [
        XFile.fromData(
          data,
          // name: fileName, // Notice, how setting the name here does not work.
          mimeType: 'text/plain',
        ),
      ],
      sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      fileNameOverrides: [fileName],
    );

    scaffoldMessenger.showSnackBar(getResultSnackBar(shareResult));
  }

  SnackBar getResultSnackBar(ShareResult result) {
    return SnackBar(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text("Share result: ${result.status}"), if (result.status == ShareResultStatus.success) Text("Shared to: ${result.raw}")],
      ),
    );
  }

  Widget getColorFont({
    required String title,
    required BuildContext context,
    required Color value,
    required String nameValue,
    required bool isChord,
  }) {
    Color currentValue = value;
    return StatefulBuilder(builder: (context, setState) {
      return EditDialog(
        height: MediaQuery.of(context).size.height,
        width: 800,
        title: title,
        okClick: () {
          context.read<SettingsBloc>().add(ChangeSettingsValue(nameValue, currentValue));
        },
        widgetContent: SingleChildScrollView(
          child: ColorPicker(
              pickerColor: currentValue,
              onColorChanged: (color) {
                setState(
                  (() => currentValue = color),
                );
              }),
        ),
      );
    });
  }

  Widget getTextFontDialog({
    required String title,
    required BuildContext context,
    required int minValue,
    required int maxValue,
    required int value,
    required String nameValue,
    required bool isChord,
  }) {
    int currentValue = value;
    if (currentValue < minValue) {
      currentValue = minValue;
    }
    if (currentValue > maxValue) {
      currentValue = maxValue;
    }
    return StatefulBuilder(builder: (context, setState) {
      return EditDialog(
        height: 300,
        title: title,
        okClick: () {
          context.read<SettingsBloc>().add(ChangeSettingsValue(nameValue, currentValue.toDouble()));
        },
        widgetContent: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(isChord ? 'Ami' : 'La, la..', style: TextStyle(fontSize: currentValue.toDouble(), fontWeight: FontWeight.bold, color: isChord ? Colors.red : Colors.black)),
            const SizedBox(width: 20),
            NumberPicker(minValue: minValue, maxValue: maxValue, value: currentValue, onChanged: (value) => setState(() => currentValue = value)),
          ],
        ),
      );
    });
  }
}

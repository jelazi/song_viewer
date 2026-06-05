import 'package:default_project/providers/pocketbase_provider.dart';
import 'package:default_project/services/constants.dart';
import 'package:default_project/view/mobile_view/widgets/settings_ui/settings_list.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:numberpicker/numberpicker.dart';

import '../../../blocs/export_blocs.dart';
import '../../../model/qr_link.dart';
import '../widgets/dialogs/edit_dialog.dart';
import '../widgets/settings_ui/settings_section.dart';
import '../widgets/settings_ui/settings_tile.dart';

class SettingsPageMobile extends StatefulWidget {
  const SettingsPageMobile({super.key});

  @override
  State<SettingsPageMobile> createState() => _SettingsPageMobileState();
}

class _SettingsPageMobileState extends State<SettingsPageMobile> {
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
                    SettingsTile.switched(
                      title: 'superuserMode'.tr(),
                      onPressed: (conte, value) {
                        context.read<SettingsBloc>().add(ChangeSettingsValue('superuserMode', value));
                        context.read<HomePageBloc>().add(const UpdateSettingsData());
                      },
                      iconData: Icons.admin_panel_settings,
                      switchValue: state.superuserMode,
                    ),
                    SettingsTile.switched(
                        title: 'autoHideTopBar'.tr(),
                        onPressed: (conte, value) {
                          context.read<SettingsBloc>().add(ChangeSettingsValue('autoHideTopBar', value));
                        },
                        iconData: Icons.hide_source,
                        switchValue: state.autoHideTopBar),
                  ],
                ),
                SettingsSection(
                  title: 'qrCodeTitle'.tr(),
                  tiles: [
                    ...state.qrLinks.asMap().entries.map((entry) {
                      final index = entry.key;
                      final link = entry.value;
                      return SettingsTile(
                        title: link.label.isNotEmpty ? link.label : 'QR ${index + 1}',
                        onPressed: (BuildContext context) {
                          _showEditQrLinkDialog(
                            context: context,
                            index: index,
                            link: link,
                          );
                        },
                        iconData: Icons.qr_code,
                        value: link.url,
                      );
                    }),
                    SettingsTile(
                      title: 'qrAddLink'.tr(),
                      onPressed: (BuildContext context) {
                        _showAddQrLinkDialog(context);
                      },
                      iconData: Icons.add,
                      value: '',
                    ),
                  ],
                ),
                SettingsSection(
                  title: 'pbSettingsTitle'.tr(),
                  tiles: [
                    SettingsTile(
                      title: 'pbUrl'.tr(),
                      onPressed: (BuildContext context) {
                        _showPbSettingsDialog(context);
                      },
                      iconData: Icons.dns,
                      value: context.read<SettingsBloc>().settingsRepository.pocketBaseProvider.config?.pocketbaseUrl ?? '',
                    ),
                    SettingsTile(
                      title: 'pbEmail'.tr(),
                      onPressed: (BuildContext context) {
                        _showPbSettingsDialog(context);
                      },
                      iconData: Icons.email,
                      value: context.read<SettingsBloc>().settingsRepository.pocketBaseProvider.config?.email ?? '',
                    ),
                    SettingsTile(
                      title: 'serverStatus'.tr(),
                      onPressed: (BuildContext context) {
                        _showPbSettingsDialog(context);
                      },
                      iconData: context.read<SettingsBloc>().settingsRepository.pocketBaseProvider.isConnected ? Icons.cloud_done : Icons.cloud_off,
                      value: context.read<SettingsBloc>().settingsRepository.pocketBaseProvider.isConnected ? 'pbConnectionSuccess'.tr() : 'pbConnectionFailed'.tr(),
                      iconColor: context.read<SettingsBloc>().settingsRepository.pocketBaseProvider.isConnected ? AppColor.alertSuccessColor : AppColor.alertErrorColor,
                    ),
                  ],
                ),
              ],
            );
          },
        ));
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

  void _showEditQrLinkDialog({
    required BuildContext context,
    required int index,
    required QrLink link,
  }) {
    final labelController = TextEditingController(text: link.label);
    final urlController = TextEditingController(text: link.url);
    showDialog(
      context: context,
      builder: (ctx) {
        return EditDialog(
          title: link.label.isNotEmpty ? link.label : 'QR ${index + 1}',
          okClick: () {
            context.read<SettingsBloc>().add(
                  UpdateQrLink(index, labelController.text, urlController.text),
                );
          },
          widgetContent: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: 'qrLabelHint'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: 'https://',
                  border: OutlineInputBorder(),
                  labelText: 'URL',
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () {
                    context.read<SettingsBloc>().add(RemoveQrLink(index));
                    Navigator.of(ctx).pop();
                  },
                  icon: const Icon(Icons.delete, color: Colors.red, size: 18),
                  label: Text('qrRemoveLink'.tr(), style: const TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddQrLinkDialog(BuildContext context) {
    final labelController = TextEditingController();
    final urlController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return EditDialog(
          title: 'qrAddLink'.tr(),
          okClick: () {
            if (urlController.text.isNotEmpty) {
              context.read<SettingsBloc>().add(
                    AddQrLink(labelController.text, urlController.text),
                  );
            }
          },
          widgetContent: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: labelController,
                decoration: InputDecoration(
                  labelText: 'qrLabelHint'.tr(),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  hintText: 'https://',
                  border: OutlineInputBorder(),
                  labelText: 'URL',
                ),
                keyboardType: TextInputType.url,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showPbSettingsDialog(BuildContext context) {
    final pbProvider = context.read<SettingsBloc>().settingsRepository.pocketBaseProvider;
    final urlController = TextEditingController(text: pbProvider.config?.pocketbaseUrl ?? '');
    final emailController = TextEditingController(text: pbProvider.config?.email ?? '');
    final passwordController = TextEditingController(text: pbProvider.config?.password ?? '');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text('pbSettingsTitle'.tr()),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: urlController,
                      decoration: InputDecoration(
                        labelText: 'pbUrl'.tr(),
                        hintText: 'http://127.0.0.1:8090',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.dns),
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        labelText: 'pbEmail'.tr(),
                        hintText: 'admin@example.com',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      decoration: InputDecoration(
                        labelText: 'pbPassword'.tr(),
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('cancel'.tr()),
                ),
                TextButton(
                  onPressed: () async {
                    final testConfig = PocketBaseConfig(
                      pocketbaseUrl: urlController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text,
                    );
                    final success = await pbProvider.testConnection(testConfig);
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'pbConnectionSuccess'.tr() : 'pbConnectionFailed'.tr()),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Text('pbTestConnection'.tr()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final newConfig = PocketBaseConfig(
                      pocketbaseUrl: urlController.text.trim(),
                      email: emailController.text.trim(),
                      password: passwordController.text,
                    );
                    final success = await pbProvider.reconnect(newConfig);
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'pbSettingsSaved'.tr() : 'pbConnectionFailed'.tr()),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                      setState(() {}); // Refresh settings page
                    }
                  },
                  child: Text('pbSaveSettings'.tr()),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

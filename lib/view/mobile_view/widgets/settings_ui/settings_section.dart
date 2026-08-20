import 'package:flutter/material.dart';

import 'settings_tile.dart';

// ignore: must_be_immutable
class SettingsSection extends StatelessWidget {
  String? title;
  List<SettingsTile>? tiles;
  Color? sectionBackgroundColor;
  Color? sectionBorderColor;
  Color? sectionTextColor;
  Color? tileIconColor;
  Color? tileTextColor;
  Color? tileBackgroundColor;
  Color? tileBorderColor;
  Color? tileValueColor;
  SettingsSection({
    super.key,
    this.title,
    this.tiles,
    this.tileIconColor,
    this.tileTextColor,
    this.tileValueColor,
    this.tileBackgroundColor,
    this.tileBorderColor,
    this.sectionBackgroundColor,
    this.sectionTextColor,
    this.sectionBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: sectionBackgroundColor ?? Colors.grey[50],
          border: Border.all(color: sectionBorderColor ?? Colors.grey),
          borderRadius: const BorderRadius.all(Radius.circular(3.0)), // Set rounded corner radius
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
                margin: const EdgeInsets.all(8), alignment: Alignment.centerLeft, child: Text(title ?? '', style: TextStyle(color: sectionTextColor ?? Colors.grey, fontSize: 12))),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey),
                borderRadius: const BorderRadius.all(Radius.circular(8.0)), // Set rounded corner radius
              ),
              child: Column(
                children: tiles != null
                    ? tiles!.map((tile) {
                        if (tiles!.first == tile) {
                          return SettingsTile(
                            title: tile.title,
                            iconData: tile.iconData,
                            value: tile.value,
                            iconColor: tile.iconColor ?? tileIconColor,
                            textColor: tile.textColor ?? tileTextColor,
                            valueColor: tile.valueColor ?? tileValueColor,
                            borderColor: tile.borderColor ?? tileBorderColor,
                            backgroundColor: tile.backgroundColor ?? tileBackgroundColor,
                            onPressed: tile.onPressed,
                            isSwitch: tile.isSwitch,
                            switchValue: tile.switchValue,
                            topRadius: true,
                          );
                        }
                        if (tiles!.last == tile) {
                          return SettingsTile(
                            title: tile.title,
                            iconData: tile.iconData,
                            value: tile.value,
                            iconColor: tile.iconColor ?? tileIconColor,
                            textColor: tile.textColor ?? tileTextColor,
                            valueColor: tile.valueColor ?? tileValueColor,
                            borderColor: tile.borderColor ?? tileBorderColor,
                            backgroundColor: tile.backgroundColor ?? tileBackgroundColor,
                            onPressed: tile.onPressed,
                            bottomRadius: true,
                            isSwitch: tile.isSwitch,
                            switchValue: tile.switchValue,
                          );
                        }
                        return SettingsTile(
                          title: tile.title,
                          iconData: tile.iconData,
                          value: tile.value,
                          onPressed: tile.onPressed,
                          iconColor: tile.iconColor ?? tileIconColor,
                          textColor: tile.textColor ?? tileTextColor,
                          valueColor: tile.valueColor ?? tileValueColor,
                          borderColor: tile.borderColor ?? tileBorderColor,
                          backgroundColor: tile.backgroundColor ?? tileBackgroundColor,
                          isSwitch: tile.isSwitch,
                          switchValue: tile.switchValue,
                        );
                      }).toList()
                    : [],
              ),
            ),
          ],
        ));
  }
}

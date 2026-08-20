import 'package:flutter/material.dart';

import 'settings_section.dart';

// ignore: must_be_immutable
class SettingsList extends StatefulWidget {
  List<SettingsSection> sections;
  Color? tileIconColor;
  Color? tileTextColor;
  Color? tileValueColor;
  Color? tileBackgroundColor;
  Color? tileBorderColor;
  Color? sectionBackgroundColor;
  Color? sectionBorderColor;
  Color? sectionTextColor;
  SettingsList({
    super.key,
    required this.sections,
    this.sectionBackgroundColor,
    this.sectionTextColor,
    this.sectionBorderColor,
    this.tileIconColor,
    this.tileTextColor,
    this.tileValueColor,
    this.tileBackgroundColor,
    this.tileBorderColor,
  });

  @override
  State<SettingsList> createState() => _SettingsListState();
}

class _SettingsListState extends State<SettingsList> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: widget.sections
            .map((section) => SettingsSection(
                  title: section.title,
                  tiles: section.tiles,
                  tileIconColor: section.tileIconColor ?? widget.tileIconColor,
                  tileTextColor: section.tileTextColor ?? widget.tileTextColor,
                  tileValueColor:
                      section.tileValueColor ?? widget.tileValueColor,
                  tileBackgroundColor:
                      section.tileBackgroundColor ?? widget.tileBackgroundColor,
                  tileBorderColor:
                      section.tileBorderColor ?? widget.tileBorderColor,
                  sectionTextColor:
                      section.sectionTextColor ?? widget.sectionTextColor,
                  sectionBackgroundColor: section.sectionBackgroundColor ??
                      widget.sectionBackgroundColor,
                  sectionBorderColor:
                      section.sectionBorderColor ?? widget.sectionBorderColor,
                ))
            .toList(),
      ),
    );
  }
}

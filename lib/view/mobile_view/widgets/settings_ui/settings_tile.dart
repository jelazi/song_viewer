import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../services/constants.dart';

// ignore: must_be_immutable
class SettingsTile extends StatefulWidget {
  String title;
  IconData? iconData;
  dynamic value;
  Function onPressed;
  Widget? leading;
  bool topRadius = false;
  bool bottomRadius = false;
  Color? iconColor;
  Color? textColor;
  Color? backgroundColor;
  Color? borderColor;
  Color? valueColor;
  bool isSwitch = false;
  bool? switchValue = false;
  SettingsTile({
    super.key,
    required this.title,
    required this.iconData,
    required this.value,
    required this.onPressed,
    this.topRadius = false,
    this.bottomRadius = false,
    this.leading,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.valueColor,
    this.isSwitch = false,
    this.switchValue,
  });

  SettingsTile.switched({
    super.key,
    required this.title,
    required this.onPressed,
    required this.iconData,
    required this.switchValue,
    this.topRadius = false,
    this.bottomRadius = false,
    this.iconColor,
    this.textColor,
    this.backgroundColor,
    this.borderColor,
    this.isSwitch = true,
  });

  @override
  State<SettingsTile> createState() => _SettingsTileState();
}

class _SettingsTileState extends State<SettingsTile> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.isSwitch ? () {} : () => widget.onPressed(context),
      child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: widget.backgroundColor ?? Colors.white,
              border: Border.all(color: widget.borderColor ?? Colors.grey),
              borderRadius: widget.topRadius
                  ? const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8))
                  : widget.bottomRadius
                      ? const BorderRadius.only(bottomLeft: Radius.circular(8), bottomRight: Radius.circular(8))
                      : BorderRadius.zero),
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.5,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                          width: min(MediaQuery.of(context).size.width * 0.1, 20),
                          child: widget.iconData != null
                              ? Icon(
                                  widget.iconData,
                                  color: widget.iconColor ?? Colors.black,
                                )
                              : Container()),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.01,
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.39,
                        child: Text(widget.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: widget.textColor ?? Colors.black,
                            )),
                      ),
                    ],
                  ),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  width: MediaQuery.of(context).size.width * 0.3,
                  child: widget.isSwitch ? getSwitchValue(context) : getTextValue(context),
                )
              ],
            ),
          )),
    );
  }

  Widget getSwitchValue(BuildContext context) {
    return CupertinoSwitch(
      // thumbColor: myBottomTabBackgroundColor,
      activeTrackColor: AppColor.primaryColor,
      onChanged: (bool value) {
        setState(() {
          //  widget.switchValue = value;
          widget.onPressed(context, value);
        });
      },
      value: widget.switchValue ?? false,
    );
  }

  Widget getTextValue(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          alignment: Alignment.centerRight,
          width: MediaQuery.of(context).size.width * 0.2,
          child: Text(
            widget.value.toString(),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.valueColor ?? Colors.grey,
            ),
          ),
        ),
        Container(
          alignment: Alignment.centerRight,
          width: 15,
          child: Text(
            ' >',
            style: TextStyle(color: widget.valueColor ?? Colors.grey),
          ),
        ),
      ],
    );
  }
}

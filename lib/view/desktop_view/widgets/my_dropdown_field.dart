// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

import '../../../services/constants.dart';

// ignore: must_be_immutable
class MyDropDownField extends StatefulWidget {
  String? label;
  EdgeInsets? margin;
  double? width;
  double? height;
  Color? backgroundColor;
  TextStyle? titleStyle;
  Icon? titleIcon;
  List<String> items;
  Function? listener;
  bool required = false;

  String selectedItem;

  MyDropDownField({
    super.key,
    this.label,
    this.margin,
    this.width,
    this.height,
    this.listener,
    this.backgroundColor,
    this.titleStyle,
    this.titleIcon,
    this.required = false,
    required this.items,
    required this.selectedItem,
  });

  @override
  State<MyDropDownField> createState() => _MyDropDownFieldState();
}

class _MyDropDownFieldState extends State<MyDropDownField> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin ?? const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      width: widget.width ?? MediaQuery.of(context).size.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.label != null ? Text(widget.label ?? '') : Container(),
          Container(
              margin: widget.margin != null ? EdgeInsets.zero : const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              height: widget.height ?? 30,
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Colors.transparent,
                border: Border.all(color: widget.required && (widget.selectedItem == '') ? AppColor.alertWarningColor : AppColor.primaryColor),
                borderRadius: BorderRadius.circular(5),
              ),
              child: DropdownButton(
                underline: Container(),
                items: widget.items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                style: widget.titleStyle ?? pTextStyle.copyWith(fontWeight: FontWeight.w700),
                isExpanded: true,
                icon: widget.titleIcon ?? const Icon(Icons.keyboard_arrow_down),
                value: widget.selectedItem,
                onChanged: (value) {
                  setState(() {
                    widget.selectedItem = value ?? widget.selectedItem;
                    if (widget.listener != null) {
                      widget.listener!(widget.selectedItem);
                    }
                  });
                },
              )),
        ],
      ),
    );
  }
}

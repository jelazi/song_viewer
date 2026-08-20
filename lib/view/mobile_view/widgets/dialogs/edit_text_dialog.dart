import 'package:flutter/material.dart';

import 'edit_dialog.dart';

// ignore: must_be_immutable
class EditTextDialog extends StatefulWidget {
  String title;
  String value;
  Function okClick;
  bool okBack = true;
  late TextEditingController textEditingController;
  EditTextDialog({
    super.key,
    required this.title,
    required this.value,
    required this.okClick,
    this.okBack = true,
  }) {
    textEditingController = TextEditingController(text: value);
  }

  @override
  State<EditTextDialog> createState() => _EditTextDialogState();
}

class _EditTextDialogState extends State<EditTextDialog> {
  @override
  Widget build(BuildContext context) {
    return EditDialog(
        okBack: widget.okBack,
        title: widget.title,
        okClick: () {
          widget.okClick(widget.textEditingController.text);
        },
        widgetContent: TextField(
          controller: widget.textEditingController,
        ));
  }
}

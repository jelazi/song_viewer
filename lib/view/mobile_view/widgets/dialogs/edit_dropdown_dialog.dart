import 'package:flutter/material.dart';

import 'edit_dialog.dart';

// ignore: must_be_immutable
class EditDropdownDialog extends StatefulWidget {
  String title;
  List<String> values;
  String selectedValue;
  Function okClick;
  EditDropdownDialog({
    super.key,
    required this.title,
    required this.values,
    required this.selectedValue,
    required this.okClick,
  });

  @override
  State<EditDropdownDialog> createState() => _EditDropdownDialogState();
}

class _EditDropdownDialogState extends State<EditDropdownDialog> {
  @override
  Widget build(BuildContext context) {
    return EditDialog(
      title: widget.title,
      okClick: () {
        widget.okClick(widget.selectedValue);
      },
      widgetContent: SizedBox(
        width: 200,
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButtonFormField(
            initialValue: widget.selectedValue,
            icon: const Icon(Icons.arrow_back),
            elevation: 16,
            style: const TextStyle(color: Colors.deepPurple),
            onChanged: (String? newValue) {
              widget.selectedValue = newValue ?? '';
            },
            onSaved: (String? newValue) {
              widget.selectedValue = newValue ?? '';
            },
            items: widget.values.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

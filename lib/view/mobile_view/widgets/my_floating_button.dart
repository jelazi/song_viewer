// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class MyFloatingButton extends StatelessWidget {
  final Function onPressed;
  final Widget icon;
  final bool enabled;

  const MyFloatingButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(15),
          ),
          onPressed: enabled ? () => onPressed() : null,
          child: icon),
    );
  }
}

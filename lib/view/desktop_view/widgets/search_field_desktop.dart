import 'package:flutter/material.dart';

class SearchFieldDesktop extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final Function(String) onSubmitted;
  final Function? onClear;

  const SearchFieldDesktop({
    super.key,
    required this.controller,
    required this.labelText,
    required this.onSubmitted,
    this.onClear,
  });

  @override
  State<SearchFieldDesktop> createState() => _SearchFieldDesktopState();
}

class _SearchFieldDesktopState extends State<SearchFieldDesktop> {
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: widget.labelText,
        suffixIcon: widget.controller.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  widget.controller.clear();
                  widget.onClear?.call();
                  setState(() {});
                },
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
      onChanged: (value) {
        setState(() {});
      },
      onSubmitted: widget.onSubmitted,
    );
  }
}
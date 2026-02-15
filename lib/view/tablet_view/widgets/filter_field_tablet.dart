import 'package:default_project/services/constants.dart';
import 'package:flutter/material.dart';

class FilterFieldTablet extends StatefulWidget {
  final TextEditingController filter;
  final Function clearFilter;
  final Function onChanged;
  final Function? onSubmitted;
  final String hintText;

  const FilterFieldTablet({
    super.key,
    required this.filter,
    required this.clearFilter,
    required this.onChanged,
    this.onSubmitted,
    required this.hintText,
  });

  @override
  State<FilterFieldTablet> createState() => _FilterFieldTabletState();
}

class _FilterFieldTabletState extends State<FilterFieldTablet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      width: MediaQuery.of(context).size.width - 20,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColor.grey3Color),
      ),
      child: Center(
        child: TextField(
          controller: widget.filter,
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: widget.filter.text.isNotEmpty
                ? IconButton(
                    onPressed: (() {
                      widget.filter.clear();
                      widget.clearFilter();
                      setState(() {}); // Update UI after clearing
                    }),
                    icon: const Icon(Icons.clear),
                  )
                : null,
          ),
          onChanged: (value) {
            widget.onChanged(value);
            setState(() {}); // Update UI to show/hide clear button
          },
          onSubmitted: widget.onSubmitted != null ? (value) => widget.onSubmitted!(value) : null,
        ),
      ),
    );
  }
}

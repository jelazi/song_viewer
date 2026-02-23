import 'dart:io';

import 'package:default_project/services/constants.dart';
import 'package:flutter/material.dart';

class FilterFieldTablet extends StatefulWidget {
  final TextEditingController filter;
  final Function clearFilter;
  final Function onSearch;
  final String hintText;

  const FilterFieldTablet({
    super.key,
    required this.filter,
    required this.clearFilter,
    required this.onSearch,
    required this.hintText,
  });

  @override
  State<FilterFieldTablet> createState() => _FilterFieldTabletState();
}

class _FilterFieldTabletState extends State<FilterFieldTablet> {
  bool _isFilterActive = false;
  bool get _isDesktop => Platform.isLinux || Platform.isWindows || Platform.isMacOS;

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
        child: ValueListenableBuilder<TextEditingValue>(
          valueListenable: widget.filter,
          builder: (context, value, child) {
            return TextField(
              controller: widget.filter,
              decoration: InputDecoration(
                hintText: widget.hintText,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        widget.onSearch(widget.filter.text);
                        _isFilterActive = widget.filter.text.isNotEmpty;
                      },
                      icon: const Icon(Icons.search),
                    ),
                    if (value.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          widget.filter.clear();
                          widget.clearFilter();
                          _isFilterActive = false;
                        },
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
              ),
              onSubmitted: (value) {
                widget.onSearch(value);
                _isFilterActive = value.isNotEmpty;
              },
              onChanged: (value) {
                if (_isDesktop) {
                  widget.onSearch(value);
                } else if (_isFilterActive) {
                  widget.clearFilter();
                  _isFilterActive = false;
                }
              },
            );
          },
        ),
      ),
    );
  }
}

import 'package:default_project/services/constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class FilterFieldTablet extends StatelessWidget {
  final TextEditingController filter;
  final Function clearFilter;
  final Function onChanged;
  final String hintText;

  const FilterFieldTablet({
    super.key,
    required this.filter,
    required this.clearFilter,
    required this.onChanged,
    required this.hintText,
  });

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
          controller: filter,
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              onPressed: (() {
                filter.clear();
                clearFilter();
              }),
              icon: const Icon(Icons.clear),
            ),
          ),
          onChanged: (value) {
            onChanged(value);
          },
        ),
      ),
    );
  }
}

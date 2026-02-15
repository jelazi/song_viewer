import 'package:default_project/services/constants.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class FilterFieldTablet extends StatelessWidget {
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
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onSubmitted != null ? () => onSubmitted!(filter.text) : null,
                  icon: const Icon(Icons.search),
                ),
                IconButton(
                  onPressed: (() {
                    filter.clear();
                    clearFilter();
                  }),
                  icon: const Icon(Icons.clear),
                ),
              ],
            ),
          ),
          onChanged: (value) {
            onChanged(value);
          },
          onSubmitted: onSubmitted != null ? (value) => onSubmitted!(value) : null,
        ),
      ),
    );
  }
}

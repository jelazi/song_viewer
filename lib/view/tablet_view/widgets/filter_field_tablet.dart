import 'package:default_project/services/constants.dart';
import 'package:flutter/material.dart';

class FilterFieldTablet extends StatelessWidget {
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
          valueListenable: filter,
          builder: (context, value, child) {
            return TextField(
              controller: filter,
              decoration: InputDecoration(
                hintText: hintText,
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        onSearch(filter.text);
                      },
                      icon: const Icon(Icons.search),
                    ),
                    if (value.text.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          filter.clear();
                          clearFilter();
                        },
                        icon: const Icon(Icons.clear),
                      ),
                  ],
                ),
              ),
              onSubmitted: (value) {
                onSearch(value);
              },
            );
          },
        ),
      ),
    );
  }
}

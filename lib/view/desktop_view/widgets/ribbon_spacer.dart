import 'package:flutter/material.dart';

import '../../../services/constants.dart';

/// A vertical spacer/divider for the ribbon menu to separate button groups.
class RibbonSpacer extends StatelessWidget {
  const RibbonSpacer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 60,
      alignment: Alignment.center,
      child: Container(
        width: 1,
        height: 40,
        color: AppColor.grey3Color,
      ),
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';

class PageResponsive extends StatelessWidget {
  final Widget pageMobile;
  final Widget pageTablet;
  final Widget pageDesktop;
  const PageResponsive({super.key, required this.pageMobile, required this.pageTablet, required this.pageDesktop});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return LayoutBuilder(builder: (context, constraints) {
      if ((Platform.isAndroid || Platform.isIOS) && width < 600) {
        return pageMobile;
      } else if (Platform.isAndroid || Platform.isIOS) {
        return pageTablet;
      } else {
        return pageDesktop;
      }
    });
  }
}

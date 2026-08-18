import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../widgets/chordpro_import_view.dart';

/// Phone and tablet page for the ChordPro import, reached from the home drawer.
class ChordProImportPageMobile extends StatelessWidget {
  const ChordProImportPageMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('chordProImport'.tr())),
      body: const SafeArea(child: ChordProImportView(compact: true)),
    );
  }
}

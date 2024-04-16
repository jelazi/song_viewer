import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../../../../blocs/export_blocs.dart';
import 'list_web_song.dart';

class WebBody extends StatefulWidget {
  const WebBody({super.key});

  @override
  State<WebBody> createState() => _WebBodyState();
}

class _WebBodyState extends State<WebBody> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WebBloc, WebState>(
      builder: (context, state) {
        return Row(
          children: [
            const ListWebSong(),
            Expanded(
                child: Column(
              children: [
                Text(state.currentSong?.title ?? ''),
                Text(state.currentInterpret?.name ?? ''),
                Expanded(
                  child: Row(
                    children: [
                      SingleChildScrollView(child: Text(state.currentSong?.lyric ?? '')),
                      SingleChildScrollView(child: Text(state.currentSong?.unformatText ?? '')),
                    ],
                  ),
                ),
              ],
            )),
          ],
        );
      },
    );
  }
}

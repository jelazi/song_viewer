// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:default_project/blocs/export_blocs.dart';
import 'package:flutter/material.dart';

import '../../../model/web_song.dart';
import '../../../services/constants.dart';

class SongCardTabletWeb extends StatefulWidget {
  final WebSong song;
  final int index;

  const SongCardTabletWeb({
    Key? key,
    required this.song,
    required this.index,
  }) : super(key: key);

  @override
  State<SongCardTabletWeb> createState() => _SongCardTabletWebState();
}

class _SongCardTabletWebState extends State<SongCardTabletWeb> with TickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        context.read<PreviewChordBloc>().add(ChangeLyricFromWebSongUpdate(webSong: widget.song, typeSearching: context.read<WebBloc>().state.searchWeb));
        Navigator.pushNamed(context, '/previewPage');
      },
      child: SizedBox(
        height: 80,
        child: Card(
            color: AppColor.whiteColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.0),
              side: const BorderSide(
                color: AppColor.grey3Color,
                width: 1.0,
              ),
            ),
            surfaceTintColor: AppColor.primaryColor,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Text(
                widget.song.title,
                style: h5TextStyle,
                softWrap: true,
              ),
            )),
      ),
    );
  }
}

// ignore_for_file: public_member_api_docs, sort_constructors_first
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
      onTap: () {},
      child: SizedBox(
        height: 60,
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Text(
                          widget.song.title,
                          style: h5TextStyle,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )),
      ),
    );
  }
}

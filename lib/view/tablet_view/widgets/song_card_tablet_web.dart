// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:default_project/blocs/export_blocs.dart';
import 'package:flutter/material.dart';

import '../../../model/web_song.dart';
import '../../../services/constants.dart';

class SongCardTabletWeb extends StatefulWidget {
  final WebSong song;
  final int index;

  const SongCardTabletWeb({
    super.key,
    required this.song,
    required this.index,
  });

  @override
  State<SongCardTabletWeb> createState() => _SongCardTabletWebState();
}

class _SongCardTabletWebState extends State<SongCardTabletWeb> {
  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            context.read<PreviewChordBloc>().add(
              ChangeLyricFromWebSongUpdate(
                webSong: song,
                typeSearching: context.read<WebBloc>().state.searchWeb,
              ),
            );
            Navigator.pushNamed(context, '/previewPage');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColor.grey3Color),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColor.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.music_note, size: 18, color: AppColor.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColor.grey1Color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (song.interpret.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            song.interpret,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColor.grey1Color.withValues(alpha: 0.8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
                if (song.lyric.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColor.alertSuccessLightColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.check, size: 14, color: AppColor.alertSuccessDarkColor),
                  ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, size: 18, color: AppColor.grey1Color.withValues(alpha: 0.5)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

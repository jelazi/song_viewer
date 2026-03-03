import 'package:flutter/material.dart';

import '../../../../../../blocs/export_blocs.dart';
import '../../../../../../services/constants.dart';

/// Narrow read-only lyrics preview shown alongside youtube/sheets/settings edit panels.
class EditLyricsPreviewColumn extends StatelessWidget {
  const EditLyricsPreviewColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EditSongBloc, EditSongState>(
      builder: (context, state) {
        final song = state.currentEditSong;
        final lyrics = song.lyricsWithChords;

        return Container(
          width: 250,
          decoration: const BoxDecoration(
            border: Border(
              right: BorderSide(color: AppColor.grey3Color, width: 1),
            ),
            color: Color(0xFFFAFAFA),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                alignment: Alignment.centerLeft,
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColor.grey3Color, width: 1)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lyrics, size: 16, color: AppColor.grey2Color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        song.title,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColor.grey1Color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Lyrics content
              Expanded(
                child: lyrics.isEmpty
                    ? const Center(
                        child: Text(
                          'Žádný text',
                          style: TextStyle(fontSize: 11, color: AppColor.grey2Color),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(6),
                        child: SelectableText(
                          lyrics,
                          style: const TextStyle(
                            fontSize: 10,
                            height: 1.3,
                            color: AppColor.grey1Color,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logger_pkg/logger_pkg.dart';

import '../../blocs/export_blocs.dart';
import '../../services/chordpro_service.dart';
import '../../services/constants.dart';
import '../../services/enums.dart';

/// Screen for importing ChordPro files, shared by the desktop, tablet and
/// mobile layouts so the three cannot drift apart.
///
/// Picking files is done here because it is platform I/O; everything after the
/// bytes are in memory belongs to [ChordProImportBloc].
class ChordProImportView extends StatelessWidget {
  const ChordProImportView({super.key, this.compact = false});

  /// Tightens the padding for phone-sized screens.
  final bool compact;

  Future<void> _pickFiles(BuildContext context) async {
    final bloc = context.read<ChordProImportBloc>();

    // iOS resolves an extension filter to UTIs, and `.cho`/`.chopro`/`.crd`
    // are not registered types there — filtering on them leaves the picker
    // with nothing selectable. Everywhere else the filter is a real help.
    final canFilterByExtension = defaultTargetPlatform != TargetPlatform.iOS;

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      // `withData` matters on mobile, where the picker may hand back a content
      // URI that has no readable path.
      withData: true,
      type: canFilterByExtension ? FileType.custom : FileType.any,
      allowedExtensions: canFilterByExtension ? ChordProService.supportedExtensions : null,
      dialogTitle: 'chordProPickFiles'.tr(),
    );
    if (result == null || result.files.isEmpty) return;

    final files = <ChordProFile>[];
    for (final file in result.files) {
      final bytes = file.bytes;
      if (bytes == null) {
        logger.w('ChordPro import: no bytes for ${file.name}');
        continue;
      }
      // ChordPro in the wild is not reliably UTF-8, and a single bad byte must
      // not cost the user the whole file.
      files.add(ChordProFile(name: file.name, content: utf8.decode(bytes, allowMalformed: true)));
    }
    if (files.isEmpty) return;

    bloc.add(ParseChordProFiles(files: files));
  }

  @override
  Widget build(BuildContext context) {
    final padding = compact ? 12.0 : 24.0;

    return BlocBuilder<ChordProImportBloc, ChordProImportState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'chordProImportTitle'.tr(),
                style: TextStyle(fontSize: compact ? 18 : 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'chordProImportHint'.tr(),
                style: const TextStyle(fontSize: 13, color: AppColor.grey2Color),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: state.isBusy ? null : () => _pickFiles(context),
                    icon: const Icon(Icons.folder_open),
                    label: Text('chordProPickFiles'.tr()),
                  ),
                  if (state.status != ChordProImportStatus.initial)
                    TextButton.icon(
                      onPressed: state.isBusy ? null : () => context.read<ChordProImportBloc>().add(const ResetChordProImport()),
                      icon: const Icon(Icons.clear),
                      label: Text('chordProClear'.tr()),
                    ),
                  if (state.isBusy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              if (state.sourceNames.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'chordProSourceFiles'.tr(args: [state.sourceNames.join(', ')]),
                  style: const TextStyle(fontSize: 12, color: AppColor.grey2Color),
                ),
              ],
              if (state.status == ChordProImportStatus.error) ...[
                const SizedBox(height: 16),
                _Banner(
                  color: AppColor.alertErrorLightColor,
                  icon: Icons.error_outline,
                  iconColor: AppColor.alertErrorDarkColor,
                  text: (state.errorMessage ?? 'chordProImportFailed').tr(),
                ),
              ],
              if (state.status == ChordProImportStatus.done) ...[
                const SizedBox(height: 16),
                _Banner(
                  color: AppColor.alertSuccessLightColor,
                  icon: Icons.check_circle_outline,
                  iconColor: AppColor.alertSuccessDarkColor,
                  text: 'chordProImported'.tr(args: ['${state.importedCount}']),
                ),
              ],
              if (state.warnings.isNotEmpty) ...[
                const SizedBox(height: 16),
                _WarningsPanel(warnings: state.warnings, skipped: state.skipped),
              ],
              if (state.songs.isNotEmpty) ...[
                const SizedBox(height: 20),
                _SongList(state: state, compact: compact),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: ElevatedButton.icon(
                    onPressed: state.isBusy || state.selectedIds.isEmpty || state.status == ChordProImportStatus.done
                        ? null
                        : () => context.read<ChordProImportBloc>().add(const ConfirmChordProImport()),
                    icon: const Icon(Icons.library_add),
                    label: Text('chordProImportSelected'.tr(args: ['${state.selectedIds.length}'])),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SongList extends StatelessWidget {
  const _SongList({required this.state, required this.compact});

  final ChordProImportState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColor.grey3Color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: [
                Checkbox(
                  value: state.allSelected,
                  tristate: false,
                  onChanged: state.isBusy
                      ? null
                      : (value) => context.read<ChordProImportBloc>().add(SetAllChordProSelected(selected: value ?? false)),
                ),
                Expanded(
                  child: Text(
                    'chordProFoundSongs'.tr(args: ['${state.songs.length}']),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.songs.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final song = state.songs[index];
              final lineCount = song.lyrics.split('\n').where((l) => l.trim().isNotEmpty).length;
              final chordCount = song.getAllUniqueChordsFromSong(TypeLyric.translate).length;

              return CheckboxListTile(
                // The parsed songs already carry generated ids, so the tile
                // keeps its state if the list is rebuilt.
                key: ValueKey(song.id),
                dense: compact,
                value: state.selectedIds.contains(song.id),
                onChanged: state.isBusy ? null : (_) => context.read<ChordProImportBloc>().add(ToggleChordProSelection(songId: song.id)),
                title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(
                  [
                    if ((song.interpret ?? '').isNotEmpty) song.interpret!,
                    'chordProLineCount'.tr(args: ['$lineCount']),
                    'chordProChordCount'.tr(args: ['$chordCount']),
                  ].join(' · '),
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WarningsPanel extends StatelessWidget {
  const _WarningsPanel({required this.warnings, required this.skipped});

  final List<String> warnings;
  final int skipped;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColor.alertWarningLightColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColor.alertWarningDarkColor),
              const SizedBox(width: 8),
              Text(
                'chordProWarningsTitle'.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColor.alertWarningDarkColor),
              ),
            ],
          ),
          if (skipped > 0) ...[
            const SizedBox(height: 6),
            Text('chordProSkipped'.tr(args: ['$skipped']), style: const TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 6),
          ...warnings.map(
            (w) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('• $w', style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.color,
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final Color iconColor;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

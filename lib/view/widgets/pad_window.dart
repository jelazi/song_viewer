import 'dart:io';
import 'dart:math';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../blocs/export_blocs.dart';
import '../../config/features.dart';
import '../../model/pad_set.dart';
import '../../model/song/song.dart';
import '../../services/constants.dart';
import '../../services/song_key_service.dart';

/// Pads need a native audio backend, which `just_audio` has on phones,
/// tablets and macOS; Windows and Linux would need `just_audio_media_kit`.
bool get padsSupported => Features.pads && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

/// The pad offered for [song]: the one saved for it, otherwise the key the
/// song sounds in (shown first chord plus capo).
({int? key, SongPadPreference? saved}) _padSuggestion(Song song, PreviewChordState preview, PadState pads) {
  final saved = pads.songPreferences[song.id];
  if (saved != null) return (key: saved.semitone, saved: saved);
  return (key: SongKeyService.soundingKey(song.lyrics, transposeIncrement: preview.transposeIncrement, capo: preview.cap), saved: null);
}

/// Puts the pad window above every page of the app, so it stays visible in
/// the song list, the playlists and every song until it is closed.
class PadWindowHost extends StatefulWidget {
  final Widget child;

  const PadWindowHost({super.key, required this.child});

  @override
  State<PadWindowHost> createState() => _PadWindowHostState();
}

class _PadWindowHostState extends State<PadWindowHost> {
  // The window sits beside the Navigator, not inside it, so it needs an
  // Overlay of its own for the slider and the ink effects.
  late final OverlayEntry _entry = OverlayEntry(builder: (_) => const _PadWindowLayer());

  @override
  Widget build(BuildContext context) {
    if (!padsSupported) return widget.child;
    return Stack(
      children: [
        widget.child,
        Positioned.fill(child: Overlay(initialEntries: [_entry])),
      ],
    );
  }
}

class _PadWindowLayer extends StatefulWidget {
  const _PadWindowLayer();

  @override
  State<_PadWindowLayer> createState() => _PadWindowLayerState();
}

class _PadWindowLayerState extends State<_PadWindowLayer> {
  static const double _maxWidth = 360;
  static const double _height = 236;
  static const double _barWidth = 210;
  static const double _barHeight = 40;
  static const double _margin = 8;

  Offset? _position;
  Offset? _barPosition;

  Offset _clamp(Offset position, Size window, Size area, EdgeInsets padding) {
    return Offset(
      position.dx.clamp(padding.left, max(padding.left, area.width - window.width - padding.right)),
      position.dy.clamp(padding.top, max(padding.top, area.height - window.height - padding.bottom)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PadBloc, PadState>(
      buildWhen: (previous, current) => previous.isWindowOpen != current.isWindowOpen || previous.isMinimized != current.isMinimized,
      builder: (context, state) {
        if (!state.isWindowOpen) return const SizedBox.shrink();
        if (state.isMinimized) {
          // On a phone the minimized pads live in the app bar (PadOpenButton).
          if (MediaQuery.of(context).size.width < 600) return const SizedBox.shrink();
          return _buildMinimized();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final area = constraints.biggest;
            final padding = MediaQuery.of(context).padding;
            final window = Size(min(_maxWidth, area.width - 2 * _margin), _height);
            final position = _clamp(
              _position ?? Offset(_margin + padding.left, area.height - window.height - _margin - padding.bottom),
              window,
              area,
              padding,
            );
            return Stack(
              children: [
                Positioned(
                  left: position.dx,
                  top: position.dy,
                  width: window.width,
                  height: window.height,
                  child: _PadWindow(
                    onDrag: (delta) => setState(() => _position = _clamp(position + delta, window, area, padding)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMinimized() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final area = constraints.biggest;
        final padding = MediaQuery.of(context).padding;
        const bar = Size(_barWidth, _barHeight);
        final position = _clamp(
          _barPosition ?? Offset(_margin + padding.left, area.height - bar.height - _margin - padding.bottom),
          bar,
          area,
          padding,
        );
        return Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              width: bar.width,
              height: bar.height,
              child: _PadMiniBar(
                onDrag: (delta) => setState(() => _barPosition = _clamp(position + delta, bar, area, padding)),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// The minimized pad window on a tablet: a thin bar with the playing key.
class _PadMiniBar extends StatelessWidget {
  final ValueChanged<Offset> onDrag;

  const _PadMiniBar({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 6,
      color: AppColor.primaryColor,
      shape: const StadiumBorder(),
      clipBehavior: Clip.antiAlias,
      child: BlocBuilder<PadBloc, PadState>(
        builder: (context, state) {
          final playing = state.playingKey;
          final label = playing == null ? 'pads'.tr() : '${SongKeyService.keyNames[playing]} · ${state.selectedSet?.name ?? ''}';
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            dragStartBehavior: DragStartBehavior.down,
            onPanUpdate: (details) => onDrag(details.delta),
            onTap: () => context.read<PadBloc>().add(const RestorePadWindow()),
            child: Row(
              children: [
                const SizedBox(width: 6),
                const Icon(Icons.drag_indicator, color: AppColor.whiteColor, size: 20),
                Icon(Icons.graphic_eq, color: playing != null ? AppColor.alertWarningColor : AppColor.whiteColor, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(label,
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColor.whiteColor, fontWeight: FontWeight.w600)),
                ),
                if (playing != null)
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 20,
                    icon: const Icon(Icons.stop_circle, color: AppColor.whiteColor),
                    onPressed: () => context.read<PadBloc>().add(const StopPad()),
                  ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  icon: const Icon(Icons.open_in_full, color: AppColor.whiteColor),
                  onPressed: () => context.read<PadBloc>().add(const RestorePadWindow()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PadWindow extends StatelessWidget {
  final ValueChanged<Offset> onDrag;

  const _PadWindow({required this.onDrag});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      color: AppColor.whiteColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: BlocBuilder<PadBloc, PadState>(
        builder: (context, state) {
          return Column(
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                dragStartBehavior: DragStartBehavior.down,
                onPanUpdate: (details) => onDrag(details.delta),
                child: _PadHeader(state: state),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Column(
                    children: [
                      SizedBox(height: 30, child: _SongKeyLine(padState: state)),
                      Expanded(child: _PadBody(state: state)),
                      SizedBox(height: 44, child: _PadControls(state: state)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PadHeader extends StatelessWidget {
  final PadState state;

  const _PadHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      color: AppColor.primaryColor,
      child: Row(
        children: [
          const SizedBox(width: 4),
          const Icon(Icons.drag_indicator, color: AppColor.whiteColor),
          const SizedBox(width: 4),
          Text('pads'.tr(), style: const TextStyle(color: AppColor.whiteColor, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final set in state.sets)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: _SetChip(
                        label: set.name,
                        isSelected: set.id == state.selectedSetId,
                        onTap: () => context.read<PadBloc>().add(SelectPadSet(setId: set.id)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove, color: AppColor.whiteColor),
            onPressed: () => context.read<PadBloc>().add(const MinimizePadWindow()),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, color: AppColor.whiteColor),
            onPressed: () => context.read<PadBloc>().add(const ClosePadWindow()),
          ),
        ],
      ),
    );
  }
}

class _SetChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SetChip({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColor.whiteColor : Colors.transparent,
      shape: StadiumBorder(side: BorderSide(color: AppColor.whiteColor.withValues(alpha: 0.8))),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: Text(
            label,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? AppColor.primaryColor : AppColor.whiteColor),
          ),
        ),
      ),
    );
  }
}

/// The open song and the key the app thinks it is in.
class _SongKeyLine extends StatelessWidget {
  final PadState padState;

  const _SongKeyLine({required this.padState});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PreviewChordBloc, PreviewChordState>(
      buildWhen: (previous, current) =>
          previous.data.song != current.data.song || previous.transposeIncrement != current.transposeIncrement || previous.cap != current.cap,
      builder: (context, state) {
        final song = state.data.song;
        if (song == null) return const SizedBox.shrink();
        final suggestion = _padSuggestion(song, state, padState);
        final key = suggestion.key;
        final saved = suggestion.saved;
        final canSave = !state.isDataFromWeb && song.id.isNotEmpty;

        final String text;
        if (key == null) {
          text = '';
        } else if (saved != null) {
          final setName = padState.sets.where((set) => set.id == saved.setId).firstOrNull?.name;
          text = '${'padSavedForSong'.tr()}: ${SongKeyService.keyNames[key]}${setName != null ? ' · $setName' : ''}';
        } else {
          final shown = SongKeyService.displayedKey(song.lyrics, transposeIncrement: state.transposeIncrement);
          final capoHint = state.cap != 0 && shown != null ? ' (${SongKeyService.keyNames[shown]} + cap ${state.cap})' : '';
          text = '${'padSuggestedKey'.tr()}: ${SongKeyService.keyNames[key]}$capoHint';
        }

        return Row(
          children: [
            Expanded(
              child: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: AppColor.grey2Color)),
            ),
            Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColor.alertWarningDarkColor)),
            if (canSave)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                iconSize: 20,
                tooltip: saved != null ? 'padRemoveForSong'.tr() : 'padSaveForSong'.tr(),
                icon: Icon(
                  saved != null ? Icons.bookmark : Icons.bookmark_add_outlined,
                  color: saved != null || padState.playingKey != null ? AppColor.alertWarningColor : AppColor.grey3Color,
                ),
                onPressed: saved != null
                    ? () => context.read<PadBloc>().add(RemoveSongPad(songId: song.id))
                    : padState.playingKey != null
                        ? () => context.read<PadBloc>().add(SaveSongPad(songId: song.id))
                        : null,
              ),
          ],
        );
      },
    );
  }
}

class _PadBody extends StatelessWidget {
  final PadState state;

  const _PadBody({required this.state});

  @override
  Widget build(BuildContext context) {
    switch (state.status) {
      case PadSetsStatus.initial:
      case PadSetsStatus.loading:
        return const Center(child: CircularProgressIndicator());
      case PadSetsStatus.failure:
        return Center(
          child: Text('padNoSets'.tr(), textAlign: TextAlign.center, style: const TextStyle(color: AppColor.grey2Color)),
        );
      case PadSetsStatus.ready:
        return BlocBuilder<PreviewChordBloc, PreviewChordState>(
          buildWhen: (previous, current) =>
              previous.data.song != current.data.song || previous.transposeIncrement != current.transposeIncrement || previous.cap != current.cap,
          builder: (context, previewState) {
            final song = previewState.data.song;
            final suggested = song == null ? null : _padSuggestion(song, previewState, state).key;
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final row in const [
                  [0, 1, 2, 3, 4, 5],
                  [6, 7, 8, 9, 10, 11],
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      children: [
                        for (final semitone in row)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: _KeyButton(
                                key: ValueKey(semitone),
                                label: SongKeyService.keyNames[semitone],
                                isPlaying: state.playingKey == semitone,
                                isLoading: state.loadingKey == semitone,
                                isSuggested: suggested == semitone,
                                isDownloaded: state.downloadedKeys.contains(semitone),
                                onTap: () => context.read<PadBloc>().add(TogglePadKey(semitone: semitone)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            );
          },
        );
    }
  }
}

class _KeyButton extends StatelessWidget {
  final String label;
  final bool isPlaying;
  final bool isLoading;
  final bool isSuggested;
  final bool isDownloaded;
  final VoidCallback onTap;

  const _KeyButton({
    super.key,
    required this.label,
    required this.isPlaying,
    required this.isLoading,
    required this.isSuggested,
    required this.isDownloaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isPlaying ? AppColor.whiteColor : (isDownloaded ? AppColor.grey1Color : AppColor.grey2Color);
    return Material(
      color: isPlaying ? AppColor.primaryColor : AppColor.grey5Color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSuggested ? const BorderSide(color: AppColor.alertWarningColor, width: 2.5) : const BorderSide(color: AppColor.grey3Color),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Center(
            child: isLoading
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
          ),
        ),
      ),
    );
  }
}

class _PadControls extends StatelessWidget {
  final PadState state;

  const _PadControls({required this.state});

  @override
  Widget build(BuildContext context) {
    final set = state.selectedSet;
    final allDownloaded = set != null && set.fileUrls.keys.every(state.downloadedKeys.contains);
    return Row(
      children: [
        IconButton(
          icon: Icon(Icons.stop_circle, color: state.playingKey != null ? AppColor.primaryColor : AppColor.grey3Color, size: 30),
          onPressed: state.playingKey != null ? () => context.read<PadBloc>().add(const StopPad()) : null,
        ),
        const Icon(Icons.volume_down, color: AppColor.grey2Color, size: 20),
        Expanded(
          child: Slider(
            value: state.volume,
            onChanged: (volume) => context.read<PadBloc>().add(ChangePadVolume(volume: volume)),
          ),
        ),
        if (state.setDownloadProgress != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('${state.setDownloadProgress}/${set?.fileUrls.length ?? 12}', style: const TextStyle(fontSize: 12, color: AppColor.grey2Color)),
          )
        else if (set != null)
          IconButton(
            icon: Icon(allDownloaded ? Icons.cloud_done : Icons.cloud_download, color: allDownloaded ? AppColor.alertSuccessDarkColor : AppColor.primaryColor),
            onPressed: allDownloaded ? null : () => context.read<PadBloc>().add(const DownloadPadSet()),
          ),
      ],
    );
  }
}

/// App bar button for the pads: opens the window, then switches it between
/// full size and minimized. Never stops a pad; only the window's close does.
/// Shows the playing key, which is how a phone shows minimized pads.
class PadOpenButton extends StatelessWidget {
  final Color color;

  const PadOpenButton({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PadBloc, PadState>(
      buildWhen: (previous, current) =>
          previous.isWindowOpen != current.isWindowOpen || previous.isMinimized != current.isMinimized || previous.playingKey != current.playingKey,
      builder: (context, state) {
        final playing = state.playingKey;
        return IconButton(
          tooltip: 'pads'.tr(),
          icon: Badge(
            isLabelVisible: playing != null,
            label: Text(playing == null ? '' : SongKeyService.keyNames[playing]),
            backgroundColor: AppColor.alertWarningColor,
            textColor: AppColor.primaryDarkestColor,
            child: Icon(Icons.graphic_eq, color: state.isWindowOpen ? AppColor.alertWarningColor : color),
          ),
          onPressed: () => context.read<PadBloc>().add(const TogglePadWindow()),
        );
      },
    );
  }
}

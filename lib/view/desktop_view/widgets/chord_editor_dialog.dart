import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../model/chord/chord_diagram.dart';
import '../../../model/song/song.dart';
import '../../../services/chord_service.dart';
import 'chord_editor_widget.dart';

/// Dialog for viewing, editing, and creating chord diagrams on desktop.
/// Shows existing positions with navigation, and allows editing/adding new ones.
/// Can save to song-level overrides or to the global default library.
class ChordEditorDialog extends StatefulWidget {
  final String chordName;
  final Song? song;
  final ChordService chordService;
  final Function(Song updatedSong)? onSongUpdated;

  const ChordEditorDialog({
    super.key,
    required this.chordName,
    required this.chordService,
    this.song,
    this.onSongUpdated,
  });

  @override
  State<ChordEditorDialog> createState() => _ChordEditorDialogState();
}

class _ChordEditorDialogState extends State<ChordEditorDialog> {
  late List<String> _positions;
  int _currentIndex = 0;
  bool _isEditing = false;
  bool _isAddingNew = false;
  String _editingPosition = '0 0 0 0 0 0';
  String? _source; // 'song', 'pb', 'hardcoded'

  @override
  void initState() {
    super.initState();
    _loadPositions();
  }

  void _loadPositions() {
    // Determine source and load positions
    final songOverrides = widget.song?.chordOverrides;
    if (songOverrides != null && songOverrides.containsKey(widget.chordName)) {
      final pos = songOverrides[widget.chordName]!;
      if (pos.isNotEmpty) {
        _positions = List.from(pos);
        _source = 'song';
        return;
      }
    }

    final pbPositions = widget.chordService.pbChordCache[widget.chordName];
    if (pbPositions != null && pbPositions.isNotEmpty) {
      _positions = List.from(pbPositions);
      _source = 'pb';
      return;
    }

    final resolved = widget.chordService.resolveChordPositions(widget.chordName, song: widget.song);
    _positions = List.from(resolved);
    _source = resolved.isNotEmpty ? 'hardcoded' : null;
  }

  void _addNewPosition() {
    setState(() {
      _isEditing = true;
      _isAddingNew = true;
      _editingPosition = '0 0 0 0 0 0';
    });
  }

  void _editCurrentPosition() {
    if (_positions.isEmpty) return;
    setState(() {
      _isEditing = true;
      _isAddingNew = false;
      _editingPosition = _positions[_currentIndex];
    });
  }

  void _deleteCurrentPosition() {
    if (_positions.isEmpty) return;
    setState(() {
      _positions.removeAt(_currentIndex);
      if (_currentIndex >= _positions.length && _positions.isNotEmpty) {
        _currentIndex = _positions.length - 1;
      }
      if (_positions.isEmpty) {
        _currentIndex = 0;
      }
    });
  }

  void _saveEditedPosition() {
    setState(() {
      if (_isAddingNew) {
        _positions.add(_editingPosition);
        _currentIndex = _positions.length - 1;
      } else {
        _positions[_currentIndex] = _editingPosition;
      }
      _isEditing = false;
      _isAddingNew = false;
    });
  }

  void _cancelEditing() {
    setState(() {
      _isEditing = false;
      _isAddingNew = false;
    });
  }

  List<String> _positionsForSave() {
    final positionsToSave = List<String>.from(_positions);

    if (_isEditing) {
      if (_isAddingNew) {
        positionsToSave.add(_editingPosition);
      } else if (positionsToSave.isNotEmpty && _currentIndex >= 0 && _currentIndex < positionsToSave.length) {
        positionsToSave[_currentIndex] = _editingPosition;
      }
    }

    return positionsToSave;
  }

  Future<void> _saveToSong() async {
    if (widget.song == null || widget.onSongUpdated == null) return;
    final positionsToSave = _positionsForSave();
    final overrides = Map<String, List<String>>.from(widget.song!.chordOverrides ?? {});
    overrides[widget.chordName] = positionsToSave;
    final updatedSong = widget.song!.copyWith(chordOverrides: overrides);
    widget.onSongUpdated!(updatedSong);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('chordSavedToSong'.tr(args: [widget.chordName]))),
      );
    }
  }

  Future<void> _saveToDefaultLibrary() async {
    final positionsToSave = _positionsForSave();
    final diagram = ChordDiagram(
      name: widget.chordName,
      positions: positionsToSave,
    );
    final success = await widget.chordService.saveChordDiagram(diagram);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'chordSavedToLibrary'.tr(args: [widget.chordName]) : 'chordSaveError'.tr()),
        ),
      );
    }
  }

  Future<void> _removeSongOverride() async {
    if (widget.song == null || widget.onSongUpdated == null) return;
    final overrides = Map<String, List<String>>.from(widget.song!.chordOverrides ?? {});
    overrides.remove(widget.chordName);
    final updatedSong = widget.song!.copyWith(chordOverrides: overrides);
    widget.onSongUpdated!(updatedSong);
    setState(() {
      _loadPositions();
    });
  }

  String _sourceLabel() {
    switch (_source) {
      case 'song':
        return 'sourceSong'.tr();
      case 'pb':
        return 'sourceLibrary'.tr();
      case 'hardcoded':
        return 'sourceDefault'.tr();
      default:
        return 'sourceNone'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.chordName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Chip(label: Text('sourceLabel'.tr(args: [_sourceLabel()]))),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isEditing) ...[
                        // Editor mode
                        Text('clickFretToPlace'.tr(), style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 8),
                        ChordEditorWidget(
                          initialPosition: _editingPosition,
                          onPositionChanged: (pos) {
                            _editingPosition = pos;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: _cancelEditing,
                              icon: const Icon(Icons.cancel),
                              label: Text('cancel'.tr()),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: _saveEditedPosition,
                              icon: const Icon(Icons.check),
                              label: Text('confirmBtn'.tr()),
                            ),
                          ],
                        ),
                      ] else ...[
                        // View mode
                        if (_positions.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text('noDiagramForChord'.tr()),
                          )
                        else ...[
                          // Navigation
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left, color: Colors.black87),
                                onPressed: _positions.length > 1
                                    ? () => setState(() {
                                          _currentIndex = (_currentIndex - 1) % _positions.length;
                                        })
                                    : null,
                              ),
                              Text('${_currentIndex + 1} / ${_positions.length}'),
                              IconButton(
                                icon: const Icon(Icons.chevron_right, color: Colors.black87),
                                onPressed: _positions.length > 1
                                    ? () => setState(() {
                                          _currentIndex = (_currentIndex + 1) % _positions.length;
                                        })
                                    : null,
                              ),
                            ],
                          ),
                          // Current diagram (read-only view via editor but non-interactive display)
                          ChordEditorWidget(
                            key: ValueKey('view_${_positions[_currentIndex]}'),
                            initialPosition: _positions[_currentIndex],
                            onPositionChanged: (pos) {
                              setState(() {
                                _positions[_currentIndex] = pos;
                              });
                            },
                          ),
                        ],
                        const SizedBox(height: 12),
                        // Action buttons
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _addNewPosition,
                              icon: const Icon(Icons.add, size: 18),
                              label: Text('newBtn'.tr()),
                            ),
                            if (_positions.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: _editCurrentPosition,
                                icon: const Icon(Icons.edit, size: 18),
                                label: Text('editBtn'.tr()),
                              ),
                            if (_positions.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: _deleteCurrentPosition,
                                icon: const Icon(Icons.delete, size: 18),
                                label: Text('deleteBtn'.tr()),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 4),
                        // Save buttons
                        if (_positions.isNotEmpty) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.center,
                            children: [
                              if (widget.song != null && widget.onSongUpdated != null)
                                ElevatedButton.icon(
                                  onPressed: _saveToSong,
                                  icon: const Icon(Icons.music_note, size: 18),
                                  label: Text('saveToSong'.tr()),
                                ),
                              ElevatedButton.icon(
                                onPressed: _saveToDefaultLibrary,
                                icon: const Icon(Icons.library_music, size: 18),
                                label: Text('saveToLibrary'.tr()),
                              ),
                            ],
                          ),
                          if (_source == 'song' && widget.onSongUpdated != null) ...[
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: _removeSongOverride,
                              icon: const Icon(Icons.remove_circle_outline, size: 18),
                              label: Text('removeSongOverride'.tr()),
                              style: TextButton.styleFrom(foregroundColor: Colors.orange),
                            ),
                          ],
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

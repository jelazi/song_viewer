import 'package:flutter/material.dart';

/// Interactive guitar chord editor widget for desktop.
/// Shows a 6-string × visibleFrets fretboard that can shift up/down the neck.
/// Supports actual fret values up to [maxFret] (default 15).
/// - Click on a fret/string intersection to place/remove a finger dot
/// - Click on the 0th fret area to toggle: open (o) → muted (x) → open
/// - Use ▲/▼ arrows to shift the visible fret range
/// Produces a position string like "x 0 7 7 6 5".
class ChordEditorWidget extends StatefulWidget {
  /// Initial position string (e.g. "x 0 2 2 1 0"). If null, starts empty (all open).
  final String? initialPosition;

  /// Called whenever the position changes.
  final ValueChanged<String> onPositionChanged;

  /// Number of frets visible at a time.
  final int visibleFrets;

  /// Maximum fret number supported.
  final int maxFret;

  const ChordEditorWidget({
    super.key,
    this.initialPosition,
    required this.onPositionChanged,
    this.visibleFrets = 5,
    this.maxFret = 15,
  });

  @override
  State<ChordEditorWidget> createState() => _ChordEditorWidgetState();
}

class _ChordEditorWidgetState extends State<ChordEditorWidget> {
  static const int stringCount = 6;
  static const List<String> stringLabels = ['E', 'A', 'D', 'G', 'B', 'e'];

  /// Each string's state: null = muted (x), 0 = open, 1-N = fret number (absolute)
  late List<int?> _positions;

  /// The first fret shown in the visible window (1-based).
  late int _startFret;

  @override
  void initState() {
    super.initState();
    _positions = _parsePosition(widget.initialPosition);
    _startFret = _calcStartFret();
  }

  @override
  void didUpdateWidget(covariant ChordEditorWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialPosition != oldWidget.initialPosition) {
      _positions = _parsePosition(widget.initialPosition);
      _startFret = _calcStartFret();
    }
  }

  List<int?> _parsePosition(String? posString) {
    if (posString == null || posString.isEmpty) {
      return List.filled(stringCount, 0);
    }
    final parts = posString.split(' ');
    return List.generate(stringCount, (i) {
      if (i >= parts.length) return 0;
      final p = parts[i].toLowerCase();
      if (p == 'x') return null;
      return int.tryParse(p) ?? 0;
    });
  }

  /// Same algorithm as guitar_tabs.dart renderer:
  /// if maxFret <= visibleFrets → startFret=1, else startFret=minFret.
  int _calcStartFret() {
    int maxF = 0;
    int minF = 1000;
    for (final p in _positions) {
      if (p != null && p > 0) {
        if (p > maxF) maxF = p;
        if (p < minF) minF = p;
      }
    }
    if (maxF <= widget.visibleFrets) return 1;
    // Ensure the window fits all dots
    if (minF + widget.visibleFrets - 1 < maxF) {
      return maxF - widget.visibleFrets + 1;
    }
    return minF;
  }

  String _positionToString() {
    return _positions.map((p) => p == null ? 'x' : p.toString()).join(' ');
  }

  void _onFretTap(int stringIndex, int absoluteFret) {
    setState(() {
      if (absoluteFret == 0) {
        // Cycle: open → muted → open
        if (_positions[stringIndex] == null) {
          _positions[stringIndex] = 0;
        } else if (_positions[stringIndex] == 0) {
          _positions[stringIndex] = null;
        } else {
          _positions[stringIndex] = 0;
        }
      } else {
        if (_positions[stringIndex] == absoluteFret) {
          _positions[stringIndex] = 0;
        } else {
          _positions[stringIndex] = absoluteFret;
        }
      }
    });
    widget.onPositionChanged(_positionToString());
  }

  void _shiftUp() {
    setState(() {
      if (_startFret + widget.visibleFrets - 1 < widget.maxFret) _startFret++;
    });
  }

  void _shiftDown() {
    setState(() {
      if (_startFret > 1) _startFret--;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lineColor = isDark ? Colors.white70 : Colors.black87;
    final dotColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? Colors.grey[850]! : Colors.grey[50]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: lineColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // String labels — offset to align with fretboard (leave room for fret numbers)
          _buildStringLabels(lineColor),
          const SizedBox(height: 4),
          // Open/muted indicators
          _buildOpenMutedRow(dotColor, lineColor),
          const SizedBox(height: 2),
          // Nut or start fret indicator
          _buildNutOrFretIndicator(lineColor),
          // Fretboard with fret numbers + shift buttons
          _buildFretboardRow(lineColor, dotColor),
          const SizedBox(height: 8),
          // Position string display
          Text(
            _positionToString(),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: lineColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStringLabels(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Spacer for fret-number column
        const SizedBox(width: 24),
        ...List.generate(stringCount, (i) {
          return SizedBox(
            width: 36,
            child: Center(
              child: Text(
                stringLabels[i],
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          );
        }),
        // Spacer for shift buttons column
        const SizedBox(width: 32),
      ],
    );
  }

  Widget _buildOpenMutedRow(Color dotColor, Color lineColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 24),
        ...List.generate(stringCount, (i) {
          final pos = _positions[i];
          String label;
          if (pos == null) {
            label = '✕';
          } else if (pos == 0) {
            label = '○';
          } else {
            label = '';
          }
          return SizedBox(
            width: 36,
            height: 24,
            child: InkWell(
              onTap: () => _onFretTap(i, 0),
              borderRadius: BorderRadius.circular(12),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: pos == null ? Colors.red : dotColor,
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 32),
      ],
    );
  }

  Widget _buildNutOrFretIndicator(Color color) {
    final totalWidth = stringCount * 36.0;
    if (_startFret == 1) {
      // Thick nut bar
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 24),
          Container(
            width: totalWidth,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(width: 32),
        ],
      );
    } else {
      // Thin line (no nut) — fret number shown on fretboard rows instead
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 24),
          Container(
            width: totalWidth,
            height: 1,
            color: color.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 32),
        ],
      );
    }
  }

  Widget _buildFretboardRow(Color lineColor, Color dotColor) {
    final fretboardWidth = stringCount * 36.0;
    final fretboardHeight = widget.visibleFrets * 36.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Fret numbers column
        SizedBox(
          width: 24,
          height: fretboardHeight,
          child: Column(
            children: List.generate(widget.visibleFrets, (i) {
              final fretNum = _startFret + i;
              return SizedBox(
                height: 36,
                child: Center(
                  child: Text(
                    fretNum.toString(),
                    style: TextStyle(
                      fontSize: 11,
                      color: lineColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Fretboard
        CustomPaint(
          size: Size(fretboardWidth, fretboardHeight),
          painter: _FretboardPainter(
            positions: _positions,
            visibleFrets: widget.visibleFrets,
            startFret: _startFret,
            stringCount: stringCount,
            lineColor: lineColor,
            dotColor: dotColor,
          ),
          child: SizedBox(
            width: fretboardWidth,
            height: fretboardHeight,
            child: GestureDetector(
              onTapDown: (details) {
                const cellWidth = 36.0;
                const cellHeight = 36.0;
                final stringIdx = (details.localPosition.dx / cellWidth).floor().clamp(0, stringCount - 1);
                final relFretIdx = (details.localPosition.dy / cellHeight).floor().clamp(0, widget.visibleFrets - 1);
                final absoluteFret = _startFret + relFretIdx;
                _onFretTap(stringIdx, absoluteFret);
              },
            ),
          ),
        ),
        // Shift buttons column
        SizedBox(
          width: 32,
          height: fretboardHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_up, size: 20, color: Colors.black87),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: _startFret + widget.visibleFrets - 1 < widget.maxFret ? _shiftUp : null,
                tooltip: 'Vyšší pražce',
              ),
              Text(
                '$_startFret–${_startFret + widget.visibleFrets - 1}',
                style: TextStyle(fontSize: 9, color: lineColor.withValues(alpha: 0.6)),
              ),
              IconButton(
                icon: const Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.black87),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: _startFret > 1 ? _shiftDown : null,
                tooltip: 'Nižší pražce',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FretboardPainter extends CustomPainter {
  final List<int?> positions;
  final int visibleFrets;
  final int startFret;
  final int stringCount;
  final Color lineColor;
  final Color dotColor;

  _FretboardPainter({
    required this.positions,
    required this.visibleFrets,
    required this.startFret,
    required this.stringCount,
    required this.lineColor,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / stringCount;
    final cellHeight = size.height / visibleFrets;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final thinLinePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    // Draw horizontal fret lines
    for (int f = 0; f <= visibleFrets; f++) {
      final y = f * cellHeight;
      canvas.drawLine(
        Offset(cellWidth / 2, y),
        Offset(size.width - cellWidth / 2, y),
        linePaint,
      );
    }

    // Draw vertical string lines
    for (int s = 0; s < stringCount; s++) {
      final x = s * cellWidth + cellWidth / 2;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        thinLinePaint,
      );
    }

    // Draw finger dots
    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final endFret = startFret + visibleFrets - 1;

    for (int s = 0; s < stringCount; s++) {
      final pos = positions[s];
      if (pos != null && pos >= startFret && pos <= endFret) {
        final relPos = pos - startFret;
        final x = s * cellWidth + cellWidth / 2;
        final y = relPos * cellHeight + cellHeight / 2;
        canvas.drawCircle(Offset(x, y), cellWidth * 0.3, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FretboardPainter oldDelegate) {
    return oldDelegate.positions != positions || oldDelegate.startFret != startFret || oldDelegate.visibleFrets != visibleFrets;
  }
}

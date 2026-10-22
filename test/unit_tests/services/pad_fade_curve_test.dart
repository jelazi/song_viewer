import 'package:flutter_test/flutter_test.dart';
import 'package:song_viewer/services/pad_audio_engine.dart';

void main() {
  group('PadFadeCurve', () {
    for (final curve in PadFadeCurve.values) {
      test('${curve.name} starts and ends at the right level', () {
        expect(curve.fadeIn(0), closeTo(0, 1e-9));
        expect(curve.fadeIn(1), closeTo(1, 1e-9));
        expect(curve.fadeOut(0), closeTo(1, 1e-9));
        expect(curve.fadeOut(1), closeTo(0, 1e-9));
      });

      test('${curve.name} clamps progress outside 0..1', () {
        expect(curve.fadeIn(1.5), closeTo(1, 1e-9));
        expect(curve.fadeOut(-0.5), closeTo(1, 1e-9));
      });
    }

    test('smooth keeps constant power during a crossfade', () {
      for (var t = 0.0; t <= 1.0; t += 0.1) {
        final fadeIn = PadFadeCurve.smooth.fadeIn(t);
        final fadeOut = PadFadeCurve.smooth.fadeOut(t);
        expect(fadeIn * fadeIn + fadeOut * fadeOut, closeTo(1, 1e-9));
      }
    });

    test('gentle rises slower than linear at the start', () {
      expect(PadFadeCurve.gentle.fadeIn(0.25), lessThan(PadFadeCurve.linear.fadeIn(0.25)));
    });
  });
}

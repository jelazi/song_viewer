import 'dart:async';
import 'dart:math';

import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:logger_pkg/logger_pkg.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// Shape of a pad fade.
enum PadFadeCurve {
  /// Volume changes at a constant rate.
  linear,

  /// Equal-power: a crossfade between two pads keeps the overall level.
  smooth,

  /// Starts slowly and speeds up, closer to how the ear hears loudness.
  gentle;

  /// Gain (0..1) at [progress] (0..1) of a fade-in.
  double fadeIn(double progress) {
    final t = progress.clamp(0.0, 1.0);
    switch (this) {
      case PadFadeCurve.linear:
        return t;
      case PadFadeCurve.smooth:
        return sin(t * pi / 2);
      case PadFadeCurve.gentle:
        return t * t;
    }
  }

  /// Gain (0..1) at [progress] (0..1) of a fade-out from full level.
  double fadeOut(double progress) {
    final t = progress.clamp(0.0, 1.0);
    switch (this) {
      case PadFadeCurve.linear:
        return 1 - t;
      case PadFadeCurve.smooth:
        return cos(t * pi / 2);
      case PadFadeCurve.gentle:
        return (1 - t) * (1 - t);
    }
  }
}

class _PadVoice {
  final AudioPlayer player;
  final String path;
  double gain = 0;
  bool fadingOut = false;
  Timer? fadeTimer;
  Timer? loopTimer;

  _PadVoice(this.player, this.path);
}

/// Plays worship pads: every key change fades the old pad out and the new one
/// in, and each pad loops by crossfading its end into a fresh start, so the
/// seam of the recording is never heard.
class PadAudioEngine {
  static const _loopCrossfade = Duration(seconds: 6);
  static const _tick = Duration(milliseconds: 40);

  final _voices = <_PadVoice>[];
  double _volume = 0.8;
  bool _sessionConfigured = false;

  bool get isPlaying => _voices.any((voice) => !voice.fadingOut);

  /// Starts the pad in [path], fading out whatever plays now.
  Future<void> play(String path, {required Duration fadeIn, required Duration fadeOut, required PadFadeCurve curve}) async {
    await _activateSession();
    for (final voice in List.of(_voices)) {
      if (!voice.fadingOut) _fadeOut(voice, fadeOut, curve);
    }
    await _startVoice(path, fadeIn, curve);
    await WakelockPlus.enable();
  }

  /// Fades every pad out.
  Future<void> stop({required Duration fadeOut, required PadFadeCurve curve}) async {
    for (final voice in List.of(_voices)) {
      if (!voice.fadingOut) _fadeOut(voice, fadeOut, curve);
    }
    await WakelockPlus.disable();
  }

  void setVolume(double volume) {
    _volume = volume.clamp(0.0, 1.0);
    for (final voice in _voices) {
      voice.player.setVolume(voice.gain * _volume);
    }
  }

  Future<void> dispose() async {
    for (final voice in List.of(_voices)) {
      await _disposeVoice(voice);
    }
    await WakelockPlus.disable();
  }

  Future<void> _startVoice(String path, Duration fadeIn, PadFadeCurve curve) async {
    // The engine manages the audio session itself so that a pad keeps playing
    // next to the YouTube window instead of being paused by it.
    final player = AudioPlayer(handleInterruptions: false, handleAudioSessionActivation: false);
    final voice = _PadVoice(player, path);
    _voices.add(voice);
    try {
      final duration = await player.setFilePath(path);
      await player.setVolume(0);
      unawaited(player.play());
      _fadeIn(voice, fadeIn, curve);
      if (duration != null && duration > _loopCrossfade * 2) {
        voice.loopTimer = Timer(duration - _loopCrossfade, () => _loop(voice));
      }
    } catch (e) {
      logger.e('Pad could not be played: $e');
      await _disposeVoice(voice);
      rethrow;
    }
  }

  void _loop(_PadVoice voice) {
    if (voice.fadingOut || !_voices.contains(voice)) return;
    _fadeOut(voice, _loopCrossfade, PadFadeCurve.smooth);
    unawaited(_startVoice(voice.path, _loopCrossfade, PadFadeCurve.smooth).catchError((_) {}));
  }

  void _fadeIn(_PadVoice voice, Duration duration, PadFadeCurve curve) {
    _runFade(voice, duration, (progress) => curve.fadeIn(progress), onDone: () {});
  }

  void _fadeOut(_PadVoice voice, Duration duration, PadFadeCurve curve) {
    voice.fadingOut = true;
    voice.loopTimer?.cancel();
    final startGain = voice.gain;
    _runFade(voice, duration, (progress) => startGain * curve.fadeOut(progress), onDone: () => _disposeVoice(voice));
  }

  void _runFade(_PadVoice voice, Duration duration, double Function(double progress) gainAt, {required void Function() onDone}) {
    voice.fadeTimer?.cancel();
    if (duration <= Duration.zero) {
      _setGain(voice, gainAt(1));
      onDone();
      return;
    }
    final watch = Stopwatch()..start();
    voice.fadeTimer = Timer.periodic(_tick, (timer) {
      final progress = watch.elapsedMicroseconds / duration.inMicroseconds;
      _setGain(voice, gainAt(progress));
      if (progress >= 1) {
        timer.cancel();
        onDone();
      }
    });
  }

  void _setGain(_PadVoice voice, double gain) {
    voice.gain = gain;
    voice.player.setVolume(gain * _volume);
  }

  Future<void> _disposeVoice(_PadVoice voice) async {
    voice.fadeTimer?.cancel();
    voice.loopTimer?.cancel();
    _voices.remove(voice);
    await voice.player.dispose();
  }

  Future<void> _activateSession() async {
    final session = await AudioSession.instance;
    if (!_sessionConfigured) {
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          usage: AndroidAudioUsage.media,
        ),
        androidWillPauseWhenDucked: false,
      ));
      _sessionConfigured = true;
    }
    await session.setActive(true);
  }
}

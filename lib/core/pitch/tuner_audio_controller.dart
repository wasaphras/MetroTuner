import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:metrotuner/core/pitch/pitch_detector.dart';
import 'package:metrotuner/core/pitch/pitch_types.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

/// Top-level for [Isolate.run] (same library as [PitchDetector]).
PitchResult? _analyzeFrameInIsolate(_AnalyzeFrameMessage msg) {
  return PitchDetector.analyzeFrame(msg.samples, msg.sampleRate);
}

/// Message for isolate pitch analysis.
class _AnalyzeFrameMessage {
  /// Creates a message with float PCM and sample rate.
  const _AnalyzeFrameMessage(this.samples, this.sampleRate);

  /// Mono normalized float samples.
  final Float32List samples;

  /// Sample rate in Hz.
  final int sampleRate;
}

/// Captures mono PCM from the mic, runs [PitchDetector] per frame on a worker
/// isolate, and releases the recorder on [stop] / [dispose].
class TunerAudioController {
  /// Sample rate used for streaming and YIN.
  static const int sampleRate = 44100;

  /// Samples per analysis frame (power of two works well for buffering).
  static const int frameSamples = 2048;

  /// Minimum milliseconds between [pitchStream] emissions (~30 Hz UI cap).
  static const int _minEmitIntervalMs = 33;

  final AudioRecorder _recorder = AudioRecorder();
  final List<int> _pcmAccum = [];

  StreamSubscription<Uint8List>? _micSub;
  final StreamController<PitchResult?> _out =
      StreamController<PitchResult?>.broadcast();

  /// Emits a result per frame while running, or null when gated out.
  Stream<PitchResult?> get pitchStream => _out.stream;

  bool _running = false;

  _AnalyzeFrameMessage? _pendingFrame;
  bool _isolateBusy = false;

  int _lastEmitMs = 0;

  /// Whether a recording session is active.
  bool get isRunning => _running;

  /// Requests mic permission and starts streaming analysis.
  ///
  /// Returns false if permission denied or stream could not start.
  Future<bool> start() async {
    if (_running) {
      return true;
    }
    final perm = await Permission.microphone.request();
    if (!perm.isGranted) {
      return false;
    }
    if (!await _recorder.hasPermission()) {
      return false;
    }
    final supported = await _recorder.isEncoderSupported(
      AudioEncoder.pcm16bits,
    );
    if (!supported) {
      return false;
    }

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        numChannels: 1,
      ),
    );

    _pcmAccum.clear();
    _pendingFrame = null;
    _lastEmitMs = 0;
    _micSub = stream.listen(
      _onPcmChunk,
      onError: _out.addError,
    );
    _running = true;
    return true;
  }

  void _onPcmChunk(Uint8List data) {
    _pcmAccum.addAll(data);
    const need = frameSamples * 2;
    while (_pcmAccum.length >= need) {
      final chunk = Uint8List(need);
      for (var i = 0; i < need; i++) {
        chunk[i] = _pcmAccum[i];
      }
      _pcmAccum.removeRange(0, need);
      final frame = _pcm16LeToFloat(chunk);
      _enqueueFrame(frame);
    }
  }

  void _enqueueFrame(Float32List frame) {
    _pendingFrame = _AnalyzeFrameMessage(frame, sampleRate);
    unawaited(_drainIsolateQueue());
  }

  Future<void> _drainIsolateQueue() async {
    if (_isolateBusy) {
      return;
    }
    _isolateBusy = true;
    while (_running) {
      final msg = _pendingFrame;
      if (msg == null) {
        break;
      }
      _pendingFrame = null;
      final result = await Isolate.run(() => _analyzeFrameInIsolate(msg));
      if (!_running || _out.isClosed) {
        break;
      }
      _emitThrottled(result);
    }
    _isolateBusy = false;
    if (_pendingFrame != null && _running) {
      unawaited(_drainIsolateQueue());
    }
  }

  void _emitThrottled(PitchResult? result) {
    if (result == null) {
      _lastEmitMs = DateTime.now().millisecondsSinceEpoch;
      if (!_out.isClosed) {
        _out.add(null);
      }
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastEmitMs < _minEmitIntervalMs) {
      return;
    }
    _lastEmitMs = now;
    if (!_out.isClosed) {
      _out.add(result);
    }
  }

  static Float32List _pcm16LeToFloat(Uint8List bytes) {
    final n = bytes.length ~/ 2;
    final out = Float32List(n);
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i < n; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  /// Stops capture and releases the microphone until [start] is called again.
  Future<void> stop() async {
    if (!_running) {
      return;
    }
    _running = false;
    _pendingFrame = null;
    await _micSub?.cancel();
    _micSub = null;
    _pcmAccum.clear();
    await _recorder.stop();
  }

  /// Stops if needed and disposes native recorder resources.
  Future<void> dispose() async {
    await stop();
    if (!_out.isClosed) {
      await _out.close();
    }
    await _recorder.dispose();
  }
}

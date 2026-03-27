import 'dart:math' as math;
import 'dart:typed_data';

/// YIN pitch estimate (Cheveigne & Kawahara, 2002).
abstract final class PitchYin {
  PitchYin._();

  /// Estimates fundamental frequency (Hz) or returns null if no clear pitch.
  ///
  /// [samples] should be mono, roughly normalized [-1, 1].
  static double? estimateHz(
    Float32List samples,
    int sampleRate, {
    double minHz = 70,
    double maxHz = 4200,
    double cmndThreshold = 0.2,
  }) {
    final n = samples.length;
    if (n < 8) {
      return null;
    }

    final tauMin = math.max(2, (sampleRate / maxHz).floor());
    var tauMax = (sampleRate / minHz).floor();
    if (tauMax >= n) {
      tauMax = n - 1;
    }
    if (tauMax <= tauMin) {
      return null;
    }

    final raw = List<double>.filled(tauMax + 1, 0);
    for (var tau = tauMin; tau <= tauMax; tau++) {
      var sum = 0.0;
      final limit = n - tau;
      for (var j = 0; j < limit; j++) {
        final diff = samples[j] - samples[j + tau];
        sum += diff * diff;
      }
      raw[tau] = sum;
    }

    final cmnd = List<double>.filled(tauMax + 1, 0);
    var cumsum = 0.0;
    for (var tau = 1; tau <= tauMax; tau++) {
      cumsum += raw[tau];
      // CMND denominator; Cheveigné & Kawahara (2002). cumsum == 0 → avoid division by zero.
      if (cumsum <= 0) {
        cmnd[tau] = 1;
      } else {
        cmnd[tau] = raw[tau] * tau / cumsum;
      }
    }

    // Prefer the first local minimum below threshold (low tau = high pitch) to
    // avoid picking subharmonics (global minimum often falls on a lower pitch).
    var bestTau = -1;
    for (var tau = tauMin + 1; tau < tauMax; tau++) {
      if (cmnd[tau] < cmnd[tau - 1] &&
          cmnd[tau] <= cmnd[tau + 1] &&
          cmnd[tau] < cmndThreshold) {
        bestTau = tau;
        break;
      }
    }

    if (bestTau < 0) {
      return null;
    }

    final t = bestTau;
    if (t <= tauMin + 1 || t >= tauMax - 1) {
      return sampleRate / t;
    }

    final y0 = raw[t - 1];
    final y1 = raw[t];
    final y2 = raw[t + 1];
    // Parabolic interpolation on the difference function (YIN paper refinement step).
    final denom = y0 - 2 * y1 + y2;
    if (denom.abs() < 1e-12) {
      return sampleRate / t;
    }
    final delta = 0.5 * (y0 - y2) / denom;
    final tauStar = t + delta;
    if (tauStar <= 0) {
      return null;
    }
    return sampleRate / tauStar;
  }
}

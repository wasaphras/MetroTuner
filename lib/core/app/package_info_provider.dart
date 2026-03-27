import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// App metadata from the platform bundle (populated from pubspec `version` at build time).
///
/// Maintain release versions only in pubspec.yaml; do not hard-code elsewhere.
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return PackageInfo.fromPlatform();
});

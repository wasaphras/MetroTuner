import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:metrotuner/core/audio/audio_engine.dart';

/// Shared startup used by `main()` and integration tests (audio engine init).
Future<void> bootstrapMetrotuner() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  await AudioEngine.instance.ensureInitialized();
}

import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/core/audio/audio_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AudioEngine ensureInitialized and dispose do not throw', () async {
    await AudioEngine.instance.ensureInitialized();
    AudioEngine.instance.dispose();
  });
}

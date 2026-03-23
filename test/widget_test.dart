import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrotuner/app.dart';

void main() {
  testWidgets('MetroTunerApp shows Tuner first', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MetroTunerApp()),
    );

    expect(find.text('Tuner'), findsWidgets);
    expect(find.text('Metronome'), findsWidgets);
  });
}

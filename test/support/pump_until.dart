import 'package:flutter_test/flutter_test.dart';

/// Pumps one frame per iteration until [satisfied] returns true or [maxPumps]
/// is reached (no fixed `Duration` sleep in the loop).
Future<void> pumpUntil(
  WidgetTester tester,
  bool Function() satisfied, {
  int maxPumps = 500,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (satisfied()) {
      return;
    }
    await tester.pump();
  }
  if (satisfied()) {
    return;
  }
  fail(
    'pumpUntil: condition not met after $maxPumps frame pumps.',
  );
}

/// Same as [pumpUntil] but stops when [finder] matches at least one widget.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 500,
}) async {
  await pumpUntil(
    tester,
    () => finder.evaluate().isNotEmpty,
    maxPumps: maxPumps,
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether [FlutterErrorDetails] correspond to a flex/viewport overflow during layout.
bool isLayoutOverflowError(FlutterErrorDetails details) {
  final s = details.exceptionAsString();
  return s.contains('overflowed') ||
      s.contains('OVERFLOWING') ||
      details.summary.toString().contains('overflow');
}

/// Pumps [widget] at [size] and fails if Flutter reports a layout overflow.
/// Uses `FlutterError.onError` because `takeException` does not reliably
/// capture overflow reports.
Future<void> pumpWidgetExpectNoOverflow(
  WidgetTester tester,
  Size size,
  Widget widget,
) async {
  final binding = tester.binding;
  await binding.setSurfaceSize(size);
  addTearDown(() async {
    await binding.setSurfaceSize(null);
  });

  final overflowReports = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) {
    if (isLayoutOverflowError(details)) {
      overflowReports.add(details);
      return;
    }
    previous?.call(details);
  };
  try {
    await tester.pump();
    await tester.pumpWidget(widget);
    await tester.pump();
  } finally {
    FlutterError.onError = previous;
  }

  expect(
    overflowReports,
    isEmpty,
    reason: overflowReports.isEmpty
        ? null
        : overflowReports.map((e) => e.exceptionAsString()).join('\n---\n'),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrotuner/app.dart';
import 'package:metrotuner/bootstrap.dart';

Future<void> main() async {
  await bootstrapMetrotuner();
  runApp(const ProviderScope(child: MetroTunerApp()));
}

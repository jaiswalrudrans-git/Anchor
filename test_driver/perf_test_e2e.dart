import 'package:flutter_driver/driver_extension.dart';
import 'package:anchor/main.dart' as app;

/// Instrumentation entry point for Flutter Driver performance benchmarking.
void main() {
  enableFlutterDriverExtension();
  app.main();
}

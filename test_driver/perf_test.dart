import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:flutter_test/flutter_test.dart' hide find;

void main() {
  group('Anchor 120Hz & 60FPS Performance Benchmark Suite', () {
    late FlutterDriver driver;

    setUpAll(() async {
      final perfDir = Directory('perf');
      if (!perfDir.existsSync()) {
        perfDir.createSync(recursive: true);
      }
      driver = await FlutterDriver.connect();
    });

    tearDownAll(() async {
      await driver.close();
    });

    test('Flow 1: Dock tab glide 20 times (target: 0 frames > 16ms)', () async {
      final timeline = await driver.traceAction(() async {
        for (var cycle = 0; cycle < 5; cycle++) {
          for (var i = 0; i < 4; i++) {
            final tab = find.byValueKey('dock_dest_$i');
            await driver.tap(tab);
            await Future<void>.delayed(const Duration(milliseconds: 150));
          }
        }
      });

      final summary = TimelineSummary.summarize(timeline);
      await summary.writeTimelineToFile(
        'dock_glide',
        destinationDirectory: 'perf',
        pretty: true,
        includeSummary: true,
      );
    });

    test('Flow 2: Quick Add Open and Close (target: < 8ms build & raster)', () async {
      final timeline = await driver.traceAction(() async {
        final quickAddBtn = find.byValueKey('quick_add_button');
        for (var i = 0; i < 5; i++) {
          await driver.tap(quickAddBtn);
          await Future<void>.delayed(const Duration(milliseconds: 250));
          final closeBtn = find.byTooltip('Close');
          await driver.tap(closeBtn);
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      });

      final summary = TimelineSummary.summarize(timeline);
      await summary.writeTimelineToFile(
        'quick_add',
        destinationDirectory: 'perf',
        pretty: true,
        includeSummary: true,
      );
    });

    test('Flow 3: Home Task Scroll and Progress Stroke Animation', () async {
      final homeTab = find.byValueKey('dock_dest_0');
      await driver.tap(homeTab);
      await Future<void>.delayed(const Duration(milliseconds: 200));

      final timeline = await driver.traceAction(() async {
        final scrollable = find.byType('Scrollable');
        await driver.scroll(scrollable, 0, -300, const Duration(milliseconds: 400));
        await driver.scroll(scrollable, 0, 300, const Duration(milliseconds: 400));
      });

      final summary = TimelineSummary.summarize(timeline);
      await summary.writeTimelineToFile(
        'home_scroll',
        destinationDirectory: 'perf',
        pretty: true,
        includeSummary: true,
      );
    });
  });
}

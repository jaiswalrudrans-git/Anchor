import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/widgets/navigation/floating_dock.dart';

void main() {
  group('DockShape Path Unit Tests', () {
    const shape = DockShape();
    final testPositions = [0.0, 1.0, 2.0, 3.0, 0.5, 2.25];
    final testRects = [
      const Rect.fromLTWH(0, 0, 216, 68),
      const Rect.fromLTWH(0, 0, 256, 68),
      const Rect.fromLTWH(0, 0, 360, 68),
      const Rect.fromLTWH(0, 0, 400, 68),
    ];

    for (final rect in testRects) {
      for (final pos in testPositions) {
        test('Path for rect width ${rect.width}, position $pos', () {
          final path = shape.buildPath(rect, pos);
          final metrics = path.computeMetrics().toList();

          // 1. Path is closed
          expect(metrics.isNotEmpty, isTrue);
          expect(metrics.first.isClosed, isTrue);

          // 2. Bounds equal dock rect
          final bounds = path.getBounds();
          expect(bounds.left, closeTo(rect.left, 0.1));
          expect(bounds.top, closeTo(rect.top, 0.1));
          expect(bounds.right, closeTo(rect.right, 0.1));
          expect(bounds.bottom, closeTo(rect.bottom, 0.1));

          // 3. Notch apex is r - bubbleLift below top edge exactly at slotCenterX across any device
          final slotCenterX = DockShape.slotCenterX(pos, rect.width);
          final expectedApexDepth = shape.notchRadius - shape.bubbleLift;

          expect(
            path.contains(Offset(slotCenterX, expectedApexDepth + 1.0)),
            isTrue,
          );
          expect(
            path.contains(Offset(slotCenterX, expectedApexDepth - 1.0)),
            isFalse,
          );

          // 4. Notch never crosses end caps (end cap regions stay filled)
          expect(
            path.contains(Offset(rect.left + 15.0, rect.top + 20.0)),
            isTrue,
          );
          expect(
            path.contains(Offset(rect.right - 15.0, rect.top + 20.0)),
            isTrue,
          );

          // 5. Continuous (no NaN)
          final metric = metrics.first;
          const sampleCount = 40;
          for (var i = 0; i <= sampleCount; i++) {
            final distance = metric.length * (i / sampleCount);
            final tangent = metric.getTangentForOffset(distance);
            expect(tangent, isNotNull);
            expect(tangent!.position.dx.isNaN, isFalse);
            expect(tangent.position.dy.isNaN, isFalse);
          }
        });
      }
    }
  });
}

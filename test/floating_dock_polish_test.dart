import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/screens/main_shell.dart';
import 'package:anchor/widgets/navigation/floating_dock.dart';
import 'package:anchor/widgets/navigation/side_nav.dart';

void main() {
  group('1. DockShape Path Geometry & Continuity Tests', () {
    const shape = DockShape();
    final testPositions = [0.0, 1.0, 2.0, 3.0, 0.5, 2.25];
    final testRects = [
      const Rect.fromLTWH(0, 0, 256, 68),
      const Rect.fromLTWH(0, 0, 360, 68),
      const Rect.fromLTWH(0, 0, 400, 68),
    ];

    for (final rect in testRects) {
      for (final pos in testPositions) {
        test('Path metrics for rect width ${rect.width}, position $pos', () {
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

  group('2. FloatingDock & QuickAddButton Interactive Widget Tests', () {
    const testDestinations = [
      DockDestination(
        label: 'Home',
        icon: Icons.check_box_outlined,
        selectedIcon: Icons.check_box,
        key: Key('nav_tab_home'),
      ),
      DockDestination(
        label: 'Academics',
        icon: Icons.school_outlined,
        selectedIcon: Icons.school,
        key: Key('nav_tab_academics'),
      ),
      DockDestination(
        label: 'Expenses',
        icon: Icons.account_balance_wallet_outlined,
        selectedIcon: Icons.account_balance_wallet,
        key: Key('nav_tab_expenses'),
      ),
      DockDestination(
        label: 'Habits',
        icon: Icons.repeat_outlined,
        selectedIcon: Icons.repeat,
        key: Key('nav_tab_habits'),
      ),
    ];

    testWidgets(
      'Destinations render in order and bubble aligns with selected slot',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        int selected = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Center(
                    child: SizedBox(
                      width: 256,
                      child: FloatingDock(
                        destinations: testDestinations,
                        selectedIndex: selected,
                        onSelected: (idx) => setState(() => selected = idx),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 4 destinations in exact order
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Academics'), findsOneWidget);
        expect(find.text('Expenses'), findsOneWidget);
        expect(find.text('Habits'), findsOneWidget);

        // Verify bubble exists and its center X equals slot 0 center X (256 / 4 * 0.5 = 32 dp)
        final bubbleFinder = find.byKey(const Key('dock_bubble'));
        expect(bubbleFinder, findsOneWidget);
        final slot0Center = tester.getCenter(
          find.byKey(const Key('nav_tab_home')),
        );
        final bubbleCenterInitial = tester.getCenter(bubbleFinder);
        expect(bubbleCenterInitial.dx, closeTo(slot0Center.dx, 1.0));

        // Tap Academics (slot 1)
        await tester.tap(find.byKey(const Key('nav_tab_academics')));
        await tester.pumpAndSettle();

        expect(selected, 1);
        final slot1Center = tester.getCenter(
          find.byKey(const Key('nav_tab_academics')),
        );
        final bubbleCenterAfter = tester.getCenter(bubbleFinder);
        expect(bubbleCenterAfter.dx, closeTo(slot1Center.dx, 1.0));

        // Previously selected slot (Home) shows its icon and label again
        expect(find.byIcon(Icons.check_box_outlined), findsOneWidget);
      },
    );

    testWidgets(
      'Semantics: each destination is a button, selected true only for active',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 256,
                  child: FloatingDock(
                    destinations: testDestinations,
                    selectedIndex: 2, // Expenses
                    onSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final homeSemantics = tester.getSemantics(
          find.byKey(const Key('nav_tab_home')),
        );
        expect(
          homeSemantics.flagsCollection.isSelected,
          isNot(Tristate.isTrue),
        );

        final expensesSemantics = tester.getSemantics(
          find.byKey(const Key('nav_tab_expenses')),
        );
        expect(expensesSemantics.flagsCollection.isSelected, Tristate.isTrue);
      },
    );

    testWidgets(
      'Plus button is outside dock, does not move when tab changes, opens Quick Add',
      (tester) async {
        tester.view.physicalSize = const Size(360, 640);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          const ProviderScope(child: MaterialApp(home: MainShell())),
        );
        await tester.pumpAndSettle();

        // Exactly ONE quick_add_button in the whole shell
        final plusFinder = find.byKey(const Key('quick_add_button'));
        expect(plusFinder, findsOneWidget);
        final plusInitialPos = tester.getCenter(plusFinder);

        // Dock is distinct and separate
        final dockFinder = find.byType(FloatingDock);
        expect(dockFinder, findsOneWidget);
        final dockRect = tester.getRect(dockFinder);
        expect(
          dockRect.contains(plusInitialPos),
          isFalse,
        ); // Outside the dock's rect

        // Switch tab to Academics
        await tester.tap(find.byKey(const Key('nav_tab_academics')));
        await tester.pumpAndSettle();

        // Plus position has NOT moved
        final plusAfterTabSwitch = tester.getCenter(plusFinder);
        expect(plusAfterTabSwitch.dx, equals(plusInitialPos.dx));
        expect(plusAfterTabSwitch.dy, equals(plusInitialPos.dy));

        // Tapping plus opens Quick Add
        await tester.tap(plusFinder);
        await tester.pumpAndSettle();

        expect(find.text('Quick add'), findsOneWidget);
      },
    );

    testWidgets('Keyboard open slides dock down', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: MainShell())),
      );
      await tester.pumpAndSettle();

      final dockFinder = find.byType(FloatingDock);
      final initialDockTop = tester.getTopLeft(dockFinder).dy;

      // Simulate keyboard opening (viewInsets.bottom = 250)
      tester.view.viewInsets = const FakeViewPadding(bottom: 250);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final loweredDockTop = tester.getTopLeft(dockFinder).dy;
      expect(loweredDockTop, greaterThan(initialDockTop));

      // Reset insets
      tester.view.resetViewInsets();
    });

    testWidgets('Reduced motion jumps instantly', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      int selected = 0;

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Center(
                    child: SizedBox(
                      width: 256,
                      child: FloatingDock(
                        destinations: testDestinations,
                        selectedIndex: selected,
                        onSelected: (idx) => setState(() => selected = idx),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final bubbleFinder = find.byKey(const Key('dock_bubble'));
      final initialCenter = tester.getCenter(bubbleFinder);

      await tester.tap(find.byKey(const Key('nav_tab_habits')));
      await tester.pump(); // 0 ms advance

      final immediateCenter = tester.getCenter(bubbleFinder);
      expect(immediateCenter.dx, isNot(equals(initialCenter.dx)));
    });
  });

  group('3. Responsive Viewports & Accessibility Matrix Tests', () {
    final viewports = [
      const Size(320, 568), // iPhone SE / narrow
      const Size(360, 640), // Standard compact
      const Size(412, 915), // Tall Android
      const Size(600, 960), // Tablet Rail
      const Size(844, 390), // Landscape Phone
      const Size(1280, 800), // Desktop Expanded
    ];

    for (final size in viewports) {
      for (final textScale in [1.0, 1.3]) {
        testWidgets(
          'Renders at ${size.width}x${size.height} textScale $textScale without overflow',
          (tester) async {
            tester.view.physicalSize = size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);

            await tester.pumpWidget(
              ProviderScope(
                child: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    textScaler: TextScaler.linear(textScale),
                  ),
                  child: MaterialApp(
                    theme: AppTheme.lightTheme,
                    home: const MainShell(),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();

            expect(tester.takeException(), isNull);

            // Verify shell add control exists
            expect(find.byKey(const Key('quick_add_button')), findsOneWidget);

            // Page content bottom clearance
            if (size.width < 600) {
              expect(find.byType(FloatingDock), findsOneWidget);
            } else {
              expect(find.byType(SideNav), findsOneWidget);
            }
          },
        );
      }
    }
  });
}

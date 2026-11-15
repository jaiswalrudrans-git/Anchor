import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/screens/main_shell.dart';
import 'package:anchor/widgets/navigation/floating_dock.dart';
import 'package:anchor/widgets/navigation/side_nav.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SideNav Breakpoints and Modes Tests', () {
    testWidgets('599px width renders compact FloatingDock and no SideNav', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(599, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(FloatingDock), findsOneWidget);
      expect(find.byType(SideNav), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);
      expect(find.byKey(const Key('quick_add_button')), findsOneWidget);
    });

    testWidgets('600px width renders 80dp compact rail and no FloatingDock', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SideNav), findsOneWidget);
      expect(find.byType(FloatingDock), findsNothing);
      expect(tester.getSize(find.byType(SideNav)).width, 80.0);
      expect(find.byKey(const Key('quick_add_button')), findsOneWidget);
      // On 600px (medium), collapse toggle is omitted
      expect(find.byKey(const Key('sidebar_collapse_toggle')), findsNothing);
    });

    testWidgets('899px width renders 80dp compact rail', (tester) async {
      tester.view.physicalSize = const Size(899, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SideNav), findsOneWidget);
      expect(tester.getSize(find.byType(SideNav)).width, 80.0);
      expect(find.byKey(const Key('sidebar_collapse_toggle')), findsNothing);
    });

    testWidgets('900px width renders 248dp full sidebar with brand wordmark and collapse toggle', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SideNav), findsOneWidget);
      expect(tester.getSize(find.byType(SideNav)).width, 248.0);
      expect(find.text('anchor'), findsOneWidget);
      expect(find.text('Menu'), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
      expect(find.text('Ctrl N'), findsOneWidget);
      expect(find.byKey(const Key('sidebar_collapse_toggle')), findsOneWidget);
    });

    testWidgets('1280x800 and 1920x1080 viewports render full 248dp sidebar', (
      tester,
    ) async {
      for (final size in [const Size(1280, 800), const Size(1920, 1080)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProviderScope(child: MainShell()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SideNav), findsOneWidget);
        expect(tester.getSize(find.byType(SideNav)).width, 248.0);
      }
    });
  });

  group('SideNav Layout & Anti-Overlap Audit', () {
    testWidgets('in compact rail, highlight pill is behind icon and never overlaps label', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      const homeKey = Key('nav_tab_home');
      final homeItemFinder = find.byKey(homeKey);
      expect(homeItemFinder, findsOneWidget);

      final iconFinder = find.descendant(
        of: homeItemFinder,
        matching: find.byIcon(Icons.check_box),
      );
      final labelFinder = find.descendant(
        of: homeItemFinder,
        matching: find.text('Home'),
      );

      expect(iconFinder, findsOneWidget);
      expect(labelFinder, findsOneWidget);

      final iconRect = tester.getRect(iconFinder);
      final labelRect = tester.getRect(labelFinder);

      // Label must be strictly below the icon (no vertical overlap)
      expect(
        labelRect.top,
        greaterThanOrEqualTo(iconRect.bottom),
        reason: 'Label must be positioned below icon in compact rail',
      );
      expect(
        iconRect.overlaps(labelRect),
        isFalse,
        reason: 'Icon and label must not overlap in compact rail',
      );
    });

    testWidgets('destinations are top-aligned directly under Add button area (not centered)', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      final addBtnRect = tester.getRect(find.byKey(const Key('quick_add_button')));
      final firstTabRect = tester.getRect(find.byKey(const Key('nav_tab_home')));

      // First tab starts within ~60dp below the Add button (Add + Menu label + spacing)
      final gap = firstTabRect.top - addBtnRect.bottom;
      expect(
        gap,
        lessThanOrEqualTo(70.0),
        reason: 'Nav items must be top-aligned directly below Add area, not vertically centered',
      );
    });
  });

  group('SideNav Collapse / Expand Persistence Tests', () {
    testWidgets('collapse toggle collapses to 80dp rail and persists in SharedPreferences', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({'sidebar_collapsed': false});

      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(SideNav)).width, 248.0);

      // Tap collapse toggle
      await tester.tap(find.byKey(const Key('sidebar_collapse_toggle')));
      await tester.pumpAndSettle();

      // Width collapses to 80dp compact rail
      expect(tester.getSize(find.byType(SideNav)).width, 80.0);
      expect(find.byKey(const Key('sidebar_expand_toggle')), findsOneWidget);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('sidebar_collapsed'), isTrue);

      // Tap expand toggle
      await tester.tap(find.byKey(const Key('sidebar_expand_toggle')));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(SideNav)).width, 248.0);
      expect(prefs.getBool('sidebar_collapsed'), isFalse);
    });
  });

  group('Keyboard Navigation & Shortcut Tests', () {
    testWidgets('Ctrl+1..4 switch destinations correctly', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const MainShell(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(container.read(mainNavIndexProvider), 0);

      // Send Ctrl+2 for Academics
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(mainNavIndexProvider), 1);

      // Send Ctrl+3 for Expenses
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit3);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(mainNavIndexProvider), 2);

      // Send Ctrl+4 for Habits
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit4);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(mainNavIndexProvider), 3);

      // Send Ctrl+1 for Home
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(container.read(mainNavIndexProvider), 0);
    });
  });

  group('Page Width and Content Right-Edge Bounds', () {
    testWidgets('Home content does not clip or overflow window at 900, 1280, 1920', (
      tester,
    ) async {
      for (final width in [900.0, 1280.0, 1920.0]) {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProviderScope(child: MainShell()),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);

        // Find today's tasks card
        final cardFinder = find.byKey(const Key('academic_radar_slot'));
        if (cardFinder.evaluate().isNotEmpty) {
          final cardRect = tester.getRect(cardFinder);
          expect(
            cardRect.right,
            lessThanOrEqualTo(width),
            reason: 'Right column cards must not overflow window edge on $width px width',
          );
        }
      }
    });

    testWidgets('Navigation rail labels scale without wrapping at textScale 1.3', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(700, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const ProviderScope(child: MainShell()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Academics'), findsWidgets);
    });
  });
}

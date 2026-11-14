import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/main.dart';
import 'package:anchor/screens/auth_screen.dart';
import 'package:anchor/screens/main_shell.dart';
import 'package:anchor/widgets/navigation/floating_dock.dart';
import 'package:anchor/widgets/navigation/floating_rail.dart';

void main() {
  group('MainShell Navigation and Adaptive Layout Tests', () {
    testWidgets('shows FloatingDock and separate Quick Add button when width < 600px', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify FloatingDock exists and FloatingRail/BottomAppBar/FAB do not
      expect(find.byType(FloatingDock), findsOneWidget);
      expect(find.byType(FloatingRail), findsNothing);
      expect(find.byType(BottomAppBar), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);

      // Verify exactly 4 destinations in order
      final labels = [
        'Home',
        'Academics',
        'Expenses',
        'Habits',
      ];
      for (final label in labels) {
        expect(find.text(label), findsWidgets);
      }
      expect(find.text('Workout'), findsNothing);

      // Verify exactly ONE global Quick Add button
      expect(find.byKey(const Key('quick_add_button')), findsOneWidget);
    });

    testWidgets('shows compact FloatingRail on medium width (600-899px)', (tester) async {
      tester.view.physicalSize = const Size(750, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify compact FloatingRail exists and FloatingDock does not
      expect(find.byType(FloatingRail), findsOneWidget);
      expect(find.byType(FloatingDock), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);

      final rail = tester.widget<FloatingRail>(find.byType(FloatingRail));
      expect(rail.destinations.length, 4);
      expect(rail.isExpanded, isFalse);

      // Verify Quick Add button in FloatingRail leading
      expect(find.byKey(const Key('quick_add_button')), findsOneWidget);
    });

    testWidgets('shows extended FloatingRail on expanded width (>= 900px)', (tester) async {
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

      // Verify extended FloatingRail exists with 'Anchor' title
      expect(find.byType(FloatingRail), findsOneWidget);
      expect(find.byType(FloatingDock), findsNothing);
      expect(find.byType(FloatingActionButton), findsNothing);

      final rail = tester.widget<FloatingRail>(find.byType(FloatingRail));
      expect(rail.destinations.length, 4);
      expect(rail.isExpanded, isTrue);
      expect(find.text('Anchor'), findsOneWidget);

      // Verify Quick Add button in FloatingRail with 'Add' text
      expect(find.byKey(const Key('quick_add_button')), findsOneWidget);
      expect(find.text('Add'), findsOneWidget);
    });

    testWidgets('switching tabs updates active screen and preserves tab state', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );
      await tester.pumpAndSettle();

      // Initially on Home tab
      expect(find.text('Nothing planned yet'), findsOneWidget);

      // Tap Academics tab
      await tester.tap(find.text('Academics'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('academics_add_subject_chip')), findsOneWidget);

      // Tap Expenses tab
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      expect(find.text('MONTHLY ALLOWANCE'), findsOneWidget);

      // Tap Habits tab
      await tester.tap(find.text('Habits'));
      await tester.pumpAndSettle();
      expect(find.text('Overview'), findsOneWidget);

      // Tap back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing planned yet'), findsOneWidget);
    });
  });

  group('AuthScreen & MissingConfigApp Tests', () {
    testWidgets('AuthScreen displays branding and Continue with Google button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: AuthScreen()),
        ),
      );

      expect(find.text('Anchor'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('MissingConfigApp renders informative error without crashing', (tester) async {
      await tester.pumpWidget(const MissingConfigApp());

      expect(find.text('Missing Supabase Configuration'), findsOneWidget);
      expect(find.textContaining('--dart-define=SUPABASE_URL='), findsOneWidget);
      expect(find.textContaining('SETUP.md'), findsOneWidget);
    });
  });
}

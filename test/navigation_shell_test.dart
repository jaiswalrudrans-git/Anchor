import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/main.dart';
import 'package:anchor/screens/auth_screen.dart';
import 'package:anchor/screens/main_shell.dart';

void main() {
  group('MainShell Navigation and Adaptive Layout Tests', () {
    testWidgets('shows bottom NavigationBar when width < 700px', (tester) async {
      tester.view.physicalSize = const Size(500, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );

      // Verify bottom NavigationBar exists and NavigationRail does not
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationRail), findsNothing);

      // Verify exactly 5 destinations in order
      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.destinations.length, 5);

      final labels = [
        'Home',
        'Academics',
        'Expenses',
        'Habits',
        'Workout',
      ];
      for (final label in labels) {
        expect(find.text(label), findsWidgets);
      }

      // Verify NO FloatingActionButton anywhere
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('shows left NavigationRail when width >= 700px', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProviderScope(child: MainShell()),
        ),
      );

      // Verify left NavigationRail exists and bottom NavigationBar does not
      expect(find.byType(NavigationRail), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      final rail = tester.widget<NavigationRail>(find.byType(NavigationRail));
      expect(rail.destinations.length, 5);
      expect(rail.labelType, NavigationRailLabelType.all);

      // Verify NO FloatingActionButton anywhere
      expect(find.byType(FloatingActionButton), findsNothing);
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
      expect(find.text('Nothing planned for today.'), findsOneWidget);

      // Tap Academics tab
      await tester.tap(find.text('Academics'));
      await tester.pumpAndSettle();
      expect(find.text('+ Subject'), findsOneWidget);

      // Tap Expenses tab
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      expect(find.text('Expenses & Budget'), findsOneWidget);

      // Tap Habits tab
      await tester.tap(find.text('Habits'));
      await tester.pumpAndSettle();
      expect(find.text('Habits & Streaks'), findsOneWidget);

      // Tap Workout tab
      await tester.tap(find.text('Workout'));
      await tester.pumpAndSettle();
      expect(find.text('Workout Splits'), findsOneWidget);

      // Tap back to Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing planned for today.'), findsOneWidget);
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

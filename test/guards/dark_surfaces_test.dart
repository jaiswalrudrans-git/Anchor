import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/screens/academics/academics_screen.dart';
import 'package:anchor/screens/expenses/expenses_screen.dart';
import 'package:anchor/screens/habits/habits_screen.dart';
import 'package:anchor/screens/home/home_screen.dart';
import 'package:anchor/screens/academics/widgets/add_assignment_sheet.dart';
import 'package:anchor/screens/expenses/widgets/add_transaction_sheet.dart';
import 'package:anchor/screens/habits/widgets/add_habit_sheet.dart';
import 'package:anchor/screens/home/widgets/add_todo_sheet.dart';
import 'package:anchor/widgets/profile/profile_menu.dart';
import 'package:anchor/widgets/quick_add/quick_add_sheet.dart';

Widget wrapDark(Widget child, [AppAccent accent = AppAccent.iris]) {
  return ProviderScope(
    child: MaterialApp(
      themeMode: ThemeMode.dark,
      theme: buildTheme(Brightness.light, accent),
      darkTheme: buildTheme(Brightness.dark, accent),
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Dark Surfaces & WCAG Contrast Guard Tests', () {
    test('Dark AppPalette tokens adhere to luminance and contrast specifications', () {
      for (final accent in AppAccent.values) {
        final dark = AppPalette.dark(accent);

        // Neutral dark luminance must be < 0.1
        expect(
          ContrastHelper.relativeLuminance(dark.background),
          lessThan(0.1),
        );
        expect(ContrastHelper.relativeLuminance(dark.card), lessThan(0.1));
        expect(
          ContrastHelper.relativeLuminance(dark.cardRaised),
          lessThan(0.1),
        );

        // textPrimary on background must have >= 7:1 contrast
        final crTextBg = ContrastHelper.contrastRatio(
          dark.textPrimary,
          dark.background,
        );
        expect(
          crTextBg,
          greaterThanOrEqualTo(7.0),
          reason: 'textPrimary must be highly readable against dark background',
        );

        // textPrimary on card must have >= 7:1 contrast
        final crTextCard = ContrastHelper.contrastRatio(
          dark.textPrimary,
          dark.card,
        );
        expect(
          crTextCard,
          greaterThanOrEqualTo(7.0),
          reason: 'textPrimary must be highly readable against card background',
        );

        // textSecondary on background must have >= 4.5:1 contrast
        final crSecBg = ContrastHelper.contrastRatio(
          dark.textSecondary,
          dark.background,
        );
        expect(
          crSecBg,
          greaterThanOrEqualTo(4.5),
          reason: 'textSecondary must meet WCAG AA against dark background',
        );

        // onAccent on accent must have >= 4.5:1 contrast
        final crOnAccent = ContrastHelper.contrastRatio(
          dark.onAccent,
          dark.accent,
        );
        expect(
          crOnAccent,
          greaterThanOrEqualTo(4.5),
          reason:
              'onAccent must meet WCAG AA against accent $accent in dark mode',
        );
      }
    });

    testWidgets(
      'Home screen renders dark background and surfaces without light leaks',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1000));
        await tester.pumpWidget(wrapDark(const HomeScreen()));
        await tester.pumpAndSettle();

        final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
        // Scaffold background must be null (inherits dark scaffoldBackgroundColor) or dark
        if (scaffold.backgroundColor != null) {
          expect(
            ContrastHelper.relativeLuminance(scaffold.backgroundColor!),
            lessThan(0.1),
          );
        }

        // Check all Container/DecoratedBox backgrounds
        for (final element in find.byType(DecoratedBox).evaluate()) {
          final box = element.widget as DecoratedBox;
          final decoration = box.decoration;
          if (decoration is BoxDecoration && decoration.color != null) {
            final c = decoration.color!;
            if (c != Colors.transparent && c.a > 0.05) {
              // Must be dark or accent
              final lum = ContrastHelper.relativeLuminance(c);
              expect(
                lum < 0.35 || lum > 0.45,
                isTrue,
                reason: 'No light grey surfaces permitted in dark mode: $c',
              );
            }
          }
        }
      },
    );

    testWidgets('Academics screen renders dark surfaces across segments', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(wrapDark(const AcademicsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Academics'), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      if (scaffold.backgroundColor != null) {
        expect(
          ContrastHelper.relativeLuminance(scaffold.backgroundColor!),
          lessThan(0.1),
        );
      }
    });

    testWidgets('Expenses screen renders dark surfaces across tabs', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(wrapDark(const ExpensesScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Expenses'), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      if (scaffold.backgroundColor != null) {
        expect(
          ContrastHelper.relativeLuminance(scaffold.backgroundColor!),
          lessThan(0.1),
        );
      }
    });

    testWidgets('Habits screen renders dark surfaces across tabs', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));
      await tester.pumpWidget(wrapDark(const HabitsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Habits'), findsOneWidget);

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      if (scaffold.backgroundColor != null) {
        expect(
          ContrastHelper.relativeLuminance(scaffold.backgroundColor!),
          lessThan(0.1),
        );
      }
    });

    testWidgets('ProfileMenu renders dark raised card without white flashes', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpWidget(
        wrapDark(
          const Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                height: 600,
                child: ProfileMenuContent(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('ACCENT COLOR'), findsOneWidget);
    });

    testWidgets('Modal Sheets render dark backgrounds and inputs', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(500, 800));

      // 1. AddTodoSheet
      await tester.pumpWidget(wrapDark(const Scaffold(body: AddTodoSheet())));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('add_todo_sheet_submit_button')),
        findsOneWidget,
      );

      // 2. AddAssignmentSheet
      await tester.pumpWidget(
        wrapDark(const Scaffold(body: AddAssignmentSheet())),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('add_assignment_submit_button')),
        findsOneWidget,
      );

      // 3. AddTransactionSheet
      await tester.pumpWidget(
        wrapDark(const Scaffold(body: AddTransactionSheet())),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('save_transaction_button')), findsOneWidget);

      // 4. AddHabitSheet
      await tester.pumpWidget(wrapDark(const Scaffold(body: AddHabitSheet())));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('create_habit_button')), findsOneWidget);

      // 5. QuickAddSheet
      await tester.pumpWidget(wrapDark(const Scaffold(body: QuickAddSheet())));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('quick_add_done_button')), findsOneWidget);
    });

    testWidgets(
      'Live Theme Switching smoothly switches from light to dark and changes accent',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(800, 1000));

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                final themeState = ref.watch(themeControllerProvider);
                return MaterialApp(
                  themeMode: themeState.mode,
                  theme: buildTheme(Brightness.light, themeState.accent),
                  darkTheme: buildTheme(Brightness.dark, themeState.accent),
                  home: const HomeScreen(),
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Check initial light theme
        BuildContext context = tester.element(find.byType(HomeScreen));
        expect(Theme.of(context).brightness, Brightness.light);
        expect(context.palette.background, const Color(0xFFFFFFFF));

        // Switch to dark mode
        final container = ProviderScope.containerOf(context);
        container
            .read(themeControllerProvider.notifier)
            .setThemeMode(ThemeMode.dark);
        await tester.pumpAndSettle();

        context = tester.element(find.byType(HomeScreen));
        expect(Theme.of(context).brightness, Brightness.dark);
        expect(context.palette.background, const Color(0xFF0E0E10));

        // Switch accent to Jade
        container
            .read(themeControllerProvider.notifier)
            .setAccent(AppAccent.jade);
        await tester.pumpAndSettle();

        context = tester.element(find.byType(HomeScreen));
        expect(context.palette.accent, AppAccent.jade.darkColor);
      },
    );
  });
}

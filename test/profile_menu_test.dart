import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/widgets/profile/profile_avatar.dart';
import 'package:anchor/widgets/profile/profile_menu.dart';

Widget wrapWithProfileScope(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: buildTheme(Brightness.light, AppAccent.iris),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Polish Stage 2 - Profile Avatar Tests', () {
    testWidgets('ProfileAvatar renders fallback initials when no user is signed in', (tester) async {
      await tester.pumpWidget(
        wrapWithProfileScope(
          const ProfileAvatar(size: 36),
        ),
      );

      expect(find.byType(ProfileAvatar), findsOneWidget);
      expect(find.text('U'), findsOneWidget);
    });

    test('ProfileAvatar.getInitials extracts uppercase initials properly', () {
      expect(ProfileAvatar.getInitials(null), 'U');
    });

    test('ProfileAvatar.getDisplayName extracts user display name or fallback', () {
      expect(ProfileAvatar.getDisplayName(null), 'User');
    });
  });

  group('Polish Stage 2 - Profile Menu & Theme Picker Tests', () {
    testWidgets('ProfileMenuContent displays appearance controls, swatches, preview, and sign out', (tester) async {
      await tester.pumpWidget(
        wrapWithProfileScope(
          const SizedBox(
            width: 340,
            height: 600,
            child: ProfileMenuContent(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Appearance segmented control
      expect(find.text('APPEARANCE'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Dark'), findsOneWidget);
      expect(find.text('System'), findsOneWidget);

      // Accent color section with 7 swatches
      expect(find.text('ACCENT COLOR'), findsOneWidget);
      for (final accent in AppAccent.values) {
        expect(find.text(accent.displayName), findsOneWidget);
      }

      // Preview strip
      expect(find.text('PREVIEW'), findsOneWidget);
      expect(find.text('Daily Goals'), findsOneWidget);
      expect(find.text('70%'), findsOneWidget);

      // Account sign out
      expect(find.text('Sign out'), findsOneWidget);
    });

    testWidgets('Tapping Dark mode on segmented control updates theme mode', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(Brightness.light, AppAccent.iris),
            home: const Scaffold(
              body: SizedBox(
                width: 340,
                height: 600,
                child: ProfileMenuContent(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Dark
      await tester.tap(find.text('Dark'));
      await tester.pumpAndSettle();

      expect(container.read(themeControllerProvider).mode, ThemeMode.dark);
    });

    testWidgets('Tapping an accent swatch updates active accent color', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(Brightness.light, AppAccent.iris),
            home: const Scaffold(
              body: SizedBox(
                width: 340,
                height: 600,
                child: ProfileMenuContent(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap Jade accent swatch by key
      await tester.tap(find.byKey(const Key('accent_swatch_jade')));
      await tester.pumpAndSettle();

      expect(container.read(themeControllerProvider).accent, AppAccent.jade);
    });

    testWidgets('Tapping Sign out displays confirmation dialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        wrapWithProfileScope(
          const SizedBox(
            width: 340,
            height: 900,
            child: ProfileMenuContent(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out of Anchor?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel closes dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out of Anchor?'), findsNothing);
    });
  });

  group('Polish Stage 2 - Overflow & Responsiveness Tests', () {
    testWidgets('ProfileMenuContent does not overflow at 360x640 with text scale 1.3', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.light, AppAccent.iris),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: const TextScaler.linear(1.3),
              ),
              child: child!,
            ),
            home: const Scaffold(
              body: ProfileMenuContent(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('ProfileMenuContent does not overflow on desktop 1280x800', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.light, AppAccent.iris),
            home: const Scaffold(
              body: SizedBox(
                width: 340,
                height: 640,
                child: ProfileMenuContent(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/constants/theme.dart';
import 'package:anchor/widgets/app_card.dart';
import 'package:anchor/widgets/empty_state.dart';
import 'package:anchor/widgets/motion/animated_checkbox.dart';
import 'package:anchor/widgets/motion/animated_progress_bar.dart';
import 'package:anchor/widgets/motion/collapse_on_remove.dart';
import 'package:anchor/widgets/motion/count_up_text.dart';
import 'package:anchor/widgets/motion/fade_slide_in.dart';
import 'package:anchor/widgets/motion/pressable_scale.dart';
import 'package:anchor/widgets/motion/pulse_ring.dart';
import 'package:anchor/widgets/section_header.dart';
import 'package:anchor/widgets/skeleton_box.dart';
import 'package:anchor/widgets/stat_chip.dart';
import 'package:anchor/widgets/tag.dart';

Widget wrapWithTheme(Widget child) {
  return MaterialApp(
    theme: buildTheme(Brightness.light, AppAccent.iris),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Polish Stage 1 - Motion Widgets Tests', () {
    testWidgets('PressableScale renders child and responds to tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          PressableScale(
            onTap: () => tapped = true,
            child: const Text('Tap Me'),
          ),
        ),
      );

      expect(find.text('Tap Me'), findsOneWidget);
      await tester.tap(find.text('Tap Me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('AnimatedCheckbox toggles value and triggers onChanged', (tester) async {
      bool value = false;
      await tester.pumpWidget(
        wrapWithTheme(
          StatefulBuilder(
            builder: (context, setState) {
              return AnimatedCheckbox(
                value: value,
                onChanged: (newVal) {
                  setState(() => value = newVal);
                },
              );
            },
          ),
        ),
      );

      expect(find.byType(AnimatedCheckbox), findsOneWidget);
      await tester.tap(find.byType(AnimatedCheckbox));
      await tester.pumpAndSettle();
      expect(value, isTrue);
    });

    testWidgets('AnimatedProgressBar renders progress and animates value change', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const SizedBox(
            width: 200,
            child: AnimatedProgressBar(value: 0.5),
          ),
        ),
      );

      expect(find.byType(AnimatedProgressBar), findsOneWidget);
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        wrapWithTheme(
          const SizedBox(
            width: 200,
            child: AnimatedProgressBar(value: 0.8),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(AnimatedProgressBar), findsOneWidget);
    });

    testWidgets('CountUpText renders target value', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const CountUpText(
            value: 42,
            style: TextStyle(fontSize: 16),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('FadeSlideIn renders child with animation', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const FadeSlideIn(
            index: 1,
            child: Text('Fade In Content'),
          ),
        ),
      );

      expect(find.text('Fade In Content'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Fade In Content'), findsOneWidget);
    });

    testWidgets('PulseRing renders child and animates on trigger change', (tester) async {
      bool trigger = false;
      await tester.pumpWidget(
        wrapWithTheme(
          StatefulBuilder(
            builder: (context, setState) {
              return PulseRing(
                trigger: trigger,
                child: GestureDetector(
                  onTap: () => setState(() => trigger = !trigger),
                  child: const Text('Pulse Target'),
                ),
              );
            },
          ),
        ),
      );

      expect(find.text('Pulse Target'), findsOneWidget);
      await tester.tap(find.text('Pulse Target'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Pulse Target'), findsOneWidget);
    });

    testWidgets('CollapseOnRemove collapses when isRemoved is true', (tester) async {
      bool isRemoved = false;
      await tester.pumpWidget(
        wrapWithTheme(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  CollapseOnRemove(
                    isRemoved: isRemoved,
                    child: const Text('Collapsing item'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => isRemoved = true),
                    child: const Text('Remove'),
                  ),
                ],
              );
            },
          ),
        ),
      );

      expect(find.text('Collapsing item'), findsOneWidget);
      await tester.tap(find.text('Remove'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.byType(CollapseOnRemove), findsOneWidget);
    });
  });

  group('Polish Stage 1 - Shared Polished Widgets Tests', () {
    testWidgets('EmptyState displays icon, title, message and action', (tester) async {
      bool ctaPressed = false;
      await tester.pumpWidget(
        wrapWithTheme(
          EmptyState(
            icon: Icons.school_outlined,
            title: 'No Items Found',
            message: 'Tap the button to create a new item.',
            action: ElevatedButton(
              onPressed: () => ctaPressed = true,
              child: const Text('Add Item'),
            ),
          ),
        ),
      );

      expect(find.text('No Items Found'), findsOneWidget);
      expect(find.text('Tap the button to create a new item.'), findsOneWidget);
      expect(find.text('Add Item'), findsOneWidget);

      await tester.tap(find.text('Add Item'));
      expect(ctaPressed, isTrue);
    });

    testWidgets('AppCard renders header, trailing, child, and handles tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        wrapWithTheme(
          AppCard(
            header: const Text('Card Header'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => tapped = true,
            child: const Text('Card Body'),
          ),
        ),
      );

      expect(find.text('Card Header'), findsOneWidget);
      expect(find.text('Card Body'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

      await tester.tap(find.text('Card Body'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('SectionHeader displays title, count chip, and trailing action', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const SectionHeader(
            title: 'Active Modules',
            count: 5,
            trailing: Icon(Icons.more_horiz),
          ),
        ),
      );

      expect(find.text('Active Modules'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.byIcon(Icons.more_horiz), findsOneWidget);
    });

    testWidgets('Tag displays label and icon', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const Tag(
            label: 'Mathematics',
            icon: Icons.calculate_outlined,
          ),
        ),
      );

      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.byIcon(Icons.calculate_outlined), findsOneWidget);
    });

    testWidgets('StatChip displays icon, value, and label', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const StatChip(
            icon: Icons.local_fire_department,
            value: '14',
            label: 'Day Streak',
          ),
        ),
      );

      expect(find.text('14'), findsOneWidget);
      expect(find.text('Day Streak'), findsOneWidget);
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
    });

    testWidgets('SkeletonBox renders without crashing', (tester) async {
      await tester.pumpWidget(
        wrapWithTheme(
          const SkeletonBox(
            width: 100,
            height: 20,
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(SkeletonBox), findsOneWidget);
    });
  });
}

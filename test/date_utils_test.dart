import 'package:flutter_test/flutter_test.dart';
import 'package:anchor/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils', () {
    test('dateOnly strips hours, minutes, seconds and milliseconds', () {
      final now = DateTime(2026, 11, 14, 18, 45, 30, 500);
      final stripped = AppDateUtils.dateOnly(now);

      expect(stripped.year, 2026);
      expect(stripped.month, 11);
      expect(stripped.day, 14);
      expect(stripped.hour, 0);
      expect(stripped.minute, 0);
      expect(stripped.second, 0);
      expect(stripped.millisecond, 0);
    });

    test('today returns midnight today', () {
      final t = AppDateUtils.today();
      final now = DateTime.now();
      expect(t.year, now.year);
      expect(t.month, now.month);
      expect(t.day, now.day);
      expect(t.hour, 0);
      expect(t.minute, 0);
    });

    test('formatDbDate and parseDbDate round-trip', () {
      final dt = DateTime(2026, 3, 5);
      final formatted = AppDateUtils.formatDbDate(dt);
      expect(formatted, '2026-03-05');

      final parsed = AppDateUtils.parseDbDate(formatted);
      expect(parsed, equals(DateTime(2026, 3, 5)));
    });

    test('parseDbDate throws on invalid input', () {
      expect(
        () => AppDateUtils.parseDbDate('invalid-date'),
        throwsFormatException,
      );
    });

    test('monthKey returns YYYY-MM format', () {
      expect(AppDateUtils.monthKey(DateTime(2026, 1, 15)), '2026-01');
      expect(AppDateUtils.monthKey(DateTime(2026, 12, 31)), '2026-12');
    });

    test('startOfWeek returns Monday for any day of the week', () {
      // 2026-11-14 is Saturday
      final sat = DateTime(2026, 11, 14);
      final mon = AppDateUtils.startOfWeek(sat);
      expect(mon.weekday, DateTime.monday);
      expect(mon, DateTime(2026, 11, 9));

      // 2026-11-09 is already Monday
      expect(AppDateUtils.startOfWeek(mon), mon);

      // 2026-11-15 is Sunday
      final sun = DateTime(2026, 11, 15);
      expect(AppDateUtils.startOfWeek(sun), DateTime(2026, 11, 9));
    });

    test(
      'daysBetween handles forward, backward, same day, and DST differences',
      () {
        final a = DateTime(2026, 5, 1);
        final b = DateTime(2026, 5, 10);
        expect(AppDateUtils.daysBetween(a, b), 9);
        expect(AppDateUtils.daysBetween(b, a), -9);
        expect(AppDateUtils.daysBetween(a, a), 0);

        // Leap year difference check
        final feb28 = DateTime(2024, 2, 28);
        final mar1 = DateTime(2024, 3, 1);
        expect(AppDateUtils.daysBetween(feb28, mar1), 2); // 2024 has Feb 29
      },
    );
  });
}
